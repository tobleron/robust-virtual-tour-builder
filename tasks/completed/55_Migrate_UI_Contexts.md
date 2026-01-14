---
description: Migrate imperative Modal and Notification managers to React Contexts
---

# Objective
Refactor `ModalManager.js` and `NotificationSystem.js` from imperative DOM manipulation modules to declarative React Contexts (`ModalContext.res`, `NotificationContext.res`).

# Context
Currently, `ModalManager.show(...)` injects HTML strings into a `div#modal-container`. This is "the jQuery way" and breaks React's component lifecycle / context availability (e.g., you can't use other contexts inside a modal easily).

# Requirements

1.  **Notification System**:
    *   Create `src/components/NotificationContext.res`.
    *   State: `array<notification>` where `notification = {id: string, message: string, type: [#Info | #Success | #Error]}`.
    *   Provider: Renders a fixed container (toast list).
    *   Hook: `let useNotification = () => { notify: (...) => unit }`.
    *   Replace `utils/NotificationSystem.js` calls.

2.  **Modal System**:
    *   Create `src/components/ModalContext.res`.
    *   State: `option<modalConfig>`.
    *   Provider: Renders the active modal overlay if state is `Some(...)`.
    *   Ensure keyboard (ESC) and click-outside handling is implemented in the Provider or container component.
    *   Replace `utils/ModalManager.js` imports.

3.  **Integration**:
    *   Wrap `App.res` root with these providers.
    *   Update `LinkModal.res` (if it uses the manager) or other UI triggers to use the hooks.

4.  **Cleanup**:
    *   Delete `src/utils/ModalManager.js`.
    *   Delete `src/utils/NotificationSystem.js`.

5.  **Verification**:
    *   Trigger notifications (e.g., via save project).
    *   Trigger modals (e.g., hotkey list or external link dialogs).
