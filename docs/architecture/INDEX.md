# Architecture Documentation

Core architectural patterns, design decisions, and system specifications for the Robust Virtual Tour Builder.

---

## Documents

### [Overview](./overview.md)
Reusable patterns for project architecture including anchor-based positioning, 3D-to-2D projection, and system architecture diagrams.

### [Async Processing Platform](./async_processing.md)
**Status:** Proposed (ADR 1525)

Architecture for migrating heavy media processing operations from synchronous to asynchronous submit-and-track job model. Includes migration milestones, SLOs, load testing strategy, and rollback procedures.

**Key Topics:**
- Queue/worker architecture
- Migration milestones (M1-M5)
- Service Level Objectives
- Load testing scenarios
- Rollback procedures

### [Simulation Architecture](./simulation.md)
**Status:** Redesign Proposed

Redesigned architecture for tour simulation (auto-forward) system with explicit state machine semantics, deterministic behavior, and eliminated race conditions.

**Key Topics:**
- FSM state machine design
- Module structure
- Implementation plan (4 phases)
- Testing strategy

### [Performance](./performance.md)
Core Web Vitals targets, runtime budgets, and performance optimization strategies.

**Key Topics:**
- Core Web Vitals (LCP, FID, CLS)
- Runtime budget presets
- E2E performance regression tests
- Viewer snapshot stability (Issue 1774)

### [System Robustness](./robustness.md)
Circuit breakers, retry mechanisms, optimistic updates, rate limiting, and interaction queues.

### [JSON Encoding](./json_encoding.md)
Type-safe JSON validation, CSP compliance, and encoding logic using `rescript-json-combinators`.

---

## Related Documentation

- **[Project Documentation](../project/)** - Project-specific mechanics, formulas, and runbooks
- **[Security Documentation](../security/)** - Authentication, rate limits, and legal policies
- **[Operations Documentation](../operations/)** - Deployment and monitoring guides
- **[Guides](../guides/)** - Implementation and AI agent guides

---

**Last Updated:** March 19, 2026
