# 1934 — Resolve FeatureLoaders Triple-File Anomaly

**Priority:** 🟡 P2  
**Effort:** 20 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

`src/systems/FeatureLoaders` has three files:
- `FeatureLoaders.res` (ReScript source)
- `FeatureLoaders.bs.js` (ReScript compiled output)
- `FeatureLoaders.js` (manually written JavaScript)

The `.js` file appears to be a hand-written counterpart. Depending on bundler resolution settings, either the `.bs.js` or the `.js` file could be picked up. This creates unpredictable behavior.

## Scope

### Steps

1. Compare `FeatureLoaders.bs.js` and `FeatureLoaders.js` — determine if they serve different purposes
2. Check all import sites:
   ```bash
   grep -r "FeatureLoaders" src/ --include="*.res" --include="*.js" --include="*.jsx"
   ```
3. If `.js` is a legacy hand-written version superseded by `.res`:
   - Delete `FeatureLoaders.js`
   - Verify `.bs.js` is picked up correctly by the bundler
4. If `.js` serves a separate purpose (e.g., it's loaded by non-ReScript code):
   - Rename it to avoid naming collision (e.g., `FeatureLoadersRuntime.js`)
   - Update all references
5. Run `npm run build` and `npm run test:frontend`

## Acceptance Criteria

- [ ] Only one canonical implementation exists (either `.res` → `.bs.js` OR standalone `.js`)
- [ ] No naming collision between `.bs.js` and `.js` files
- [ ] `npm run build` passes
