# T1868 Troubleshoot Portal Admin Delete Actions Not Working

## Hypothesis (Ordered Expected Solutions)

- [ ] The frontend delete buttons are hitting the new routes, but the requests are failing due to a route/handler mismatch or an unhandled backend response shape.
- [ ] The delete requests are succeeding server-side but the admin UI is not refreshing state correctly afterward, making the records appear unchanged.
- [ ] The browser confirm or click wiring is firing on the wrong row/detail target, so the intended customer/tour ID is not reaching the delete request.

## Activity Log

- [ ] Reproduce recipient/tour delete actions against the live local portal admin.
- [ ] Inspect network/backend responses for delete requests.
- [ ] Patch the failing route/client/UI path.
- [ ] Re-run portal build and full build.

## Code Change Ledger

- [ ] Pending investigation.

## Rollback Check

- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff

Portal admin delete actions were wired end-to-end, but the user reports they do not work in the live UI. The next step is to reproduce the delete flow and identify whether the failure is route-level, response-decoding, or stale-state refresh. Once isolated, patch only the failing delete path and keep the broader dashboard layout changes intact.
