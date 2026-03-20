# 1899 Dashboard Pagination and Bulk Delete

## Objective
- Limit the dashboard project list to 20 tours per page.
- Add explicit dashboard pagination controls so large local project libraries do not render as one unbounded table.
- Add bulk selection and a confirmation dialog for deleting multiple dashboard tours in one action.
- Make the dashboard select-all checkbox apply to the whole dashboard list, not only the visible page.
- Keep the bulk-delete dialog contained within the viewport with internal scrolling when many tours are selected.

## Implementation Notes
- Keep the dashboard route and existing per-project actions intact.
- Add pagination metadata to the dashboard project list flow so the UI can render page controls consistently.
- Keep bulk delete as an explicit confirmation flow; no destructive action should happen without user confirmation.
- Preserve existing history toggle and duplicate/open actions.

## Verification
- `npm run build`
