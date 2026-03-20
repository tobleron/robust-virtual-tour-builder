# T1915 Troubleshoot Builder Frontend Production Mode on Stable Start

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] The Rsbuild production build is injecting `import.meta.env` as development, so stable `npm run start` serves a dev-mode frontend bundle.
  - [ ] The duplicated `AddScenes` logs are a dev/strict-mode side effect rather than a true duplicate dispatch.
  - [ ] The repeated weak fingerprint fallback logs on `rubox` are from stale/old frontend code or dev-mode bundle behavior, not the latest polished path.

- [ ] **Activity Log**
  - [x] Confirmed the built `dist` bundle contains `MODE:"development", DEV:true` after `npm run build`.
  - [x] Patch the Rsbuild config/build path so `rsbuild build` injects production env values deterministically.
  - [x] Rebuild locally and verify the built bundle no longer contains development env values.
  - [x] Redeploy to `rubox` and re-check the console for service worker mode, fingerprint noise, and duplicate `AddScenes` logs.

- [ ] **Code Change Ledger**
  - [x] `rsbuild.config.mjs` / `rsbuild.portal.config.mjs` / `src/utils/Constants.res` — bypass the broken default `import.meta.env` injection for app mode and use explicit build-time globals for `MODE` / `DEV` / `PROD`.
  - [ ] `package.json` / launcher scripts if needed — only if the build command must explicitly pass the production mode to Rsbuild.

- [ ] **Rollback Check**
  - [ ] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [x] Current stable start on `rubox` still shows `Service Worker Unregistered (Dev Mode)`.
  - [x] The built frontend bundle currently hardcodes `import.meta.env` with development values even after `npm run build`.
  - [x] Fix the build-mode injection first, then reassess whether duplicate `AddScenes` remains a real bug.
