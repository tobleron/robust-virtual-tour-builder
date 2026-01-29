# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🚨 CRITICAL VIOLATIONS (1)
**Action:** Fix these patterns immediately using project standards.

### Pattern: `mutable `
- [ ] `../../src/components/VisualPipeline.res`

---

## 🛠️ SURGICAL REFACTOR TASKS (110)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../src/core/ViewerState.res**
  - *Reason:* [Exception: High-frequency state updates] LOC 91 > Limit 30 (Role: domain-logic, Drag: 43.11)
    🔥 Hotspot: Lines 18-22 (AI Context Fog (score 26.6))
- [ ] **../../src/core/SceneHelpersParser.res**
  - *Reason:* LOC 67 > Limit 30 (Role: domain-logic, Drag: 5.76)
    🔥 Hotspot: Lines 49-53 (AI Context Fog (score 27.2))
- [ ] **../../src/core/Actions.res**
  - *Reason:* LOC 105 > Limit 30 (Role: orchestrator, Drag: 51.80)
    🔥 Hotspot: Lines 55-59 (AI Context Fog (score 3.0))
- [ ] **../../src/core/UiHelpers.res**
  - *Reason:* LOC 40 > Limit 30 (Role: domain-logic, Drag: 18.15)
    🔥 Hotspot: Lines 25-29 (AI Context Fog (score 17.8))
- [ ] **../../src/core/SharedTypes.res**
  - *Reason:* [Exception: Deeply nested but necessary data models] LOC 132 > Limit 33 (Role: data-model, Drag: 19.30)
    🔥 Hotspot: Lines 6-10 (AI Context Fog (score 26.0))
- [ ] **../../src/core/AppContext.res**
  - *Reason:* LOC 135 > Limit 30 (Role: domain-logic, Drag: 5.59)
    🔥 Hotspot: Lines 85-89 (AI Context Fog (score 36.0))
- [ ] **../../src/core/Types.res**
  - *Reason:* [Exception: Deeply nested but necessary data models] LOC 192 > Limit 117 (Role: data-model, Drag: 8.30)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Exception: Central schema collection (Authorized debt)] LOC 132 > Limit 30 (Role: domain-logic, Drag: 21.59)
    🔥 Hotspot: Lines 103-107 (AI Context Fog (score 27.2))
- [ ] **../../src/core/SchemasShared.res**
  - *Reason:* LOC 99 > Limit 30 (Role: domain-logic, Drag: 7.28)
    🔥 Hotspot: Lines 24-28 (AI Context Fog (score 8.0))
- [ ] **../../src/core/SchemasDomain.res**
  - *Reason:* LOC 154 > Limit 30 (Role: domain-logic, Drag: 11.70)
    🔥 Hotspot: Lines 160-164 (AI Context Fog (score 13.0))
- [ ] **../../src/core/SceneHelpersLogic.res**
  - *Reason:* LOC 198 > Limit 30 (Role: service-orchestrator, Drag: 23.20)
    🔥 Hotspot: Lines 122-126 (AI Context Fog (score 41.2))
- [ ] **../../src/core/reducers/NavigationReducer.res**
  - *Reason:* LOC 63 > Limit 30 (Role: domain-logic, Drag: 8.96)
    🔥 Hotspot: Lines 31-35 (AI Context Fog (score 25.0))
- [ ] **../../src/core/reducers/SimulationReducer.res**
  - *Reason:* LOC 94 > Limit 30 (Role: domain-logic, Drag: 7.63)
    🔥 Hotspot: Lines 9-13 (AI Context Fog (score 16.0))
- [ ] **../../src/core/reducers/SceneReducer.res**
  - *Reason:* LOC 91 > Limit 30 (Role: domain-logic, Drag: 10.55)
    🔥 Hotspot: Lines 22-26 (AI Context Fog (score 21.4))
- [ ] **../../src/core/reducers/HotspotReducer.res**
  - *Reason:* LOC 94 > Limit 30 (Role: domain-logic, Drag: 10.55)
    🔥 Hotspot: Lines 75-79 (AI Context Fog (score 69.4))
