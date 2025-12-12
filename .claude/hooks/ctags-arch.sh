#!/bin/bash

# ctags architectural analysis script with configuration support
# 
# Generates a markdown architectural overview of Python codebases
# showing plugin patterns, inheritance hierarchies, and component categories
#
# Usage: 
#   ./ctags-arch.sh                        # Uses .claude/tags.conf -> .claude/memory/tags.md
#
# Requirements: ctags, jq, .claude/tags.conf, python tiktoken module/library

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

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT")"

# Create temporary file for combined ctags output
TEMP_TAGS=$(mktemp)

# Process each path in config file
while IFS= read -r path; do
    [[ -z "$path" || "$path" =~ ^# ]] && continue  # Skip empty lines and comments
    if [[ -e "$path" ]]; then
        echo "Processing: $path"
        ctags --kinds-python=cfm --fields=+iSn --exclude=__pycache__ --exclude=.venv --exclude=node_modules --exclude=.git --languages=python --output-format=json -f - -R "$path" >> "$TEMP_TAGS"
    else
        echo "Warning: Path not found: $path" >&2
    fi
done < "$CONF_FILE"

# Generate architecture markdown from combined tags
cat "$TEMP_TAGS" | jq -s --raw-output '
def safe_inherits: if has("inherits") then .inherits else false end;
def safe_signature: if has("signature") then .signature else "()" end;
def safe_line: if has("line") then ":\(.line)" else "" end;

"# Code Architecture Overview\n",
"## Plugin Architecture\n",
"### Abstract Base Classes",
([.[] | select(.kind == "class" and safe_inherits == "ABC")] | map("- **\(.name)** (`\(.path)\(safe_line)`)")[] // empty),
"\n### Concrete Implementations", 
([.[] | select(.kind == "class" and safe_inherits != false and safe_inherits != "ABC")] | map("- **\(.name)** extends `\(safe_inherits)` (`\(.path)\(safe_line)`)")[] // empty),
"\n### Factory Functions",
([.[] | select(.kind == "function" and (.name | contains("create") or contains("factory") or contains("build") or contains("make")))] | map("- **\(.name)**\(safe_signature) (`\(.path)\(safe_line)`)")[] // empty),
"\n## All Classes",
([.[] | select(.kind == "class")] | map("- **\(.name)** (`\(.path)\(safe_line)`)")[] // empty),
"\n## All Functions", 
([.[] | select(.kind == "function")] | map("- **\(.name)**\(safe_signature) (`\(.path)\(safe_line)`)")[] // empty),
"\n## All Methods",
([.[] | select(.kind == "member")] | map("- **\(.name)**\(safe_signature) (`\(.path)\(safe_line)`)")[] // empty)
' > "$OUTPUT"

# Calculate tokens for all configured paths
if python3 -c "import tiktoken" 2>/dev/null; then
    TOTAL_TOKENS=0
    
    # Add tokens from the generated tags.md
    TAGS_TOKENS=$(python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
with open('$OUTPUT', 'r') as f:
    content = f.read()
print(len(enc.encode(content)))
")
    TOTAL_TOKENS=$((TOTAL_TOKENS + TAGS_TOKENS))
    
    # Add tokens from all configured files/folders
    while IFS= read -r path; do
        [[ -z "$path" || "$path" =~ ^# ]] && continue
        if [[ -e "$path" ]]; then
            PATH_TOKENS=$(find "$path" -name "*.py" -type f -exec python3 -c "
import tiktoken
import sys
enc = tiktoken.get_encoding('cl100k_base')
total = 0
for file in sys.argv[1:]:
    try:
        with open(file, 'r') as f:
            total += len(enc.encode(f.read()))
    except:
        pass
print(total)
" {} +)
            TOTAL_TOKENS=$((TOTAL_TOKENS + PATH_TOKENS))
        fi
    done < "$CONF_FILE"
    
    echo -e "\n## Token Count\n\nTotal tokens (cl100k_base): $TOTAL_TOKENS" >> "$OUTPUT"
fi

# Cleanup
rm -f "$TEMP_TAGS"

echo "Architecture analysis saved to: $OUTPUT"