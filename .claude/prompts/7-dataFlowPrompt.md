# Data Flows Analysis

## Objective

Analyze how data moves through this application and document it in `.claude/analysis/dataFlows.md`.

**Definition**: A "data flow" traces how data enters the system, transforms, moves between components, gets stored, and exits. This includes state management, component communication, and processing pipelines.

---

## Phase 1: Reconnaissance

Before documenting, understand the application:

1. **Read available memory/context files** to understand purpose and architecture
2. **Identify state management** - how is application state stored and updated?
3. **Identify component boundaries** - where does data cross from one module to another?
4. **Trace a complete flow** - follow one piece of data from entry to exit
5. **Find transformation points** - where is data validated, parsed, or reformatted?

**Do not fill tables until you can trace data through the system.**

---

## Phase 2: Section-by-Section Analysis

### Section 1: State Management

**Search for**: State containers, stores, context providers, session state, global variables.

**1.1 State Containers** - Where state lives
| Column | What to capture |
|--------|-----------------|
| State | Descriptive name |
| Location | `file:line` where defined |
| Type | Data structure type |
| Scope | Global, page, component, request |
| Persistence | Memory, session, localStorage, database |

**1.2 State Updates** - How state changes
- Document **Trigger**: what user action or event causes the update?
- Document **Side Effects**: what else happens when state updates?

**State Summary**: Describe the overall state architecture in 2-3 sentences.

---

### Section 2: Component Communication

**Search for**: Props passing, callbacks, events, shared state access, message passing.

**2.1 Data Passing** - Direct data transfer between components
| Column | What to capture |
|--------|-----------------|
| From | Source component/module |
| To | Destination component/module |
| Mechanism | Props, function call, event, etc. |
| Data | What data is passed |

**2.2 Event/Callback Flow** - Indirect communication
- Document **Effect**: what happens when the event fires?

**2.3 Shared State Access** - Multiple components reading same state
- Document **Access Pattern**: read-only, read-write, subscribe

---

### Section 3: Data Transformations

**Search for**: Validators, parsers, formatters, mappers, serializers.

**3.1 Validation** - Data correctness checks
| Column | What to capture |
|--------|-----------------|
| Input | What data is validated |
| Validator | Function/class that validates |
| Rules | What conditions are checked |
| On Failure | What happens when validation fails |

**3.2 Parsing** - Format conversion
- Document **Source Format** and **Target Format**

**3.3 Formatting** - Display/output preparation
- Document **Purpose**: why is this formatting needed?

**3.4 Enrichment** - Data augmentation
- Document **Source**: where does the additional data come from?

---

### Section 4: Data Sources & Sinks

**Search for**: Entry points (user input, API calls, file reads), exit points (renders, writes, API responses).

**4.1 Entry Points** - Where data enters
| Column | What to capture |
|--------|-----------------|
| Entry Point | How data enters (form, API, file, etc.) |
| Data Type | What kind of data |
| Source | External source (user, service, file) |
| First Handler | First function that processes it |

**4.2 Exit Points** - Where data leaves
- Document **Final Handler**: last function before data exits

**4.3 Storage Points** - Where data persists
- Document **Read By** and **Written By**: which components access storage

---

### Section 5: Complete Flow Examples

**Document 2-3 representative flows end-to-end.**

For each flow:
1. Draw an ASCII diagram showing each step
2. Write a natural language description
3. Document the data shape at each transformation point

---

### Summary Section

**Flow Patterns** - Recurring data flow patterns
| Column | What to capture |
|--------|-----------------|
| Pattern | Name of the pattern |
| Usage | Where this pattern is used |
| Locations | `file:line` references |

**Data Lifecycle** - For each major data type, trace its full lifecycle

**Bottlenecks & Concerns** - Identify potential issues:
- Where might data pile up?
- Where are race conditions possible?
- Where is data copied unnecessarily?

---

## Phase 3: Natural Language Guidelines

When writing descriptions and summaries:

1. **Trace, don't list** - Show the journey, not just the stops
2. **Name the data** - Be specific about what data flows, not just "data"
3. **Show transformations** - Document how data shape changes
4. **Include timing** - Note async operations, queues, batching
5. **Identify ownership** - Which component "owns" the data at each point?

---

## Phase 4: Verification Checklist

Before marking complete, verify:

- [ ] Every state container is documented
- [ ] Every major component boundary has data passing documented
- [ ] Every validation function is listed
- [ ] Every data entry point is documented
- [ ] Every data exit point is documented
- [ ] At least 2 complete flow examples with diagrams
- [ ] Data lifecycle documented for major data types
- [ ] Bottlenecks/concerns identified
- [ ] All `file:line` locations verified against current code
- [ ] No placeholder text remains in the output file

---

## Output

Save completed analysis to: `.claude/analysis/dataFlows.md`
