#!/bin/bash

input_json=$(cat)
user_prompt=$(echo "$input_json" | jq -r '.prompt')

# Skip atomization if user prefixes with "no-atom"
if [[ "$user_prompt" == no-atom* ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DEBUG_LOG="$PROJECT_DIR/.claude/atomDebug.md"
TASK_FILE="$PROJECT_DIR/.claude/memory/task.md"

echo -e "# Atomizer Debug Log\n**$(date)**\n\n## Prompt\n\`\`\`\n$user_prompt\n\`\`\`\n" > "$DEBUG_LOG"

# Spawn planning agent with NO tools (forces pure text output, no execution)
# --system-prompt replaces agent prompt with strict schema enforcement
SCHEMA='You are a task atomizer. Output ONLY a JSON object with these EXACT keys:
{
  "task": "Brief description",
  "objectives": ["Goal 1", "Goal 2"],
  "dependencies": {
    "prerequisites": ["Required before starting"],
    "sequential": ["Must happen in order"],
    "parallel": ["Can happen simultaneously"]
  },
  "atomic_actions": [
    {"step": 1, "action": "Task description", "input": "What step needs", "output": "What step produces", "file": "path/if/applicable"}
  ],
  "success_criteria": {
    "per_step": ["How to verify each step"],
    "overall": "What constitutes complete success"
  }
}
NO MARKDOWN FENCES. NO PREAMBLE. NO EXPLANATION. ONLY THE JSON OBJECT.'

RESULT=$(cd "$PROJECT_DIR" && echo "$user_prompt" | claude -p \
  --output-format json \
  --settings .claude/no-hooks.json \
  --tools "" \
  --system-prompt "$SCHEMA" \
  2>/dev/null)

echo -e "## Raw Response\n\`\`\`json\n$RESULT\n\`\`\`\n" >> "$DEBUG_LOG"

# Extract .result field from wrapper
RAW_RESULT=$(echo "$RESULT" | jq -r '.result // empty' 2>/dev/null)

if [[ -z "$RAW_RESULT" ]]; then
  echo -e "## Result\n⚠️ No result returned" >> "$DEBUG_LOG"
  exit 0
fi

# Extract just the JSON object (strip markdown fences, then parse)
TASK_JSON=$(echo "$RAW_RESULT" | sed 's/```json//g; s/```//g' | jq '.' 2>/dev/null)

if [[ -z "$TASK_JSON" || "$TASK_JSON" == "null" ]]; then
  echo -e "## Extraction Failed\nRaw result:\n\`\`\`\n$RAW_RESULT\n\`\`\`" >> "$DEBUG_LOG"
  exit 0
fi

echo -e "## Cleaned JSON\n\`\`\`json\n$TASK_JSON\n\`\`\`" >> "$DEBUG_LOG"

# Write task breakdown directly to task.md
echo "$TASK_JSON" > "$TASK_FILE"
echo -e "\n## Written to\n$TASK_FILE" >> "$DEBUG_LOG"

# Return minimal context to primary agent - just point to the file
jq -n '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: "Task breakdown saved to .claude/memory/task.md - read it and execute the plan."
  }
}'