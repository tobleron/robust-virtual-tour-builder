# T1903 Troubleshoot CI Pipeline Failure

## Hypothesis (Ordered Expected Solutions)
- [x] The latest promoted commit passed local `npm run build` but fails CI due to a branch-specific release guard or workflow step that is stricter than local verification.
- [x] CI is failing because a test or check outside the current local short-cycle verification path is unstable or broken on the latest `main` push.
- [ ] CI is failing because the workflow environment is picking up repo-state issues such as generated files, missing artifacts, or branch protection expectations.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, and `.agent/workflows/debug-standards.md`.
- [x] Inspect the latest failed GitHub Actions runs and failing job logs.
- [x] Reproduce the failing CI step locally with `npm test`.
- [x] Narrow the failure to stale frontend test expectations plus one leaked jsdom/React root from `VisualPipeline_v.test`.
- [x] Patch the affected tests, rebuild ReScript-generated test output, and verify the originally failing subset.
- [x] Verify `npm run test:frontend`.
- [x] Verify `npm test`.

## Code Change Ledger
- [x] `tests/unit/ViewerManager_v.test.res`: updated viewer and adapter mocks for tripod dead-zone calls; corrected stage interaction assertion to use `pointerdown`.
- [x] `tests/unit/ViewerManagerSceneLoad_v.test.res`: added `getHfov` and `setPitchBounds` support to test doubles.
- [x] `tests/unit/AuthenticatedClient_v.test.res`: aligned request-header and credentials expectations with current auth request behavior.
- [x] `tests/unit/Exporter_v.test.res`: fixed broken abort-controller setup and removed stale dev-token expectation in no-auth export flow.
- [x] `tests/unit/FloorNavigation_v.test.res`: updated inactive-state expectation to current `is-inactive` class.
- [x] `tests/unit/UtilityBar_v.test.res`: updated inactive-state expectation to current `is-inactive` class.
- [x] `tests/unit/PortalAccessLinks_v.test.res`: updated mocked gallery payload shape to current portal decoder contract.
- [x] `tests/unit/ServiceWorkerMain_v.test.res`: aligned cached asset expectation with current logo path.
- [x] `tests/unit/TeaserHardening_v.test.res`: updated hidden-state assertion to current `is-hidden` class.
- [x] `tests/unit/TourTemplateScripts_v.test.res`: aligned viewport export script expectation with current exported constants.
- [x] `tests/unit/HotspotSequence_v.test.res`: updated canonical traversal order expectation to current graph-driven sequencing behavior.
- [x] `tests/unit/VisualPipeline_v.test.res`: added explicit React root unmount/cleanup to prevent post-test `window is not defined` exceptions.

## Rollback Check
- [x] Confirmed CLEAN. No experimental source changes were kept; only targeted test fixes and cleanup remained.

## Context Handoff
- [x] GitHub Actions run `#32` failed in `Run Full Test Suite`, which maps to local `npm test`.
- [x] The root cause was stale frontend tests on `main`, plus a leaked React/jsdom render in `VisualPipeline_v.test` that produced unhandled errors even when assertions passed.
- [x] Local verification now passes for the original failing subset, `npm run test:frontend`, and `npm test`; one backend warning about an unused import in `backend/src/services/portal.rs` remains non-blocking.
