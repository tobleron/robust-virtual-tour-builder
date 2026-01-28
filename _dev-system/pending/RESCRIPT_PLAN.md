# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🚨 CRITICAL VIOLATIONS (12)
**Action:** Fix these patterns immediately using project standards.

### Pattern: `console.log`
- [ ] `../../tests/unit/LoggerLogic_v.test.res`

### Pattern: `mutable `
- [ ] `../../src/core/ViewerState.res`
- [ ] `../../src/core/ViewerTypes.res`
- [ ] `../../src/core/SharedTypes.res`
- [ ] `../../src/core/SceneCache.res`
- [ ] `../../src/components/VisualPipeline/VisualPipelineTypes.res`
- [ ] `../../src/systems/SvgManager.res`
- [ ] `../../src/systems/UploadProcessorTypes.res`
- [ ] `../../src/systems/ViewerPool.res`
- [ ] `../../src/systems/PannellumAdapter.res`
- [ ] `../../src/systems/SimulationPathGenerator.res`
- [ ] `../../src/systems/PannellumLifecycle.res`

---

## 🛠️ SURGICAL REFACTOR TASKS (92)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../tests/unit/ProjectApi_v.test.res**
  - *Reason:* [Exception: Scaffolding for testing] LOC 166 > Limit 30 (Role: infra-adapter, Drag: 32.27)
    🔥 Hotspot: Lines 57-61 (AI Context Fog (score 36.0))
- [ ] **../../tests/unit/HotspotLineLogic_v.test.res**
  - *Reason:* [Exception: Scaffolding for testing] LOC 220 > Limit 30 (Role: service-orchestrator, Drag: 32.12)
    🔥 Hotspot: Lines 109-113 (AI Context Fog (score 24.0))
- [ ] **../../tests/unit/Bindings_Unified_v.test.res**
  - *Reason:* [Exception: Scaffolding for testing] LOC 188 > Limit 70 (Role: infra-adapter, Drag: 14.56)
    🔥 Hotspot: Lines 160-164 (AI Context Fog (score 10.0))
- [ ] **../../src/core/ViewerState.res**
  - *Reason:* LOC 91 > Limit 30 (Role: domain-logic, Drag: 37.56)
    🔥 Hotspot: Lines 18-22 (AI Context Fog (score 26.6))
- [ ] **../../src/core/Actions.res**
  - *Reason:* LOC 105 > Limit 57 (Role: orchestrator, Drag: 3.00)
    🔥 Hotspot: Lines 55-59 (AI Context Fog (score 3.0))
- [ ] **../../src/core/UiHelpers.res**
  - *Reason:* LOC 40 > Limit 30 (Role: domain-logic, Drag: 12.25)
    🔥 Hotspot: Lines 25-29 (AI Context Fog (score 17.8))
- [ ] **../../src/core/SharedTypes.res**
  - *Reason:* [Exception: Deeply nested but necessary data models] LOC 132 > Limit 33 (Role: data-model, Drag: 19.30)
    🔥 Hotspot: Lines 6-10 (AI Context Fog (score 26.0))
- [ ] **../../src/core/AppContext.res**
  - *Reason:* LOC 135 > Limit 103 (Role: domain-logic, Drag: 1.99)
    🔥 Hotspot: Lines 85-89 (AI Context Fog (score 36.0))
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Exception: Central schema collection (Authorized debt)] LOC 132 > Limit 69 (Role: domain-logic, Drag: 4.84)
    🔥 Hotspot: Lines 103-107 (AI Context Fog (score 27.2))
- [ ] **../../src/core/SchemasShared.res**
  - *Reason:* LOC 99 > Limit 30 (Role: domain-logic, Drag: 6.58)
    🔥 Hotspot: Lines 24-28 (AI Context Fog (score 8.0))
- [ ] **../../src/core/SchemasDomain.res**
  - *Reason:* LOC 154 > Limit 30 (Role: domain-logic, Drag: 7.10)
    🔥 Hotspot: Lines 160-164 (AI Context Fog (score 13.0))
