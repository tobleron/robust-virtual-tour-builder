# Refactor CSS Plan: style.css

Refactor the monolithic `style.css` into a modular architecture using CSS partials.

## Objectives
- [ ] Decompose `style.css` into logical component-based files.
- [ ] Ensure CSS variables are centralized.
- [ ] Maintain feature parity (no visual regressions).
- [ ] Adhere to functional standards where possible (component-based organization).

## Checklist
- [ ] Create `tasks/current_refactor.md` (Self-reference)
- [ ] Define modular structure in `css/` directory.
- [ ] Extract :root variables to `css/variables.css`.
- [ ] Extract base/reset styles to `css/base.css`.
- [ ] Extract animations to `css/animations.css`.
- [ ] Extract layout styles to `css/layout.css`.
- [ ] Extract component styles:
    - [ ] `css/components/viewer.css`
    - [ ] `css/components/modals.css`
    - [ ] `css/components/buttons.css`
    - [ ] `css/components/ui.css`
    - [ ] `css/components/floor-nav.css`
- [ ] Move legacy/restoration styles to `css/legacy.css`.
- [ ] Update `css/style.css` to import all partials.
- [ ] Verify build and visual parity.
