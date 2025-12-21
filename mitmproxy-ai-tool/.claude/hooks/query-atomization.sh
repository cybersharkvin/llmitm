#!/bin/bash

# =============================================================================
# Penetration Testing Task Atomizer
# =============================================================================
# Transforms user requests into structured JSON security testing plans using
# Claude's Structured Outputs feature (--json-schema) for guaranteed valid JSON.
#
# Designed specifically for the llmitm bug bounty hunter agent using CAMRO workflow.
#
# Usage: Triggered by UserPromptSubmit hook in Claude Code
# Output: JSON plan written to .claude/memory/task.md
# Skip: Prefix prompt with "no-atom" to bypass atomization
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 1: Initialize paths
# -----------------------------------------------------------------------------
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DEBUG_LOG="$PROJECT_DIR/.claude/atomDebug.md"
TASK_FILE="$PROJECT_DIR/.claude/memory/task.md"
SETTINGS_FILE="$PROJECT_DIR/.claude/no-hooks.json"

# -----------------------------------------------------------------------------
# Phase 2: Read input JSON
# -----------------------------------------------------------------------------
input_json=$(cat)
user_prompt=$(echo "$input_json" | jq -r '.prompt')

# Initialize debug log
echo -e "# Pentest Atomizer Debug Log\n**$(date)**\n" > "$DEBUG_LOG"
echo -e "## Phase 1: Initialization" >> "$DEBUG_LOG"
echo -e "- PROJECT_DIR: $PROJECT_DIR" >> "$DEBUG_LOG"
echo -e "- TASK_FILE: $TASK_FILE\n" >> "$DEBUG_LOG"

echo -e "## Phase 2: Input" >> "$DEBUG_LOG"
echo -e "- Prompt length: ${#user_prompt} chars" >> "$DEBUG_LOG"
echo -e "- Prompt: $user_prompt\n" >> "$DEBUG_LOG"

# -----------------------------------------------------------------------------
# Phase 3: Check skip conditions
# -----------------------------------------------------------------------------
echo -e "## Phase 3: Skip Check" >> "$DEBUG_LOG"
if [[ "$user_prompt" == no-atom* ]]; then
  echo -e "- Result: SKIPPED (no-atom prefix detected)\n" >> "$DEBUG_LOG"
  exit 0
fi
echo -e "- Result: Proceeding with atomization\n" >> "$DEBUG_LOG"

# -----------------------------------------------------------------------------
# Phase 4: Verify prerequisites
# -----------------------------------------------------------------------------
echo -e "## Phase 4: Prerequisites" >> "$DEBUG_LOG"
if ! command -v claude &> /dev/null; then
  echo -e "- ERROR: claude CLI not found\n" >> "$DEBUG_LOG"
  exit 0
fi
echo -e "- claude CLI: $(which claude)" >> "$DEBUG_LOG"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo -e "- ERROR: Settings file not found: $SETTINGS_FILE\n" >> "$DEBUG_LOG"
  exit 0
fi
echo -e "- Settings file: EXISTS\n" >> "$DEBUG_LOG"

# -----------------------------------------------------------------------------
# Phase 5: Define JSON Schema for Structured Outputs
# -----------------------------------------------------------------------------
# This schema is specifically designed for the llmitm bug bounty hunter agent.
# It produces plans with executable mitmdump commands following the CAMRO workflow.

