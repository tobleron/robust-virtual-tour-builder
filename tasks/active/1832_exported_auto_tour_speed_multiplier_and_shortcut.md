# 1832 Exported Auto Tour Speed Multiplier And Shortcut

## Objective
Increase exported-tour auto-tour speed to a new default of `1.2x` the current pace and add an in-tour `a` shortcut/action that toggles the active exported auto-tour between the default auto-tour pace and an extra `1.7x` boosted state.

## Scope
- Inspect the exported auto-tour runtime for current pan timing, auto-forward delay, and active shortcut-panel rendering.
- Add shared exported auto-tour speed state and helper functions.
- Apply the default `1.2x` multiplier when exported auto-tour starts.
- Render the active auto-tour glass-panel rows with `a` on top and `s` at the bottom.
- Make the active `a` row toggle its label/action between `speed up 1.7x` and `slow down 1x`.
- Update keyboard handling so pressing `a` during active exported auto-tour toggles that boosted state instead of restarting.
- Align the affected frontend unit tests with the finalized exported auto-tour runtime behavior.
- Verify the exported runtime build.

## Constraints
- Scope is limited to exported tours, not builder teaser timing or builder simulation timing.
- Preserve the existing export visual language and shortcut-panel theme.
- Keep stop behavior and completion/home-return behavior intact.
- Defer test rewrites and add touched source files to the shared deferred test-review task.

## Verification
- `npm run test:frontend`
- `npm run build`
