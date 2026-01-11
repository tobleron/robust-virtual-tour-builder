# AI Guidelines & Project Preferences

> **Quick Reference for AI Agents**
> This document defines high-level rules, philosophy, and best practices for AI-assisted development on this project.

---

## 🎯 Project Philosophy

### Core Principles
- **Stability First**: Prioritize robustness over rapid feature deployment
- **User Experience**: Every change should preserve or enhance UX
- **Code Quality**: Maintainable, well-documented code is non-negotiable
- **Incremental Progress**: Small, tested changes over large refactors

---

## 🔧 Development Workflow

### Branch Strategy
- **`develop`**: Default branch for all AI-assisted changes (beta versions with `-beta` suffix)
- **`main`**: Stable releases only (clean version numbers like `v4.1.0`)
- **Rule**: When in doubt, always use `develop`

### Version Management
- **Format**: `vX.Y.Z` for stable, `vX.Y.Z-beta` for development
- **Rollover**: When Z reaches 9, increment Y and reset Z (e.g., `v4.9.9` → `v4.10.0`)
- **Display**: Show as `vX.Y.Z[-beta] [Max 3 Words]` (e.g., `v4.1.0-beta [Teaser Fix]`)
- **Location**: `src/version.js`

### Git Workflow
- **Local Commits**: Commit every change locally with descriptive messages
- **GitHub Pushes**: Only push on **major updates** (when Y increments in `x.Y.z`)
- **Exception**: Critical security fixes or user-requested stable releases can push anytime
- **Pre-Push**: Always run cleanup checklist before pushing to GitHub

---

## 📋 Mandatory Hard Rules

### 1. Versioning
- Bump version on **EVERY** user-facing change
- Update `src/version.js` with version number and brief description
- Maintain consistency between version file, cache busting, and git tags

### 2. Change Logging
- **Location**: `/logs/log_changes.txt`
- **Format**:
  ```
  [YYYY-MM-DD HH:MM] Version X.Y.Z[-beta]
  - Change description 1
  - Change description 2
  ```
- Log **every** version bump with clear, actionable descriptions

### 3. Cache Busting
- Update `?v=X.Y.Z` query parameters in `index.html` on **EVERY** version bump
- Files: `style.css?v=...` and `main.js?v=...`
- Version string must match `src/version.js` exactly (including `-beta` suffix)

### 4. Error Handling
- ❌ **Never** use blocking `alert()` dialogs
- ✅ Use toast notification system (`showToast()`)
- ✅ Log errors to centralized debug buffer (`src/utils/Debug.js`)
- **Debug Protocol**:
  - Enable: `window.DEBUG.enable()`
  - Log: `Debug.error('Module', 'Message', { data })`
  - Export: `window.DEBUG.downloadLog()` → saves to `logs/` folder

### 5. State Preservation
- Only reload/reset **after** successful operations, not before
- Detect user cancellation (e.g., file picker cancel) and preserve state
- Use **No-Reload Technique**: incremental UI updates over full re-initialization

### 6. Security & Best Practices
- AI agent should **proactively remind** user about security concerns
- If a commit needs security refinement and fix is not time-consuming, **suggest improvements**
- Follow WCAG accessibility guidelines
- Sanitize all user inputs
- Use centralized blob URL management

---

## 📁 Project Architecture

### File Structure
```
project/
├── ai_guidelines.md        # This file (High-level rules)
├── .agent/workflows/       # Step-by-step procedures
├── docs/                   # Feature documentation
├── src/
│   ├── components/         # UI components
│   ├── systems/            # Business logic modules
│   ├── libs/               # Third-party libraries
│   ├── store.js            # State management
│   ├── constants.js        # Configuration values
│   ├── version.js          # Version info
│   └── main.js             # Entry point
├── css/style.css           # Styles
├── logs/log_changes.txt    # Change history
└── index.html              # Main HTML
```

### Architectural Principles
- **Separation of Concerns**: UI components, business logic, data management
- **Centralized State**: Use `store.js` for application state
- **System Modules**: Create dedicated modules in `src/systems/` for specific tasks
- **Constants**: Extract magic numbers to `src/constants.js`

### 7. Documentation Organization
- **Root Directory**: Only `ai_guidelines.md` and essential project files (`README.md`, `LICENSE`, config files)
- **`/docs` Directory**: ALL other documentation including:
  - Feature documentation
  - Security reports and analysis
  - Release notes
  - Architecture guides
  - Module size reports
- **`.agent/workflows`**: AI agent procedural workflows only
- **Rule**: When creating new documentation, place it in `/docs` unless it's a root-level project file

---

## 🎨 Code Quality Standards

### Documentation
- **JSDoc Comments**: Add `@param`, `@returns`, `@example` to public functions
- **Inline Comments**: Explain "why" not just "what" for complex logic
- **Descriptive Names**: Use `BLOB_URL_CLEANUP_DELAY` not `DELAY`

### User Experience
- Show progress bars for operations > 500ms
- Auto-hide progress bars after 2-3 seconds
- Use modal dialogs for destructive actions with clear Cancel option
- Preserve user context during asynchronous operations

### Performance
- Cache large assets (e.g., WASM files) in IndexedDB
- Use `requestAnimationFrame` for animations
- Use modern formats: WebP for images, WebM for video
- Lazy-load non-critical resources

---

## 🎨 Typography & Design

### Dual-Font System
- **Headings/Titles**: Outfit (`var(--font-heading)`)
- **UI/Forms/Buttons**: Inter (`var(--font-ui)`)
- **Minimum font size**: 12px (WCAG compliance)

👉 **Full details**: [TYPOGRAPHY.md](docs/TYPOGRAPHY.md)

---

## 📚 Related Documentation

| Document | Purpose |
|----------|---------|
| [TYPOGRAPHY.md](docs/TYPOGRAPHY.md) | Font system, sizes, and accessibility |
| [ACCESSIBILITY_GUIDE.md](docs/ACCESSIBILITY_GUIDE.md) | WCAG compliance and a11y patterns |
| [IMPROVEMENTS.md](docs/IMPROVEMENTS.md) | Planned features and enhancements |
| [SIMULATION_MODE_IMPLEMENTATION.md](docs/SIMULATION_MODE_IMPLEMENTATION.md) | Jump link navigation system |

---

## 🧪 Testing & Validation

### Testing Mindset
- Test happy path **AND** edge cases (cancel, error, empty state)
- Verify changes in browser after each modification
- Ensure state is preserved on unexpected interruptions

### Visual Testing
- **Test Images**: Use `test_images/` folder (3 images) for consistent upload testing
- **Teaser Verification**: Ensure teasers respect "Live View" updates (targetYaw) over "Director View" (viewFrame)
- **Local Server**: Access at [http://localhost:9999](http://localhost:9999) (Vite dev server)

---

## 💬 Communication Style

### With Users
- Explain **changes made**, not just what code was written
- Acknowledge when backtracking due to bugs or new information
- Ask for clarification rather than making assumptions
- Provide options when multiple approaches exist

### In Code
- Write code that explains itself through clear naming
- Add comments for non-obvious business logic or workarounds
- Document assumptions and constraints
- Explain "why" in comments, not "what" (code shows "what")

---

## 🔧 Project Rules

For step-by-step procedures and mandatory rules, see **`.cursorrules`** in the project root. This file includes:
- **Commit Process**: How to commit changes properly
- **Pre-Push Checklist**: Required cleanup before GitHub push
- **Security Review**: Security checks for commits

> The AI agent will automatically follow these rules.

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

*Last updated: 2026-01-11*