- [ ] **../../src/core/AuthContext.res**
  - *Reason:* LOC 76 > Limit 30 (Role: domain-logic, Drag: 7.69)
    🔥 Hotspot: Lines 42-46 (AI Context Fog (score 29.4))
- [ ] **../../src/core/SceneCache.res**
  - *Reason:* LOC 35 > Limit 30 (Role: domain-logic, Drag: 5.24)
    🔥 Hotspot: Lines 4-8 (AI Context Fog (score 6.0))
- [ ] **../../src/ServiceWorkerMain.res**
  - *Reason:* LOC 164 > Limit 91 (Role: orchestrator, Drag: 2.20)
    🔥 Hotspot: Lines 169-173 (AI Context Fog (score 61.0))
- [ ] **../../src/utils/GeoUtils.res**
  - *Reason:* LOC 83 > Limit 30 (Role: util-pure, Drag: 3.77)
    🔥 Hotspot: Lines 67-71 (AI Context Fog (score 29.4))
- [ ] **../../src/utils/PersistenceLayer.res**
  - *Reason:* LOC 66 > Limit 30 (Role: util-pure, Drag: 9.26)
    🔥 Hotspot: Lines 38-42 (AI Context Fog (score 11.4))
- [ ] **../../src/utils/ProgressBar.res**
  - *Reason:* LOC 106 > Limit 30 (Role: util-pure, Drag: 10.36)
    🔥 Hotspot: Lines 111-115 (AI Context Fog (score 37.0))
- [ ] **../../src/utils/ColorPalette.res**
  - *Reason:* LOC 46 > Limit 30 (Role: util-pure, Drag: 11.40)
    🔥 Hotspot: Lines 22-26 (AI Context Fog (score 25.2))
- [ ] **../../src/utils/StateInspector.res**
  - *Reason:* LOC 88 > Limit 30 (Role: state-reducer, Drag: 4.81)
    🔥 Hotspot: Lines 67-71 (AI Context Fog (score 25.4))
- [ ] **../../src/utils/TourLogic.res**
  - *Reason:* LOC 129 > Limit 103 (Role: service-orchestrator, Drag: 2.03)
    🔥 Hotspot: Lines 75-79 (AI Context Fog (score 32.6))
- [ ] **../../src/utils/LoggerTelemetry.res**
  - *Reason:* LOC 94 > Limit 30 (Role: util-pure, Drag: 6.51)
    🔥 Hotspot: Lines 51-55 (AI Context Fog (score 31.6))
- [ ] **../../src/utils/Logger.res**
  - *Reason:* LOC 106 > Limit 30 (Role: util-pure, Drag: 3.65)
    🔥 Hotspot: Lines 69-73 (AI Context Fog (score 11.0))
- [ ] **../../src/utils/ImageOptimizer.res**
  - *Reason:* LOC 92 > Limit 30 (Role: util-pure, Drag: 3.92)
    🔥 Hotspot: Lines 59-63 (AI Context Fog (score 49.0))
- [ ] **../../src/utils/LazyLoad.res**
  - *Reason:* LOC 87 > Limit 30 (Role: util-pure, Drag: 6.16)
    🔥 Hotspot: Lines 30-34 (AI Context Fog (score 58.0))
- [ ] **../../src/utils/LoggerLogic.res**
  - *Reason:* LOC 197 > Limit 129 (Role: service-orchestrator, Drag: 1.75)
    🔥 Hotspot: Lines 68-72 (AI Context Fog (score 17.8))
- [ ] **../../src/utils/PathInterpolation.res**
  - *Reason:* LOC 236 > Limit 30 (Role: util-pure, Drag: 15.56)
    🔥 Hotspot: Lines 109-113 (AI Context Fog (score 64.0))
- [ ] **../../src/utils/ProjectionMath.res**
  - *Reason:* LOC 88 > Limit 30 (Role: util-pure, Drag: 4.51)
    🔥 Hotspot: Lines 104-108 (AI Context Fog (score 14.6))