- [ ] **../../src/core/SceneHelpersLogic.res**
  - *Reason:* LOC 198 > Limit 77 (Role: service-orchestrator, Drag: 2.40)
    🔥 Hotspot: Lines 122-126 (AI Context Fog (score 41.2))
- [ ] **../../src/core/reducers/SceneReducer.res**
  - *Reason:* LOC 91 > Limit 80 (Role: domain-logic, Drag: 2.35)
    🔥 Hotspot: Lines 22-26 (AI Context Fog (score 21.4))
- [ ] **../../src/core/reducers/HotspotReducer.res**
  - *Reason:* LOC 94 > Limit 57 (Role: domain-logic, Drag: 2.90)
    🔥 Hotspot: Lines 75-79 (AI Context Fog (score 69.4))
- [ ] **../../src/ServiceWorkerMain.res**
  - *Reason:* LOC 164 > Limit 91 (Role: orchestrator, Drag: 2.20)
    🔥 Hotspot: Lines 169-173 (AI Context Fog (score 61.0))
- [ ] **../../src/utils/GeoUtils.res**
  - *Reason:* LOC 83 > Limit 54 (Role: util-pure, Drag: 1.97)
    🔥 Hotspot: Lines 67-71 (AI Context Fog (score 29.4))
- [ ] **../../src/utils/PersistenceLayer.res**
  - *Reason:* LOC 66 > Limit 30 (Role: util-pure, Drag: 4.46)
    🔥 Hotspot: Lines 38-42 (AI Context Fog (score 11.4))
- [ ] **../../src/utils/ProgressBar.res**
  - *Reason:* LOC 106 > Limit 36 (Role: util-pure, Drag: 2.41)
    🔥 Hotspot: Lines 111-115 (AI Context Fog (score 37.0))
- [ ] **../../src/utils/ColorPalette.res**
  - *Reason:* LOC 46 > Limit 40 (Role: util-pure, Drag: 2.40)
    🔥 Hotspot: Lines 22-26 (AI Context Fog (score 25.2))
- [ ] **../../src/utils/StateInspector.res**
  - *Reason:* LOC 88 > Limit 76 (Role: state-reducer, Drag: 2.01)
    🔥 Hotspot: Lines 67-71 (AI Context Fog (score 25.4))
- [ ] **../../src/utils/TourLogic.res**
  - *Reason:* LOC 129 > Limit 111 (Role: service-orchestrator, Drag: 1.93)
    🔥 Hotspot: Lines 75-79 (AI Context Fog (score 32.6))
- [ ] **../../src/utils/LoggerTelemetry.res**
  - *Reason:* LOC 94 > Limit 45 (Role: util-pure, Drag: 2.11)
    🔥 Hotspot: Lines 51-55 (AI Context Fog (score 31.6))
- [ ] **../../src/utils/Logger.res**
  - *Reason:* LOC 106 > Limit 71 (Role: util-pure, Drag: 1.60)
    🔥 Hotspot: Lines 69-73 (AI Context Fog (score 11.0))
- [ ] **../../src/utils/ImageOptimizer.res**
  - *Reason:* LOC 92 > Limit 43 (Role: util-pure, Drag: 2.12)
    🔥 Hotspot: Lines 59-63 (AI Context Fog (score 49.0))
- [ ] **../../src/utils/LazyLoad.res**
  - *Reason:* LOC 87 > Limit 35 (Role: util-pure, Drag: 2.41)
    🔥 Hotspot: Lines 30-34 (AI Context Fog (score 58.0))
- [ ] **../../src/utils/LoggerLogic.res**
  - *Reason:* LOC 197 > Limit 129 (Role: service-orchestrator, Drag: 1.75)
    🔥 Hotspot: Lines 68-72 (AI Context Fog (score 17.8))
- [ ] **../../src/utils/PathInterpolation.res**
  - *Reason:* LOC 236 > Limit 37 (Role: util-pure, Drag: 2.46)
    🔥 Hotspot: Lines 109-113 (AI Context Fog (score 64.0))
