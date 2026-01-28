# CSS MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🚨 CRITICAL VIOLATIONS (9)
**Action:** Fix these patterns immediately using project standards.

### Pattern: `!important`
- [ ] `../../css/tailwind.css`
- [ ] `../../css/components/floor-nav.css`
- [ ] `../../css/components/popover.css`
- [ ] `../../css/components/modals.css`
- [ ] `../../css/components/ui.css`
- [ ] `../../css/components/viewer.css`
- [ ] `../../css/components/buttons.css`
- [ ] `../../css/components/label-menu.css`
- [ ] `../../css/legacy.css`

---

## 🛠️ SURGICAL REFACTOR TASKS (8)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../css/animations.css**
  - *Reason:* LOC 276 > Limit 222 (Role: ui-component, Drag: 1.77)
- [ ] **../../css/tailwind.css**
  - *Reason:* LOC 126 > Limit 30 (Role: ui-component, Drag: 16.47)
- [ ] **../../css/components/modals.css**
  - *Reason:* LOC 109 > Limit 30 (Role: ui-component, Drag: 61.39)
- [ ] **../../css/components/ui.css**
  - *Reason:* LOC 179 > Limit 30 (Role: ui-component, Drag: 121.43)
- [ ] **../../css/components/viewer.css**
  - *Reason:* LOC 627 > Limit 30 (Role: ui-component, Drag: 109.53)
- [ ] **../../css/components/buttons.css**
  - *Reason:* LOC 124 > Limit 30 (Role: ui-component, Drag: 19.41)
- [ ] **../../css/components/label-menu.css**
  - *Reason:* LOC 150 > Limit 30 (Role: ui-component, Drag: 10.42)
- [ ] **../../css/legacy.css**
  - *Reason:* LOC 58 > Limit 30 (Role: ui-component, Drag: 10.53)

---