- [ ] **../../src/utils/RequestQueue.res**
  - *Reason:* LOC 57 > Limit 30 (Role: util-pure, Drag: 5.15)
    🔥 Hotspot: Lines 43-47 (AI Context Fog (score 27.0))
- [ ] **../../src/utils/LoggerTypes.res**
  - *Reason:* [Exception: Deeply nested but necessary data models] LOC 105 > Limit 30 (Role: data-model, Drag: 29.49)
    🔥 Hotspot: Lines 110-114 (AI Context Fog (score 8.0))
- [ ] **../../src/utils/SessionStore.res**
  - *Reason:* LOC 84 > Limit 30 (Role: util-pure, Drag: 10.49)
    🔥 Hotspot: Lines 53-57 (AI Context Fog (score 29.0))
- [ ] **../../src/components/SceneList/SceneItem.res**
  - *Reason:* LOC 200 > Limit 36 (Role: ui-component, Drag: 5.77)
    🔥 Hotspot: Lines 83-87 (AI Context Fog (score 14.6))
- [ ] **../../src/components/SceneList/SceneListMain.res**
  - *Reason:* LOC 211 > Limit 30 (Role: ui-component, Drag: 10.08)
    🔥 Hotspot: Lines 213-217 (AI Context Fog (score 51.0))
- [ ] **../../src/components/NotificationLayer.res**
  - *Reason:* LOC 59 > Limit 36 (Role: ui-component, Drag: 5.85)
    🔥 Hotspot: Lines 38-42 (AI Context Fog (score 49.0))
- [ ] **../../src/components/LabelMenu.res**
  - *Reason:* LOC 169 > Limit 32 (Role: ui-component, Drag: 6.22)
    🔥 Hotspot: Lines 134-138 (AI Context Fog (score 43.8))
- [ ] **../../src/components/HotspotManager.res**
  - *Reason:* LOC 115 > Limit 30 (Role: service-orchestrator, Drag: 11.27)
    🔥 Hotspot: Lines 109-113 (AI Context Fog (score 16.0))
- [ ] **../../src/components/UploadReport.res**
  - *Reason:* LOC 189 > Limit 30 (Role: ui-component, Drag: 7.55)
    🔥 Hotspot: Lines 91-95 (AI Context Fog (score 36.6))
- [ ] **../../src/components/HotspotActionMenu.res**
  - *Reason:* LOC 147 > Limit 30 (Role: ui-component, Drag: 20.31)
    🔥 Hotspot: Lines 84-88 (AI Context Fog (score 38.0))
- [ ] **../../src/components/QualityIndicator.res**
  - *Reason:* LOC 48 > Limit 36 (Role: ui-component, Drag: 5.78)
    🔥 Hotspot: Lines 44-48 (AI Context Fog (score 14.6))
- [ ] **../../src/components/ViewerSnapshot.res**
  - *Reason:* LOC 54 > Limit 30 (Role: ui-component, Drag: 13.67)
    🔥 Hotspot: Lines 41-45 (AI Context Fog (score 52.0))
- [ ] **../../src/components/PopOver.res**
  - *Reason:* LOC 147 > Limit 30 (Role: ui-component, Drag: 20.15)
    🔥 Hotspot: Lines 50-54 (AI Context Fog (score 29.4))
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* LOC 567 > Limit 160 (Role: ui-component, Drag: 2.20)
    🔥 Hotspot: Lines 103-107 (AI Context Fog (score 52.0))
- [ ] **../../src/components/PreviewArrow.res**
  - *Reason:* LOC 188 > Limit 30 (Role: ui-component, Drag: 26.20)
    🔥 Hotspot: Lines 90-94 (AI Context Fog (score 66.0))
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* LOC 364 > Limit 30 (Role: ui-component, Drag: 28.64)
    🔥 Hotspot: Lines 241-245 (AI Context Fog (score 83.0))
