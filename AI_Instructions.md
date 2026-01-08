# AI Instructions & Project Preferences

> **Quick Reference for AI Agents**
> This document defines mandatory rules and best practices for AI-assisted development on this project.

## ⚠️ Hard Rules (Must Follow)

These rules are **non-negotiable** and must be followed on every change:

### 1. Versioning
- **Format**: Use `vX.X.X` for stable releases and `vX.X.X-beta` for development updates.
- **Rollover**: When patch reaches 9, increment minor and reset patch (e.g., `v0.7.9` → `v0.8.0`).
- **Location**: `src/version.js`
- **Display**: Show as `vX.X.X[-beta] [Brief Description]` with **Strict Max 3 Words** in brackets (e.g. `[Teaser Fix]`).
- **Consistency**: Bump version on **EVERY** user-facing change.

### 2. Change Logging
- **Location**: `/logs/log_changes.txt`
- **Format**:
  ```
  [YYYY-MM-DD HH:MM] Version X.Y.Z[-beta]
  - Change description 1
  - Change description 2
  ```
- **Frequency**: Log **every** version bump with clear descriptions.

### 3. Cache Busting
- **Requirement**: Update `?v=X.X.X` query parameters in `index.html` on **EVERY** version bump.
- **Files**: `style.css?v=...` and `main.js?v=...`
- **Sync**: Version string must match `src/version.js` exactly (including `-beta` suffix if present).

### 4. Git Protocol
- **Branch Selection**: Autonomously choose between `main` (stable) and `develop` (beta) based on risk (see Rule #7).
- **Requirement**: Perform a Git commit on **EVERY** version bump.
- **Message Format**: `vX.X.X[-beta] [Brief Description]` (Description matches `BUILD_INFO` in `version.js`).

### 5. Error Handling & Debugging
- ❌ **Never** use blocking `alert()` dialogs.
- ✅ Use the toast notification system (`showToast()`).
- ✅ Log errors to the centralized debug buffer (`src/utils/Debug.js`).
- **Debugging Protocol**:
  - Enable debug mode: `window.DEBUG.enable()`
  - Log events: `Debug.error('Module', 'Message', { data })`
  - Export logs: `window.DEBUG.downloadLog()` (Saves JSON to `logs/` folder for AI analysis)

### 6. State Preservation
- Only reload/reset **AFTER** successful operations, not before.
- Detect user cancellation (e.g., file picker cancel) and preserve state.
- Use the **No-Reload Technique**: incremental UI updates over full re-initialization.

### 7. Autonomous Branch Selection
The AI agent must autonomously decide the target branch based on the risk profile of the change. **When in doubt, default to `develop`.**

- **Low Risk (Target: `main` / Stable)**:
  - **Definition**: Changes that are isolated, non-functional, or have virtually zero probability of breaking the application's core workflow.
  - **Criteria**:
    - Documentation updates (`.md` files) and comment improvements.
    - UI text typos or label corrections.
    - Minor CSS tweaks (colors, margins, padding) that don't affect layout/responsiveness.
    - Adding log statements, debug telemetry, or safe diagnostic tools.
    - Fixes for localized bugs in non-critical auxiliary components.
  - **Action**: Commit directly to `main`.
  - **Version**: Increment standard version (e.g., `v1.0.5`).

- **High Risk (Target: `develop` / Beta)**:
  - **Definition**: Changes that modify core logic, involve multiple interconnected files, or introduce new features.
  - **Criteria**:
    - Implementation of new features or significant UI/UX redesigns.
    - Refactoring existing system modules or business logic.
    - Modifying state management (`store.js`) or shared constants.
    - Updating third-party libraries or internal dependencies.
    - Changes to critical paths (upload processing, image resizing, video encoding).
    - Any structural changes to `index.html` or the build/deployment pipeline.
  - **Action**: Commit to `develop`.
  - **Version**: Use beta suffix (e.g., `v1.0.6-beta`).
  - **Note**: When `develop` stabilizes, the user may request a merge to `main`.

### 8. Cleanup & Maintenance
- **Requirement**: Before performing major updates, project-wide commits, or switching branches, execute a thorough cleanup.
- **Backend**: Run `cargo clean` in the `backend/` directory to remove large build artifacts (`target/`).
- **Logs**: Rotate or clear non-essential logs in the `logs/` directory (e.g., `telemetry.log`).
- **Test Artifacts**: Remove temporary test ZIPs from the `test/` directory once verification is complete.
- **Purpose**: Prevents massive build artifacts and temporary data from bloating the repository and slowing down Git operations.

---

## 📚 Related Documentation

| Document | Purpose |
|----------|---------|
| [TYPOGRAPHY.md](docs/TYPOGRAPHY.md) | Font system, sizes, and accessibility |
| [ACCESSIBILITY_GUIDE.md](docs/ACCESSIBILITY_GUIDE.md) | WCAG compliance and a11y patterns |
| [IMPROVEMENTS.md](docs/IMPROVEMENTS.md) | Planned features and enhancements |
| [SIMULATION_MODE_IMPLEMENTATION.md](docs/SIMULATION_MODE_IMPLEMENTATION.md) | Jump link navigation system |

---

## 📁 File Organization

```
project/
├── AI_Instructions.md  # This file (Agent instructions)
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
- **Teaser Verification**: Ensure punchy teasers respect "Live View" updates (targetYaw) over original "Director View" (viewFrame).

---

## 🛠️ Local Development & Debugging

- **Dev Server**: The project is served via `npm run dev` (Vite).
- **URL**: Access the application at [http://localhost:9999](http://localhost:9999) for DOM testing and visual verification.
- **Agent Workflow**: Always prefer testing on `localhost:9999` when visual confirmation is required.

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

- **Branching Note**: Ensure local `git` configuration is set to push to `origin develop` by default to avoid accidental main pushes.

---

*Last updated: 2026-01-08 11:35*