# Task 281: Visual Regression Testing for CSS Migration

## 🎯 Objective
Perform comprehensive visual regression testing to ensure the CSS migration and color palette changes have not introduced any unintended visual changes.

---

## 🛠️ Step-by-Step Implementation

### Step 1: Capture Baseline Screenshots (Before Changes)
- If not already done, capture screenshots of key UI states:
  - Empty state (no scenes loaded)
  - Scene loaded in viewer
  - Linking mode active
  - Auto-pilot active
  - Floor navigation (all states: default, hover, active)
  - Hotspot arrows (default, hover, auto-forward active)
  - Modal dialogs (Link Modal, Label Menu)
  - Sidebar with scenes
  - Upload report

**Verification**:
- Screenshots saved in organized folder structure.

### Step 2: Apply CSS Changes
- Complete tasks 275-279 (CSS variable migration, theme unification, gradients).

**Verification**:
- All tasks marked as complete.

### Step 3: Capture After Screenshots
- Capture the same UI states as Step 1 using identical viewport sizes.

**Verification**:
- Screenshots captured in parallel folder structure.

### Step 4: Compare Screenshots
- Use a visual diff tool (e.g., `pixelmatch`, `BackstopJS`, or manual side-by-side comparison).
- Identify any visual differences.

**Verification**:
- Document all differences found.

### Step 5: Validate or Fix Differences
- For each difference:
  - **Expected**: Document as intentional improvement (e.g., unified color palette).
  - **Unexpected**: Fix the CSS to restore original appearance.

**Verification**:
- All unexpected differences are resolved.
- Expected differences are documented and approved.

### Step 6: Test Interactive States
- Manually test all interactive elements:
  - Button hover states
  - Floor navigation transitions
  - Hotspot arrow animations
  - Modal open/close animations
  - Linking mode cursor
  - Auto-pilot visual feedback

**Verification**:
- All interactions work smoothly without visual glitches.

---

## 🧪 Final Verification
- Run `npm run build`.
- All visual states match expected appearance.
- No regressions introduced by CSS migration.
- Document any intentional visual improvements.
