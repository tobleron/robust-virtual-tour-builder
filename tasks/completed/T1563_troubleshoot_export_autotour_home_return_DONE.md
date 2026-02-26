# T1563 Troubleshoot Export Auto-Tour Final Scene Return Home

- [ ] Hypothesis (Ordered Expected Solutions)
  - [x] Update exported auto-tour completion logic to detect the final scene, stop progression, show a 5-second glass-panel countdown, then navigate to the first scene.
  - [x] Ensure completion state resets correctly so manual navigation and any replay behavior do not get stuck on the final scene.
  - [x] Align countdown UI rendering with existing glass panel styles and avoid introducing duplicate timers when auto-tour state changes quickly.

- [ ] Activity Log
  - [x] Read architecture/task context docs and locate exported tour auto-tour runtime script path.
  - [x] Implement completion + countdown + home-return behavior in export template script.
  - [x] Validate build and smoke-check generated runtime logic.

- [ ] Code Change Ledger
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - added completion countdown timers, `completeAutoTour`, panel countdown rendering, and delayed home navigation (5s). Revert note: remove the countdown state/functions and restore prior `stopAutoTour`-only behavior.
  - [x] `src/systems/TourTemplates/TourScriptHotspots.res` - switched end-of-track and cycle/dead-end auto-tour stops from `stopAutoTour()` to `completeAutoTour()`. Revert note: replace `completeAutoTour` calls back to `stopAutoTour` if return-home countdown should be disabled.

- [ ] Rollback Check
  - [x] Confirmed CLEAN (all implemented changes compile and build successfully; no non-working edits left in place).

- [ ] Context Handoff
  - [x] Export auto-tour now stops at terminal/cycle detection and enters a dedicated completion state instead of remaining on the final scene indefinitely.
  - [x] The glass panel now shows a live 5-second countdown row (`returning home`) during completion before navigation resumes.
  - [x] After countdown expiry, runtime automatically navigates to the first scene (home), and normal shortcut rows are restored.
