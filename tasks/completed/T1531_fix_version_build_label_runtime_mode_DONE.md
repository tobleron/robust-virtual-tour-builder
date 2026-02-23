# T1531 - Fix sidebar build label to reflect runtime mode

## Objective
Ensure sidebar build label reflects actual runtime mode (production/development/testing) instead of stale branch-derived value.

## Scope
- Update `scripts/update-version.js` template for `src/utils/Version.res`.
- Regenerate `src/utils/Version.res`.
- Verify build passes.

## Acceptance Criteria
- Production runtime shows `[Stable Release]`.
- Development runtime shows `[Development Build]`.
- Existing semantic version/build number values remain unchanged.

## Verification
- `node scripts/update-version.js`
- `npm run build`