- [ ] **../../src/utils/ProjectionMath.res**
  - *Reason:* LOC 88 > Limit 65 (Role: util-pure, Drag: 1.71)
    🔥 Hotspot: Lines 104-108 (AI Context Fog (score 14.6))
- [ ] **../../src/utils/RequestQueue.res**
  - *Reason:* LOC 57 > Limit 45 (Role: util-pure, Drag: 2.10)
    🔥 Hotspot: Lines 43-47 (AI Context Fog (score 27.0))
- [ ] **../../src/utils/SessionStore.res**
  - *Reason:* LOC 84 > Limit 36 (Role: util-pure, Drag: 2.54)
    🔥 Hotspot: Lines 53-57 (AI Context Fog (score 29.0))
- [ ] **../../src/components/SceneList/SceneItem.res**
  - *Reason:* LOC 200 > Limit 192 (Role: ui-component, Drag: 1.92)
    🔥 Hotspot: Lines 83-87 (AI Context Fog (score 14.6))
- [ ] **../../src/components/SceneList/SceneListMain.res**
  - *Reason:* LOC 211 > Limit 122 (Role: ui-component, Drag: 2.53)
    🔥 Hotspot: Lines 213-217 (AI Context Fog (score 51.0))
- [ ] **../../src/components/Sidebar/SidebarMain.res**
  - *Reason:* LOC 221 > Limit 133 (Role: ui-component, Drag: 2.44)
    🔥 Hotspot: Lines 72-76 (AI Context Fog (score 49.0))
- [ ] **../../src/components/Sidebar/SidebarMainLogic.res**
  - *Reason:* LOC 152 > Limit 62 (Role: service-orchestrator, Drag: 2.69)
    🔥 Hotspot: Lines 83-87 (AI Context Fog (score 43.8))
- [ ] **../../src/components/LabelMenu.res**
  - *Reason:* LOC 169 > Limit 153 (Role: ui-component, Drag: 2.22)
    🔥 Hotspot: Lines 134-138 (AI Context Fog (score 43.8))
- [ ] **../../src/components/HotspotManager.res**
  - *Reason:* LOC 115 > Limit 98 (Role: service-orchestrator, Drag: 1.97)
    🔥 Hotspot: Lines 109-113 (AI Context Fog (score 16.0))
- [ ] **../../src/components/UploadReport.res**
  - *Reason:* LOC 189 > Limit 159 (Role: ui-component, Drag: 2.15)
    🔥 Hotspot: Lines 91-95 (AI Context Fog (score 36.6))
- [ ] **../../src/components/HotspotActionMenu.res**
  - *Reason:* LOC 147 > Limit 146 (Role: ui-component, Drag: 2.31)
    🔥 Hotspot: Lines 84-88 (AI Context Fog (score 38.0))
- [ ] **../../src/components/VisualPipeline/VisualPipelineRender.res**
  - *Reason:* LOC 160 > Limit 82 (Role: ui-component, Drag: 2.93)
    🔥 Hotspot: Lines 47-51 (AI Context Fog (score 66.0))
- [ ] **../../src/components/VisualPipeline/VisualPipelineLogic.res**
  - *Reason:* LOC 96 > Limit 65 (Role: service-orchestrator, Drag: 2.48)
    🔥 Hotspot: Lines 77-81 (AI Context Fog (score 17.8))
- [ ] **../../src/components/PopOver.res**
  - *Reason:* LOC 147 > Limit 132 (Role: ui-component, Drag: 2.40)
    🔥 Hotspot: Lines 50-54 (AI Context Fog (score 29.4))
- [ ] **../../src/components/PreviewArrow.res**
  - *Reason:* LOC 188 > Limit 119 (Role: ui-component, Drag: 2.65)
    🔥 Hotspot: Lines 90-94 (AI Context Fog (score 66.0))
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* LOC 307 > Limit 58 (Role: service-orchestrator, Drag: 2.67)
    🔥 Hotspot: Lines 183-187 (AI Context Fog (score 61.0))
- [ ] **../../src/components/LinkModal.res**
  - *Reason:* LOC 175 > Limit 128 (Role: ui-component, Drag: 2.55)
    🔥 Hotspot: Lines 135-139 (AI Context Fog (score 100.0))
