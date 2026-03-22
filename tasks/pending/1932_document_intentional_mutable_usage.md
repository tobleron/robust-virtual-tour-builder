# 1932 — Document Intentional Mutable Usage and Fix TeaserRecorderHudTypes

**Priority:** 🟠 P1  
**Effort:** 20 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

The project's coding vitals mandate: *"Maintain functional purity in ReScript; avoid `mutable`"*. Several modules use `mutable` record fields. Most are justified for stateful singletons (imperative constructs by nature), but they lack documentation explaining why the exception is valid.

## Scope

### Justified Mutability (Document Only)

Add `// JUSTIFIED: imperative singleton` comments to:

| Module | Mutable Fields |
|---|---|
| `src/core/InteractionGuard.res` | `lastExecution`, `timerId`, `pendingReject`, `limiter` |
| `src/utils/RateLimiter.res` | `timestamps` |
| `src/utils/CircuitBreaker.res` | `internalState` |

### Unjustified Mutability (Fix)

| Module | Field | Fix |
|---|---|---|
| `src/systems/TeaserRecorderHudTypes.res` | `mutable width: float` | Convert to a non-mutable field or use React ref/state |

### Steps

1. Add justification comments to `InteractionGuard.res`, `RateLimiter.res`, `CircuitBreaker.res`
2. Investigate `TeaserRecorderHudTypes.res` — determine if `width` can be made immutable
3. If `width` is mutated in-place, refactor to use a new record copy instead
4. Run `npm run build`

## Acceptance Criteria

- [ ] All `mutable` usages in `src/` are documented with justification comments
- [ ] `TeaserRecorderHudTypes.width` is either made immutable or documented with justification
- [ ] `npm run build` passes
