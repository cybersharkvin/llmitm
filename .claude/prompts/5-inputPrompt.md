# Major Inputs Analysis

## Objective

Analyze ALL inputs to this application and document them in `.claude/analysis/majorInputs.md`.

**Definition**: An "input" is any data that enters the system from outside its execution boundary - user actions, external services, files, configuration, URL state, or environment.

---

## Phase 1: Reconnaissance

Before documenting, understand the application:

1. **Read available memory/context files** to understand purpose and architecture
2. **Identify the main entry point(s)** - where does execution begin?
3. **Identify the UI framework** (if any) - what patterns indicate user input?
4. **Locate configuration** - environment files, docker configs, settings modules
5. **Find data layer** - database models, API clients, file loaders

**Do not fill tables until you understand how data flows into the system.**

---

## Phase 2: Section-by-Section Analysis

### Section 1: User Input Points

**Search for**: Form widgets, input elements, file upload handlers, button click handlers, implicit data extraction from user-provided content.

**1.1 Form Fields** - Text inputs, textareas, date pickers, number inputs
| Column | What to capture |
|--------|-----------------|
| Field | Descriptive name the user would recognize |
| Location | `file:line` where the input is defined |
| Widget Type | The actual component/widget used |
| Purpose | ONE sentence: what does this input accomplish? |
| Validation | How is input validated? (regex, type check, required, max length, or "None") |
| Default | Initial value, or "None" |

**Summary**: 2-3 sentences describing the overall form experience and what information users provide.

**1.2 Selection Inputs** - Dropdowns, radio buttons, checkboxes, toggles
- Document the **Options** (static list or "Dynamic from [source]")

**1.3 File Uploads** - Any file input mechanism
- **Security Notes**: Describe how uploads are validated and stored

**1.4 Action Buttons** - Buttons that trigger operations (not navigation)
- Focus on **Side Effects**: what changes when clicked?

**1.5 Implicit Inputs** - Data extracted indirectly from user actions
- Filenames parsed for metadata
- Ordering from drag-drop
- Clipboard paste handling
- Browser metadata used by the application

---

### Section 2: External Data Sources

**Search for**: HTTP clients, database connections, file readers, service integrations.

**2.1 API Integrations** - External services called
- Create a subsection for each service
- Document **Failure Mode**: what happens if unavailable?
- List all endpoints with request/response formats

**2.2 Database Connections** - All data stores
- Document EVERY table with EVERY column
- Include types, constraints, and descriptions
- Describe **Relationships** in natural language

**2.3 Data Files** - CSV, JSON, YAML, etc. read at runtime
- Document the **Schema** for each file

**2.4 External Services** - Docker services, microservices, workers
- Include **Health Check** endpoint/method

---

### Section 3: Configuration Inputs

**Search for**: Environment variable lookups, config file loaders, constants that control behavior.

**3.1 Environment Variables**
- Check BOTH code AND deployment configs (docker-compose, .env.example, Dockerfile)
- Note which are **Sensitive** (secrets, keys)
- Group by category after the table

**3.2 Configuration Files** - Settings files loaded at runtime
- Note if **Hot Reload** is supported

**3.3 Hardcoded Constants** - Values in code that affect behavior
- Ask: **Should this be configurable?**

**3.4 Thresholds & Parameters** - Values controlling algorithms, validation, ML
- Describe **Impact** of changing each value

---

### Section 4: URL & State Inputs

**Search for**: URL parsing, query string handling, route parameters, session/state management.

**4.1 Query Parameters** - URL parameters affecting behavior
**4.2 Route Parameters** - Dynamic URL segments
**4.3 Session/State Management** - State persisted between requests
- Note **Persistence** mechanism and **Cleared On** conditions

---

### Section 5: Internal Data Structures

**Search for**: Dataclasses, models, TypedDicts that carry data through the system.

**5.1 Domain Models** - Core business objects
- Copy actual definitions with field comments
- Describe **Usage Flow**: where created, where consumed

**5.2 API Request/Response Types** - Structures for API communication
- Include actual JSON examples

**5.3 Processing Structures** - Intermediate data during pipelines
- Note **Lifespan**: created when, discarded when

---

### Section 6: Specialized Inputs

**Adapt this section to the application's domain.**

**6.1 Image/Vision Inputs** - If processing images
- Document coordinate systems and extraction zones

**6.2 [Other]** - Audio, video, sensor data, real-time streams, etc.

---

### Summary Section

**Input Counts** - Tally inputs by category, mark critical ones

**Data Flow** - ASCII diagram showing how inputs flow through the system

**Security Considerations** - For each input type:
| Column | What to capture |
|--------|-----------------|
| Risk | What could go wrong? (injection, traversal, DoS) |
| Mitigation | What prevents this? |
| Status | Implemented / Partial / Planned / None |

**Validation Strategy** - Describe in prose:
1. Boundary validation (at entry points)
2. Type coercion (string → expected type)
3. Sanitization (transformations before use)
4. Error handling (what happens on invalid input)

**Known Gaps** - Actionable checklist of security/completeness issues found

---

## Phase 3: Natural Language Guidelines

When writing descriptions and summaries:

1. **Specific over generic** - Descriptions should teach about THIS app, not any app
2. **WHY over WHAT** - Explain intent, not just existence
3. **Include consequences** - "If X, then Y" is more useful than "X exists"
4. **Honest about gaps** - Document missing validation as "None (gap)" not blank
5. **Consistent terminology** - Match the codebase's terms

---

## Phase 4: Verification Checklist

Before marking complete, verify:

- [ ] Every user input widget has a corresponding table entry
- [ ] Every file upload has security notes
- [ ] Every API integration has failure mode documented
- [ ] Every database table has full column documentation
- [ ] Every environment variable from code AND config files is listed
- [ ] Every session/state key is documented
- [ ] Security section has real mitigations, not placeholders
- [ ] Data flow diagram reflects actual application architecture
- [ ] All `file:line` locations verified against current code
- [ ] No placeholder text remains in the output file

---

## Output

Save completed analysis to: `.claude/analysis/majorInputs.md`
