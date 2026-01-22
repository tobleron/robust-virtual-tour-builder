# Task 019: Fix All Security Issues (innerHTML / dangerouslySetInnerHTML)

## 🎯 Objective
Remove XSS vulnerabilities by replacing all unsafe HTML content insertion methods with safe DOM manipulation or proper React JSX rendering.

## 🛠 Technical Implementation
- **Modal System Refactoring**:
  - Refactored `EventBus.modalConfig` to replace the unsafe `contentHtml: option<string>` field with a type-safe `content: option<React.element>` field.
  - Updated `ModalContext.res` to render the `content` element directly, removing all `dangerouslySetInnerHTML` usage.
  - Migrated complex HTML generation logic in `UploadReport.res` and `LinkModal.res` to structured JSX, ensuring all data is properly escaped by React.
  - Updated `Sidebar.res` (About and New Project modals) to use JSX for content.
- **Export Template Optimization**:
  - Refactored the `renderGoldArrow` JavaScript function in `TourTemplateScripts.res` to use `document.createElementNS` and other DOM APIs instead of `innerHTML` for SVG injection. This ensures that exported tours are also protected from XSS.
- **Visual Pipeline Hardening**:
  - Replaced `innerHTML` usage in `VisualPipeline.res` with programmatic element creation via `Dom.createElement`. This secured the timeline step tooltips and indicators.
- **Test Integrity**:
  - Updated `EventBusTest.res` to align with the new `modalConfig` type.
- **Verification**:
  - Confirmed that `grep` finds no remaining unsafe HTML methods in `.res` files (except for safe clearing with empty strings).
  - Verified that all frontend tests and the full production build pass.

## 📝 Notes
- Choosing to refactor the modal system to use JSX instead of just sanitizing strings provides a much higher level of security and better developer experience for future features.