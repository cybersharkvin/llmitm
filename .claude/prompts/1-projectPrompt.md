# Overall Project Structure Analysis

## Objective

Analyze the overall structure and organization of this project and document it in `.claude/analysis/overallProject.md`.

**Definition**: "Overall project structure" covers directory organization, component categorization, naming conventions, project type, and scale. This is the bird's-eye view of the codebase.

---

## Phase 1: Reconnaissance

Before documenting, survey the project:

1. **Explore the root directory** - what's at the top level?
2. **Identify main directories** - what are the major organizational units?
3. **Count files by type** - how much of each file type exists?
4. **Find entry points** - where does execution start?
5. **Read available memory/context files** for stated architecture

**Do not fill tables until you have a mental map of the project.**

---

## Phase 2: Section-by-Section Analysis

### Section 1: Directory Structure

**Search for**: All directories and their contents.

**1.1 Complete Directory Tree**
Create a tree showing:
- All directories (ignore `node_modules`, `venv`, `.git`, etc.)
- Representative files in each directory
- Brief inline comments explaining purpose

```markdown
project/
├── src/                    # Source code
│   ├── components/         # UI components
│   └── utils/              # Utilities
├── tests/                  # Test files
└── config/                 # Configuration
```

**1.2 File Counts by Directory**
| Column | What to capture |
|--------|-----------------|
| Directory | Path from root |
| Source | Code files (.py, .js, .ts, etc.) |
| Config | Configuration files |
| Tests | Test files |
| Docs | Documentation |
| Other | Everything else |
| Total | Sum |

---

### Section 2: Component Categories

**Analyze**: How are components organized conceptually?

**2.1 Component Inventory**
| Column | What to capture |
|--------|-----------------|
| Category | Conceptual grouping (UI, Data, Utils, etc.) |
| Components | What belongs in this category |
| Location | Where to find them |

**2.2 Component Relationships**
Draw an ASCII diagram showing:
- How component categories relate
- Which categories depend on which
- Data flow between categories

---

### Section 3: Naming Conventions

**Analyze**: What patterns exist in file and directory naming?

**3.1 Extension Usage**
Count files by extension:
- What extensions are used?
- What purpose does each serve?

**3.2 Naming Patterns**
| Column | What to capture |
|--------|-----------------|
| Element | What's being named (classes, files, functions, etc.) |
| Convention | The pattern (PascalCase, snake_case, kebab-case, etc.) |
| Examples | Real examples from the codebase |

**3.3 Directory Naming**
Document patterns:
- Singular vs plural (component vs components)
- Grouping strategy (by feature, by type, by layer)

---

### Section 4: Project Type

**Determine**: What kind of project is this?

**4.1 Framework/Platform**
| Column | What to capture |
|--------|-----------------|
| Primary Framework | Main application framework |
| Language | Programming language(s) |
| Runtime | Node, Python, JVM, browser, etc. |
| Platform | Web, CLI, mobile, desktop, library |

**4.2 Architecture Type**
| Column | What to capture |
|--------|-----------------|
| Pattern | MVC, microservices, monolith, serverless, etc. |
| Style | REST, GraphQL, event-driven, etc. |
| Deployment | Docker, serverless, static, etc. |

Include an ASCII architecture diagram.

**4.3 Entry Points**
List all ways to run/access the application:
- Main application entry
- CLI commands
- API endpoints
- Test runners
- Build scripts

---

### Section 5: Codebase Scale

**Count**: How big is this project?

**5.1 Scale Metrics**
| Metric | What to count |
|--------|---------------|
| Total files | All source files |
| Total lines of code | LOC excluding blanks/comments |
| Total classes/components | Major abstractions |
| Total functions | Functions/methods |
| Test files | Test source files |
| Test cases | Individual tests |

**5.2 File Size Distribution**
Group files by size:
- Small (<100 lines)
- Medium (100-500 lines)
- Large (500-1000 lines)
- Very large (>1000 lines)

**5.3 Largest Files**
List the largest files:
- Document purpose
- Consider if they should be split

---

### Section 6: Project Organization

**Assess**: How well-organized is the project?

**6.1 Separation of Concerns**
| Column | What to capture |
|--------|-----------------|
| Concern | UI, business logic, data access, etc. |
| Location | Where this concern is handled |
| Boundary Clear? | Yes, No, Partial |

**6.2 Public API Surface**
What does this project export/expose?
- For libraries: exported modules
- For apps: API endpoints, CLI commands

**6.3 Configuration Organization**
How is configuration structured?
- Environment-based?
- Feature-based?
- Scattered or centralized?

---

### Summary Section

**Project Profile**
| Aspect | Assessment |
|--------|------------|
| Size | Tiny (<1K LOC), Small, Medium, Large, Very Large |
| Complexity | Low, Medium, High |
| Organization | Well-organized, Adequate, Needs work |
| Maturity | Prototype, Active development, Stable, Legacy |

**Structural Health**
Assess each aspect:
- Directory organization
- Naming consistency
- Separation of concerns
- Test organization

**Recommendations** - Actionable improvements

---

## Phase 3: Natural Language Guidelines

When writing descriptions and summaries:

1. **Explain the organization** - Why is it structured this way?
2. **Note patterns** - What conventions does the project follow?
3. **Identify inconsistencies** - Where does organization break down?
4. **Consider scale** - Is the organization appropriate for the size?
5. **Think evolution** - Will this structure scale as the project grows?

---

## Phase 4: Verification Checklist

Before marking complete, verify:

- [ ] Complete directory tree documented
- [ ] File counts by directory calculated
- [ ] All component categories identified
- [ ] Naming conventions documented with examples
- [ ] Project type clearly identified
- [ ] Architecture diagram created
- [ ] Scale metrics calculated
- [ ] Largest files identified
- [ ] Separation of concerns assessed
- [ ] Structural health evaluated
- [ ] Recommendations provided
- [ ] No placeholder text remains in the output file

---

## Output

Save completed analysis to: `.claude/analysis/overallProject.md`
