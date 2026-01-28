# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🚨 CRITICAL VIOLATIONS (11)
**Action:** Fix these patterns immediately using project standards.

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

## 🛠️ SURGICAL REFACTOR TASKS (57)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../tests/unit/utils/TestUtils.res**
  - *Reason:* LOC 77 > Limit 30 (Role: util-pure, Drag: 3.63)
    🔥 Hotspot: Lines 13-17 (High local density (score 5.0))
- [ ] **../../src/core/ViewerState.res**
  - *Reason:* LOC 91 > Limit 30 (Role: domain-logic, Drag: 37.36)
    🔥 Hotspot: Lines 18-22 (High local density (score 28.0))
- [ ] **../../src/core/Actions.res**
  - *Reason:* LOC 105 > Limit 69 (Role: orchestrator, Drag: 2.90)
    🔥 Hotspot: Lines 55-59 (High local density (score 4.5))
- [ ] **../../src/core/UiHelpers.res**
  - *Reason:* LOC 40 > Limit 30 (Role: domain-logic, Drag: 11.75)
    🔥 Hotspot: Lines 25-29 (High local density (score 10.5))
- [ ] **../../src/core/SharedTypes.res**
  - *Reason:* LOC 132 > Limit 30 (Role: data-model, Drag: 19.10)
    🔥 Hotspot: Lines 6-10 (High local density (score 27.5))
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Exception: Central schema collection] LOC 132 > Limit 94 (Role: domain-logic, Drag: 4.24)
    🔥 Hotspot: Lines 103-107 (High local density (score 13.0))
- [ ] **../../src/core/SchemasShared.res**
  - *Reason:* LOC 99 > Limit 31 (Role: domain-logic, Drag: 6.38)
    🔥 Hotspot: Lines 24-28 (High local density (score 9.0))
- [ ] **../../src/core/SchemasDomain.res**
  - *Reason:* LOC 154 > Limit 30 (Role: domain-logic, Drag: 6.80)
    🔥 Hotspot: Lines 160-164 (High local density (score 12.0))
- [ ] **../../src/core/SceneHelpersLogic.res**
  - *Reason:* LOC 198 > Limit 117 (Role: service-orchestrator, Drag: 1.70)
    🔥 Hotspot: Lines 122-126 (High local density (score 16.0))
- [ ] **../../src/ServiceWorkerMain.res**
  - *Reason:* LOC 164 > Limit 142 (Role: orchestrator, Drag: 1.40)
    🔥 Hotspot: Lines 169-173 (High local density (score 22.0))
- [ ] **../../src/utils/GeoUtils.res**
  - *Reason:* LOC 83 > Limit 72 (Role: util-pure, Drag: 1.37)
    🔥 Hotspot: Lines 64-68 (High local density (score 13.5))
- [ ] **../../src/utils/PersistenceLayer.res**
  - *Reason:* LOC 66 > Limit 30 (Role: util-pure, Drag: 4.06)
    🔥 Hotspot: Lines 73-77 (High local density (score 10.0))
- [ ] **../../src/utils/ProgressBar.res**
  - *Reason:* LOC 106 > Limit 55 (Role: util-pure, Drag: 1.81)
    🔥 Hotspot: Lines 111-115 (High local density (score 16.0))
- [ ] **../../src/utils/LoggerTelemetry.res**
  - *Reason:* LOC 94 > Limit 66 (Role: util-pure, Drag: 1.51)
    🔥 Hotspot: Lines 49-53 (High local density (score 14.0))
- [ ] **../../src/utils/Logger.res**
  - *Reason:* LOC 106 > Limit 76 (Role: util-pure, Drag: 1.30)
    🔥 Hotspot: Lines 68-72 (High local density (score 10.0))
- [ ] **../../src/utils/ImageOptimizer.res**
  - *Reason:* LOC 92 > Limit 70 (Role: util-pure, Drag: 1.42)
    🔥 Hotspot: Lines 59-63 (High local density (score 17.5))
- [ ] **../../src/utils/LazyLoad.res**
  - *Reason:* LOC 87 > Limit 62 (Role: util-pure, Drag: 1.61)
    🔥 Hotspot: Lines 26-30 (High local density (score 19.0))
- [ ] **../../src/utils/LoggerLogic.res**
  - *Reason:* LOC 197 > Limit 160 (Role: service-orchestrator, Drag: 1.25)
    🔥 Hotspot: Lines 162-166 (High local density (score 11.0))
- [ ] **../../src/utils/PathInterpolation.res**
  - *Reason:* LOC 236 > Limit 60 (Role: util-pure, Drag: 1.66)
    🔥 Hotspot: Lines 121-125 (High local density (score 21.0))