- [ ] **../../src/components/HotspotMenuLayer.res**
  - *Reason:* LOC 51 > Limit 37 (Role: ui-component, Drag: 5.74)
    🔥 Hotspot: Lines 21-25 (AI Context Fog (score 25.0))
- [ ] **../../src/components/FloorNavigation.res**
  - *Reason:* LOC 63 > Limit 35 (Role: ui-component, Drag: 5.85)
    🔥 Hotspot: Lines 59-63 (AI Context Fog (score 27.4))
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* LOC 307 > Limit 30 (Role: service-orchestrator, Drag: 42.57)
    🔥 Hotspot: Lines 183-187 (AI Context Fog (score 61.0))
- [ ] **../../src/components/ReturnPrompt.res**
  - *Reason:* LOC 61 > Limit 30 (Role: ui-component, Drag: 7.53)
    🔥 Hotspot: Lines 25-29 (AI Context Fog (score 28.0))
- [ ] **../../src/components/UtilityBar.res**
  - *Reason:* LOC 116 > Limit 40 (Role: ui-component, Drag: 5.30)
    🔥 Hotspot: Lines 25-29 (AI Context Fog (score 18.0))
- [ ] **../../src/components/LinkModal.res**
  - *Reason:* LOC 175 > Limit 114 (Role: ui-component, Drag: 2.75)
    🔥 Hotspot: Lines 135-139 (AI Context Fog (score 100.0))
- [ ] **../../src/components/ModalContext.res**
  - *Reason:* LOC 166 > Limit 30 (Role: ui-component, Drag: 35.14)
    🔥 Hotspot: Lines 77-81 (AI Context Fog (score 81.0))
- [ ] **../../src/ServiceWorker.res**
  - *Reason:* LOC 87 > Limit 30 (Role: orchestrator, Drag: 8.24)
    🔥 Hotspot: Lines 79-83 (AI Context Fog (score 36.0))
- [ ] **../../src/i18n/I18n.res**
  - *Reason:* LOC 44 > Limit 30 (Role: infra-adapter, Drag: 6.11)
    🔥 Hotspot: Lines 45-49 (AI Context Fog (score 16.6))
- [ ] **../../src/systems/TeaserRecorderLogic.res**
  - *Reason:* LOC 251 > Limit 36 (Role: service-orchestrator, Drag: 3.96)
    🔥 Hotspot: Lines 214-218 (AI Context Fog (score 34.8))
- [ ] **../../src/systems/VideoEncoder.res**
  - *Reason:* LOC 100 > Limit 30 (Role: service-orchestrator, Drag: 10.07)
    🔥 Hotspot: Lines 57-61 (AI Context Fog (score 67.4))
- [ ] **../../src/systems/ExifReportGeneratorLogicExtraction.res**
  - *Reason:* LOC 108 > Limit 30 (Role: service-orchestrator, Drag: 15.97)
    🔥 Hotspot: Lines 56-60 (AI Context Fog (score 100.0))
- [ ] **../../src/systems/ViewerFollow.res**
  - *Reason:* LOC 131 > Limit 30 (Role: service-orchestrator, Drag: 21.82)
    🔥 Hotspot: Lines 57-61 (AI Context Fog (score 38.6))
- [ ] **../../src/systems/SvgManager.res**
  - *Reason:* [Exception: DOM-heavy state] LOC 137 > Limit 30 (Role: service-orchestrator, Drag: 25.46)
    🔥 Hotspot: Lines 85-89 (AI Context Fog (score 18.0))
- [ ] **../../src/systems/NavigationFSM.res**
  - *Reason:* LOC 79 > Limit 30 (Role: service-orchestrator, Drag: 21.64)
    🔥 Hotspot: Lines 52-56 (AI Context Fog (score 13.2))
- [ ] **../../src/systems/LinkEditorLogic.res**
  - *Reason:* LOC 123 > Limit 30 (Role: service-orchestrator, Drag: 14.97)
    🔥 Hotspot: Lines 123-127 (AI Context Fog (score 38.0))
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* LOC 132 > Limit 30 (Role: service-orchestrator, Drag: 22.12)
    🔥 Hotspot: Lines 55-59 (AI Context Fog (score 53.0))
