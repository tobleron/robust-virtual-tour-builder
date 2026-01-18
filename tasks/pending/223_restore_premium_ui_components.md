# Task 223: Restore v4.2.18 Premium Modal & UI Component Styling

## Objective
Restore the "Premium" look of modals and sidebar components using the gradient and animation logic from v4.2.18.

## Context
Current modals use a flatter design. v4.2.18 used deep navy-to-blue gradients and specific spring-like animations that felt more "high-end".

## Requirements
1.  **Modal Gradients:** Update `.modal-box-premium` in `css/components/modals.css` to use the `linear-gradient(to bottom, #001a38 0%, #002a70 50%, #003da5 100%)`.
2.  **Modal Animations:** Implement the `scale(0.95)` to `scale(1.0)` transition with `cubic-bezier(0.34, 1.56, 0.64, 1)`.
3.  **Button Premium States:** Port the `.modal-btn-premium` styles, including the `translateY(-2px)` hover effect and the specific inner shadows.
4.  **Sidebar Action Buttons:** Restore the grid-based square and wide button layouts (`sidebar-action-btn-square`, `sidebar-action-btn-wide`).

## Verification
*   Opening the "About" or "Link" modal should show the deep blue gradient.
*   The modal should "pop" in with a spring animation.
*   Sidebar buttons should have the "lift" effect on hover.
