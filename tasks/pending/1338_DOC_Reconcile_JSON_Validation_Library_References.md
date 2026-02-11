# [1338] Reconcile JSON Validation Library Documentation

## Priority: P1 (High — developer confusion risk)

## Context
Three documents currently **contradict each other** about which JSON validation library to use:

| Document | States |
|----------|--------|
| `GEMINI.md` (user rules) | "Use `rescript-json-combinators` (module `JsonCombinators`)" |
| `docs/GENERAL_MECHANICS.md` | "Use `rescript-schema` for all JSON decoding" |
| `docs/PROJECT_SPECS.md` | "Uses `rescript-schema` to enforce strict runtime validation" |

`GEMINI.md` explicitly forbids `rescript-schema` for CSP (Content Security Policy) compliance reasons, as `rescript-schema` uses `eval()` internally.

## Objective
Reconcile all documentation to reflect the single source of truth: **`rescript-json-combinators`** as stated in `GEMINI.md`.

## Implementation

1. **[MODIFY] `docs/GENERAL_MECHANICS.md`**
   - Find all references to `rescript-schema`
   - Replace with `rescript-json-combinators` / `JsonCombinators`
   - Add note about CSP compliance as the reason

2. **[MODIFY] `docs/PROJECT_SPECS.md`**
   - Find all references to `rescript-schema`
   - Replace with `rescript-json-combinators` / `JsonCombinators`

3. **[VERIFY] `docs/architecture/JSON_ENCODING_STANDARDS.md`**
   - Confirm it already references the correct library
   - Fix any inconsistencies

4. **[VERIFY] `package.json`**
   - Confirm `rescript-json-combinators` is in dependencies
   - If `rescript-schema` is still listed, note whether any code still uses it

5. **[AUDIT] Source Code**
   ```bash
   grep -r "rescript-schema\|RescriptSchema\|S\.string\|S\.object" src/ --include="*.res"
   ```
   - If any source files still import `rescript-schema`, flag them for migration (separate task)

## Verification
- [ ] `grep -ri "rescript-schema" docs/` returns 0 results (excluding historical/archive docs)
- [ ] All docs consistently reference `rescript-json-combinators`

## Estimated Effort: 1 hour
