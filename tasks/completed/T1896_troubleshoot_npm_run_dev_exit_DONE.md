# T1896 Troubleshoot `npm run dev` Exiting

## Objective
Find why `npm run dev` exits in the current workspace, fix the responsible process or configuration, and leave the dev stack able to stay up.

## Hypothesis (Ordered Expected Solutions)
- [ ] A frontend or ReScript watcher is terminating immediately because of a compile/runtime error introduced by recent source changes.
- [ ] One of the concurrently launched dev child processes is exiting cleanly or failing fast, causing the top-level `npm run dev` runner to tear down the rest.
- [ ] A stale watcher, orphaned PID, or port/process conflict is causing the dev script supervisor to abort.
- [ ] A backend dev watcher or auxiliary watcher script is failing on startup due to a missing file, import, or config mismatch.

## Activity Log
- [x] Read required repo context and debugging workflow docs.
- [x] Reproduce `npm run dev` locally and capture the first terminating subprocess.
- [x] Inspect relevant package scripts / watcher commands.
- [x] Apply the minimal fix needed for the failing dev process.
- [x] Re-run `npm run dev` and confirm the stack stays running.

## Code Change Ledger
- [x] No product code change required. Root cause was an already-running `rescript watch` process (PID `43659`) causing `npm run res:watch` to exit immediately inside `concurrently`.

## Rollback Check
- [x] Confirmed CLEAN. No non-working code changes were introduced for this troubleshooting pass.

## Context Handoff
- [x] `npm run dev` was exiting because `rescript watch` was already running outside the dev stack, so the `RES` subprocess failed with "A ReScript build is already running". After stopping the stray watcher, `npm run dev` successfully brought up `RES`, `SW`, `BACK`, `FRONT`, and the governor. No repository code change was needed for this specific issue; the active task remains open only for user sign-off.
