# T1541 Troubleshooting: Dev Build Runtime Errors

## Hypothesis (Ordered Expected Solutions)
1. [ ] **Resource Exhaustion**: `concurrently` might be hitting memory or file descriptor limits on the user's machine.
2. [ ] **Port Conflicts**: One of the services (Frontend/Backend) might be failing to start because the port is already in use.
3. [ ] **Incompatible Node/Dependency State**: `node_modules` or `lib/bs` might be in a corrupt state.
4. [ ] **New Module Runtime Crash**: Recently added modules like `TeaserOfflineCfrRenderer.res` might have invalid bindings or top-level code that crashes during initialization in dev mode.

## Activity Log
- [x] Verified `rescript` build (Success).
- [x] Verified `sw:sync` (Success).
- [ ] Attempting to run `npm run dev:frontend` individually.
- [ ] Attempting to run `npm run dev:backend` individually.

## Code Change Ledger
(None yet)

## Rollback Check
- [ ] (Confirmed CLEAN or REVERTED non-working changes)

## Context Handoff
Investigating build runtime errors reported by the user during `npm run dev`. ReScript build passes, but the combined dev environment might be failing.
