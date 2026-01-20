# CSS Migration Task Summary

**Created:** 2026-01-20  
**Based on:** CSS Migration Analysis & Color Palette Review  
**Last Updated:** 2026-01-20 (Reorganized - Artistic decisions moved to end)

---

## 📋 Tasks Created (275-280, 283-284)

All tasks follow the project's task management workflow and include:
- Step-by-step implementation instructions
- Verification steps after each change
- Final build and visual checks
- Careful migration approach to avoid breaking existing UI

---

## Priority 1: Core CSS Variable Migration

### Task 275: Complete CSS Variable Migration
**Complexity:** 3/10 | **Estimated Time:** 1-2 hours

**Objective:** Eliminate all hardcoded hex values in CSS files and replace with design tokens.

**Files to Update:**
- `css/components/viewer.css` (~10 replacements)
- `css/components/floor-nav.css` (~5 replacements)
- `css/components/ui.css` (~2 replacements)
- `css/components/modals.css` (~1 replacement)

**Verification:** Build passes, all UI elements retain correct colors.

---

### Task 278: Create CSS Gradient Variables
**Complexity:** 3/10 | **Estimated Time:** 1 hour

**Objective:** Extract hardcoded gradients into reusable CSS variables.

**Changes:**
- Add `--gradient-brand` and related variables to `variables.css`
- Replace gradients in `ui.css` and `modals.css`

**Verification:** Sidebar header and modal backgrounds maintain consistent appearance.

---

## Priority 2: Component Refactoring

### Task 276: Refactor UploadReport.res Inline Styles
**Complexity:** 4/10 | **Estimated Time:** 2-3 hours

**Objective:** Move inline styles from ReScript to dedicated CSS file.

**Changes:**
- Create `css/components/upload-report.css`
- Define semantic classes for report elements
- Update `UploadReport.res` to use classes instead of inline styles

**Verification:** Upload report UI matches previous appearance exactly.

---

## Priority 3: Quality Assurance

### Task 279: Add Color Accessibility Audit
**Complexity:** 4/10 | **Estimated Time:** 2 hours

**Objective:** Verify all color combinations meet WCAG 2.1 AA standards.

**Changes:**
- Audit contrast ratios for all color combinations
- Fix any accessibility issues
- Document findings in `COLOR_PALETTE_REFERENCE.md`

**Verification:** All combinations meet 4.5:1 ratio for normal text.

---

### Task 280: Visual Regression Testing
**Complexity:** 5/10 | **Estimated Time:** 2-3 hours

**Objective:** Ensure CSS migration hasn't introduced visual regressions.

**Process:**
- Capture before/after screenshots of all UI states
- Compare using visual diff tools
- Validate or fix any differences
- Test all interactive states

**Verification:** No unexpected visual changes, all interactions work smoothly.

---

## Priority 4: Documentation

### Task 277: Design System Documentation & Compliance
**Complexity:** 2/10 | **Estimated Time:** 1 hour

**Objective:** Finalize design system docs and perform compliance audit.

**Changes:**
- Update `CSS_ARCHITECTURE_AND_BEST_PRACTICES.md`
- Finalize `COLOR_PALETTE_REFERENCE.md`
- Audit for remaining inline styles
- Cleanup legacy CSS

**Verification:** Documentation is complete and accurate.

---

## Priority 5: Artistic Decisions (Deferred to End)

### Task 283: Implement Remax-Centric Theme
**Complexity:** 5/10 | **Estimated Time:** 3-4 hours

**Objective:** Simplify color palette from 20+ colors to 12 core colors with unified theme.

**Changes:**
- Consolidate palette in `variables.css`
- Unify floor navigation colors
- Unify hotspot interaction colors
- Map outlier colors to core variables

**Verification:** UI feels like a unified application with strong brand identity.

**Note:** This task involves **artistic color decisions** and should be done after technical migration is complete.

---

### Task 284: Theme Switching Infrastructure (Optional)
**Complexity:** 6/10 | **Estimated Time:** 4-5 hours

**Objective:** Implement dynamic theme switching for future customization.

**Changes:**
- Create `ThemeConfig.res` module
- Add data-theme attribute support
- Create theme variants in CSS
- Add theme switcher UI
- Persist theme preference

**Verification:** Theme switching works smoothly across all UI elements.

**Note:** This is an **optional enhancement** and can be deferred.

---

## 📊 Task Execution Order

### Recommended Sequence:

1. **Task 275** - Complete CSS Variable Migration
   - *Foundation for all other tasks*
   - *Quick win, high impact*

2. **Task 278** - Create CSS Gradient Variables
   - *Complements Task 275*
   - *Small, focused change*

3. **Task 276** - Refactor UploadReport.res
   - *Completes separation of concerns*
   - *Independent of theme changes*

4. **Task 279** - Color Accessibility Audit
   - *Quality assurance*
   - *Ensures current colors meet standards*

5. **Task 280** - Visual Regression Testing
   - *Validation of technical migration*
   - *Ensures no regressions from variable adoption*

6. **Task 277** - Documentation & Compliance
   - *Documents technical changes*
   - *Prepares foundation for artistic decisions*

7. **Task 283** - Implement Remax-Centric Theme *(Artistic Decision)*
   - *Major visual unification*
   - *Requires user input on color choices*
   - *Done after technical foundation is solid*

8. **Task 284** - Theme Switching (Optional)
   - *Future enhancement*
   - *Can be done later*

---

## 🎯 Success Criteria

### After Technical Tasks (275-277):
✅ **100% CSS Variable Adoption** - No hardcoded colors in CSS  
✅ **Complete Separation of Concerns** - No inline styles in ReScript  
✅ **WCAG 2.1 AA Compliance** - All color combinations accessible  
✅ **Zero Visual Regressions** - UI maintains exact appearance  
✅ **Professional Documentation** - Complete design system reference  

### After Artistic Tasks (283-284):
✅ **Unified Color Palette** - 12 core colors with clear hierarchy  
✅ **Strong Brand Identity** - Cohesive visual theme  
✅ **Themeable Architecture** - Easy to customize for clients  

---

## ⏱️ Total Estimated Time

**Technical Tasks (275-277):** 6-9 hours  
**Artistic Tasks (283):** +3-4 hours  
**Optional Task (284):** +4-5 hours

**Recommended Approach:**
- **Sprint 1 (1-2 days):** Complete technical tasks (275-277)
- **Review Point:** User reviews and decides on color direction
- **Sprint 2 (1 day):** Implement artistic decisions (283)

---

## 🔄 Task Management Workflow

Remember to follow the project's task workflow:

1. **Move to active/** before starting work
2. **Read and implement** the task to completion
3. **Verify** after each step
4. **Rename with _REPORT** postfix when complete
5. **Move to completed/** after verification
6. **Wait** for approval before next task

---

*Generated by: Antigravity AI*  
*Date: 2026-01-20*  
*Reorganized: Artistic decisions moved to end per user request*
