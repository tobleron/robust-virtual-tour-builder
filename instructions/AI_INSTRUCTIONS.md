# AI Instructions & Project Preferences

> **Quick Reference for AI Agents**  
> This document defines mandatory rules and best practices for AI-assisted development on this project.

## ⚠️ Hard Rules (Must Follow)

These rules are **non-negotiable** and must be followed on every change:

### 1. Versioning
- **Format**: Use `vX.X.X` (semantic versioning: major.minor.patch)
- **Rollover**: When patch reaches 9, increment minor and reset patch (e.g., `v0.7.9` → `v0.8.0`)
- **Location**: `src/version.js`
- **Display**: Show as `vX.X.X [Brief Description]` with **max 3 words** in brackets
- **Consistency**: Bump version on **EVERY** user-facing change

### 2. Change Logging
- **Location**: `/logs/log_changes.txt`
- **Format**:
  ```
  [YYYY-MM-DD HH:MM] Version X.Y.Z
  - Change description 1
  - Change description 2
  ```
- **Frequency**: Log **every** version bump with clear descriptions

### 3. Cache Busting
- **Requirement**: Update `?v=X.X.X` query parameters in `index.html` on **EVERY** version bump
- **Files**: `style.css?v=X.X.X` and `main.js?v=X.X.X`
- **Sync**: Version must match `src/version.js`

### 4. Git Protocol
- **Requirement**: Perform a Git commit on **EVERY** version bump
- **Message Format**: `vX.X.X [Brief Description]` (Description matches `BUILD_INFO` in `version.js`)
- **Main Branch**: Always commit to the `main` branch unless specifically directed otherwise
- **Pushing**: Push to remote repository after successful local commit if environment allows

### 5. Error Handling
- ❌ **Never** use blocking `alert()` dialogs
- ✅ Use the toast notification system (`showToast()`)
- ✅ Log errors to the debug buffer

### 6. State Preservation
- Only reload/reset **AFTER** successful operations, not before
- Detect user cancellation (e.g., file picker cancel) and preserve state
- Use the **No-Reload Technique**: incremental UI updates over full re-initialization

---

## 📚 Related Documentation

| Document | Purpose |
|----------|---------|
| [TYPOGRAPHY.md](../docs/TYPOGRAPHY.md) | Font system, sizes, and accessibility |
| [ACCESSIBILITY_GUIDE.md](../docs/ACCESSIBILITY_GUIDE.md) | WCAG compliance and a11y patterns |
| [IMPROVEMENTS.md](../docs/IMPROVEMENTS.md) | Planned features and enhancements |
| [SIMULATION_MODE_IMPLEMENTATION.md](../docs/SIMULATION_MODE_IMPLEMENTATION.md) | Jump link navigation system |

*(Note: links updated to point to ../docs/ since this file is now in instructions/)*

---

## 📁 File Organization

```
project/
├── instructions/       # Agent instructions
│   └── AI_INSTRUCTIONS.md  # This file
├── docs/               # Project documentation
│   ├── TYPOGRAPHY.md       # Font system
│   └── *.md                # Feature-specific docs
├── src/
│   ├── components/     # UI components
│   ├── systems/        # Business logic modules
│   ├── libs/           # Third-party libraries
│   ├── store.js        # State management
│   ├── constants.js    # Configuration values
│   ├── version.js      # Version info
│   └── main.js         # Entry point
├── css/
│   └── style.css       # Styles
├── logs/
│   └── log_changes.txt # Change history
└── index.html          # Main HTML
```

---

## 📋 Best Practices (Should Follow)

These guidelines improve code quality but allow for reasonable exceptions:

### Code Quality

| Practice | Description |
|----------|-------------|
| **JSDoc Comments** | Add `@param`, `@returns`, `@example` to functions |
| **Inline Comments** | Explain "why" not just "what" for complex logic |
| **Constants** | Extract magic numbers to `src/constants.js` |
| **Descriptive Names** | Use `BLOB_URL_CLEANUP_DELAY` not `DELAY` |

### Architecture
- Separate concerns: UI components, business logic, data management
- Use the centralized `store.js` for state management
- Create dedicated system modules in `src/systems/` for specific tasks

### User Experience
- Show progress bars for operations over 500ms
- Auto-hide progress bars after 2-3 seconds
- Use modal dialogs for destructive actions with clear Cancel option

### Performance
- Cache large assets (e.g., WASM files) in IndexedDB
- Use `requestAnimationFrame` for animations
- Use modern formats: WebP for images, WebM for video

---

## 🎨 Typography

This project uses a **dual-font system** (Outfit + Inter) for optimal readability.

**Quick reference:**
- **Headings/Titles**: Outfit (`var(--font-heading)`)
- **UI/Forms/Buttons**: Inter (`var(--font-ui)`)
- **Minimum font size**: 12px (WCAG compliance)

👉 **Full details**: [TYPOGRAPHY.md](../docs/TYPOGRAPHY.md)

---

## 🧪 Testing Mindset

- Test the happy path **AND** edge cases (cancel, error, empty state)
- Verify changes in browser after each modification
- Ensure state is preserved on unexpected interruptions
- **Visual Debugging**: Use the `test_images/` folder (3 images) for consistent upload testing.

---

## 🛠️ Local Development & Debugging

- **Dev Server**: The project is served via `npx live-server --port=9999`.
- **URL**: Access the application at [http://localhost:9999](http://localhost:9999) for DOM testing and visual verification.
- **Agent Workflow**: Always prefer testing on `localhost:9999` when visual confirmation is required.

---

---

## 💬 Communication Style

- Explain changes made, not just what code was written
- Acknowledge when backtracking due to bugs or new information
- Ask for clarification rather than making assumptions
- Provide options when multiple approaches exist

---

## 📦 Export & Embedding

### Structure
- Create self-contained export folders with all dependencies
- Use relative paths for portability
- Include embed codes with `title` attributes for accessibility

### Calibration
- When precision matters (e.g., visual proportions), use fixed sizes
- Document the relationship between coordinated settings
- Avoid responsive scaling if it breaks calibrated proportions

---

## 🔧 Tweaks & Future Adjustments

*Place any minor tweaks, experimental preferences, or temporary overrides here.*

- (None currently)

---

*Last updated: 2026-01-03*