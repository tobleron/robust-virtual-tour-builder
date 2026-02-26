# T1566 Troubleshoot Export Non-Auto-Tour Home Return Regression

- [ ] Hypothesis (Ordered Expected Solutions)
  - [x] Restrict completion countdown + home-return flow to active auto-tour sessions only.
  - [x] Keep auto-tour completion behavior unchanged (stop row + countdown + return home).
  - [x] Ensure normal/manual navigation on final scene no longer auto-returns.

- [ ] Activity Log
  - [x] Locate shared completion entrypoint and add auto-tour guard.
  - [x] Verify build and confirm runtime scripts compile.

- [ ] Code Change Ledger
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - added early return in `completeTourAndReturnHome()` when auto-tour is not active, preventing non-auto-tour final-scene home return.

- [ ] Rollback Check
  - [x] Confirmed CLEAN (build passes; no non-working edits remain).

- [ ] Context Handoff
  - [x] Non-auto-tour final-scene behavior no longer triggers countdown/home-return.
  - [x] Auto-tour completion behavior remains intact.
  - [x] Verified with `npm run build` and archived.