- [ ] **../../src/components/ModalContext.res**
  - *Reason:* LOC 166 > Limit 93 (Role: ui-component, Drag: 3.04)
    🔥 Hotspot: Lines 77-81 (AI Context Fog (score 81.0))
- [ ] **../../src/ServiceWorker.res**
  - *Reason:* LOC 87 > Limit 79 (Role: orchestrator, Drag: 2.34)
    🔥 Hotspot: Lines 79-83 (AI Context Fog (score 36.0))
- [ ] **../../src/systems/TeaserRecorderLogic.res**
  - *Reason:* LOC 251 > Limit 106 (Role: service-orchestrator, Drag: 1.96)
    🔥 Hotspot: Lines 214-218 (AI Context Fog (score 34.8))
- [ ] **../../src/systems/VideoEncoder.res**
  - *Reason:* LOC 100 > Limit 60 (Role: service-orchestrator, Drag: 2.67)
    🔥 Hotspot: Lines 57-61 (AI Context Fog (score 67.4))
- [ ] **../../src/systems/ExifReportGeneratorLogicExtraction.res**
  - *Reason:* LOC 108 > Limit 56 (Role: service-orchestrator, Drag: 3.02)
    🔥 Hotspot: Lines 56-60 (AI Context Fog (score 100.0))
- [ ] **../../src/systems/ViewerFollow.res**
  - *Reason:* LOC 131 > Limit 69 (Role: service-orchestrator, Drag: 2.57)
    🔥 Hotspot: Lines 57-61 (AI Context Fog (score 38.6))
- [ ] **../../src/systems/SvgManager.res**
  - *Reason:* LOC 137 > Limit 30 (Role: service-orchestrator, Drag: 5.11)
    🔥 Hotspot: Lines 85-89 (AI Context Fog (score 18.0))
- [ ] **../../src/systems/NavigationFSM.res**
  - *Reason:* LOC 79 > Limit 73 (Role: service-orchestrator, Drag: 2.54)
    🔥 Hotspot: Lines 52-56 (AI Context Fog (score 13.2))
- [ ] **../../src/systems/LinkEditorLogic.res**
  - *Reason:* LOC 123 > Limit 81 (Role: service-orchestrator, Drag: 2.27)
    🔥 Hotspot: Lines 123-127 (AI Context Fog (score 38.0))
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* LOC 132 > Limit 70 (Role: service-orchestrator, Drag: 2.57)
    🔥 Hotspot: Lines 55-59 (AI Context Fog (score 53.0))
- [ ] **../../src/systems/TourTemplates.res**
  - *Reason:* LOC 138 > Limit 128 (Role: service-orchestrator, Drag: 1.75)
    🔥 Hotspot: Lines 127-131 (AI Context Fog (score 25.0))
- [ ] **../../src/systems/TourTemplateScripts.res**
  - *Reason:* LOC 139 > Limit 128 (Role: service-orchestrator, Drag: 1.76)
    🔥 Hotspot: Lines 113-117 (AI Context Fog (score 17.8))
- [ ] **../../src/systems/ServerTeaser.res**
  - *Reason:* LOC 89 > Limit 82 (Role: service-orchestrator, Drag: 2.15)
    🔥 Hotspot: Lines 76-80 (AI Context Fog (score 26.2))
- [ ] **../../src/systems/TeaserRecorderTypes.res**
  - *Reason:* [Exception: Deeply nested but necessary data models] LOC 76 > Limit 30 (Role: service-orchestrator, Drag: 16.15)
    🔥 Hotspot: Lines 62-66 (AI Context Fog (score 26.0))
- [ ] **../../src/systems/SceneTransitionManager.res**
  - *Reason:* LOC 111 > Limit 74 (Role: service-orchestrator, Drag: 2.31)
    🔥 Hotspot: Lines 44-48 (AI Context Fog (score 25.2))
- [ ] **../../src/systems/ViewerPool.res**
  - *Reason:* LOC 94 > Limit 30 (Role: service-orchestrator, Drag: 6.67)
    🔥 Hotspot: Lines 90-94 (AI Context Fog (score 16.6))
