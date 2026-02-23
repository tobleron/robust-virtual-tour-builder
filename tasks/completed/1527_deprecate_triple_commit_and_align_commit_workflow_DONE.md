# 1527 - Deprecate triple-commit and align standard commit workflow

## Objective
Deprecate `scripts/triple-commit.sh` as the default path and make `scripts/commit.sh` the primary workflow, while preserving any useful safety/quality behaviors currently unique to triple-commit.

## Scope
- Compare `scripts/triple-commit.sh` and `scripts/commit.sh` behavior.
- Port useful safeguards/features from triple-commit into standard commit flow where appropriate.
- Deprecate `scripts/triple-commit.sh` so multi-branch sync only runs with explicit override/intention.
- Keep existing scripts non-interactive and deterministic.

## Functional Requirements
- [ ] `scripts/commit.sh` includes any justified guard/quality steps previously only in triple-commit.
- [ ] `scripts/triple-commit.sh` is clearly deprecated and does not run accidental triple-sync by default.
- [ ] Explicit path still exists for intentional triple-sync use.
- [ ] Script output clearly communicates deprecation and recommended command.

## Non-Functional Requirements
- [ ] Scripts remain shellcheck-safe style and readable.
- [ ] No destructive git operations introduced.
- [ ] Build verification passes after script changes.

## Files Expected
- `scripts/commit.sh`
- `scripts/triple-commit.sh`
- (Optional) related helper scripts only if needed

## Validation
- [ ] `npm run build` passes.
- [ ] Dry-run level invocation proves `triple-commit.sh` default path is blocked/deprecated.
- [ ] Standard `commit.sh` still works with expected validations.