JSON_SCHEMA='{
  "type": "object",
  "properties": {
    "task": { "type": "string", "description": "Brief security testing objective" },
    "assumptions": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Implicit assumptions about target behavior, security controls, or business logic"
    },
    "target_analysis": {
      "type": "object",
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
      "properties": {
        "primary": { "type": "array", "items": { "type": "string" }, "description": "Main security testing goals" },
        "supporting": { "type": "array", "items": { "type": "string" }, "description": "Enabler goals" }
      },
      "required": ["primary", "supporting"]
    },
    "dependencies": {
      "type": "object",
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
      "items": {
        "type": "object",
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
          "hypothesis": { "type": "string", "description": "Vulnerability theory being tested (null for CAPTURE phase)" },
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
      "properties": {
        "per_step": {
          "type": "array",
          "items": {
            "type": "object",
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
        "overall": { "type": "string", "description": "What constitutes complete success" },
        "evidence_requirements": {
          "type": "array",
          "items": { "type": "string" },
          "description": "What evidence is needed for a valid bug bounty report"
        }
      },
      "required": ["per_step", "vulnerability_indicators", "overall", "evidence_requirements"]
    }
  },
  "required": ["task", "assumptions", "target_analysis", "objectives", "dependencies", "atomic_actions", "success_criteria"]
}'

echo -e "## Phase 5: JSON Schema" >> "$DEBUG_LOG"
echo -e "- Schema defined for constrained output" >> "$DEBUG_LOG"
echo -e "- Schema length: ${#JSON_SCHEMA} chars\n" >> "$DEBUG_LOG"

# -----------------------------------------------------------------------------
# Phase 6: Define System Prompt (Pentest-Specific Context)
# -----------------------------------------------------------------------------
read -r -d '' SYSTEM_PROMPT << 'PROMPT_EOF'
You are a penetration testing task atomizer with deep expertise in mitmproxy/mitmdump CLI and bug bounty methodology.

Your job is to transform security testing requests into structured JSON plans that the llmitm bug bounty hunter agent can execute directly.

## CAMRO Workflow

Every plan MUST follow the CAMRO workflow:
- **CAPTURE**: Intercept and save traffic (mitmdump -w)
- **ANALYZE**: Examine captured flows (mitmdump -nr --flow-detail 3)
- **MUTATE**: Modify requests to test hypotheses (mitmdump -nr -H/-B -w)
- **REPLAY**: Send modified requests (mitmdump -C)
- **OBSERVE**: Analyze responses for vulnerability indicators

## Mitmdump Command Reference

### Capture Commands
- `mitmdump -w session.mitm "~d target.com"` - Capture traffic to domain
- `mitmdump -w session.mitm "~m POST & ~u /api"` - Capture POST requests to /api

### Analysis Commands
- `mitmdump -nr session.mitm --flow-detail 3` - Show all flows with headers+body
- `mitmdump -nr session.mitm "~u /user" --flow-detail 3` - Filter by path
- `mitmdump -nr session.mitm "~bs password|token" --flow-detail 3` - Search response body

### Mutation Commands
- `mitmdump -nr session.mitm -B "/user_id=1/user_id=2" -w mutated.mitm` - Replace in body
- `mitmdump -nr session.mitm -H "/~q/Authorization/Bearer evil" -w mutated.mitm` - Replace header

### Replay Commands
- `mitmdump -C mutated.mitm --flow-detail 3` - Replay and show response

### Filter Expressions
- `~d domain` - Match domain
- `~u path` - Match URL path
- `~m METHOD` - Match HTTP method
- `~c code` - Match status code
- `~bq regex` - Match request body
- `~bs regex` - Match response body
- `~hq header` - Match request header
- Combine: `&` (and), `|` (or), `!` (not), `()` (group)

## Vulnerability Focus

Prioritize testing for:
1. **IDOR** - Can user A access user B's data by changing IDs?
2. **Auth Bypass** - Can admin functions be accessed without proper auth?
3. **Privilege Escalation** - Can user role be elevated by modifying requests?
4. **Data Exposure** - Are tokens, keys, or credentials leaked in responses?

## Memory File Updates

The agent maintains three memory files:
- **session.md** - Update after captures, target changes (memory_update: "session")
- **hypotheses.md** - Update BEFORE testing a theory (memory_update: "hypotheses")
- **findings.md** - Update when vulnerability confirmed with evidence (memory_update: "findings")

## Evidence Requirements

Every finding needs:
- Exact mitmdump commands for reproduction
- Before/after response comparison
- Impact assessment
- Severity rating (Critical/High/Medium/Low)

## Rules

1. Every atomic_action MUST have either mitmdump_command OR python_addon (preferably mitmdump_command)
2. All file paths should be in the captures/ directory
3. CAPTURE phase actions should NOT have a hypothesis (it's reconnaissance)
4. ANALYZE phase identifies interesting patterns and formulates hypotheses
5. MUTATE/REPLAY phases test specific hypotheses
6. OBSERVE phase verifies results and documents findings
7. Include memory_update for steps that change state (captures, hypotheses, findings)
8. Use checkpoints after REPLAY to verify responses before proceeding
9. Use decision_points when the next action depends on observed results
PROMPT_EOF

echo -e "## Phase 6: System Prompt" >> "$DEBUG_LOG"
echo -e "- System prompt length: ${#SYSTEM_PROMPT} chars\n" >> "$DEBUG_LOG"

# -----------------------------------------------------------------------------
# Phase 7: Spawn Claude with Structured Outputs
# -----------------------------------------------------------------------------
echo -e "## Phase 7: Claude Execution" >> "$DEBUG_LOG"
echo -e "- Model: haiku (fast planning)" >> "$DEBUG_LOG"
echo -e "- Using --json-schema for constrained output" >> "$DEBUG_LOG"
echo -e "- Starting at: $(date '+%Y-%m-%d %H:%M:%S.%3N')" >> "$DEBUG_LOG"

RESULT=$(cd "$PROJECT_DIR" && echo "$user_prompt" | claude -p \
  --model haiku \
  --output-format json \
  --settings "$SETTINGS_FILE" \
  --tools "" \
  --system-prompt "$SYSTEM_PROMPT" \
  --json-schema "$JSON_SCHEMA" \
  2>/dev/null)

EXIT_CODE=$?

# -----------------------------------------------------------------------------
# Phase 8: Capture results
# -----------------------------------------------------------------------------
echo -e "- Finished at: $(date '+%Y-%m-%d %H:%M:%S.%3N')" >> "$DEBUG_LOG"
echo -e "- Exit code: $EXIT_CODE" >> "$DEBUG_LOG"
echo -e "- Result length: ${#RESULT} chars\n" >> "$DEBUG_LOG"

echo -e "## Phase 8: Raw Response\n\`\`\`json\n$RESULT\n\`\`\`\n" >> "$DEBUG_LOG"

# -----------------------------------------------------------------------------
# Phase 9: Extract from .structured_output (Structured Outputs feature)
# -----------------------------------------------------------------------------
echo -e "## Phase 9: Task Extraction" >> "$DEBUG_LOG"

# With --json-schema, the actual JSON is in .structured_output, not .result
STRUCTURED_OUTPUT=$(echo "$RESULT" | jq '.structured_output // empty' 2>/dev/null)

if [[ -n "$STRUCTURED_OUTPUT" && "$STRUCTURED_OUTPUT" != "null" ]]; then
  echo -e "- Found .structured_output (constrained JSON)" >> "$DEBUG_LOG"
  TASK_JSON="$STRUCTURED_OUTPUT"
else
  # Fallback: try .result and strip markdown fences (for non-structured-output responses)
  echo -e "- No .structured_output, trying .result fallback" >> "$DEBUG_LOG"
  RAW_RESULT=$(echo "$RESULT" | jq -r '.result // empty' 2>/dev/null)
  if [[ -z "$RAW_RESULT" ]]; then
    echo -e "- ERROR: No .result field either\n" >> "$DEBUG_LOG"
    exit 0
  fi
  TASK_JSON=$(echo "$RAW_RESULT" | sed 's/```json//g; s/```//g' | jq '.' 2>/dev/null)
fi

if [[ -z "$TASK_JSON" || "$TASK_JSON" == "null" ]]; then
  echo -e "- ERROR: Failed to extract valid JSON\n" >> "$DEBUG_LOG"
  exit 0
fi

echo -e "- Successfully extracted task JSON" >> "$DEBUG_LOG"

# Count atomic actions for debug
ACTION_COUNT=$(echo "$TASK_JSON" | jq '.atomic_actions | length' 2>/dev/null)
echo -e "- Atomic actions: $ACTION_COUNT\n" >> "$DEBUG_LOG"

# -----------------------------------------------------------------------------
# Phase 10: Write to task.md
# -----------------------------------------------------------------------------
echo -e "## Phase 10: Output" >> "$DEBUG_LOG"
echo "$TASK_JSON" > "$TASK_FILE"
echo -e "- Written to: $TASK_FILE" >> "$DEBUG_LOG"
echo -e "- File size: $(wc -c < "$TASK_FILE") bytes\n" >> "$DEBUG_LOG"

echo -e "## Complete\nPentest atomization successful at $(date)" >> "$DEBUG_LOG"

# Return hook response to primary agent
jq -n '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: "You MUST IMMEDIATELY read the security testing plan saved to @.claude/memory/task.md BEFORE proceeding. - You MUST read it and execute the CAMRO workflow. You MUST to update memory files (session.md, hypotheses.md, findings.md) at each step."
  }
}'
