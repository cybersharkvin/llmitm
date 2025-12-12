# Third-Party Libraries Analysis

## Objective

Analyze all third-party library dependencies and document them in `.claude/analysis/libraries.md`.

**Definition**: "Third-party libraries" are external packages installed via package managers (npm, pip, cargo, etc.). This analysis covers what's installed, how it's used, and dependency health.

---

## Phase 1: Reconnaissance

Before documenting, gather dependency information:

1. **Find package files** - `package.json`, `requirements.txt`, `Pipfile`, `Cargo.toml`, `go.mod`
2. **Find lock files** - `package-lock.json`, `poetry.lock`, `Cargo.lock` (for exact versions)
3. **Distinguish runtime vs dev** - which dependencies are needed in production?
4. **Read available memory/context files** for known dependency decisions

**Do not fill tables until you have the complete dependency list.**

---

## Phase 2: Section-by-Section Analysis

### Section 1: Dependency Inventory

**Search for**: Package files, lock files.

**1.1 Runtime Dependencies**
| Column | What to capture |
|--------|-----------------|
| Library | Package name |
| Version | Exact version from lock file |
| Purpose | ONE sentence: why is this needed? |

**1.2 Development Dependencies**
Same format as runtime, but for dev-only packages (testing, linting, building).

**1.3 Optional/Peer Dependencies**
Dependencies that are optional or required by other packages:
- Document **Required By**: which package needs this?

---

### Section 2: Usage Analysis

**Search for**: Import statements for each dependency.

**2.1 Most Used Libraries**
| Column | What to capture |
|--------|-----------------|
| Import Count | How many files import this |
| Files | Which files (or "many" if >5) |
| Criticality | High (core functionality), Medium, Low |

**2.2 Unused Dependencies**
Libraries in package file but never imported:
- Document **Recommendation**: remove, keep (why?), investigate

**2.3 Implicit Dependencies**
Libraries not in package file but available via transitive dependencies:
- Document **Used Directly?**: is this imported in code?
- If yes, should it be an explicit dependency?

---

### Section 3: Import Locations

For each significant library, document where it's used:

**Create a subsection for each major library:**
```markdown
### [Library Name]

| Import | Location | Purpose |
|--------|----------|---------|
| `from lib import X` | `file.py:10` | Why is X used here? |
```

Focus on:
- Libraries used in >3 files
- Libraries critical to architecture
- Libraries with complex APIs

---

### Section 4: Library Categories

Group libraries by purpose. For each category:
| Column | What to capture |
|--------|-----------------|
| Library | Package name |
| Purpose | Specific use in this project |
| Alternatives | Other libraries that could do this |

**Categories to consider:**
- Core/Framework - fundamental to the application
- Data Processing - parsing, transformation, validation
- UI/Display - rendering, components, styling
- Networking/API - HTTP clients, API tools
- Database/Storage - ORMs, drivers, caching
- Testing - test runners, mocking, assertions
- Development Tools - linting, formatting, debugging
- Security - auth, encryption, validation

---

### Section 5: Dependency Health

**Analyze**: Are dependencies up-to-date, secure, maintained?

**5.1 Version Status**
| Column | What to capture |
|--------|-----------------|
| Current | Version installed |
| Latest | Latest available version |
| Status | Up-to-date, Minor behind, Major behind, Deprecated |

**5.2 Security Advisories**
Check for known vulnerabilities:
- Use `npm audit`, `pip-audit`, `cargo audit`, etc.
- Document severity and resolution path

**5.3 Maintenance Status**
| Column | What to capture |
|--------|-----------------|
| Last Release | When was it last updated? |
| Maintainers | Active maintainers? |
| Status | Active, Maintenance mode, Abandoned, Archived |

---

### Summary Section

**Dependency Metrics** - Raw counts

**Dependency Graph** - ASCII diagram showing key relationships

**Risk Assessment**
| Column | What to capture |
|--------|-----------------|
| Risk | Type of risk (security, abandonment, complexity) |
| Libraries | Which libraries have this risk |
| Mitigation | How to address |

**Recommendations** - Actionable improvements:
- Dependencies to remove
- Dependencies to update
- Dependencies to replace
- Missing dependencies to add

---

## Phase 3: Natural Language Guidelines

When writing descriptions and summaries:

1. **Be specific about usage** - "JSON parsing for API responses" not just "JSON"
2. **Note lock-in** - How hard would it be to replace this library?
3. **Document why** - Why this library over alternatives?
4. **Flag risks** - Unmaintained, security issues, heavy dependencies
5. **Consider bundle size** - Note unusually large dependencies

---

## Phase 4: Verification Checklist

Before marking complete, verify:

- [ ] Every dependency from package file is listed
- [ ] Runtime vs dev dependencies separated
- [ ] Version numbers are exact (from lock file)
- [ ] Each dependency has a purpose documented
- [ ] Import locations documented for major libraries
- [ ] Libraries categorized by purpose
- [ ] Unused dependencies identified
- [ ] Security audit run and documented
- [ ] Maintenance status checked for critical deps
- [ ] Recommendations provided
- [ ] No placeholder text remains in the output file

---

## Output

Save completed analysis to: `.claude/analysis/libraries.md`
