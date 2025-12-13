# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MANDATORY: Read Memory Files First

**At the start of EVERY session, you MUST read all memory files before doing any work:**

@.claude/memory/activeContext.md
@.claude/memory/projectBrief.md
@.claude/memory/systemPatterns.md
@.claude/memory/techContext.md
@.claude/memory/projectProgress.md
@.claude/memory/tags.md

**You MUST NOT skip this step.** These files contain persistent context that survives between sessions.

---

## Memory File System

This project uses a memory file system for persistent context across Claude Code sessions.

### The Two-Part System

- **Memory files** (`.claude/memory/*.md`) = **Context** — WHY patterns exist, HOW systems work, PURPOSE of implementations
- **tags.md** = **Inventory** — WHAT exists, WHERE it's located (auto-generated)

### The Six Memory Files

| File | Purpose |
|------|---------|
| `activeContext.md` | Current working state, recent changes, immediate next steps |
| `projectBrief.md` | Project goals, scope, requirements |
| `systemPatterns.md` | Architectural patterns and design decisions |
| `techContext.md` | Tech stack, dependencies, constraints |
| `projectProgress.md` | Completed features, known issues, technical debt |
| `tags.md` | Auto-generated codebase inventory (**MUST NOT edit manually**) |

---

## When to Update Memory Files

### `activeContext.md` — MUST Update FREQUENTLY

**You MUST update after:**
- Completing any significant task or feature
- Making architectural decisions
- Discovering important issues or blockers
- Changing working focus or context
- End of every work session

**You MUST include:**
- What was just completed (with file paths)
- Current state of work in progress
- Immediate next steps
- Any blockers or decisions needed

**You SHOULD keep it current** — This is the "working memory" for the next session.

---

### `projectProgress.md` — MUST Update after COMPLETING features

**You MUST update after:**
- Finishing a feature (move from "In Progress" to "Completed")
- Discovering bugs or technical debt
- Identifying new known issues
- Major milestones

**You MUST include:**
- Completion dates for features
- Known issues with priority
- Technical debt items with reasoning

---

### `systemPatterns.md` — MUST Update after ESTABLISHING patterns

**You MUST update after:**
- Creating new architectural patterns
- Establishing coding conventions
- Making significant design decisions
- Adding new integration patterns

**You MUST include:**
- Pattern name and purpose
- When to use the pattern
- Key files/functions involved
- Why this pattern was chosen

---

### `techContext.md` — MUST Update after CHANGING dependencies

**You MUST update after:**
- Adding new dependencies
- Removing dependencies
- Updating configuration files
- Changing build/test commands
- Modifying environment variables

**You MUST include:**
- Dependency name and version
- Why it was added
- How it's used
- Any configuration needed

---

### `projectBrief.md` — SHOULD Update RARELY

**You SHOULD update only when:**
- Project scope fundamentally changes
- Core requirements are added/removed
- Success criteria change

**This file SHOULD remain stable** — update only for major scope changes.

---

### `tags.md` — MUST NOT Edit Manually

This file is auto-generated. It provides codebase inventory:
- Component locations
- Function signatures
- Interface definitions
- Configuration mappings

**You MUST check tags.md before creating new code** to avoid duplication.