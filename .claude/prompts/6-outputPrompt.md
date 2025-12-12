# Major Outputs Analysis

## Objective

Analyze ALL outputs from this application and document them in `.claude/analysis/majorOutputs.md`.

**Definition**: An "output" is any data, rendering, or effect that leaves the system's processing boundary - UI rendering, file generation, API responses, database writes, external calls, or user downloads.

---

## Phase 1: Reconnaissance

Before documenting, understand the application:

1. **Read available memory/context files** to understand purpose and architecture
2. **Identify the UI framework** - what renders to the user?
3. **Identify API layer** - what endpoints return data?
4. **Locate file operations** - where are files written?
5. **Find external integrations** - what services are called?

**Do not fill tables until you understand what the application produces.**

---

## Phase 2: Section-by-Section Analysis

### Section 1: UI Rendering

**Search for**: Render functions, page components, template rendering, dynamic content generation.

**1.1 Pages/Views** - Top-level rendered pages
| Column | What to capture |
|--------|-----------------|
| Page | Descriptive name of the page |
| Location | `file:line` where rendering is defined |
| Route/Entry | URL route or entry condition |
| Purpose | ONE sentence: what does the user accomplish here? |

**1.2 Components/Sections** - Reusable UI pieces
- Document **Parent**: which page(s) include this component?

**1.3 Dynamic Content** - Content that changes based on state/data
- Document **Trigger**: what causes this content to update?
- Document **Data Source**: where does the content come from?

**UI Summary**: Describe the overall user experience in 2-3 sentences.

---

### Section 2: File Generation

**Search for**: File writes, export functions, build processes, asset generation.

**2.1 Runtime Generated Files** - Files created during normal operation
| Column | What to capture |
|--------|-----------------|
| File | Descriptive name or pattern |
| Trigger | What action causes generation? |
| Format | File format (PDF, CSV, JSON, etc.) |
| Purpose | Why is this file created? |

**2.2 Build Artifacts** - Files created during build/deploy

**2.3 Static Assets** - Pre-existing files served to users

---

### Section 3: API Responses

**Search for**: Route handlers, endpoint definitions, response returns.

**3.1 Endpoints** - All API endpoints
| Column | What to capture |
|--------|-----------------|
| Endpoint | URL path pattern |
| Method | HTTP method |
| Response Format | JSON structure or content type |
| Status Codes | All possible status codes returned |
| Purpose | What does this endpoint provide? |

**3.2 Response Schemas** - Document actual response structures

**3.3 Error Responses** - How errors are communicated
- Document **Trigger**: what conditions cause this error?

---

### Section 4: Side Effects

**Search for**: Database operations, HTTP clients, file system operations, notification services.

**4.1 Database Writes** - INSERT, UPDATE, DELETE operations
- Document **Trigger**: what user action or event causes the write?

**4.2 External API Calls** - Outbound HTTP requests to other services

**4.3 File System Writes** - Files created/modified outside exports
- Include logs, temp files, caches

**4.4 Notifications** - Emails, SMS, push notifications, webhooks

**4.5 Logging** - Application logs
- Note **Level**: DEBUG, INFO, WARN, ERROR

---

### Section 5: Downloads/Exports

**Search for**: Download handlers, export functions, file streaming.

**5.1 User Downloads** - Files users explicitly download
- Document **Trigger**: button click, link, etc.

**5.2 Data Exports** - Bulk data exports, reports

---

### Summary Section

**Output Counts** - Tally outputs by category

**Output Flow** - ASCII diagram showing how data flows out of the system

**Failure Modes** - For each critical output:
| Column | What to capture |
|--------|-----------------|
| Failure Scenario | What could go wrong? |
| Handling | How is failure handled? |
| User Impact | What does the user experience? |

**Idempotency** - Document which operations are safe to retry

---

## Phase 3: Natural Language Guidelines

When writing descriptions and summaries:

1. **Specific over generic** - Descriptions should teach about THIS app, not any app
2. **WHY over WHAT** - Explain intent, not just existence
3. **Include consequences** - What happens as a result of this output?
4. **Document failures** - What happens when output fails?
5. **Consistent terminology** - Match the codebase's terms

---

## Phase 4: Verification Checklist

Before marking complete, verify:

- [ ] Every rendered page/view has a table entry
- [ ] Every file write operation is documented
- [ ] Every API endpoint has response format documented
- [ ] Every database write operation is documented
- [ ] Every external API call is documented
- [ ] Every download/export is documented
- [ ] Failure modes documented for critical outputs
- [ ] Output flow diagram reflects actual architecture
- [ ] All `file:line` locations verified against current code
- [ ] No placeholder text remains in the output file

---

## Output

Save completed analysis to: `.claude/analysis/majorOutputs.md`
