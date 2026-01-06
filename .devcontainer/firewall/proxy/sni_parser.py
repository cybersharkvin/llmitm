"""
Parse SNI (Server Name Indication) from TLS ClientHello.
No TLS decryption - just reads the handshake.
"""
from __future__ import annotations

import struct
from typing import Optional


def extract_sni(data: bytes) -> Optional[str]:
    """
    Extract SNI hostname from TLS ClientHello.
    Returns None if not a valid ClientHello or no SNI present.
    """
    if len(data) < 5:
        return None

    # TLS record header
    content_type = data[0]
    if content_type != 0x16:  # Handshake
        return None

    # TLS version (we don't care which)
    # data[1:3] is version

    # Record length
    record_length = struct.unpack("!H", data[3:5])[0]
    if len(data) < 5 + record_length:
        return None

    # Handshake header
    pos = 5
    if pos >= len(data):
        return None

    handshake_type = data[pos]
    if handshake_type != 0x01:  # ClientHello
        return None

    pos += 1
    if pos + 3 > len(data):
        return None

    # Handshake length (3 bytes) - not used but must skip
    # handshake_length = (data[pos] << 16) | (data[pos + 1] << 8) | data[pos + 2]
    pos += 3

    # Client version (2 bytes)
    pos += 2

    # Random (32 bytes)
    pos += 32

    # Session ID
    if pos >= len(data):
        return None
    session_id_length = data[pos]
    pos += 1 + session_id_length

    # Cipher suites
    if pos + 2 > len(data):
        return None
    cipher_suites_length = struct.unpack("!H", data[pos : pos + 2])[0]
    pos += 2 + cipher_suites_length

    # Compression methods
    if pos >= len(data):
        return None
    compression_methods_length = data[pos]
    pos += 1 + compression_methods_length

    # Extensions
    if pos + 2 > len(data):
        return None
    extensions_length = struct.unpack("!H", data[pos : pos + 2])[0]
    pos += 2

    # Parse extensions looking for SNI (type 0x0000)
    extensions_end = pos + extensions_length
    while pos + 4 <= extensions_end and pos + 4 <= len(data):
        ext_type = struct.unpack("!H", data[pos : pos + 2])[0]
        ext_length = struct.unpack("!H", data[pos + 2 : pos + 4])[0]
        pos += 4

        if ext_type == 0x0000:  # SNI extension
            # SNI extension data
            if pos + 2 > len(data):
                return None
            # sni_list_length = struct.unpack("!H", data[pos : pos + 2])[0]
            pos += 2

            if pos + 3 > len(data):
                return None
            sni_type = data[pos]
            sni_length = struct.unpack("!H", data[pos + 1 : pos + 3])[0]
            pos += 3

            if sni_type == 0x00:  # Host name
                if pos + sni_length > len(data):
                    return None
                return data[pos : pos + sni_length].decode("ascii", errors="ignore")

        pos += ext_length

    return None
