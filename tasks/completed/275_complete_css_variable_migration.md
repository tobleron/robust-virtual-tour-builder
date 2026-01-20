# Task 275: Complete CSS Variable Migration

## 🎯 Objective
Eliminate all remaining hardcoded hex color values across the CSS codebase and replace them with design tokens from `css/variables.css`.

---

## 🛠️ Step-by-Step Implementation

### Step 1: Audit and Update Design Tokens
- Open `css/variables.css`.
- Add any missing semantic variables for existing colors that don't have a clear variable name yet (e.g., specific orange or navy shades used in `floor-nav.css`).

**Verification**:
- Run `npm run build` to ensure the CSS remains valid.

### Step 2: Migrate `css/components/viewer.css`
- Locate hardcoded hex values (identified ~10 instances).
- Replace with `var(--...)` references.

**Verification**:
- Verify viewer UI elements (Linking Mode crosshair, Hotspot arrows, buttons) still appear with correct colors.

### Step 3: Migrate `css/components/floor-nav.css`
- Locate hardcoded hex values (~5 instances).
- Replace with `var(--...)` references.

**Verification**:
- Verify Floor Navigation circles change state (hover, active) correctly.

### Step 4: Migrate `css/components/ui.css` and `modals.css`
- Locate hardcoded hex values in gradients and backgrounds.
- Replace with `var(--...)` references.

**Verification**:
- Verify Modal overlays and gradients in headers/sidebars still look correct.

---

## 🧪 Final Verification
- Final `npm run build`.
- Visual check across the application.