- [ ] **../../src/systems/HotspotLineLogicArrow.res**
  - *Reason:* LOC 189 > Limit 76 (Role: service-orchestrator, Drag: 2.45)
    🔥 Hotspot: Lines 105-109 (AI Context Fog (score 52.0))
- [ ] **../../src/systems/SceneLoaderLogic.res**
  - *Reason:* LOC 170 > Limit 55 (Role: service-orchestrator, Drag: 2.88)
    🔥 Hotspot: Lines 109-113 (AI Context Fog (score 83.0))
- [ ] **../../src/systems/ExifReportGeneratorLogicLocation.res**
  - *Reason:* LOC 117 > Limit 96 (Role: service-orchestrator, Drag: 2.09)
    🔥 Hotspot: Lines 99-103 (AI Context Fog (score 36.0))
- [ ] **../../src/systems/AudioManager.res**
  - *Reason:* LOC 122 > Limit 54 (Role: service-orchestrator, Drag: 3.10)
    🔥 Hotspot: Lines 100-104 (AI Context Fog (score 15.2))
- [ ] **../../src/systems/PanoramaClusterer.res**
  - *Reason:* LOC 146 > Limit 60 (Role: service-orchestrator, Drag: 2.78)
    🔥 Hotspot: Lines 44-48 (AI Context Fog (score 64.0))
- [ ] **../../src/systems/PannellumAdapter.res**
  - *Reason:* LOC 68 > Limit 30 (Role: service-orchestrator, Drag: 14.83)
    🔥 Hotspot: Lines 6-10 (AI Context Fog (score 10.8))
- [ ] **../../src/systems/SvgRenderer.res**
  - *Reason:* LOC 114 > Limit 68 (Role: service-orchestrator, Drag: 2.32)
    🔥 Hotspot: Lines 48-52 (AI Context Fog (score 27.2))
- [ ] **../../src/systems/SimulationPathGenerator.res**
  - *Reason:* LOC 202 > Limit 30 (Role: service-orchestrator, Drag: 9.13)
    🔥 Hotspot: Lines 193-197 (AI Context Fog (score 118.8))
- [ ] **../../src/systems/UploadProcessorLogicLogic.res**
  - *Reason:* LOC 307 > Limit 87 (Role: service-orchestrator, Drag: 2.25)
    🔥 Hotspot: Lines 332-336 (AI Context Fog (score 64.0))
- [ ] **../../src/systems/ProjectData.res**
  - *Reason:* LOC 94 > Limit 89 (Role: service-orchestrator, Drag: 2.22)
    🔥 Hotspot: Lines 16-20 (AI Context Fog (score 21.0))
- [ ] **../../src/systems/ExifReportGeneratorUtils.res**
  - *Reason:* LOC 102 > Limit 101 (Role: service-orchestrator, Drag: 2.05)
    🔥 Hotspot: Lines 54-58 (AI Context Fog (score 49.4))
- [ ] **../../src/systems/SimulationNavigation.res**
  - *Reason:* LOC 218 > Limit 91 (Role: service-orchestrator, Drag: 2.20)
    🔥 Hotspot: Lines 97-101 (AI Context Fog (score 58.0))
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* LOC 112 > Limit 63 (Role: service-orchestrator, Drag: 2.62)
    🔥 Hotspot: Lines 104-108 (AI Context Fog (score 100.0))
- [ ] **../../src/systems/ExifParser.res**
  - *Reason:* LOC 266 > Limit 100 (Role: service-orchestrator, Drag: 2.06)
    🔥 Hotspot: Lines 49-53 (AI Context Fog (score 48.4))
- [ ] **../../src/systems/TeaserManager.res**
  - *Reason:* LOC 237 > Limit 51 (Role: service-orchestrator, Drag: 3.00)
    🔥 Hotspot: Lines 223-227 (AI Context Fog (score 146.0))
