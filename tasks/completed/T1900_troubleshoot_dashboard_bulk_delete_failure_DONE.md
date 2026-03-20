# T1900 Troubleshoot Dashboard Bulk Delete Failure

## Hypothesis (Ordered Expected Solutions)
- [ ] The dashboard bulk delete is failing because it fans out multiple single-project delete requests and aborts on the first failing request without surfacing which project failed.
- [ ] The current bulk delete path lacks server-side batching, so transport/rate-limit/partial-failure conditions are being collapsed into one generic frontend error.
- [ ] The dashboard delete API needs a dedicated bulk route with per-project results so the UI can complete the batch and report exact failures.

## Activity Log
- [x] Inspect current dashboard bulk delete frontend flow and delete endpoint behavior.
- [x] Add a server-side bulk delete endpoint for dashboard projects.
- [x] Update the dashboard bulk delete dialog to call the batched endpoint and surface exact failure details.
- [x] Verify build and validate the dashboard bulk delete path.

## Code Change Ledger
- [x] `backend/src/api/project_assets.rs` - Added a batched dashboard bulk delete payload/response, shared delete helper, and per-project failure reporting.
- [x] `backend/src/api/project.rs` / `backend/src/api/config_routes_project.rs` - Exposed and routed the new `/api/project/dashboard/projects/bulk-delete` write endpoint.
- [x] `src/site/PageFrameworkBuilder.js` - Added a bulk dashboard delete client API helper.
- [x] `src/site/PageFrameworkDashboard.js` - Replaced the frontend delete loop with one bulk request and now surfaces exact failed project details in the dialog.

## Rollback Check
- [x] Confirm non-working changes are reverted or the final path is clean.

## Context Handoff
- [x] The original dashboard bulk delete path failed opaquely because it issued many single-project delete requests from the browser and collapsed any one failing request into one generic dialog error.
- [x] The exact failing item was not recoverable from the old UI because there was no per-project error reporting and no local backend log artifact available in this workspace.
- [x] Bulk delete now executes as one backend batch operation and reports exact failed project IDs/messages back to the dialog instead of only showing a generic failure.
