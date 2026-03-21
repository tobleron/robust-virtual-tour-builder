# 1919_update_settings_modal_layout

## Objective
Reduce wasted space in the builder settings modal and tighten the content-to-footer layout while preserving the current settings fields and behavior.

## Scope
- Refine settings modal structure in `src/components/Sidebar/SidebarSettings.res` if needed
- Refine settings modal shell styling in `css/components/modals-core.css`
- Refine settings panel layout styling in `css/components/modals-panels.css`
- Preserve current settings inputs and save behavior

## Verification
- `npm run build`

## Notes
- Match the teaser modal optimization approach where appropriate
- Prioritize removing forced dead height and improving spacing rhythm