- [ ] **../../src/utils/ProjectionMath.res**
  - *Reason:* LOC 88 > Limit 76 (Role: util-pure, Drag: 1.31)
    🔥 Hotspot: Lines 103-107 (High local density (score 9.5))
- [ ] **../../src/utils/Constants.res**
  - *Reason:* LOC 185 > Limit 82 (Role: util-pure, Drag: 1.21)
    🔥 Hotspot: Lines 216-220 (High local density (score 7.0))
- [ ] **../../src/utils/SessionStore.res**
  - *Reason:* LOC 84 > Limit 49 (Role: util-pure, Drag: 2.04)
    🔥 Hotspot: Lines 53-57 (High local density (score 16.5))
- [ ] **../../src/components/Sidebar/SidebarMainLogic.res**
  - *Reason:* LOC 152 > Limit 114 (Role: service-orchestrator, Drag: 1.74)
    🔥 Hotspot: Lines 75-79 (High local density (score 16.5))
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* LOC 307 > Limit 107 (Role: service-orchestrator, Drag: 1.87)
    🔥 Hotspot: Lines 136-140 (High local density (score 20.0))
- [ ] **../../src/components/ModalContext.res**
  - *Reason:* LOC 166 > Limit 163 (Role: ui-component, Drag: 2.14)
    🔥 Hotspot: Lines 77-81 (High local density (score 22.5))
- [ ] **../../src/systems/TeaserRecorderLogic.res**
  - *Reason:* LOC 251 > Limit 147 (Role: service-orchestrator, Drag: 1.36)
    🔥 Hotspot: Lines 214-218 (High local density (score 15.5))
- [ ] **../../src/systems/ExifReportGeneratorLogicExtraction.res**
  - *Reason:* LOC 108 > Limit 99 (Role: service-orchestrator, Drag: 2.02)
    🔥 Hotspot: Lines 54-58 (High local density (score 26.0))
- [ ] **../../src/systems/ViewerFollow.res**
  - *Reason:* LOC 131 > Limit 107 (Role: service-orchestrator, Drag: 1.87)
    🔥 Hotspot: Lines 140-144 (High local density (score 16.5))
- [ ] **../../src/systems/SvgManager.res**
  - *Reason:* LOC 137 > Limit 42 (Role: service-orchestrator, Drag: 4.71)
    🔥 Hotspot: Lines 82-86 (High local density (score 12.5))
- [ ] **../../src/systems/LinkEditorLogic.res**
  - *Reason:* LOC 123 > Limit 119 (Role: service-orchestrator, Drag: 1.67)
    🔥 Hotspot: Lines 123-127 (High local density (score 17.0))
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* LOC 132 > Limit 107 (Role: service-orchestrator, Drag: 1.87)
    🔥 Hotspot: Lines 55-59 (High local density (score 21.5))
- [ ] **../../src/systems/TeaserRecorderTypes.res**
  - *Reason:* LOC 76 > Limit 30 (Role: service-orchestrator, Drag: 16.05)
    🔥 Hotspot: Lines 62-66 (High local density (score 27.5))
- [ ] **../../src/systems/SceneTransitionManager.res**
  - *Reason:* LOC 111 > Limit 110 (Role: service-orchestrator, Drag: 1.81)
    🔥 Hotspot: Lines 42-46 (High local density (score 14.0))
- [ ] **../../src/systems/ViewerPool.res**
  - *Reason:* LOC 94 > Limit 31 (Role: service-orchestrator, Drag: 6.27)
    🔥 Hotspot: Lines 6-10 (High local density (score 17.5))
- [ ] **../../src/systems/HotspotLineLogicArrow.res**
  - *Reason:* LOC 189 > Limit 120 (Role: service-orchestrator, Drag: 1.65)
    🔥 Hotspot: Lines 53-57 (High local density (score 18.0))
- [ ] **../../src/systems/SceneLoaderLogic.res**
  - *Reason:* LOC 170 > Limit 101 (Role: service-orchestrator, Drag: 1.98)
    🔥 Hotspot: Lines 105-109 (High local density (score 25.5))
- [ ] **../../src/systems/AudioManager.res**
  - *Reason:* LOC 122 > Limit 74 (Role: service-orchestrator, Drag: 2.70)
    🔥 Hotspot: Lines 100-104 (High local density (score 11.0))
- [ ] **../../src/systems/PanoramaClusterer.res**
  - *Reason:* LOC 146 > Limit 101 (Role: service-orchestrator, Drag: 1.98)
    🔥 Hotspot: Lines 37-41 (High local density (score 21.5))