- [ ] **../../src/systems/TourTemplates.res**
  - *Reason:* LOC 138 > Limit 128 (Role: service-orchestrator, Drag: 1.75)
    🔥 Hotspot: Lines 127-131 (AI Context Fog (score 25.0))
- [ ] **../../src/systems/TourTemplateScripts.res**
  - *Reason:* LOC 139 > Limit 122 (Role: service-orchestrator, Drag: 1.81)
    🔥 Hotspot: Lines 113-117 (AI Context Fog (score 17.8))
- [ ] **../../src/systems/ServerTeaser.res**
  - *Reason:* LOC 89 > Limit 30 (Role: service-orchestrator, Drag: 10.10)
    🔥 Hotspot: Lines 76-80 (AI Context Fog (score 26.2))
- [ ] **../../src/systems/TeaserRecorderTypes.res**
  - *Reason:* [Exception: Deeply nested but necessary data models] LOC 76 > Limit 30 (Role: service-orchestrator, Drag: 16.15)
    🔥 Hotspot: Lines 62-66 (AI Context Fog (score 26.0))
- [ ] **../../src/systems/TourTemplateAssets.res**
  - *Reason:* LOC 142 > Limit 120 (Role: service-orchestrator, Drag: 1.83)
    🔥 Hotspot: Lines 127-131 (AI Context Fog (score 5.0))
- [ ] **../../src/systems/SceneTransitionManager.res**
  - *Reason:* LOC 111 > Limit 30 (Role: service-orchestrator, Drag: 20.36)
    🔥 Hotspot: Lines 44-48 (AI Context Fog (score 25.2))
- [ ] **../../src/systems/ViewerPool.res**
  - *Reason:* [Exception: Authorized state management] LOC 94 > Limit 30 (Role: service-orchestrator, Drag: 17.62)
    🔥 Hotspot: Lines 90-94 (AI Context Fog (score 16.6))
- [ ] **../../src/systems/HotspotLineLogicArrow.res**
  - *Reason:* LOC 189 > Limit 30 (Role: service-orchestrator, Drag: 16.85)
    🔥 Hotspot: Lines 105-109 (AI Context Fog (score 52.0))
- [ ] **../../src/systems/SceneLoaderLogic.res**
  - *Reason:* LOC 170 > Limit 30 (Role: service-orchestrator, Drag: 29.13)
    🔥 Hotspot: Lines 109-113 (AI Context Fog (score 83.0))
- [ ] **../../src/systems/ExifReportGeneratorLogicLocation.res**
  - *Reason:* LOC 117 > Limit 30 (Role: service-orchestrator, Drag: 7.59)
    🔥 Hotspot: Lines 99-103 (AI Context Fog (score 36.0))
- [ ] **../../src/systems/AudioManager.res**
  - *Reason:* LOC 122 > Limit 54 (Role: service-orchestrator, Drag: 3.10)
    🔥 Hotspot: Lines 100-104 (AI Context Fog (score 15.2))
- [ ] **../../src/systems/PanoramaClusterer.res**
  - *Reason:* LOC 146 > Limit 30 (Role: service-orchestrator, Drag: 24.68)
    🔥 Hotspot: Lines 44-48 (AI Context Fog (score 64.0))
- [ ] **../../src/systems/EventBus.res**
  - *Reason:* LOC 64 > Limit 30 (Role: service-orchestrator, Drag: 11.24)
    🔥 Hotspot: Lines 59-63 (AI Context Fog (score 10.4))
- [ ] **../../src/systems/FingerprintService.res**
  - *Reason:* LOC 77 > Limit 37 (Role: service-orchestrator, Drag: 3.78)
    🔥 Hotspot: Lines 68-72 (AI Context Fog (score 23.2))
