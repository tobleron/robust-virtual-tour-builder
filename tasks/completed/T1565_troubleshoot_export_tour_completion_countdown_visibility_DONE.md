# T1565 Troubleshoot Export Tour Completion Countdown + Glass Panel Visibility

- [ ] Hypothesis (Ordered Expected Solutions)
  - [x] Restore glass panel chrome while still hiding the top looking-mode section in portrait and auto-tour, so stop/countdown rows remain visible inside the panel.
  - [x] Generalize end-of-tour handling to trigger 5-second countdown + return home for both auto-tour and normal guided tour completion paths.
  - [x] Add fallback completion triggers for dead-end/no-hotspot/retry-exhausted paths to avoid final-scene stalls.

- [ ] Activity Log
  - [x] Audit current export UI CSS and runtime completion handlers.
  - [x] Patch style rules and script completion flow in TourTemplates runtime modules.
  - [x] Verify with full build.

- [ ] Code Change Ledger
  - [x] `src/systems/TourTemplates/TourStyles.res` - preserved glass panel chrome while hiding top mode section; removed shortcut separator spacing for portrait/auto-tour only.
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - added shared `completeTourAndReturnHome()` flow and wired `completeAutoTour()` to shared completion countdown behavior.
  - [x] `src/systems/TourTemplates/TourScriptHotspots.res` - invoked shared completion flow for no-hotspot/dead-end/cycle end states.
  - [x] `src/systems/TourTemplates/TourScriptNavigation.res` - invoked shared completion flow for auto-forward blocked/invalid-target/retry-exhausted end states.

- [ ] Rollback Check
  - [x] Confirmed CLEAN (all changes compile and build passes).

- [ ] Context Handoff
  - [x] Glass panel remains visible in portrait and auto-tour; only the top looking-mode section is hidden and separator spacing is removed.
  - [x] Countdown + home return now uses a shared completion path and is triggered for both auto-tour and normal guided end-of-tour conditions.
  - [x] Verified by running `npm run build` successfully.
