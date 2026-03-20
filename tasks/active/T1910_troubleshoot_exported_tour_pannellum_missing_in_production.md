# T1910 Troubleshoot Exported Tour Pannellum Missing In Production

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] Export packaging rewrites HTML asset paths incorrectly for `web_only` and/or standalone outputs, so `pannellum.js` / `pannellum.css` are present in the ZIP but referenced from the wrong relative location.
  - [ ] The production package writes the Pannellum files only to some profile folders while the generated HTML expects them in all outputs.
  - [ ] Template HTML or runtime rewrite logic diverged between development preview and packaged export, causing the exported tour to reference development-relative `../../libs/...` paths that no longer exist.
  - [ ] Standalone blob packaging rewrites scene asset paths but leaves the viewer library bootstrap incomplete, so `window.pannellum` never exists at runtime.

- [ ] **Activity Log**
  - [x] Read export template generation and package output code for library paths.
  - [x] Inspect a freshly generated export ZIP or output tree to compare actual files vs referenced paths.
  - [x] Identify the exact runtime failure: exported HTML referenced an unsubstituted script placeholder, not a missing Pannellum file.
  - [x] Patch the packaging/runtime rewrite logic.
  - [x] Verify with `npm run build`.

- [ ] **Code Change Ledger**
  - [x] [src/systems/TourTemplates/TourScripts.res](src/systems/TourTemplates/TourScripts.res) — added missing placeholder substitution for `__EXPORT_ALLOW_TABLET_LANDSCAPE_STAGE__` with a default `false` value. Revert by removing the new optional argument and replacement call if needed.
  - [x] [/Users/r2/Desktop/Export_RMX_kamel_al_kilany_080326_1528_v5.3.6/web_only/tour_4k/index.html](/Users/r2/Desktop/Export_RMX_kamel_al_kilany_080326_1528_v5.3.6/web_only/tour_4k/index.html) — patched only for live diagnosis by replacing the unsubstituted placeholder with `false`.
  - [x] [/Users/r2/Desktop/Export_RMX_kamel_al_kilany_080326_1528_v5.3.6/desktop/index.html](/Users/r2/Desktop/Export_RMX_kamel_al_kilany_080326_1528_v5.3.6/desktop/index.html) — patched only for live diagnosis by replacing the unsubstituted placeholder with `false`.

- [ ] **Rollback Check**
  - [x] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [ ] Exported tours load incorrectly in packaged outputs: both `web_only` and standalone fail to initialize Pannellum even though development behavior is fine.
  - [ ] Investigation should focus on HTML path rewriting and ZIP output layout under `backend/src/services/project/package_output.rs` and `backend/src/services/project/package_utils.rs`, plus the generated HTML from `src/systems/TourTemplateHtmlSupportRender.res`.
  - [ ] If the context window fills, continue by opening a fresh export ZIP and comparing `libs/pannellum.*` locations against the `<script>` and `<link>` paths in each packaged `index.html`.
