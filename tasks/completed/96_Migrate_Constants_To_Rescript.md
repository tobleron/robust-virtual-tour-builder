# Task: Migrate Constants to ReScript
**Priority:** Medium (Type Safety/Professionalism)
**Status:** Pending

## Objective
Convert the legacy JavaScript configuration file (`src/constants.js`) into a fully typed ReScript module (`src/utils/Constants.res`).

## Context
`src/constants.js` is one of the last remaining "JavaScript Islands" in our ReScript codebase. It lacks type safety, dead code elimination, and proper integration with the ReScript build system.

## Requirements
1. **Create** `src/utils/Constants.res`.
2. **Port** all constants from `src/constants.js` to ReScript `let` bindings.
   - Example: `export const DEBUG_LOG_LEVEL = "info"` -> `let debugLogLevel = #info` (or string if preferred, but variants are better).
3. **Update** all references in the codebase:
   - Search for `Constants.` or imports from `../constants.js`.
   - Update them to use `Constants.res` values.
4. **Remove** `src/constants.js`.

## Verification
- `npm run res:build` must pass.
- Application behavior (debug flags, backend URLs) must remain unchanged.
