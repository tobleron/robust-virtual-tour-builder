- [x] Hypothesis (Ordered Expected Solutions)
  - [x] Viewer capture is occurring before the scene transition/render settles, causing black frames during cinematic transitions.
  - [x] Fast-shots rendering is using an invalid or empty viewer/canvas target after the recent viewer/load refactors, causing every captured frame to be black.
  - [x] A recent export/teaser runtime refactor changed viewport sizing or renderer initialization order, producing blank frames in both teaser styles.
  - [x] A regression in the headless/offscreen capture path is returning valid blobs from blank canvases rather than failing loudly.

- [x] Activity Log
  - [x] Created troubleshooting task.
  - [x] Inspect cinematic teaser flow and frame capture timing.
  - [x] Inspect fast-shots teaser flow and frame generation path.
  - [x] Compare current teaser renderer orchestration against likely refactor touchpoints.
  - [x] Reproduce with the narrowest local verification path.
  - [x] Patch root cause.
  - [x] Verify build and tests.
  - [x] Patch teaser canvas probe to distinguish an unpainted canvas from legitimate dark frames.
  - [x] Inspect generated teaser artifact frames directly to confirm the output is HUD-only black capture, not an encoder failure.
  - [x] Patch the vendored Pannellum WebGL context to preserve the drawing buffer for teaser capture readback.
  - [x] Redeploy the latest teaser fix to rubox and retest fast shots.

- [x] Code Change Ledger
  - [x] `src/systems/TeaserOfflineCfrRenderer.res`: strengthened teaser scene readiness to wait for a renderable source canvas across stable animation frames before deterministic capture proceeds; revert by restoring the simple `Viewer.isLoaded + wait(200)` path.
  - [x] `src/systems/TeaserPlayback.res`: mirrored the stronger renderable-canvas readiness gate in the non-headless teaser playback path; revert by restoring the simple viewer-ready wait.
  - [x] `tests/unit/TeaserPlayback_v.test.res`: extended the `TeaserRecorder` mock with `resolveSourceCanvas` so the new readiness path is testable; revert by removing the added mock export.
  - [x] `src/systems/TeaserRecorderSupport.res`: replaced the black-fill pixel probe with a magenta sentinel probe and `willReadFrequently` sampling so legitimate dark frames do not deadlock teaser readiness; revert by restoring the earlier black-fill/non-black check.
  - [x] `src/bindings/GraphicsBindings.res`: added typed-array helpers needed by the teaser pixel probe; revert by removing the added bindings if the probe is removed.
  - [x] `public/libs/pannellum.js`: enabled `preserveDrawingBuffer` on the vendored WebGL context so teaser recorder readback can capture panorama pixels instead of a black framebuffer; revert by restoring the original `experimental-webgl` context options.

- [x] Rollback Check
  - [x] Confirmed CLEAN for working changes; no non-working edits were left behind.

- [x] Context Handoff
  - [x] Both cinematic and fast shots converge on the same teaser capture pipeline. The regression was traced first to teaser capture trusting `Viewer.isLoaded` too early, then to source-canvas selection using broad selectors rather than the active viewer container. The latest follow-up patch changes the teaser pixel probe to use a magenta sentinel fill instead of a black fill, because the black-fill probe wrongly classified legitimate dark frames as “not painted” and caused teaser generation to stall.
  - [x] Direct inspection of `artifacts/222.webm` showed that encoding and HUD composition were fine, but the panorama layer was black in decoded frames while the logo and room tag rendered correctly. That narrowed the issue to WebGL canvas readback, and the current patch enables `preserveDrawingBuffer` in the vendored Pannellum build so the teaser recorder can copy real panorama pixels from the render canvas.
