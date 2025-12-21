{
  "task": "Test user profile API for Insecure Direct Object Reference vulnerabilities",
  "assumptions": [
    "Target application uses numeric or predictable user IDs in profile endpoints",
    "Authorization may rely on session token without verifying resource ownership",
    "Profile endpoint returns user-specific PII that would confirm unauthorized access"
  ],
  "target_analysis": {
    "application_purpose": "User profile management - view and edit personal data",
    "identified_assumptions": [
      "Business: Users should only access their own profile data",
      "Developer: User ID in request matches authenticated session"
    ],
    "assumption_gaps": [
      "Gap: Server may not verify user ID ownership against session token",
      "Gap: Numeric IDs may be enumerable without rate limiting"
    ]
  },
  "objectives": {
    "primary": [
      "Determine if user A can access user B's profile data",
      "Document authorization bypass with reproducible evidence"
    ],
    "supporting": [
      "Identify if user IDs are predictable/enumerable",
      "Map all profile-related endpoints"
    ]
  },
  "dependencies": {
    "prerequisites": [
      "Authenticated session captured for at least one user",
      "At least 2 test user accounts available",
      "Target scope confirmed and authorized"
    ],
    "constraints": [
      "Must use mitmdump CLI only",
      "Must stay within authorized scope",
      "Must not modify production data"
    ],
    "sequential": [
      "Capture baseline before mutation",
      "Mutate before replay",
      "Observe before documenting"
    ],
    "parallel": [
      "Can test multiple endpoints simultaneously after capture"
    ]
  },
  "atomic_actions": [
    {
      "step": 1,
      "phase": "CAPTURE",
      "type": "task",
      "action": "Capture authenticated profile request for user A",
      "hypothesis": null,
      "input": "Browser session with user A logged in",
      "output": "Baseline traffic file with profile request",
      "mitmdump_command": "mitmdump -w captures/profile-baseline.mitm \"~d api.target.com & ~u /profile\"",
      "python_addon": null,
      "file": "captures/profile-baseline.mitm",
      "memory_update": "session",
      "depends_on": []
    },
    {
      "step": 2,
      "phase": "ANALYZE",
      "type": "task",
      "action": "Identify user ID parameter in profile requests",
      "hypothesis": null,
      "input": "captures/profile-baseline.mitm",
      "output": "Understanding of how user ID is transmitted (path, query, body, header)",
      "mitmdump_command": "mitmdump -nr captures/profile-baseline.mitm --flow-detail 3 \"~u /profile\"",
      "python_addon": null,
      "file": null,
      "memory_update": null,
      "depends_on": [1]
    },
    {
      "step": 3,
      "phase": "ANALYZE",
      "type": "checkpoint",
      "action": "Document IDOR hypothesis in hypotheses.md before testing",
      "hypothesis": "User A can access user B's profile by changing user_id parameter",
      "input": "Analysis from step 2",
      "output": "Documented hypothesis with planned test commands",
      "mitmdump_command": null,
      "python_addon": null,
      "file": ".claude/memory/hypotheses.md",
      "memory_update": "hypotheses",
      "depends_on": [2]
    },
    {
      "step": 4,
      "phase": "MUTATE",
      "type": "task",
      "action": "Replace user A's ID with user B's ID in captured request",
      "hypothesis": "Server does not verify user ID ownership",
      "input": "captures/profile-baseline.mitm, user B's ID",
      "output": "Mutated request file targeting user B's data",
      "mitmdump_command": "mitmdump -nr captures/profile-baseline.mitm -B \"/~q/user_id=123/user_id=456\" -w captures/idor-test.mitm",
      "python_addon": null,
      "file": "captures/idor-test.mitm",
      "memory_update": null,
      "depends_on": [3]
    },
    {
      "step": 5,
      "phase": "REPLAY",
      "type": "task",
      "action": "Replay mutated request with user A's session token",
      "hypothesis": "Server does not verify user ID ownership",
      "input": "captures/idor-test.mitm",
      "output": "Server response to cross-user request",
      "mitmdump_command": "mitmdump -C captures/idor-test.mitm -w captures/idor-response.mitm --flow-detail 3",
      "python_addon": null,
      "file": "captures/idor-response.mitm",
      "memory_update": null,
      "depends_on": [4]
    },
    {
      "step": 6,
      "phase": "OBSERVE",
      "type": "decision_point",
      "action": "Analyze response - check if user B's data was returned",
      "hypothesis": "Server does not verify user ID ownership",
      "input": "captures/idor-response.mitm",
      "output": "Determination: IDOR confirmed or disproved",
      "mitmdump_command": "mitmdump -nr captures/idor-response.mitm --flow-detail 4 \"~bs email|name|address\"",
      "python_addon": null,
      "file": null,
      "memory_update": "hypotheses",
      "depends_on": [5]
    },
    {
      "step": 7,
      "phase": "OBSERVE",
      "type": "task",
      "action": "Document confirmed finding with reproducible evidence",
      "hypothesis": null,
      "input": "All .mitm files from test, analysis from step 6",
      "output": "Vulnerability report in findings.md with severity, reproduction steps, impact",
      "mitmdump_command": null,
      "python_addon": null,
      "file": ".claude/memory/findings.md",
      "memory_update": "findings",
      "depends_on": [6]
    }
  ],
  "subagent_delegation": {
    "strategy": "sequential",
    "consolidation": "Each step builds on previous; no parallel execution for this test",
    "subagents": []
  },
  "success_criteria": {
    "per_step": [
      {"step": 1, "criterion": "Profile request captured with visible user ID", "measurable": true},
      {"step": 2, "criterion": "User ID parameter location identified", "measurable": true},
      {"step": 3, "criterion": "Hypothesis documented with planned commands", "measurable": true},
      {"step": 4, "criterion": "Mutated file contains altered user ID", "measurable": true},
      {"step": 5, "criterion": "Replay completes without connection errors", "measurable": true},
      {"step": 6, "criterion": "Response analyzed for cross-user data indicators", "measurable": true},
      {"step": 7, "criterion": "Finding documented with all evidence files referenced", "measurable": true}
    ],
    "per_subagent": [],
    "vulnerability_indicators": [
      "200 OK response with different user's PII",
      "Response contains user B's email/name/data",
      "No authorization error (401/403) when accessing other user's profile"
    ],
    "overall": "Confirmed whether user A can access user B's profile data via IDOR, with reproducible evidence",
    "quality_standards": [
      "All commands use mitmdump CLI exclusively",
      "All evidence files saved in captures/ directory",
      "Hypothesis documented before mutation testing"
    ],
    "acceptance_criteria": [
      "IDOR test produces 7 atomic actions with specific mitmdump commands",
      "Evidence chain: baseline → mutated → response",
      "Memory files updated at appropriate steps"
    ]
  }
}
