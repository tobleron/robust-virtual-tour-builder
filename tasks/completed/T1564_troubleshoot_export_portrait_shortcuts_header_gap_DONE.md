# T1564 Troubleshoot Export Portrait Shortcuts Header Gap

- [ ] Hypothesis (Ordered Expected Solutions)
  - [x] In portrait mode, force-hide the shortcuts top section and its separator so only shortcut rows remain with no reserved top spacing.
  - [x] During auto-tour mode (all viewports), apply the same top-section suppression and spacing collapse.
  - [x] Ensure CSS/class logic does not regress desktop/tablet behavior outside portrait/auto-tour contexts.

- [ ] Activity Log
  - [x] Locate looking-mode/shortcuts panel layout and separator rules in tour export templates.
  - [x] Patch runtime classes and/or CSS selectors for portrait + auto-tour suppression.
  - [x] Verify build and confirm generated export assets compile cleanly.

- [ ] Code Change Ledger
  - [x] `src/systems/TourTemplates/TourStyles.res` - hid `.mode-status-line` in portrait and auto-tour; collapsed `.looking-mode-indicator` chrome (padding/background/border/shadow/blur) and removed `#viewer-floor-tags-export` top separator spacing for portrait + auto-tour. Revert note: remove new portrait/auto-tour selectors to restore prior header chrome + separator behavior.

- [ ] Rollback Check
  - [x] Confirmed CLEAN (build passes and no non-working edits were left in place).

- [ ] Context Handoff
  - [x] Portrait mode now fully hides the upper looking-mode section and removes related reserved spacing/chrome, leaving shortcuts only.
  - [x] Auto-tour mode now applies the same compact shortcuts-only panel treatment.
  - [x] Verified with `npm run build`; export template/style generation compiles successfully.
