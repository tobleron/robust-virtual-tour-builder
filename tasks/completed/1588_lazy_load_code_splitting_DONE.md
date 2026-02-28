# Task: Route-Level Code Splitting with Lazy Component Loading

## Objective
Implement code splitting for non-critical system modules (Teaser, Simulation, Exporter, EXIF Report) to reduce initial bundle size and improve Time-to-Interactive (TTI).

## Problem Statement
The current build bundles **all** system modules into the main chunk. The `LazyLoad.res` module only handles external library scripts (Pannellum, JSZip, FileSaver). Internal system modules like `TeaserManager`, `Simulation`, `Exporter`, `ExifReportGenerator` (and their transitive dependencies: TourTemplates, TourScripts, video encoding) are loaded eagerly even though they're only used when the user explicitly triggers those flows. Bundle budget allows up to 4.5MB raw JS — code splitting can significantly reduce the critical path.

## Acceptance Criteria
- [ ] Implement `React.lazy` + `Suspense` boundaries for:
  - Teaser system (TeaserManager, TeaserLogic, TeaserRecorder, TeaserPlayback, TeaserOfflineCfrRenderer)
  - Simulation system (Simulation, SimulationLogic, SimulationMainLogic, SimulationPathGenerator)
  - Export system (Exporter, ExporterPackaging, ExporterUpload, TourTemplates and all sub-modules)
  - EXIF Report (ExifReportGenerator, ExifParser, ExifUtils)
- [x] Configure Vite/Rollup manual chunks for these boundaries with meaningful chunk names
- [ ] Add loading skeleton/placeholder UI during chunk load (not a blank screen)
- [x] Preload chunks on hover: when user hovers over "Export" or "Simulation" button, start chunk prefetch
- [x] Update `asset-manifest.json` generation and service worker caching to handle dynamic chunks
- [ ] Initial bundle (critical path) should be ≤ 2MB raw JS (currently measured against 4.5MB ceiling)

## Technical Notes
- **Files**: `vite.config.ts`, `src/App.res`, `src/components/Sidebar/SidebarLogicHandler.res`, `src/ServiceWorkerMain.res`
- **Pattern**: Vite `rollupOptions.output.manualChunks` + React dynamic imports
- **Risk**: Medium — ReScript's module bundling requires careful chunk boundary definition
- **Measurement**: Initial load bundle size before/after; Time-to-Interactive via Lighthouse
