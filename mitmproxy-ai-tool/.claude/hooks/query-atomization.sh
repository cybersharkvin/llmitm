#!/bin/bash

# ==============================================================================
# ATOMIZER HOOK - Penetration Testing Task Atomization via Claude Subagent
# ==============================================================================
# This hook intercepts user prompts and breaks them into atomic security testing
# task plans using Claude's Structured Outputs (--json-schema) for guaranteed JSON.
# Debug output goes to .claude/atomDebug.md (preserves previous output on skip)
# ==============================================================================

# Determine paths FIRST before anything else
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DEBUG_LOG="./.claude/atomDebug.md"
TASK_FILE="./.claude/memory/task.json"

# ==============================================================================
# Read Input BEFORE any debug file operations
# ==============================================================================
input_json=$(cat)

# Check if input is valid JSON
if ! echo "$input_json" | jq -e '.' >/dev/null 2>&1; then
  exit 0
fi

user_prompt=$(echo "$input_json" | jq -r '.prompt // empty')

if [[ -z "$user_prompt" ]]; then
  # Write debug log even for empty prompts
  {
    echo "# Atomizer Debug Log - Empty Prompt"
    echo "**$(date)**"
    echo "Input JSON was empty or malformed"
    echo "Raw input: ${input_json:0:200}"
  } > "$DEBUG_LOG"
  exit 0
fi

# ==============================================================================
# Check Skip Conditions - DO NOT WRITE TO DEBUG LOG FOR NO-ATOM
# ==============================================================================
if [[ "$user_prompt" == no-atom* ]]; then
  exit 0
fi

# ==============================================================================
# Collect init info (don't log yet - will log at END)
# ==============================================================================
INIT_INPUT_LEN="${#input_json}"
INIT_PROMPT_LEN="${#user_prompt}"
INIT_PWD="$(pwd)"

# ==============================================================================
# Check Prerequisites (don't log yet)
# ==============================================================================

# Check if claude CLI exists
if ! command -v claude &> /dev/null; then
  exit 0
fi
INIT_CLAUDE_PATH="$(which claude)"

# Check if agent file exists
AGENT_FILE="./.claude/agents/atom.md"
if [[ ! -f "$AGENT_FILE" ]]; then
  exit 0
fi
INIT_AGENT_SIZE="$(wc -c < "$AGENT_FILE")"

# Check if no-hooks settings exist
SETTINGS_FILE="$PROJECT_DIR/.claude/no-hooks.json"
INIT_SETTINGS_EXISTS="$([ -f "$SETTINGS_FILE" ] && echo "EXISTS" || echo "MISSING")"

# Check memory files
INIT_MEMORY_FILES=""
for memfile in session.md hypotheses.md findings.md; do
  filepath="./.claude/memory/$memfile"
  if [[ -f "$filepath" ]]; then
    INIT_MEMORY_FILES+="  - $memfile: EXISTS ($(wc -c < "$filepath") bytes)\n"
  else
    INIT_MEMORY_FILES+="  - $memfile: MISSING\n"
  fi
done

# ==============================================================================
# Read agent file
# ==============================================================================
AGENT_CONTENT=$(cat "$AGENT_FILE" 2>/dev/null)

if [[ -z "$AGENT_CONTENT" ]]; then
  exit 0
fi