- [ ] **../../src/systems/PannellumAdapter.res**
  - *Reason:* [Exception: External library adapter] LOC 68 > Limit 30 (Role: service-orchestrator, Drag: 20.88)
    🔥 Hotspot: Lines 6-10 (AI Context Fog (score 10.8))
- [ ] **../../src/systems/SvgRenderer.res**
  - *Reason:* LOC 114 > Limit 30 (Role: service-orchestrator, Drag: 16.72)
    🔥 Hotspot: Lines 48-52 (AI Context Fog (score 27.2))
- [ ] **../../src/systems/SimulationPathGenerator.res**
  - *Reason:* [Exception: Complex iterative algorithm state] LOC 202 > Limit 30 (Role: service-orchestrator, Drag: 37.93)
    🔥 Hotspot: Lines 193-197 (AI Context Fog (score 118.8))
- [ ] **../../src/systems/UploadProcessorLogicLogic.res**
  - *Reason:* LOC 307 > Limit 30 (Role: service-orchestrator, Drag: 4.75)
    🔥 Hotspot: Lines 332-336 (AI Context Fog (score 64.0))
- [ ] **../../src/systems/ProjectData.res**
  - *Reason:* LOC 94 > Limit 42 (Role: service-orchestrator, Drag: 3.67)
    🔥 Hotspot: Lines 16-20 (AI Context Fog (score 21.0))
- [ ] **../../src/systems/ExifReportGeneratorUtils.res**
  - *Reason:* LOC 102 > Limit 101 (Role: service-orchestrator, Drag: 2.05)
    🔥 Hotspot: Lines 54-58 (AI Context Fog (score 49.4))
- [ ] **../../src/systems/SimulationNavigation.res**
  - *Reason:* LOC 218 > Limit 91 (Role: service-orchestrator, Drag: 2.20)
    🔥 Hotspot: Lines 97-101 (AI Context Fog (score 58.0))
- [ ] **../../src/systems/SimulationChainSkipper.res**
  - *Reason:* LOC 66 > Limit 30 (Role: service-orchestrator, Drag: 5.68)
    🔥 Hotspot: Lines 58-62 (AI Context Fog (score 36.0))
- [ ] **../../src/systems/Api.res**
  - *Reason:* LOC 584 > Limit 32 (Role: service-orchestrator, Drag: 4.37)
    🔥 Hotspot: Lines 593-597 (AI Context Fog (score 67.4))
- [ ] **../../src/systems/CursorPhysics.res**
  - *Reason:* LOC 47 > Limit 31 (Role: service-orchestrator, Drag: 3.62)
    🔥 Hotspot: Lines 53-57 (AI Context Fog (score 16.0))
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* LOC 112 > Limit 30 (Role: service-orchestrator, Drag: 4.62)
    🔥 Hotspot: Lines 104-108 (AI Context Fog (score 100.0))
- [ ] **../../src/systems/ExifParser.res**
  - *Reason:* LOC 266 > Limit 97 (Role: service-orchestrator, Drag: 2.11)
    🔥 Hotspot: Lines 49-53 (AI Context Fog (score 48.4))
- [ ] **../../src/systems/TeaserManager.res**
  - *Reason:* LOC 237 > Limit 30 (Role: service-orchestrator, Drag: 14.55)
    🔥 Hotspot: Lines 223-227 (AI Context Fog (score 146.0))
- [ ] **../../src/systems/TourTemplateStyles.res**
  - *Reason:* LOC 186 > Limit 113 (Role: service-orchestrator, Drag: 1.90)
    🔥 Hotspot: Lines 188-192 (AI Context Fog (score 14.6))
- [ ] **../../src/systems/NavigationController.res**
  - *Reason:* LOC 193 > Limit 30 (Role: service-orchestrator, Drag: 27.32)
    🔥 Hotspot: Lines 162-166 (AI Context Fog (score 201.8))
- [ ] **../../src/systems/NavigationGraph.res**
  - *Reason:* LOC 211 > Limit 30 (Role: service-orchestrator, Drag: 27.65)
    🔥 Hotspot: Lines 188-192 (AI Context Fog (score 49.0))
