# 1886 Remove Legacy Tiered Portrait HFOV Dead Code

## Objective
Remove the unused legacy tiered portrait HFOV branch from the exported tour runtime after the formula-based web package has proved stable on real devices.

## Scope
- [src/systems/TourTemplates/TourScriptViewport.res](src/systems/TourTemplates/TourScriptViewport.res)
- [src/systems/TourTemplates/TourScripts.res](src/systems/TourTemplates/TourScripts.res)
- [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res)

## Why This Exists
The current implementation keeps the old tiered portrait HFOV logic in the app as rollback-only dead code. That is intentional for now, but it should be deleted once the formula path has enough real-world validation.

## Acceptance Criteria
- [ ] The legacy tiered portrait HFOV helper is removed from the exported runtime.
- [ ] The formula-based portrait HFOV path remains the only active path.
- [ ] The repo still builds cleanly after removing the dead code.

## Verification
- `npm run build`

## Notes
- Do not reintroduce a formula toggle in the export dialog.
- Keep this task postponed until the formula has been proven stable on the target devices.
