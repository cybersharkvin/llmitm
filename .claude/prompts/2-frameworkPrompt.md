# Framework Configuration Analysis

## Objective

Analyze the framework(s) used in this application and document configuration in `.claude/analysis/frameworks.md`.

**Definition**: "Framework" means the primary application framework that structures the codebase (e.g., React, Django, Rails, Streamlit), plus supporting frameworks (e.g., ORMs, test frameworks). This analysis covers configuration, patterns, and conventions.

---

## Phase 1: Reconnaissance

Before documenting, identify the framework:

1. **Check package files** - `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`
2. **Check config files** - `next.config.js`, `settings.py`, `config.ru`, `docker-compose.yml`
3. **Look at entry points** - main files often reveal the framework
4. **Read available memory/context files** for stated architecture

**Do not fill tables until you've identified all frameworks in use.**

---

## Phase 2: Section-by-Section Analysis

### Section 1: Framework Identity

**Search for**: Package dependencies, framework-specific imports, config files.

**1.1 Primary Framework**
| Column | What to capture |
|--------|-----------------|
| Name | Official framework name |
| Version | Exact version from lock file or package file |
| Type | Web framework, CLI framework, GUI framework, etc. |
| Documentation | Link to official docs |

**1.2 Secondary Frameworks**
List supporting frameworks:
- ORM (SQLAlchemy, Prisma, ActiveRecord)
- Testing (pytest, Jest, RSpec)
- Validation (Pydantic, Zod, Joi)
- etc.

---

### Section 2: Configuration

**Search for**: Framework config files, settings modules, environment setup.

**2.1 Configuration Files**
List all framework-specific config files.

**2.2 Configuration Details**
For each config file, document every non-default setting:
| Column | What to capture |
|--------|-----------------|
| Setting | The configuration key |
| Value | The configured value |
| Purpose | Why is this configured? |
| Default | What's the default if not set? |

---

### Section 3: Framework Patterns

**Search for**: Architecture patterns, conventions, special features.

**3.1 Architecture Pattern**
- What pattern does the framework encourage? (MVC, Component, Layered, etc.)
- How does this project implement it?
- Where does implementation deviate from the pattern?

**3.2 Rendering Strategy**
| Column | What to capture |
|--------|-----------------|
| Type | SSR, CSR, SSG, Hybrid, Server components |
| Mechanism | How rendering is triggered |
| Data Fetching | Where/when is data fetched for rendering |

**3.3 Routing**
- How are routes defined?
- File-based, config-based, decorator-based?
- Document dynamic route patterns

**3.4 Framework Conventions**
| Column | What to capture |
|--------|-----------------|
| Convention | The expected pattern |
| Usage | How this project uses it |
| Location | Where to find examples |

**3.5 Special Features**
Document enabled framework features:
- Middleware
- Plugins/extensions
- Feature flags
- Experimental features

---

### Section 4: Build System

**Search for**: Build tools, compilers, bundlers, task runners.

**4.1 Build Tool**
- What builds the project? (webpack, vite, setuptools, cargo)
- What version?
- Where is it configured?

**4.2 Build Commands**
Document all build-related commands:
- Development server
- Production build
- Test runner
- Linting

**4.3 Compiler Configuration**
- TypeScript, Babel, Rust compiler settings
- Target versions
- Strict mode settings

**4.4 Build Optimizations**
Document enabled optimizations:
- Minification
- Tree shaking
- Code splitting
- Caching

---

### Section 5: Environment Configuration

**Search for**: Environment modes, environment-specific settings.

**5.1 Environment Modes**
What environments are configured?
- Development
- Production
- Test
- Staging

**5.2 Environment-Specific Settings**
What changes between environments?
- API URLs
- Debug flags
- Logging levels
- Feature toggles

---

### Summary Section

**Framework Stack** - ASCII diagram showing framework layers

**Configuration Health**
| Column | What to capture |
|--------|-----------------|
| Aspect | Security defaults, performance, DX |
| Status | Good, Needs attention, Missing |
| Notes | Specific observations |

**Recommendations** - Actionable improvements

---

## Phase 3: Natural Language Guidelines

When writing descriptions and summaries:

1. **Version matters** - Always include exact versions
2. **Explain deviations** - Why does this project differ from framework conventions?
3. **Document decisions** - Why was this setting chosen?
4. **Link to docs** - Reference official documentation for complex features
5. **Note deprecations** - Flag deprecated patterns or upcoming breaking changes

---

## Phase 4: Verification Checklist

Before marking complete, verify:

- [ ] Primary framework identified with exact version
- [ ] All framework config files listed and documented
- [ ] Architecture pattern identified and described
- [ ] Routing strategy documented
- [ ] Build tool and commands documented
- [ ] Environment modes identified
- [ ] Special features/plugins listed
- [ ] Configuration health assessed
- [ ] Recommendations provided
- [ ] No placeholder text remains in the output file

---

## Output

Save completed analysis to: `.claude/analysis/frameworks.md`
