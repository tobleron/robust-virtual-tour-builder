# T1812 Troubleshoot GPS Average + Reverse Geocode Regression

- Assignee: Codex
- Capacity Class: A
- Objective: Restore GPS coordinate averaging and reverse-geocoding execution after upload finalization.
- Boundary: `src/systems/Upload/*`, `src/systems/ExifReport/*`, related callsites only.
- Owned Interfaces: `UploadReporting.handleExifReport` invocation contract from upload finalization.
- No-Touch Zones: Navigation FSM, Visual pipeline rendering, backend geocoding service contracts.
- Independent Verification: Upload a GPS-bearing image set and confirm location section + averaged coordinates + resolved place name are present in generated report.
- Depends On: 1811

## Hypothesis (Ordered Expected Solutions)
- [ ] Upload finalizer is calling EXIF report generation with a bypass flag enabled, preventing GPS averaging/geocode.
- [ ] Upload pipeline no longer passes required metadata/EXIF payload into report generation.
- [ ] Reverse geocode backend call is not being invoked due to domain gate/rate limiter behavior.

## Activity Log
- [x] Located upload processing and item processor paths.
- [x] Located EXIF report location generation module.
- [x] Confirm bypass behavior at report callsite and validate effect.
- [x] Apply minimal fix and verify behavior.

## Code Change Ledger
- [x] `src/systems/Upload/UploadReporting.res`: Added backend-title-discovery timeout guard and deterministic unlock path for `discoveringTitleCount`; unified auto-title eligibility rule.
- [x] `src/components/Sidebar/SidebarProjectInfo.res`: Restored prop-driven `disabled` binding for project name/upload controls (instead of hardcoded disable).
- [x] `src/utils/Constants.res`: Added `Media.backgroundTitleDiscoveryTimeoutMs` constant.
- [x] `tests/unit/UploadReporting_v.test.res`: Added regression tests for timeout helper and auto-title eligibility.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The regression appears in post-upload reporting rather than backend geocoding itself. Upload finalization likely suppresses EXIF report generation via a bypass flag. Next step is to patch only the upload finalizer callsite and re-verify with GPS-bearing uploads.
