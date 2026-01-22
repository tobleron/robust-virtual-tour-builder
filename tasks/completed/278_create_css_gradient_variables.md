# Task 279: Create CSS Gradient Variables

## 🎯 Objective
Extract hardcoded gradient definitions into reusable CSS variables to improve maintainability and enable consistent theming across the application.

---

## 🛠️ Step-by-Step Implementation

### Step 1: Define Gradient Variables in `css/variables.css`
- Add gradient variables to the design tokens section:
  ```css
  /* Brand Gradients */
  --gradient-brand: linear-gradient(to bottom, var(--primary-dark) 0%, #002a70 50%, var(--primary) 100%);
  --gradient-brand-subtle: linear-gradient(to bottom, var(--primary-dark) 0%, var(--primary) 100%);
  ```

**Verification**:
- Run `npm run build` to ensure CSS is valid.

### Step 2: Replace Hardcoded Gradients in `css/components/ui.css`
- Locate line 88: `background: linear-gradient(to bottom, #001a38 0%, #002a70 50%, #003da5 100%);`
- Replace with: `background: var(--gradient-brand);`

**Verification**:
- Check sidebar branding header to ensure gradient appears correctly.
- Verify visual consistency with previous appearance.

### Step 3: Replace Hardcoded Gradients in `css/components/modals.css`
- Locate line 20: Same gradient as above
- Replace with: `background: var(--gradient-brand);`

**Verification**:
- Open any modal dialog (e.g., Link Modal, Label Menu).
- Verify the modal header gradient matches the previous appearance.

### Step 4: Test Theme Switching
- Temporarily change `--primary` in `variables.css` to a different color.
- Verify that gradients update automatically across all components.
- Revert the change.

**Verification**:
- Gradients should update dynamically when primary color changes.

---

## 🧪 Final Verification
- Run `npm run build`.
- Visual check: Sidebar header and modal backgrounds should have consistent gradients.
- No visual regressions from the previous state.
