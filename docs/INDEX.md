# Robust Virtual Tour Builder Documentation

**Last Updated**: 2026-02-04

---

## 📚 Quick Navigation

### Architecture (General)
- **[Overview](arch_overview.md)** - Reusable patterns for project architecture.
- **[System Robustness](arch_system_robustness.md)** - Circuit breakers, retry, optimistic updates, rate limiting.
- **[Performance](arch_performance.md)** - Performance targets, thresholds, and Core Web Vitals.
- **[JSON Encoding](arch_json_encoding.md)** - Type-safe validation, CSP compliance, and encoding logic.

### Project Specific Methods & Specs
- **[Visual Pipeline](project_visual_pipeline.md)** - Overview of the Virtual Tour visual pipeline.
- **[Mechanics](project_mechanics.md)** - Workspace, initialization, and application state mechanics.
- **[Formulas](project_formulas.md)** - Drag score, limits, and complexity math.
- **[Specs](project_specs.md)** - UX specifications, core dependencies, and design systems.
- **[Testing Strategy](project_testing_strategy.md)** - End-to-end, optimistic update, and verification strategy.
- **[Dev System](project_dev_system.md)** - `_dev-system` and agent logic governance.
- **[Runbook & Audits](project_runbook_and_audits.md)** - Past and active operational auditing, and CI stress gates.
- **[History](project_history.md)** - Version history, evolution, and milestones.

### Guides
- **[Implementation](guide_implementation.md)** - Project-specific implementation mappings.
- **[AI Agents](guide_ai_agents.md)** - Agent configurations, parallelization, and capacities.

### Policies & Legal
- **[Legal Policies](policy_legal.md)** - Privacy Policy and Terms of Service.
- **[Rate Limits](policy_rate_limits.md)** - Rate limiting policies and background logic.

### Coding Standards & Workflows
- **[Functional Standards](../.agent/workflows/functional-standards.md)** - Universal functional programming principles.
- **[ReScript Standards](../.agent/workflows/rescript-standards.md)** - ReScript frontend standards.
- **[Rust Standards](../.agent/workflows/rust-standards.md)** - Rust backend standards.
- **[Testing Standards](../.agent/workflows/testing-standards.md)** - Testing methodology.
- **[Debug Standards](../.agent/workflows/debug-standards.md)** - Logging and debugging.
- **[Commit Workflow](../.agent/workflows/commit-workflow.md)** - Commit quality standards.
- **[Pre-push Workflow](../.agent/workflows/pre-push-workflow.md)** - Pre-push verification.

### API Reference
- **[openapi.yaml](openapi.yaml)** - Backend API specification (OpenAPI 3.0)
