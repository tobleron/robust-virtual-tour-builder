# 1933 — Remove Dead Cypress Dependency and Assets

**Priority:** 🟡 P2  
**Effort:** 15 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

The project uses **Playwright** as the canonical E2E test framework (`tests/e2e/`, `playwright.config.ts`). However, Cypress artifacts are still present:

- `cypress/` directory with test assets
- `cypress.config.js` configuration file
- `cypress@^15.11.0` in `devDependencies`
- `tests/cypress/` directory referenced in `.gitignore`

This is dead weight that adds ~300MB+ to `node_modules` and creates confusion about which E2E framework is canonical.

## Scope

### Steps

1. Verify no active test scripts reference Cypress:
   ```bash
   grep -r "cypress" package.json scripts/
   ```
2. Remove `cypress` from `devDependencies` in `package.json`
3. Delete `cypress.config.js`
4. Delete `cypress/` directory
5. Clean up Cypress references in `.gitignore` (line 57: `tests/cypress/videos/`)
6. Run `npm install` to update `package-lock.json`
7. Run `npm run build` and `npm run test:frontend`

## Acceptance Criteria

- [ ] `cypress` is not in `package.json`
- [ ] `cypress/` directory and `cypress.config.js` are deleted
- [ ] `npm run build` passes
- [ ] `npm run test:frontend` passes
