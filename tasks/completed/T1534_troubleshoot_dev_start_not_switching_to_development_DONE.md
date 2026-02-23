# T1534 - Troubleshoot dev start not switching to development build context

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] `npm run dev` path lacks branch/version sync step; add predev wrapper to switch to `development` and run `update-version.js`.
  - [ ] Existing `setup.sh` runs without branch guard; integrate wrapper while keeping setup behavior unchanged.
  - [ ] Cache may still display old label once; require hard refresh after sync.

- [ ] **Activity Log**
  - [ ] Inspect `package.json` scripts and startup flow.
  - [ ] Add new `scripts/predev.sh` wrapper.
  - [ ] Update `package.json` `predev` to call wrapper.
  - [ ] Verify build and basic script execution.

- [ ] **Code Change Ledger**
  - [ ] `scripts/predev.sh` - new wrapper: switch to development branch + version sync + setup handoff. (revert: remove file)
  - [ ] `package.json` - point `predev` at wrapper script. (revert: restore predev to setup.sh)

- [ ] **Rollback Check**
  - [ ] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [ ] User expects `npm run dev` to auto-enter development context. Planned fix inserts a predev gate that checks out `development` and regenerates `Version.res` before watchers start. Build verification ensures no regressions in production build pipeline.
