#!/bin/bash

# Atomizer Hook - Opt-in query atomization via Claude subagent (pentest variant)
# Prefix prompt with "ea " to enable. All other prompts skip instantly.
# Debug: .claude/atomDebug.json | Output: .claude/memory/task.json

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TASK_FILE="$PROJECT_DIR/.claude/memory/task.json"
DEBUG_FILE="$PROJECT_DIR/.claude/atomDebug.json"

# 1. Read hook input
input_json=$(cat)
echo "$input_json" | jq -e '.' >/dev/null 2>&1 || exit 0
user_prompt=$(echo "$input_json" | jq -r '.prompt // empty')

# 2. Only run when explicitly enabled with 'ea ' prefix
[[ "$user_prompt" == ea\ * ]] || exit 0
actual_prompt="${user_prompt#ea }"
[[ -n "$actual_prompt" ]] || exit 0

# 3. Prerequisites
command -v claude &>/dev/null || exit 0
AGENT_FILE="$PROJECT_DIR/.claude/agents/atom.md"
[[ -f "$AGENT_FILE" ]] || exit 0
AGENT_CONTENT=$(cat "$AGENT_FILE" 2>/dev/null)
[[ -n "$AGENT_CONTENT" ]] || exit 0

# 4. JSON schema — pentest-specific with CAMRO phases, hypothesis tracking, evidence collection
#    NOTE: additionalProperties:false silently breaks Claude Code CLI structured output — DO NOT ADD
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
      },
      "minItems": 1
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

# 5. Call opus in separate context
RESULT=$(cd "$PROJECT_DIR" && echo "$actual_prompt" | timeout 180 claude -p \
  --model opus \
  --output-format json \
  --settings "$PROJECT_DIR/.claude/no-hooks.json" \
  --system-prompt "$AGENT_CONTENT" \
  --json-schema "$JSON_SCHEMA" 2>&1)
EXIT_CODE=$?

# 6. Write debug log (hook input + raw response)
RESULT_JSON="$RESULT"
echo "$RESULT" | jq -e '.' >/dev/null 2>&1 || RESULT_JSON='"'"$(echo "$RESULT" | head -c 2000)"'"'
jq -n \
  --arg ts "$(date -Iseconds)" \
  --argjson hook_input "$input_json" \
  --arg actual "$actual_prompt" \
  --argjson response "$RESULT_JSON" \
  --argjson exit_code "$EXIT_CODE" \
  '{timestamp: $ts, hook_input: $hook_input, actual_prompt: $actual, response: $response, exit_code: $exit_code}' \
  > "$DEBUG_FILE" 2>/dev/null

# 7. Write task.json from structured_output
if [[ $EXIT_CODE -eq 0 ]]; then
  TASK_JSON=$(echo "$RESULT" | jq '.structured_output // empty' 2>/dev/null)
  if [[ -n "$TASK_JSON" && "$TASK_JSON" != "null" ]]; then
    echo "$TASK_JSON" > "$TASK_FILE"
  fi
fi

# 8. Return execution contract
jq -n '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: "You MUST comply with the following requirements:\n\n1. You MUST read @.claude/memory/task.json IMMEDIATELY before proceeding\n2. You MUST NOT execute your own interpretation of the user request\n3. You MUST follow the atomic_actions array in exact dependency order (see depends_on field)\n4. You MUST NOT skip, reorder, or parallel-execute steps without explicit user approval\n5. You MUST validate each step against its success_criteria before marking complete\n6. You MUST update memory files (session.md, hypotheses.md, findings.md) after each major step\n7. You SHOULD use TodoWrite to track progress through the atomic steps\n8. You MUST NOT stop work until all steps are completed OR the user explicitly stops you\n\nThe task file contains:\n- Target analysis (application purpose, assumptions, assumption gaps, attack surface)\n- Objectives (primary and supporting)\n- Dependencies (prerequisites, constraints, sequential/parallel execution)\n- Atomic steps with CAMRO phases (CAPTURE, ANALYZE, MUTATE, REPLAY, OBSERVE)\n- mitmdump commands and Python addons for each step\n- Hypothesis tracking for vulnerability theories\n- Per-step validation requirements\n- Evidence requirements for bug bounty reporting\n\nFailure to read this file before proceeding violates the task execution contract."
  }
}'
