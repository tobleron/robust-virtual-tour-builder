# Robust Virtual Tour Builder Documentation

**Last Updated:** March 19, 2026  
**Current Version:** 5.3.6 (Build 63)

---

## 📚 Documentation Structure

### [Architecture](./architecture/)
Core architectural patterns, design decisions (ADRs), and system specifications.

**Key Documents:**
- **[Overview](./architecture/overview.md)** - Reusable patterns and system architecture
- **[Async Processing Platform](./architecture/async_processing.md)** - ADR 1525: Queue/worker migration (Proposed)
- **[Simulation Architecture](./architecture/simulation.md)** - FSM redesign for deterministic behavior (Proposed)
- **[Performance](./architecture/performance.md)** - Core Web Vitals and optimization
- **[System Robustness](./architecture/robustness.md)** - Circuit breakers, retry, rate limiting
- **[JSON Encoding](./architecture/json_encoding.md)** - Type-safe validation and CSP compliance

### [Project](./project/)
Project-specific mechanics, formulas, visual pipeline, and operational runbooks.

**Key Documents:**
- **[Mechanics](./project/mechanics.md)** - Workspace and state mechanics
- **[Formulas](./project/formulas.md)** - Drag score and complexity math
- **[Visual Pipeline](./project/visual_pipeline.md)** - Tour visual pipeline overview
- **[Testing Strategy](./project/testing_strategy.md)** - E2E and verification approach
- **[Dev System](./project/dev_system.md)** - `_dev-system` analyzer governance
- **[Runbook & Audits](./project/runbook_and_audits.md)** - Performance budgets and code quality
- **[History](./project/history.md)** - Version history and verification reports

### [Operations](./operations/)
Deployment guides and operational procedures.

**Key Documents:**
- **[Deployment Guide](./operations/deployment.md)** - Cloudflare Tunnel setup for `robust-vtb.com`

### [Security](./security/)
Authentication, authorization, rate limiting, and legal policies.

**Key Documents:**
- **[Authentication](./security/authentication.md)** - Risk-based auth with email OTP (Proposed)
- **[Rate Limits](./security/rate_limits.md)** - Rate limiting policies
- **[Legal](./security/legal.md)** - Privacy Policy and Terms of Service

### [Guides](./guides/)
Implementation guides and AI agent documentation.

**Key Documents:**
- **[Implementation](./guides/implementation.md)** - Project-specific implementation
- **[AI Agents](./guides/ai_agents.md)** - Agent configurations and parallelization

### [API Reference](./api/)
Backend API specification.

**Key Documents:**
- **[OpenAPI Specification](./api/openapi.yaml)** - Complete REST API spec (OpenAPI 3.0)

### [Archive](./_archive/)
Historical documents and superseded specifications.

---

## 🚀 Quick Start

### New Developers
1. Start with **[Architecture Overview](./architecture/overview.md)**
2. Read **[Project Mechanics](./project/mechanics.md)**
3. Review **[Dev System](./project/dev_system.md)** for coding standards

### AI Agents
1. Read **[AI Agents Guide](./guides/ai_agents.md)**
2. Review **[Coding Standards](../.agent/workflows/)** in `.agent/workflows/`
3. Always use root-relative paths (`src/Main.res`)

### Operations
1. Follow **[Deployment Guide](./operations/deployment.md)**
2. Review **[Runbook & Audits](./project/runbook_and_audits.md)**
3. Monitor **[Performance Budgets](./architecture/performance.md)**

---

## 📋 Coding Standards & Workflows

Located in [`.agent/workflows/`](../.agent/workflows/):

- **[Functional Standards](../.agent/workflows/functional-standards.md)** - Universal functional programming principles
- **[ReScript Standards](../.agent/workflows/rescript-standards.md)** - ReScript frontend standards
- **[Rust Standards](../.agent/workflows/rust-standards.md)** - Rust backend standards
- **[Testing Standards](../.agent/workflows/testing-standards.md)** - Testing methodology
- **[Debug Standards](../.agent/workflows/debug-standards.md)** - Logging and debugging
- **[Commit Workflow](../.agent/workflows/commit-workflow.md)** - Commit message conventions
- **[Pre-push Workflow](../.agent/workflows/pre-push-workflow.md)** - Pre-push verification

---

## 📊 Project Status

**Current Version:** 5.3.6 (Build 63)

### Technology Stack
- **Frontend:** ReScript v12 + React 19 + Rsbuild + Tailwind CSS 4.0
- **Backend:** Rust (Actix-web) with image processing and FFmpeg
- **Testing:** Vitest (unit) + Playwright (E2E)
- **Database:** SQLite with SQLx
- **Portal:** Multi-tenant customer gallery system

### Key Features (v5.3.6)
- **Interactive 360° Viewer:** Dual-panorama crossfade system with Pannellum
- **Visual Pipeline Navigation:** Graph-based scene navigation with floor-plan routing
- **Intelligent Hotspot System:** Bidirectional linking with label management
- **Teaser Video Generation:** Multiple render styles (Cinematic, CFR, Simple Crossfade)
- **Self-Contained HTML Export:** Portable tour creation with custom branding
- **Chunked Import/Export:** Resumable uploads for large projects
- **Portal System:** Admin dashboard + customer gallery access
- **Operation Lifecycle Tracking:** Unified progress monitoring for all long-running operations
- **Recovery System:** Three-layer recovery (OperationJournal, RecoveryManager, PersistenceLayer)
- **Navigation Supervisor:** Structured concurrency with abort signals for navigation tasks
- **Advanced Labeling:** Tabbed label menu with sequence and untagged organization
- **Floor Navigation:** Floor-based scene organization and navigation
- **Lock Feedback:** Real-time operation progress indicators
- **EXIF Analysis:** Automated location detection and camera grouping
- **Background Thumbnail Enhancement:** Auto-generation of rectilinear thumbnails

### Architecture Highlights
- **Centralized Reducer Pattern:** Composite state management with domain-specific sub-reducers
- **FSM Architecture:** NavigationFSM and AppFSM for predictable state transitions
- **EventBus Pattern:** Decoupled pub/sub for cross-system communication
- **Circuit Breaker:** Resilient backend calls with automatic retry
- **Operation Journal:** Transactional logging in IndexedDB for crash recovery

---

## 🔗 Related Resources

- **[README.md](../README.md)** - Full project documentation and feature overview
- **[MAP.md](../MAP.md)** - Semantic codebase map with file descriptions
- **[DATA_FLOW.md](../DATA_FLOW.md)** - Critical data flow diagrams
- **[AGENTS.md](../AGENTS.md)** - Agent protocols and context
- **[QWEN.md](../QWEN.md)** - Project protocols and standards

---

**For questions or clarifications, refer to the relevant documentation section or check the project's task system.**
