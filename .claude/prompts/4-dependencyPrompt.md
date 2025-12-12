# Internal Dependencies Analysis

## Objective

Analyze internal import relationships in this codebase and document them in `.claude/analysis/dependencies.md`.

**Definition**: "Internal dependencies" are import relationships between files within the project (not third-party packages). This reveals coupling, layering, and architectural health.

---

## Phase 1: Reconnaissance

Before documenting, understand the codebase:

1. **Read available memory/context files** to understand architecture
2. **Identify the module structure** - what are the main packages/directories?
3. **Identify architectural layers** - is there UI, business logic, data access separation?
4. **Find central modules** - which files are imported most often?
5. **Look for patterns** - barrel files, re-exports, type-only imports

**Do not fill tables until you understand the intended architecture.**

---

## Phase 2: Section-by-Section Analysis

### Section 1: Import Graph

**Search for**: All import statements in all source files.

**1.1 File-by-File Imports**
For each source file, create a subsection:

```markdown
#### filename.py

| Imports | Type |
|---------|------|
| `from x import y` | internal/external |
```

- **Type**: Mark as "internal" (from this project) or "external" (third-party)
- Focus on internal imports for this analysis

---

### Section 2: Dependency Hotspots

**Analyze**: Which modules are most depended upon?

**2.1 Most Imported Modules**
| Column | What to capture |
|--------|-----------------|
| Module | The imported module |
| Import Count | How many files import it |
| Imported By | List of importing files |

**2.2 Import Distribution**
- Count files in each range
- High-import files may be overly coupled

---

### Section 3: Circular Dependencies

**Search for**: Import cycles where A imports B and B imports A (directly or transitively).

**3.1 Detected Cycles**
| Column | What to capture |
|--------|-----------------|
| Cycle | Visual representation: A → B → C → A |
| Files Involved | All files in the cycle |
| Severity | Breaking (causes errors), Warning (works but risky), Minor |

**3.2 Resolution Strategy**
- For each cycle, suggest how to break it
- Common solutions: extract shared module, dependency injection, lazy imports

---

### Section 4: Import Patterns

**Search for**: Special import patterns that affect architecture.

**4.1 Re-exports** - Modules that import and re-export from others
- Often in `__init__.py` or `index.ts` files
- Document **Purpose**: public API, convenience, encapsulation

**4.2 Type-Only Imports** - Imports used only for type checking
- Common in TypeScript: `import type { X }`
- Python: `from typing import TYPE_CHECKING`

**4.3 Barrel Files** - Files that aggregate exports from a directory
- Usually `__init__.py`, `index.ts`, `mod.rs`
- Document all exports

**4.4 Dynamic Imports** - Runtime imports, not at module level
- Document **Trigger**: what condition loads this module?
- Document **Purpose**: lazy loading, optional feature, plugin

**4.5 Conditional Imports** - Imports inside try/except or if blocks
- Document **Condition** and **Fallback**

---

### Section 5: Architecture Insights

**Analyze**: What does the import graph tell us about architecture?

**5.1 Layer Dependencies**
Draw an ASCII diagram showing:
- Which layers exist (UI, business logic, data, utilities)
- Which layers depend on which
- Any layer violations (e.g., data layer importing UI)

**5.2 Coupling Analysis**
| Column | What to capture |
|--------|-----------------|
| Afferent (incoming) | How many modules depend on this one |
| Efferent (outgoing) | How many modules this one depends on |
| Instability | Efferent / (Afferent + Efferent) - higher = more unstable |

**5.3 Module Boundaries**
- Identify intended boundaries (packages, directories)
- Document whether boundaries are respected
- List any violations

---

### Summary Section

**Dependency Metrics** - Raw counts

**Architecture Assessment**
- **Coupling**: Is it well-decoupled or tightly coupled?
- **Cohesion**: Are related things grouped together?

**Recommendations** - Actionable improvements

---

## Phase 3: Natural Language Guidelines

When writing descriptions and summaries:

1. **Explain the why** - Why does A depend on B?
2. **Identify patterns** - Are there consistent architectural patterns?
3. **Note violations** - Where does reality differ from intended architecture?
4. **Assess health** - Is this dependency structure sustainable?
5. **Be actionable** - Recommendations should be specific and achievable

---

## Phase 4: Verification Checklist

Before marking complete, verify:

- [ ] Every source file has its imports listed
- [ ] Most-imported modules identified with import counts
- [ ] All circular dependencies documented (or noted as "none found")
- [ ] Re-exports and barrel files documented
- [ ] Layer dependency diagram created
- [ ] Coupling metrics calculated for key modules
- [ ] Architecture assessment written
- [ ] Recommendations provided
- [ ] No placeholder text remains in the output file

---

## Output

Save completed analysis to: `.claude/analysis/dependencies.md`
