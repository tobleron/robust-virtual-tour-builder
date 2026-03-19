# Troubleshoot `npm run dev` Errors and Warnings

## Hypothesis
- [ ] The recent tripod dead-zone setting and export parity changes left one or more source/type call sites out of sync with the current ReScript signatures, causing dev-time compile warnings or errors.
- [ ] The current dev output is surfacing stale generated artifacts or test fixtures that were not rebuilt after the latest state-shape changes.
- [ ] One or more runtime/dev-server entrypoints are still referencing old viewer/export plumbing, so `npm run dev` is starting with mismatched generated output.
- [ ] Some of the current warnings are non-fatal but noisy, and can be eliminated by aligning helper call sites and type constructors with the new `tripodDeadZoneEnabled` field.

## Activity Log
- [ ] Reproduce the current `npm run dev` output and capture the exact warnings/errors.
- [ ] Trace each warning/error back to the file and signature causing it.
- [ ] Patch the minimum source files required to restore a clean dev startup.
- [ ] Re-run the dev/build verification path until warnings/errors are gone or clearly isolated.

## Code Change Ledger
- [ ] `/Users/r2/Desktop/robust-virtual-tour-builder/tasks/active/T1889_troubleshoot_npm_run_dev_errors_and_warnings.md` - created to track the dev-startup warning/error cleanup. Revert note: delete the task file if this troubleshooting branch is abandoned.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The active issue is that `npm run dev` still reports errors and warnings after the tripod dead-zone work. The likely cause is signature drift from the new `tripodDeadZoneEnabled` plumbing or stale generated/test fixtures that still need to be aligned. Start by reproducing the exact output, then fix only the concrete files implicated by the compiler or dev-server logs.
