# Accessibility (a11y) System

This document outlines the accessibility standards, implementation details, and audit results for the Robust Virtual Tour Builder, ensuring the application is usable by everyone, regardless of ability.

---

## 1. Audit Status & Compliance
**Current Status:** ✅ **WCAG 2.1 Level AA Compliant**  
**Last Audit Date:** January 15, 2026  
**Lighthouse Score:** 100/100

### Remediation Summary
| Category | Status | Improvements Made |
|:---|:---|:---|
| **Keyboard Navigation** | ✅ PASS | Full Tab/Enter/Space support, focus traps in modals, Escape to close. |
| **Screen Reader Support** | ✅ PASS | ARIA labels for all icon buttons, live regions for notifications. |
| **Semantic HTML** | ✅ PASS | Use of `<main>`, `<complementary>`, and `<region>` landmarks. |
| **Pannellum Viewer** | ✅ PASS | Accessible hotspots via virtual buttons and keyboard activation. |

---

## 2. Core Accessibility Features

### A. Keyboard Navigation
Users can navigate the entire application without a mouse:
- **Tab / Shift+Tab**: Move focus between interactive elements.
- **Enter / Space**: Activate buttons and links.
- **Escape**: Immediately close modals, context menus, or cancel "linking mode".
- **Focus Indicators**: A clear blue outline (`:focus-visible`) shows exactly where the user is on the page.

### B. Screen Reader Support (ARIA)
Assistive technologies (like VoiceOver or NVDA) receive full context through ARIA attributes:
- **ARIA Labels**: Every icon-only button (e.g., "Add Link") has a descriptive `aria-label`.
- **Live Regions**: Notifications and upload progress are marked with `role="status"` and `aria-live="polite"` to be announced immediately.
- **Modals**: Dialogs use `role="dialog"` and `aria-labelledby` to announce the title when opened.
- **Landmarks**: The UI is divided into semantic sections: "Editor Sidebar", "Viewer", and "Visual Pipeline".

### C. Panorama Viewer (Pannellum) Accessibility
Since the 360 canvas is naturally inaccessible, we implemented a custom bridge:
- **Virtual Hotspots**: Hotspots are mirrored in the DOM as `role="button"` elements with `tabindex="0"`.
- **Navigation Context**: Screen readers announce the destination of links (e.g., "Navigate to Kitchen").
- **Custom UI**: Zoom and autopilot controls are fully accessible via keyboard.

---

## 3. Implementation Standards

### Visible vs. Invisible Content
- **`sr-only`**: Used for descriptive labels that are necessary for screen readers but would clutter the visual UI.
- **Skip Link**: A "Skip to Main Content" link is available at the very top of the page (hidden until focused).
- **Focus Management**: When a modal opens, focus is automatically moved to the first input to save the user from multiple Tab presses.

### 🚫 Forbidden Practices
- **Never remove focus outlines**: `outline: none` is forbidden. Use `:focus-visible` to hide outlines for mouse users while keeping them for keyboard users.
- **Avoid audio-only feedback**: Every sound effect must be accompanied by a visual notification (toast).
- **No generic buttons**: Avoid buttons labeled "Click Here". Use "Save Navigation Link" or similar descriptive text.

---

## 4. How to Test Accessibility

1. **Keyboard Test**: Unplug your mouse. Can you reach and activate every feature using only Tab, Enter, and Space?
2. **Screen Reader Test**: Enable VoiceOver (Mac: `Cmd+F5`) or NVDA (Windows). Navigate through a typical workflow. Does the audio feedback make sense?
3. **Automated Audit**: Run Chrome Lighthouse or Axe DevTools. Aim for a perfect 100 score.

---
*Last Updated: 2026-01-18*
