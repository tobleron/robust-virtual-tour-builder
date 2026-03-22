# 1926 — Clean Orphaned .bs.js Source Artifacts

**Priority:** 🔴 P0  
**Effort:** 15 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

Multiple compiled `.bs.js` files exist in the source tree without corresponding `.res` source files. These are "zombie artifacts" from deleted modules and can:
- Be accidentally imported by the bundler, introducing stale logic
- Create confusing errors during development
- Pollute IDE autocompletion

## Scope

### Files to Delete

| File | Location |
|---|---|
| `SchemaDefinitions.bs.js` | `src/core/` |
| `SchemaParsers.bs.js` | `src/core/` |
| `Schemas.bs.js` | `src/core/` |
| `ViewerClickEventShared.bs.js` | `src/utils/` |
| `Dummy.bs.js` | `src/` |

### Steps

1. Run `npx rescript clean` to remove all generated `.bs.js` files
2. Run `npx rescript` to rebuild only files with valid `.res` sources
3. Verify no import references the deleted modules:
   ```bash
   grep -r "SchemaDefinitions\|SchemaParsers\|Schemas\|ViewerClickEventShared\|Dummy" src/ --include="*.res" --include="*.js"
   ```
4. Manually delete any orphans that survived the clean/rebuild cycle
5. Run `npm run build` to verify no build breakage

## Acceptance Criteria

- [ ] No `.bs.js` files exist without a corresponding `.res` source
- [ ] `npm run build` passes
- [ ] No runtime imports reference deleted modules