# ==============================================================================
# Build JSON Schema
# ==============================================================================
JSON_SCHEMA='{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "task": { "type": "string", "description": "Brief security testing objective" },
    "assumptions": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Implicit assumptions about target behavior, security controls, or business logic"
    },
    "target_analysis": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "application_purpose": { "type": "string", "description": "What the application does" },
        "identified_assumptions": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Business logic and developer assumptions"
        },
        "assumption_gaps": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Where assumptions may be wrong - priority test areas"
        },
        "attack_surface": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Interesting endpoints, parameters, or features to test"
        }
      },
      "required": ["application_purpose", "identified_assumptions", "assumption_gaps", "attack_surface"]
    },
    "objectives": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "primary": { "type": "array", "items": { "type": "string" }, "description": "Main security testing goals" },
        "supporting": { "type": "array", "items": { "type": "string" }, "description": "Enabler goals" }
      },
      "required": ["primary", "supporting"]
    },
    "dependencies": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "prerequisites": { "type": "array", "items": { "type": "string" }, "description": "Required before starting - scope confirmation, auth tokens, captures" },
        "constraints": { "type": "array", "items": { "type": "string" }, "description": "Scope boundaries, allowlisted domains, rate limits" },
        "sequential": { "type": "array", "items": { "type": "string" }, "description": "Steps that must happen in order" },
        "parallel": { "type": "array", "items": { "type": "string" }, "description": "Steps that can happen simultaneously" }
      },
      "required": ["prerequisites", "constraints", "sequential", "parallel"]
    },
    "atomic_actions": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "step": { "type": "integer", "description": "Step number" },
          "phase": {
            "type": "string",
            "enum": ["CAPTURE", "ANALYZE", "MUTATE", "REPLAY", "OBSERVE"],
            "description": "CAMRO workflow phase"
          },
          "type": {
            "type": "string",
            "enum": ["task", "checkpoint", "decision_point"],
            "description": "task=work item, checkpoint=verify before continuing, decision_point=branch based on result"
          },
          "action": { "type": "string", "description": "Single discrete security testing task" },
          "hypothesis": { "type": ["string", "null"], "description": "Vulnerability theory being tested (null for CAPTURE phase)" },
          "input": { "type": "string", "description": "What this step needs" },
          "output": { "type": "string", "description": "What this step produces" },
          "mitmdump_command": { "type": "string", "description": "Exact mitmdump CLI command to execute" },
          "python_addon": { "type": "string", "description": "Python addon code if custom detection logic needed" },
          "file": { "type": "string", "description": "Path to capture/evidence file (in captures/ directory)" },
          "memory_update": {
            "type": "string",
            "enum": ["session", "hypotheses", "findings"],
            "description": "Which memory file to update after this step"
          },
          "depends_on": {
            "type": "array",
            "items": { "type": "integer" },
            "description": "Step numbers this step depends on"
          }
        },
        "required": ["step", "phase", "type", "action", "input", "output", "depends_on"]
      }
    },
    "success_criteria": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "per_step": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "step": { "type": "integer" },
              "criterion": { "type": "string" },
              "measurable": { "type": "boolean" }
            },
            "required": ["step", "criterion", "measurable"]
          }
        },
        "vulnerability_indicators": {
          "type": "array",
          "items": { "type": "string" },
          "description": "What would indicate a security vulnerability exists"
        },
        "overall": { "type": "string", "description": "What constitutes complete success for this testing objective" },
        "quality_standards": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Code quality, style, or technical requirements"
        },
        "acceptance_criteria": {
          "type": "array",
          "items": { "type": "string" },
          "description": "User-facing requirements that define done"
        },
        "evidence_requirements": {
          "type": "array",
          "items": { "type": "string" },
          "description": "What evidence is needed for a valid bug bounty report"
        }
      },
      "required": ["per_step", "vulnerability_indicators", "overall", "quality_standards", "acceptance_criteria", "evidence_requirements"]
    }
  },
  "required": ["task", "assumptions", "target_analysis", "objectives", "dependencies", "atomic_actions", "success_criteria"]
}'

# ==============================================================================
# Execute Claude with Structured Outputs
# ==============================================================================
STDERR_FILE=$(mktemp)
START_TIME=$(date +%s.%N)

# Write initial debug marker to file BEFORE claude command
{
  echo "# Atomizer Debug Log"
  echo "**$(date)** - Starting claude invocation"
  echo "User prompt: $user_prompt"
} > "$DEBUG_LOG"

# Execute claude with explicit 180-second timeout (hooks have 180s total)
# Use --setting-sources user to skip project hooks (prevents recursion)
# NOTE: --settings flag breaks --json-schema (structured_output not populated)
RESULT=$(cd "$PROJECT_DIR" && echo "$user_prompt" | timeout 180 claude -p \
  --model haiku \
  --output-format json \
  --setting-sources user \
  --tools "Read" \
  --system-prompt-file "./.claude/agents/atom.md" \
  --json-schema "$JSON_SCHEMA" \
  2>"$STDERR_FILE")