- [ ] **../../src/systems/api/ProjectApi.res**
  - *Reason:* LOC 280 > Limit 53 (Role: service-orchestrator, Drag: 2.89)
    🔥 Hotspot: Lines 257-261 (AI Context Fog (score 52.0))
- [ ] **../../src/systems/api/MediaApi.res**
  - *Reason:* LOC 174 > Limit 64 (Role: service-orchestrator, Drag: 2.53)
    🔥 Hotspot: Lines 27-31 (AI Context Fog (score 35.8))
- [ ] **../../src/systems/TourTemplateStyles.res**
  - *Reason:* LOC 186 > Limit 140 (Role: service-orchestrator, Drag: 1.65)
    🔥 Hotspot: Lines 188-192 (AI Context Fog (score 14.6))
- [ ] **../../src/systems/NavigationController.res**
  - *Reason:* LOC 193 > Limit 39 (Role: service-orchestrator, Drag: 3.67)
    🔥 Hotspot: Lines 162-166 (AI Context Fog (score 201.8))
- [ ] **../../src/systems/NavigationGraph.res**
  - *Reason:* LOC 211 > Limit 75 (Role: service-orchestrator, Drag: 2.45)
    🔥 Hotspot: Lines 188-192 (AI Context Fog (score 49.0))
- [ ] **../../src/systems/ProjectManagerLogic.res**
  - *Reason:* LOC 226 > Limit 30 (Role: service-orchestrator, Drag: 5.07)
    🔥 Hotspot: Lines 175-179 (AI Context Fog (score 43.8))
- [ ] **../../src/systems/HotspotLineLogicLogic.res**
  - *Reason:* LOC 287 > Limit 90 (Role: service-orchestrator, Drag: 2.15)
    🔥 Hotspot: Lines 130-134 (AI Context Fog (score 36.0))
- [ ] **../../src/systems/ResizerLogic.res**
  - *Reason:* LOC 258 > Limit 59 (Role: service-orchestrator, Drag: 2.78)
    🔥 Hotspot: Lines 146-150 (AI Context Fog (score 63.0))
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* LOC 102 > Limit 69 (Role: service-orchestrator, Drag: 2.55)
    🔥 Hotspot: Lines 97-101 (AI Context Fog (score 66.0))
- [ ] **../../src/systems/SimulationDriver.res**
  - *Reason:* LOC 148 > Limit 58 (Role: service-orchestrator, Drag: 2.81)
    🔥 Hotspot: Lines 132-136 (AI Context Fog (score 116.8))
- [ ] **../../src/systems/TeaserPlayback.res**
  - *Reason:* LOC 213 > Limit 80 (Role: service-orchestrator, Drag: 2.29)
    🔥 Hotspot: Lines 31-35 (AI Context Fog (score 27.2))
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* LOC 98 > Limit 71 (Role: service-orchestrator, Drag: 2.40)
    🔥 Hotspot: Lines 60-64 (AI Context Fog (score 39.0))
- [ ] **../../src/systems/ExifReportGeneratorLogicGroups.res**
  - *Reason:* LOC 90 > Limit 68 (Role: service-orchestrator, Drag: 2.59)
    🔥 Hotspot: Lines 77-81 (AI Context Fog (score 22.0))
- [ ] **../../src/systems/SceneSwitcher.res**
  - *Reason:* LOC 267 > Limit 80 (Role: service-orchestrator, Drag: 2.32)
    🔥 Hotspot: Lines 208-212 (AI Context Fog (score 38.6))
- [ ] **../../src/systems/DownloadSystem.res**
  - *Reason:* LOC 135 > Limit 96 (Role: service-orchestrator, Drag: 1.97)
    🔥 Hotspot: Lines 131-135 (AI Context Fog (score 29.4))
- [ ] **../../src/systems/NavigationRenderer.res**
  - *Reason:* LOC 250 > Limit 52 (Role: service-orchestrator, Drag: 3.07)
    🔥 Hotspot: Lines 206-210 (AI Context Fog (score 125.6))
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* LOC 205 > Limit 68 (Role: service-orchestrator, Drag: 2.51)
    🔥 Hotspot: Lines 55-59 (AI Context Fog (score 67.4))

---

