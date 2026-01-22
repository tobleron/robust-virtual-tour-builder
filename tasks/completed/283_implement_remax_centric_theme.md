# Task 277: Implement Remax-Centric Theme Unification

## 🎯 Objective
Simplify and unify the project's color palette to align with a cohesive "Remax-Centric" theme, reducing the number of disparate colors and strengthening brand identity.

---

## 🛠️ Step-by-Step Implementation

### Step 1: Consolidate Palette in `css/variables.css`
- Update `--primary`, `--accent`, and sister variables to a unified Remax family.
- Map existing outlier colors (like random oranges/blues in `floor-nav.css`) to these core variables.

**Verification**:
- Check `css/variables.css` for consistency.

### Step 2: Unify Floor Navigation Colors
- Update `floor-nav.css` to use the primary and accent families.
- Replace `#ea580c` and `#0047AB` with `--accent` and `--primary-light` variations.

**Verification**:
- Verify Floor Nav visual state changes (hover, active) remain high-contrast and clear.

### Step 3: Unify Hotspot Interaction Colors
- Update `viewer.css` hotspot forward buttons to use the unified palette.
- Ensure the active/autopilot states use the `--success` and `--accent` variables consistently.

**Verification**:
- Test Hotspot clicking and Autopilot state visuals.

---

## 🧪 Final Verification
- Run `npm run build`.
- Visual sweep: ensure the UI feels like a single unified application rather than a collection of different modules.