EXIT_CODE=$?
END_TIME=$(date +%s.%N)
DURATION=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null || echo "unknown")
STDERR_CONTENT=$(cat "$STDERR_FILE" 2>/dev/null)

# If timeout occurred (exit code 124), add immediate debug note
if [[ $EXIT_CODE -eq 124 ]]; then
  {
    echo ""
    echo "**TIMEOUT: claude command exceeded 120-second limit at $(date)**"
  } >> "$DEBUG_LOG"
fi

rm -f "$STDERR_FILE"

# ==============================================================================
# EXTRACT CLI RESPONSE FIELDS FOR DIAGNOSTICS
# ==============================================================================
IS_ERROR=$(echo "$RESULT" | jq -r '.is_error // "unknown"' 2>/dev/null)
SUBTYPE=$(echo "$RESULT" | jq -r '.subtype // "unknown"' 2>/dev/null)
HAS_STRUCTURED=$(echo "$RESULT" | jq 'has("structured_output")' 2>/dev/null)
NUM_TURNS=$(echo "$RESULT" | jq -r '.num_turns // 0' 2>/dev/null)

# Build diagnostic message
DIAGNOSTIC=""
if [[ "$EXIT_CODE" -ne 0 ]]; then
  DIAGNOSTIC="**ERROR**: Exit code $EXIT_CODE (timeout=124, error=1)"
elif [[ "$IS_ERROR" == "true" ]]; then
  DIAGNOSTIC="**ERROR**: is_error=true - request failed"
elif [[ "$SUBTYPE" != "success" ]]; then
  DIAGNOSTIC="**WARNING**: subtype=$SUBTYPE (expected 'success')"
elif [[ "$HAS_STRUCTURED" != "true" ]]; then
  DIAGNOSTIC="**WARNING**: structured_output MISSING despite subtype=success. Possible causes: invalid schema syntax, --settings flag breaking --json-schema, schema too complex"
fi

# Check stderr for schema errors
if [[ -n "$STDERR_CONTENT" ]]; then
  if echo "$STDERR_CONTENT" | grep -qiE "schema|recursive|complex|unsupported|grammar"; then
    DIAGNOSTIC="${DIAGNOSTIC}"$'\n'"**SCHEMA ERROR** in stderr"
  fi
fi

# ==============================================================================
# WRITE RESULTS TO FILES
# ==============================================================================

