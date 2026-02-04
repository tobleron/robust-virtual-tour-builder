# Documentation Index

**Last Updated**: 2026-02-04

---

## 📚 Quick Navigation

### For New Developers
1. Start with [README.md](../README.md) - Project overview
2. Read [PROJECT_SPECS.md](PROJECT_SPECS.md) - Architecture & design system
3. Review [GENERAL_MECHANICS.md](GENERAL_MECHANICS.md) - Development workflow

### For Contributors
1. [Implementation Guide](guides/IMPLEMENTATION_GUIDE.md) - How we implement patterns
2. [Architecture Patterns](architecture/) - Reusable design patterns
3. [Workflow Standards](../.agent/workflows/) - Coding standards by language

---

## 🗂️ Documentation Structure

### `/docs/` - Project-Specific Documentation

#### Core Documentation
- **[PROJECT_SPECS.md](PROJECT_SPECS.md)** - System architecture, design system, technical specifications
- **[GENERAL_MECHANICS.md](GENERAL_MECHANICS.md)** - Development guidelines, initialization standards, testing strategy
- **[PROJECT_HISTORY.md](PROJECT_HISTORY.md)** - Version history, bug fixes, roadmap, analysis reports

#### Performance & Operations
- **[PERFORMANCE_AND_METRICS.md](PERFORMANCE_AND_METRICS.md)** - Core Web Vitals, telemetry, optimization strategies

#### Legal & Compliance
- **[PRIVACY_POLICY.md](PRIVACY_POLICY.md)** - Privacy policy
- **[TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)** - Terms of service

#### API Reference
- **[openapi.yaml](openapi.yaml)** - Backend API specification (OpenAPI 3.0)

---

### `/docs/architecture/` - General Architectural Patterns

**Purpose**: Reusable patterns applicable to any modern web application

- **[SYSTEM_ROBUSTNESS.md](architecture/SYSTEM_ROBUSTNESS.md)** - Circuit breakers, retry logic, rate limiting, graceful degradation
- **[JSON_ENCODING_STANDARDS.md](architecture/JSON_ENCODING_STANDARDS.md)** - Type-safe JSON validation, CSP compliance, error handling

**Audience**: Developers building similar systems or learning architectural patterns

---

### `/docs/guides/` - Implementation Guides

**Purpose**: Bridge between general patterns and project-specific code

- **[IMPLEMENTATION_GUIDE.md](guides/IMPLEMENTATION_GUIDE.md)** - How this project implements architectural patterns

**Audience**: Project contributors and maintainers

---

### `/.agent/workflows/` - Coding Standards

**Purpose**: Language-specific standards and workflows

- **[functional-standards.md](../.agent/workflows/functional-standards.md)** - Universal functional programming principles (router)
- **[rescript-standards.md](../.agent/workflows/rescript-standards.md)** - ReScript frontend standards
- **[rust-standards.md](../.agent/workflows/rust-standards.md)** - Rust backend standards
- **[testing-standards.md](../.agent/workflows/testing-standards.md)** - Testing methodology
- **[debug-standards.md](../.agent/workflows/debug-standards.md)** - Logging and debugging
- **[commit-workflow.md](../.agent/workflows/commit-workflow.md)** - Commit quality standards
- **[pre-push-workflow.md](../.agent/workflows/pre-push-workflow.md)** - Pre-push verification

**Audience**: Active developers working on the codebase

---

## 📖 Documentation by Use Case

### "I want to understand the system architecture"
1. [PROJECT_SPECS.md](PROJECT_SPECS.md) - High-level architecture
2. [MAP.md](../MAP.md) - Codebase semantic map
3. [IMPLEMENTATION_GUIDE.md](guides/IMPLEMENTATION_GUIDE.md) - Actual implementation

### "I want to add a new feature"
1. [GENERAL_MECHANICS.md](GENERAL_MECHANICS.md) - Development workflow
2. [/.agent/workflows/functional-standards.md](../.agent/workflows/functional-standards.md) - Choose your language standard
3. [IMPLEMENTATION_GUIDE.md](guides/IMPLEMENTATION_GUIDE.md) - Follow existing patterns

