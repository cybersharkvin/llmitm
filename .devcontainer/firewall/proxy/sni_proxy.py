"""
Lightweight transparent proxy with SNI-based filtering.
No TLS decryption - just reads Host header (HTTP) or SNI (HTTPS).
"""
from __future__ import annotations

import asyncio
import logging
import socket
import struct
from typing import Optional, Tuple

from models import ProxyConfig
from sni_parser import extract_sni

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("sni_proxy")


class SNIProxy:
    """Transparent proxy that filters by domain using SNI/Host header."""

    def __init__(self, config: ProxyConfig) -> None:
        self.config = config

    async def handle_http(
        self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        """Handle HTTP connection - extract Host header."""
        client_addr = writer.get_extra_info("peername")

        try:
            # Read HTTP request line and headers
            request_data = await asyncio.wait_for(reader.read(8192), timeout=10.0)
            if not request_data:
                return

            # Extract Host header
            host = self._extract_http_host(request_data)
            if not host:
                logger.warning(f"[BLOCK] {client_addr} - No Host header")
                return

            # Check allowlist
            if not self.config.is_allowed(host):
                if self.config.log_blocked:
                    logger.warning(f"[BLOCK] {client_addr} -> {host}")
                return

            if self.config.log_allowed:
                logger.info(f"[ALLOW] {client_addr} -> {host}")

            # Get original destination (from iptables redirect)
            orig_dst = self._get_original_dst(writer)
            if not orig_dst:
                # Fallback: resolve host
                orig_dst = (host, 80)

            # Connect to destination and forward
            await self._forward_connection(
                reader, writer, request_data, orig_dst[0], orig_dst[1]
            )

        except asyncio.TimeoutError:
            logger.debug(f"Timeout from {client_addr}")
        except Exception as e:
            logger.error(f"Error handling HTTP: {e}")
        finally:
            writer.close()
            await writer.wait_closed()

    async def handle_https(
        self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        """Handle HTTPS connection - extract SNI from ClientHello."""
        client_addr = writer.get_extra_info("peername")

        try:
            # Read TLS ClientHello
            client_hello = await asyncio.wait_for(reader.read(8192), timeout=10.0)
            if not client_hello:
                return

            # Extract SNI
            sni = extract_sni(client_hello)
            if not sni:
                logger.warning(f"[BLOCK] {client_addr} - No SNI")
                return

            # Check allowlist
            if not self.config.is_allowed(sni):
                if self.config.log_blocked:
                    logger.warning(f"[BLOCK] {client_addr} -> {sni}:443")
                return

            if self.config.log_allowed:
                logger.info(f"[ALLOW] {client_addr} -> {sni}:443")

            # Get original destination
            orig_dst = self._get_original_dst(writer)
            if not orig_dst:
                orig_dst = (sni, 443)

            # Connect to destination and forward (including ClientHello)
            await self._forward_connection(
                reader, writer, client_hello, orig_dst[0], orig_dst[1]
            )

        except asyncio.TimeoutError:
            logger.debug(f"Timeout from {client_addr}")
        except Exception as e:
            logger.error(f"Error handling HTTPS: {e}")
        finally:
            writer.close()
            await writer.wait_closed()

    def _extract_http_host(self, data: bytes) -> Optional[str]:
        """Extract Host header from HTTP request."""
        try:
            headers = data.decode("utf-8", errors="ignore")
            for line in headers.split("\r\n"):
                if line.lower().startswith("host:"):
                    host = line.split(":", 1)[1].strip()
                    # Remove port if present
                    if ":" in host:
                        host = host.split(":")[0]
                    return host
        except Exception:
            pass
        return None

    def _get_original_dst(
        self, writer: asyncio.StreamWriter
    ) -> Optional[Tuple[str, int]]:
        """Get original destination from iptables REDIRECT (SO_ORIGINAL_DST)."""
        try:
            sock = writer.get_extra_info("socket")
            if sock is None:
                return None
            # SO_ORIGINAL_DST = 80
            dst = sock.getsockopt(socket.SOL_IP, 80, 16)
            port = struct.unpack("!H", dst[2:4])[0]
            ip = socket.inet_ntoa(dst[4:8])
            return (ip, port)
        except Exception:
            return None

    async def _forward_connection(
        self,
        client_reader: asyncio.StreamReader,
        client_writer: asyncio.StreamWriter,
        initial_data: bytes,
        dest_host: str,
        dest_port: int,
    ) -> None:
        """Forward connection to destination, bidirectionally."""
        dest_writer: Optional[asyncio.StreamWriter] = None
        try:
            # Connect to destination
            dest_reader, dest_writer = await asyncio.wait_for(
                asyncio.open_connection(dest_host, dest_port),
                timeout=10.0,
            )

            # Send initial data (request/ClientHello)
            dest_writer.write(initial_data)
            await dest_writer.drain()

            # Bidirectional forwarding
            await asyncio.gather(
                self._pipe(client_reader, dest_writer),
                self._pipe(dest_reader, client_writer),
            )

        except Exception as e:
            logger.debug(f"Forward error to {dest_host}:{dest_port}: {e}")
        finally:
            if dest_writer is not None:
                try:
                    dest_writer.close()
                    await dest_writer.wait_closed()
                except Exception:
                    pass

    async def _pipe(
        self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        """Pipe data from reader to writer."""
        try:
            while True:
                data = await reader.read(65536)
                if not data:
                    break
                writer.write(data)
                await writer.drain()
        except Exception:
            pass

    async def start(self) -> None:
        """Start HTTP and HTTPS proxy servers."""
        http_server = await asyncio.start_server(
            self.handle_http, "0.0.0.0", self.config.http_port
        )
        https_server = await asyncio.start_server(
            self.handle_https, "0.0.0.0", self.config.https_port
        )

        logger.info(f"HTTP proxy listening on :{self.config.http_port}")
        logger.info(f"HTTPS proxy listening on :{self.config.https_port}")
        logger.info(f"Allowlist: {[r.pattern for r in self.config.allowlist]}")
        logger.info(f"System domains: {self.config.system_domains}")

        async with http_server, https_server:
            await asyncio.gather(
                http_server.serve_forever(),
                https_server.serve_forever(),
            )


async def main() -> None:
    """Entry point."""
    config = ProxyConfig.from_env()
    proxy = SNIProxy(config)
    await proxy.start()


if __name__ == "__main__":
    asyncio.run(main())