# Write comprehensive debug log
{
  echo "# Atomizer Debug Log"
  echo "**$(date)**"
  echo ""
  echo "## Execution Summary"
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| Exit Code | $EXIT_CODE |"
  echo "| Duration | ${DURATION}s |"
  echo "| is_error | $IS_ERROR |"
  echo "| subtype | $SUBTYPE |"
  echo "| num_turns | $NUM_TURNS |"
  echo "| structured_output | $([ "$HAS_STRUCTURED" == "true" ] && echo "PRESENT" || echo "**MISSING**") |"
  echo "| Working Dir | $INIT_PWD |"
  echo "| Claude Path | $INIT_CLAUDE_PATH |"
  echo "| Agent File | $AGENT_FILE ($INIT_AGENT_SIZE bytes) |"
  echo ""
  echo "## Memory Files"
  echo -e "$INIT_MEMORY_FILES"
  echo ""
  if [[ -n "$DIAGNOSTIC" ]]; then
    echo "## Diagnostics"
    echo "$DIAGNOSTIC"
    echo ""
  fi
  echo "## User Prompt"
  echo '```'
  echo "$user_prompt"
  echo '```'
  echo ""
  echo "## stderr Output"
  if [[ -n "$STDERR_CONTENT" ]]; then
    echo '```'
    echo "$STDERR_CONTENT"
    echo '```'
  else
    echo "_No stderr output_"
  fi
  echo ""
  echo "## stdout (Raw Response)"
  echo '```json'
  echo "$RESULT"
  echo '```'
  echo ""
  echo "## Task JSON Extraction"
  TASK_JSON_PREVIEW=""
  if [[ "$HAS_STRUCTURED" == "true" ]]; then
    TASK_JSON=$(echo "$RESULT" | jq '.structured_output' 2>/dev/null)
    if [[ -n "$TASK_JSON" && "$TASK_JSON" != "null" ]]; then
      echo "**Source**: .structured_output field"
      TASK_JSON_PREVIEW="$TASK_JSON"
    fi
  elif [[ $EXIT_CODE -eq 0 && -n "$RESULT" ]]; then
    # Fallback: extract from .result field (markdown fence)
    RAW_RESULT=$(echo "$RESULT" | jq -r '.result // empty' 2>/dev/null)
    if [[ -n "$RAW_RESULT" ]]; then
      CLEANED=$(echo "$RAW_RESULT" | awk '/^```json/,/^```$/' | sed '1d;$d')
      TASK_JSON=$(echo "$CLEANED" | jq '.' 2>/dev/null)
      if [[ -n "$TASK_JSON" && "$TASK_JSON" != "null" ]]; then
        echo "**Source**: .result field (extracted from markdown fence) - FALLBACK"
        TASK_JSON_PREVIEW="$TASK_JSON"
      else
        echo "**ERROR**: No structured_output AND failed to parse JSON from .result"
        echo "Raw .result content (first 500 chars):"
        echo '```'
        echo "${RAW_RESULT:0:500}"
        echo '```'
      fi
    else
      echo "**ERROR**: No structured_output AND no .result field"
    fi
  else
    echo "**ERROR**: Exit code $EXIT_CODE or empty RESULT"
  fi
  if [[ -n "$TASK_JSON_PREVIEW" ]]; then
    echo ""
    echo "**Extracted JSON** (first 1000 chars):"
    echo '```json'
    echo "${TASK_JSON_PREVIEW:0:1000}"
    echo '```'
  fi
} > "$DEBUG_LOG"

# Write structured output to task.json
if [[ "$HAS_STRUCTURED" == "true" ]]; then
  # Use structured_output directly
  TASK_JSON=$(echo "$RESULT" | jq '.structured_output' 2>/dev/null)
  if [[ -n "$TASK_JSON" && "$TASK_JSON" != "null" ]]; then
    echo "$TASK_JSON" > "$TASK_FILE"
  fi
elif [[ $EXIT_CODE -eq 0 && -n "$RESULT" ]]; then
  # Fallback: extract from .result field (markdown fence)
  RAW_RESULT=$(echo "$RESULT" | jq -r '.result // empty' 2>/dev/null)
  if [[ -n "$RAW_RESULT" ]]; then
    CLEANED=$(echo "$RAW_RESULT" | awk '/^```json/,/^```$/' | sed '1d;$d')
    TASK_JSON=$(echo "$CLEANED" | jq '.' 2>/dev/null)
    if [[ -n "$TASK_JSON" && "$TASK_JSON" != "null" ]]; then
      echo "$TASK_JSON" > "$TASK_FILE"
    fi
  fi
fi

# ==============================================================================
# Return context to primary agent
# ==============================================================================
jq -n '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: "You MUST comply with the following requirements:\n\n1. You MUST read @.claude/memory/task.json IMMEDIATELY before proceeding\n2. You MUST NOT execute your own interpretation of the user request\n3. You MUST follow the atomic_actions array in exact dependency order (see depends_on field)\n4. You MUST NOT skip, reorder, or parallel-execute steps without explicit user approval\n5. You MUST validate each step against its success_criteria before marking complete\n6. You MUST update memory files (session.md, hypotheses.md, findings.md) after each major step\n7. You SHOULD use TodoWrite to track progress through the atomic steps\n8. You MUST NOT stop work until all steps are completed OR the user explicitly stops you\n\nThe task file contains:\n- Objectives (primary and supporting)\n- Dependencies (prerequisites, constraints, sequential/parallel execution)\n- Atomic steps with CAMRO phases (CAPTURE, ANALYZE, MUTATE, REPLAY, OBSERVE)\n- mitmdump commands for each step\n- Per-step validation requirements\n\nFailure to read this file before proceeding violates the task execution contract."
  }
}'
