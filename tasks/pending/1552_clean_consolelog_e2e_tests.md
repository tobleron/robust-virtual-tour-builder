# 1552 — Clean Console.log Usage in E2E Tests

## Priority: P3 — Code Quality

## Objective
Replace `console.log` calls in E2E tests with proper test logging patterns, or at minimum ensure consistency with project standards.

## Context
Several E2E test files use `console.log()` for step-by-step logging during test execution. While E2E tests are TypeScript (not ReScript) and not subject to the `Logger` module requirement, the usage should be consistent and meaningful.

Specifically flagged:
- `desktop-import.spec.ts` line 31: `console.log('Imported Tour Name:', importedName);`
- Multiple tests use `console.log('Step N: ...')` for progress tracking

## Acceptance Criteria
- [ ] Audit all E2E tests for `console.log` usage
- [ ] Replace informational logs with Playwright's built-in `test.info()` or `test.step()` where appropriate
- [ ] Keep diagnostic logs that are useful for CI debugging
- [ ] Remove trivial/redundant logs
- [ ] No functional changes to test logic

## Files to Audit
- All files in `tests/e2e/*.spec.ts`