### "I want to fix a bug"
1. [/.agent/workflows/debug-standards.md](../.agent/workflows/debug-standards.md) - Debugging approach
2. [GENERAL_MECHANICS.md](GENERAL_MECHANICS.md#part-3-testing-strategy) - Testing strategy
3. [PROJECT_HISTORY.md](PROJECT_HISTORY.md#notable-bug-fixes) - Historical fixes

### "I want to deploy the application"
1. [PROJECT_SPECS.md](PROJECT_SPECS.md#security--stability-systems) - Security checklist
2. [PERFORMANCE_AND_METRICS.md](PERFORMANCE_AND_METRICS.md) - Performance targets
3. [IMPLEMENTATION_GUIDE.md](guides/IMPLEMENTATION_GUIDE.md#9-deployment) - Build process

### "I want to learn architectural patterns"
1. [architecture/SYSTEM_ROBUSTNESS.md](architecture/SYSTEM_ROBUSTNESS.md) - Robustness patterns
2. [architecture/JSON_ENCODING_STANDARDS.md](architecture/JSON_ENCODING_STANDARDS.md) - Validation patterns
3. [IMPLEMENTATION_GUIDE.md](guides/IMPLEMENTATION_GUIDE.md) - Real-world examples

---

## 🔄 Documentation Maintenance

### When to Update

| Trigger | Update These Docs |
|---------|-------------------|
| New architectural pattern added | `architecture/*.md` |
| Project-specific implementation changed | `guides/IMPLEMENTATION_GUIDE.md` |
| Major version release | `PROJECT_HISTORY.md`, `CHANGELOG.md` |
| Design system change | `PROJECT_SPECS.md` (Part 2) |
| New coding standard | `/.agent/workflows/*.md` |
| API endpoint added/changed | `openapi.yaml` |
| Performance optimization | `PERFORMANCE_AND_METRICS.md` |

### Documentation Standards

1. **Separation of Concerns**:
   - General patterns → `/docs/architecture/`
   - Project-specific → `/docs/` and `/docs/guides/`
   - Coding standards → `/.agent/workflows/`

2. **Markdown Formatting**:
   - Use headers for navigation
   - Include code examples
   - Add "Last Updated" dates
   - Link to related docs

3. **Versioning**:
   - Document version in frontmatter
   - Mark deprecated sections clearly
   - Archive old versions in `/docs/archive/` (if needed)

---

## 🎯 Quick Reference

### Key Concepts

- **System 2 Thinking**: Deliberate, type-safe, functional architecture
- **Zero Warnings Policy**: All compiler warnings treated as errors
- **CSP Compliance**: No `eval()`, strict Content Security Policy
- **Immutability First**: Functional data structures, no mutations
- **Result Types**: Errors as values, not exceptions

### File Naming Conventions

- **Standards**: `UPPERCASE_WITH_UNDERSCORES.md`
- **Guides**: `Title_Case_With_Underscores.md`
- **Workflows**: `lowercase-with-hyphens.md`

### Common Abbreviations

- **CSP**: Content Security Policy
- **FSM**: Finite State Machine
- **LOC**: Lines of Code
- **PWA**: Progressive Web App
- **SoC**: Separation of Concerns
- **WCAG**: Web Content Accessibility Guidelines

---

## 📞 Getting Help

1. **Search the docs**: Use your editor's search or `grep`
2. **Check MAP.md**: Find the relevant module
3. **Read the workflow**: Language-specific standards in `/.agent/workflows/`
4. **Review examples**: Implementation guide has real code examples

---

## 🤝 Contributing to Documentation

1. Follow the separation of concerns principle
2. Add examples for complex concepts
3. Update the index when adding new docs
4. Keep language-agnostic patterns in `/architecture/`
5. Link related documents

---

*This index is automatically maintained. Last regenerated: 2026-02-04*
