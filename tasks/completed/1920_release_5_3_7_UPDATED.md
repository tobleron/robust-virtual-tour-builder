# 1920_release_5_3_7

## Objective
Promote the approved teaser/settings modal space optimizations and release the application as version 5.3.7 to `main` and `development`, with local verification matching GitHub CI.

## Scope
- Bump release version to `5.3.7`
- Sync generated version/service-worker artifacts
- Include approved teaser/settings modal space optimizations
- Verify local checks that mirror CI before pushing

## Verification
- `npm test`
- `npm run build`
- `npm run budget:bundle`
- `npm run test:e2e:budgets`
- `npm run budget:runtime`

## Notes
- Keep unrelated local README/docs/cache artifacts out of the release commit
- Push the same verified release state to both `main` and `development`
