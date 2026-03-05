# Task 1804: Types: Structured Error Algebra & Unified Handling

## 🤖 Agent Metadata
- **Assignee**: Antigravity (AI Agent)
- **Capacity Class**: B
- **Objective**: Standardize error reporting and telemetry across the stack.
- **Boundary**: `src/core/SharedTypes.res`, `src/utils/Logger.res`.
- **Owned Interfaces**: Error types/variants.
- **No-Touch Zones**: Existing feature logic (beyond error wrapping).
- **Independent Verification**: 
  - [ ] Telemetry entries show structured `error_type` and `operation_context` instead of raw strings.
- **Depends On**: None

---

## 🛡️ Objective
Move from `string`-based error messages to a typed `appError` variant. This enables better retry logic (retryable vs fatal), clearer user feedback, and precise telemetry analysis.

---

## 🛠️ Execution Roadmap
1. **Type Definition**: Create the `appError` variant in `SharedTypes.res` (Network, Validation, Timeout, Permission, Internal).
2. **Logger Integration**: Update `Logger` to accept the `appError` type and extract structured metadata for Sentry.
3. **Migration (Phased)**: Start by migrating the `Api` and `Persistence` layers to the new error type.

---

## ✅ Acceptance Criteria
- [ ] Unified error variant used in all `Result` types in core systems.
- [ ] Telemetry includes structured error categorization.