- [ ] **../../src/systems/ProjectManagerLogic.res**
  - *Reason:* LOC 226 > Limit 30 (Role: service-orchestrator, Drag: 31.57)
    🔥 Hotspot: Lines 175-179 (AI Context Fog (score 43.8))
- [ ] **../../src/systems/HotspotLineLogicLogic.res**
  - *Reason:* LOC 287 > Limit 30 (Role: service-orchestrator, Drag: 23.75)
    🔥 Hotspot: Lines 130-134 (AI Context Fog (score 36.0))
- [ ] **../../src/systems/ResizerLogic.res**
  - *Reason:* LOC 258 > Limit 30 (Role: service-orchestrator, Drag: 34.58)
    🔥 Hotspot: Lines 146-150 (AI Context Fog (score 63.0))
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* LOC 102 > Limit 30 (Role: service-orchestrator, Drag: 13.35)
    🔥 Hotspot: Lines 97-101 (AI Context Fog (score 66.0))
- [ ] **../../src/systems/SimulationDriver.res**
  - *Reason:* LOC 148 > Limit 30 (Role: service-orchestrator, Drag: 9.26)
    🔥 Hotspot: Lines 132-136 (AI Context Fog (score 116.8))
- [ ] **../../src/systems/TeaserPlayback.res**
  - *Reason:* LOC 213 > Limit 30 (Role: service-orchestrator, Drag: 22.54)
    🔥 Hotspot: Lines 31-35 (AI Context Fog (score 27.2))
- [ ] **../../src/systems/NavigationUI.res**
  - *Reason:* LOC 54 > Limit 30 (Role: service-orchestrator, Drag: 11.78)
    🔥 Hotspot: Lines 44-48 (AI Context Fog (score 49.4))
- [ ] **../../src/systems/InputSystem.res**
  - *Reason:* LOC 75 > Limit 30 (Role: service-orchestrator, Drag: 7.77)
    🔥 Hotspot: Lines 84-88 (AI Context Fog (score 13.2))
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* LOC 98 > Limit 30 (Role: service-orchestrator, Drag: 8.20)
    🔥 Hotspot: Lines 60-64 (AI Context Fog (score 39.0))
- [ ] **../../src/systems/ExifReportGeneratorLogicGroups.res**
  - *Reason:* LOC 90 > Limit 30 (Role: service-orchestrator, Drag: 20.99)
    🔥 Hotspot: Lines 77-81 (AI Context Fog (score 22.0))
- [ ] **../../src/systems/SceneLoaderLogicConfig.res**
  - *Reason:* LOC 73 > Limit 42 (Role: infra-config, Drag: 5.51)
    🔥 Hotspot: Lines 27-31 (AI Context Fog (score 17.8))
- [ ] **../../src/systems/SceneSwitcher.res**
  - *Reason:* LOC 267 > Limit 30 (Role: service-orchestrator, Drag: 23.17)
    🔥 Hotspot: Lines 208-212 (AI Context Fog (score 38.6))
- [ ] **../../src/systems/DownloadSystem.res**
  - *Reason:* LOC 135 > Limit 30 (Role: service-orchestrator, Drag: 4.32)
    🔥 Hotspot: Lines 131-135 (AI Context Fog (score 29.4))
- [ ] **../../src/systems/SceneLoaderLogicEvents.res**
  - *Reason:* LOC 93 > Limit 51 (Role: service-orchestrator, Drag: 2.94)
    🔥 Hotspot: Lines 80-84 (AI Context Fog (score 27.2))
- [ ] **../../src/systems/NavigationRenderer.res**
  - *Reason:* LOC 250 > Limit 30 (Role: service-orchestrator, Drag: 22.17)
    🔥 Hotspot: Lines 206-210 (AI Context Fog (score 125.6))
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* LOC 205 > Limit 30 (Role: service-orchestrator, Drag: 10.51)
    🔥 Hotspot: Lines 55-59 (AI Context Fog (score 67.4))

---

