# Technical Context

## Tech Stack

**Framework**: [Framework name and version]
**Runtime**: [Runtime/language and version]
**Language**: [Primary language and version]
**Styling**: [Styling solution]
**Build Tool**: [Build tool]
**Package Manager**: [npm, yarn, pip, etc.]

## Dependencies

### Core Framework
- **[dependency-name]** ([version]): [Purpose and why chosen]
- **[another-dependency]** ([version]): [Purpose and why chosen]

### [Category (e.g., UI & Styling)]
- **[dependency]** ([version]): [Purpose]
- **[dependency]** ([version]): [Purpose]

### [Another Category]
- **[dependency]** ([version]): [Purpose]

## Development Setup

### Prerequisites
- [Tool/software name] [version]+ ([recommended version])
- [Another prerequisite]

### Installation
```bash
[installation command]
```

### Development Server
```bash
[dev server command]  # [Description, e.g., "Runs on http://localhost:3000"]
```

### Production Build
```bash
[build command]  # [Description]
[start command]  # [Description]
```

## Technical Constraints

### [Framework/Tool Name]
- **[Constraint]**: [Description]
- **[Limitation]**: [Description]

### [Platform/Environment]
- **[Requirement]**: [Description]
- **[Limitation]**: [Description]

## Configuration

### Environment Variables
**Required**:
- `[VAR_NAME]`: [Description]

**Optional**:
- `[VAR_NAME]`: [Description and default]

### [Config File Name]
- **[Setting]**: [Description]
- **[Another Setting]**: [Description]

## Known Technical Issues

### [Issue Name]
- **Location**: [Where in code]
- **Status**: [Current status]
- **Impact**: [How it affects development]
- **Workaround**: [How to work around it, if any]

## Performance Characteristics

### [Performance Aspect]
- **[Metric]**: [Expected performance]
- **[Bottleneck]**: [Known limitation]
- **[Optimization]**: [How to optimize if needed]

## Platform Support

### [Platform 1]
- **Tested**: [Versions tested]
- **Issues**: [Any known issues]
- **Notes**: [Special considerations]

### [Platform 2]
- **Tested**: [Versions tested]
- **Issues**: [Any known issues]
- **Notes**: [Special considerations]

## Context Management (Claude Code Specific)

### Memory Files
All files in `.claude/memory/` are loaded into context on every prompt:
- activeContext.md - Current work state
- projectBrief.md - Project goals and scope
- systemPatterns.md - Design patterns and architecture
- techContext.md - This file (tech stack and constraints)
- projectProgress.md - Implementation status
- tags.md - Auto-generated code structure (via ctags hook)

### Hooks
Claude Code hooks configured to maintain context:
- **ctags-arch.sh**: Runs before each prompt to update tags.md
- **tags.conf**: Configures which paths to index

### Token Budget
- **Target**: Keep all memory files under 10-15K tokens total
- **Current**: See tags.md for token count
- **Strategy**: Compress, generalize, avoid duplication

---

**Update Frequency**: After adding dependencies or changing configuration
