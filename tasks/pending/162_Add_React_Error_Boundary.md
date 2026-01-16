---
title: Add React Error Boundary
status: pending
priority: high
assignee: unassigned
---

# Add React Error Boundary

## Objective
Implement a top-level **Error Boundary** to catch React render errors and prevent the entire application from crashing to a white screen.

## Context
The current `App.res` does not wrap its children in an error boundary. If a runtime error occurs in a component (e.g. `ViewerManager`), the entire UI unmounts.

## Requirements
1.  **Component**: Create `src/components/ErrorBoundary.res`.
    *   It should catch errors during the render phase.
    *   It should render a fallback UI ("Something went wrong") with a "Reload App" button.
2.  **Integration**: Wrap the main `App` component's children (or the App itself in `index.js`) with this Error Boundary.
3.  **Logging**: Ensure the error is logged to the centralized `Logger` (Action Item for `unhandled`) so it reaches the backend telemetry if possible.

## Implementation Details
-   Since ReScript React doesn't fully support class components easily for Error Boundaries without bindings, consider using a binding to `react-error-boundary` or writing a small raw JS wrapper component and binding to it.
    -   *Preferred*: Use `rescript-react-error-boundary` if available, or write a simple `src/components/ErrorBoundary.js` (React Class Component) and bind to it in `ErrorBoundary.res`.
-   **Fallback UI**: Should be styled with Tailwind and match the app aesthetic.

## Definition of Done
- [ ] Application does not white-screen on intentional render error.
- [ ] Fallback UI is visible and "Reload" button works.
- [ ] Error is logged to `Logger.error`.