- [ ] **../../src/systems/PannellumAdapter.res**
  - *Reason:* LOC 68 > Limit 30 (Role: service-orchestrator, Drag: 14.53)
    🔥 Hotspot: Lines 6-10 (High local density (score 12.0))
- [ ] **../../src/systems/SimulationPathGenerator.res**
  - *Reason:* LOC 202 > Limit 30 (Role: service-orchestrator, Drag: 8.03)
    🔥 Hotspot: Lines 190-194 (High local density (score 29.5))
- [ ] **../../src/systems/UploadProcessorLogicLogic.res**
  - *Reason:* LOC 307 > Limit 137 (Role: service-orchestrator, Drag: 1.45)
    🔥 Hotspot: Lines 332-336 (High local density (score 20.0))
- [ ] **../../src/systems/SimulationNavigation.res**
  - *Reason:* LOC 218 > Limit 142 (Role: service-orchestrator, Drag: 1.40)
    🔥 Hotspot: Lines 229-233 (High local density (score 19.5))
- [ ] **../../src/systems/ExifParser.res**
  - *Reason:* LOC 266 > Limit 147 (Role: service-orchestrator, Drag: 1.36)
    🔥 Hotspot: Lines 48-52 (High local density (score 20.5))
- [ ] **../../src/systems/TeaserManager.res**
  - *Reason:* LOC 237 > Limit 110 (Role: service-orchestrator, Drag: 1.80)
    🔥 Hotspot: Lines 223-227 (High local density (score 32.0))
- [ ] **../../src/systems/api/ProjectApi.res**
  - *Reason:* LOC 280 > Limit 108 (Role: service-orchestrator, Drag: 1.84)
    🔥 Hotspot: Lines 255-259 (High local density (score 18.5))
- [ ] **../../src/systems/api/MediaApi.res**
  - *Reason:* LOC 174 > Limit 119 (Role: service-orchestrator, Drag: 1.68)
    🔥 Hotspot: Lines 26-30 (High local density (score 16.5))
- [ ] **../../src/systems/TourTemplateStyles.res**
  - *Reason:* LOC 186 > Limit 159 (Role: service-orchestrator, Drag: 1.25)
    🔥 Hotspot: Lines 188-192 (High local density (score 9.5))
- [ ] **../../src/systems/NavigationController.res**
  - *Reason:* LOC 193 > Limit 91 (Role: service-orchestrator, Drag: 2.17)
    🔥 Hotspot: Lines 162-166 (High local density (score 35.5))
- [ ] **../../src/systems/NavigationGraph.res**
  - *Reason:* LOC 211 > Limit 114 (Role: service-orchestrator, Drag: 1.75)
    🔥 Hotspot: Lines 182-186 (High local density (score 18.0))
- [ ] **../../src/systems/ProjectManagerLogic.res**
  - *Reason:* LOC 226 > Limit 45 (Role: service-orchestrator, Drag: 4.37)
    🔥 Hotspot: Lines 175-179 (High local density (score 16.5))
- [ ] **../../src/systems/HotspotLineLogicLogic.res**
  - *Reason:* LOC 287 > Limit 128 (Role: service-orchestrator, Drag: 1.55)
    🔥 Hotspot: Lines 58-62 (High local density (score 15.5))
- [ ] **../../src/systems/ResizerLogic.res**
  - *Reason:* LOC 258 > Limit 100 (Role: service-orchestrator, Drag: 1.98)
    🔥 Hotspot: Lines 144-148 (High local density (score 24.5))
- [ ] **../../src/systems/SimulationDriver.res**
  - *Reason:* LOC 148 > Limit 116 (Role: service-orchestrator, Drag: 1.71)
    🔥 Hotspot: Lines 97-101 (High local density (score 28.5))
- [ ] **../../src/systems/TeaserPlayback.res**
  - *Reason:* LOC 213 > Limit 118 (Role: service-orchestrator, Drag: 1.69)
    🔥 Hotspot: Lines 23-27 (High local density (score 13.0))
- [ ] **../../src/systems/SceneSwitcher.res**
  - *Reason:* LOC 267 > Limit 123 (Role: service-orchestrator, Drag: 1.62)
    🔥 Hotspot: Lines 200-204 (High local density (score 18.0))
- [ ] **../../src/systems/NavigationRenderer.res**
  - *Reason:* LOC 250 > Limit 106 (Role: service-orchestrator, Drag: 1.87)
    🔥 Hotspot: Lines 206-210 (High local density (score 28.0))
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* LOC 205 > Limit 124 (Role: service-orchestrator, Drag: 1.61)
    🔥 Hotspot: Lines 55-59 (High local density (score 20.5))

---

