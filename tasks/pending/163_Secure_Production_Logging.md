---
title: Secure Production Logging
status: pending
priority: high
assignee: unassigned
---

# Secure Production Logging

## Objective
Prevent debug logs and sensitive information from leaking into the browser console in production builds.

## Context
The `Logger.res` currently has `enabled` set to `true` by default. While `rsbuild` removes `console.log`, the custom `%raw` implementation in `Logger.res` might bypass this, or logic might explicitly print logs. We need to ensure logging is strictly Opt-In for production.

## Requirements
1.  **Environment Detection**: Modify `Logger.res` initialization.
    *   Check `Node.Process.env` (or equivalent define/binding) for `NODE_ENV`.
    *   If `production`, default `enabled` to `false`.
    *   If `development`, default `enabled` to `true`.
2.  **Badge Visibility**: The "🐛 DEBUG" badge should NEVER appear automatically in production.
3.  **Telemetry**: Ensure that *Error* reporting to the backend still functions even if console logging is disabled.

## Implementation Details
-   Use `let isDev = %raw("process.env.NODE_ENV !== 'production'")` or pass it via `ReBindings`.
-   Ensure `Logger.error` still sends telemetry payload regardless of `enabled` flag (separation of concerns: Console vs Telemetry).

## Definition of Done
- [ ] `npm run build` -> Serve -> Console should be clean of `[Info]`, `[Debug]` logs.
- [ ] "🐛 DEBUG" badge is hidden in production.
- [ ] Errors still report to backend.
