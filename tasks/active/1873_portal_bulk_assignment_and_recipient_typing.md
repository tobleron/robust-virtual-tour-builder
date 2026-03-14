# 1873 Portal Bulk Assignment and Recipient Typing

## Objective
Add a production-grade bulk assignment workflow to the portal admin so multiple recipients can receive multiple tours in one action, while preserving the existing single-recipient detail workflow. Add recipient typing with `Property owner`, `Broker`, and `Property owner & broker` as metadata/filtering only.

## Required Changes
- Add `recipient_type` to portal customers and expose it through create/update/list payloads.
- Add an explicit bulk-assignment admin workflow with additive many-to-many assignment.
- Keep current single-recipient detail/editing and single-recipient assign/remove behavior for normal mode.
- Add bulk summary inspector instead of a third heavy relationship form.
- Keep the portal responsive on desktop/tablet/mobile.

## Verification
- `npm run build`
- `cd backend && cargo check`
- Manual verification of portal admin selection, filtering, and bulk assignment behavior.

## Notes
- Recipient labels must use `Property owner`, not `Store owner`.
- Bulk assignment is additive only in v1.
- Recipient type does not affect access behavior in v1.
