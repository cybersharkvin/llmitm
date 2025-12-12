#!/bin/bash

# ctags architectural analysis script for Next.js projects
# Generates markdown overview at .claude/memory/tags.md
# Adapted for Claude Code CLI hooks

# Change to project directory using Claude's environment variable
if [[ -n "$CLAUDE_PROJECT_DIR" ]]; then
    cd "$CLAUDE_PROJECT_DIR"
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0"
    echo "  Reads paths from .claude/tags.conf and outputs to .claude/memory/tags.md"
    exit 0
fi

CONF_FILE=".claude/tags.conf"
OUTPUT=".claude/memory/tags.md"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "Error: $CONF_FILE not found"
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
TEMP=$(mktemp)

# Generate ctags data from all configured paths
while IFS= read -r path; do
    [[ -z "$path" || "$path" =~ ^# ]] && continue
    if [[ -e "$path" ]]; then
        echo "Processing: $path"
        ctags --kinds-TypeScript=fciCvmpa --kinds-JavaScript=fcvmp --fields=+iSnt \
            --exclude=node_modules --exclude=.next --exclude=.git \
            --languages=TypeScript,JavaScript \
            --langmap=TypeScript:.ts.tsx --langmap=JavaScript:.js.jsx.mjs \
            --output-format=json -f - -R "$path" >> "$TEMP"
    fi
done < "$CONF_FILE"

# Scan root-level config files separately
for config in *.config.js *.config.ts *.config.mjs; do
    if [[ -f "$config" ]]; then
        echo "Processing: $config"
        ctags --kinds-TypeScript=fciCvmpa --kinds-JavaScript=fcvmp --fields=+iSnt \
            --languages=TypeScript,JavaScript \
            --langmap=TypeScript:.ts.tsx --langmap=JavaScript:.js.jsx.mjs \
            --output-format=json -f - "$config" >> "$TEMP"
    fi
done

# Build markdown file section by section
cat > "$OUTPUT" << 'EOF'
# Next.js Architecture Overview

## App Router Structure

### Pages
EOF

cat "$TEMP" | jq -sr '
  [.[] | select((.path | test("(^|/)page\\.(tsx?|jsx?)$")) and (.path | test("(^|/)app/")))] |
  if length > 0 then
    sort_by(.path) | map("- **\(.path | gsub("(^|/)page\\.(tsx?|jsx?)$"; ""))** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No App Router pages found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "### Layouts" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select((.path | test("(^|/)layout\\.(tsx?|jsx?)$")) and (.path | test("(^|/)app/")))] |
  if length > 0 then
    sort_by(.path) | map("- **\(.path | gsub("(^|/)layout\\.(tsx?|jsx?)$"; ""))** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No layouts found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "### Loading & Error States" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select((.path | test("(^|/)(loading|error|not-found)\\.(tsx?|jsx?)$")) and (.path | test("(^|/)app/")))] |
  if length > 0 then
    sort_by(.path) | map("- **\(.path | gsub("(^|/)(loading|error|not-found)\\.(tsx?|jsx?)$"; ""))** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No loading/error states found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "### API Routes" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select((.path | test("(^|/)route\\.(ts|js)$")) and (.path | test("(^|/)app/")))] |
  if length > 0 then
    sort_by(.path) | map("- **\(.name)**() (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No API routes found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Pages Router (Legacy)" >> "$OUTPUT"
echo "" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select((.path | test("(^|/)pages/")) and (.path | test("\\.(tsx?|jsx?)$")) and (.path | test("(^|/)api/") | not))] |
  if length > 0 then
    sort_by(.path) | map("- **\(.path | gsub("^.*pages"; "") | gsub("\\.(tsx?|jsx?)$"; "") | gsub("/index$"; ""))** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No Pages Router routes found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "### API Routes" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select((.path | test("(^|/)pages/api/")))] |
  if length > 0 then
    sort_by(.path) | map("- **\(.name)**() (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No Pages Router API routes found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## TypeScript Interfaces" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select(.kind == "interface")] |
  if length > 0 then
    sort_by(.name) | map("- **\(.name)** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No interfaces found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Type Aliases" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select(.kind == "alias")] |
  if length > 0 then
    sort_by(.name) | map("- **\(.name)** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No type aliases found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Classes" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select(.kind == "class")] |
  if length > 0 then
    sort_by(.name) | map("- **\(.name)** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No classes found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Methods" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  def extract_sig:
    if .pattern then
      (.pattern | gsub("^/\\^"; "") | gsub("\\$/$"; "") |
       if test("\\([^)]*\\)") then
         (capture("\\((?<params>[^)]*)\\)(?:\\s*:\\s*(?<ret>[\\w<>\\[\\]]+))?") |
          "(\(.params))\(if .ret then ": " + .ret else "" end)")
       else "()" end)
    else "()" end;
  [.[] | select(.kind == "method")] |
  if length > 0 then
    group_by(.scope) | map(
      "### \(.[0].scope // "Global")\n" +
      (sort_by(.name) | map("- **\(.name)**\(extract_sig) (`\(.path):\(.line // "?")`)")  | join("\n"))
    ) | .[]
  else
    "- No methods found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Custom Hooks" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  def extract_sig:
    if .pattern then
      (.pattern | gsub("^/\\^"; "") | gsub("\\$/$"; "") |
       if test("\\([^)]*\\)") then
         (capture("\\((?<params>[^)]*)\\)(?:\\s*:\\s*(?<ret>[\\w<>\\[\\]]+))?") |
          "(\(.params))\(if .ret then ": " + .ret else "" end)")
       else "()" end)
    else "()" end;
  [.[] | select(.kind == "function" and (.name | test("^use[A-Z]")))] |
  if length > 0 then
    sort_by(.name) | map("- **\(.name)**\(extract_sig) (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No custom hooks found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Components" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select(.kind == "function" and (.name | test("^[A-Z]")) and (.path | test("(^|/)page\\.(tsx?|jsx?)$") | not) and (.path | test("(^|/)route\\.(ts|js)$") | not))] |
  if length > 0 then
    sort_by(.name) | map("- **\(.name)** (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No components found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Utility Functions" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  def extract_sig:
    if .pattern then
      (.pattern | gsub("^/\\^"; "") | gsub("\\$/$"; "") |
       if test("\\([^)]*\\)") then
         (capture("\\((?<params>[^)]*)\\)(?:\\s*:\\s*(?<ret>[\\w<>\\[\\]]+))?") |
          "(\(.params))\(if .ret then ": " + .ret else "" end)")
       else "()" end)
    else "()" end;
  [.[] | select(.kind == "function" and (.name | test("^[a-z]")) and (.name | test("^use[A-Z]") | not))] |
  if length > 0 then
    sort_by(.name) | map("- **\(.name)**\(extract_sig) (`\(.path):\(.line // "?")`)")  | .[]
  else
    "- No utility functions found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Configuration Files" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[] | select(.path | test("(next\\.config|tailwind\\.config|jest\\.config|playwright\\.config|middleware|instrumentation)\\.(js|ts|mjs)$"))] |
  map(select(.name | test("^(\\d+%|from|to|0%|100%)$") | not)) |
  if length > 0 then
    sort_by(.path) | map("- **\(.name)** in `\(.path):\(.line // "?")`")  | .[]
  else
    "- No configuration files found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## File Inventory" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "All source files analyzed:" >> "$OUTPUT"

cat "$TEMP" | jq -sr '
  [.[].path] | unique | sort |
  if length > 0 then
    group_by(. | split("/")[0:2] | join("/")) |
    map(
      "### " + (.[0] | split("/")[0:2] | join("/")) + " (" + (length | tostring) + " files)\n" +
      (map("- `\(.)`") | join("\n"))
    ) | .[]
  else
    "- No source files found"
  end
' >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "## Import Analysis" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "_Note: Imports cannot be captured via ctags. For import analysis, use grep or AST parsing tools._" >> "$OUTPUT"

# Token counting
if command -v python3 &> /dev/null && python3 -c "import tiktoken" 2>/dev/null; then
    TOTAL_TOKENS=0

    TAGS_TOKENS=$(python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
with open('$OUTPUT', 'r') as f:
    print(len(enc.encode(f.read())))
" 2>/dev/null)

    if [[ -n "$TAGS_TOKENS" ]]; then
        TOTAL_TOKENS=$((TOTAL_TOKENS + TAGS_TOKENS))

        while IFS= read -r path; do
            [[ -z "$path" || "$path" =~ ^# ]] && continue
            if [[ -e "$path" ]]; then
                PATH_TOKENS=$(find "$path" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.mjs" \) 2>/dev/null -exec python3 -c "
import tiktoken, sys
enc = tiktoken.get_encoding('cl100k_base')
total = 0
for file in sys.argv[1:]:
    try:
        with open(file, 'r') as f:
            total += len(enc.encode(f.read()))
    except: pass
print(total)
" {} + 2>/dev/null)
                [[ -n "$PATH_TOKENS" ]] && TOTAL_TOKENS=$((TOTAL_TOKENS + PATH_TOKENS))
            fi
        done < "$CONF_FILE"

        echo "" >> "$OUTPUT"
        echo "## Token Count" >> "$OUTPUT"
        echo "" >> "$OUTPUT"
        echo "Total tokens (cl100k_base): $TOTAL_TOKENS" >> "$OUTPUT"
    fi
fi

rm -f "$TEMP"
echo "Architecture analysis saved to: $OUTPUT"
