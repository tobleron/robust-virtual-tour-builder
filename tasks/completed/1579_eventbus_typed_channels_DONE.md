# Task: EventBus Typed Channel Subscription & Leak Prevention

## Objective
Replace the current broadcast-to-all EventBus pattern with typed channel subscriptions to eliminate O(N) listener iteration overhead and prevent subscription memory leaks.

## Problem Statement
`EventBus.res` maintains a single `listeners` array. Every dispatched event iterates **all** subscribers, and each subscriber pattern-matches to find relevant events. With 15-20 active subscribers (modals, hotspot sync, navigation, upload progress, etc.), high-frequency events like `NavProgress` and `UpdateProcessing` cause unnecessary function calls. Additionally, the current `subscribe` function returns an unsubscribe thunk, but if React components forget cleanup in `useEffect`, listeners accumulate.

## Acceptance Criteria
- [x] Implement channel-based subscription: `subscribe(~channel: eventChannel, callback)` where `eventChannel` is a variant matching event categories (Navigation, Upload, Ui, System)
- [x] `dispatch` only iterates listeners for the relevant channel — O(1) lookup + O(M) iteration where M << N
- [x] Add a `WeakRef`-based listener registry (with fallback for environments without `WeakRef`) to auto-cleanup garbage-collected listeners
- [x] Add a `subscriptionCount()` diagnostic function for `StateDensityMonitor` integration
- [x] Add a `Logger.warn` if total subscriptions exceed 50 (leak sentinel)
  - Implemented via decoupled global hook (`globalThis.__vtbLoggerWarn`) registered by `Logger.init`; EventBus falls back to `Console.warn` if logger is not initialized yet.
- [x] No behavioral changes: existing `subscribe` without channel continues to work (receives all events)

## Technical Notes
- **Files**: `src/systems/EventBus.res`
- **Pattern**: `Dict.t<array<event => unit>>` keyed by channel string
- **Risk**: Low — backward compatible, purely additive
- **Measurement**: Flamechart comparison during rapid navigation showing reduced EventBus overhead
