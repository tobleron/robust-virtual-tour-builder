# Task 1087: Surgical Refactor SYSTEMS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 2.00 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🚨 Hotspots (Focus Area)
The following regions are calculated to be the most confusing for AI:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/228  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/224  Hotspot: Lines 204-208)

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/141  Hotspot: Lines 55-59)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 5.95 | LOC: 697/118  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/LinkEditorLogic.res** (Metric: [Nesting: 0.90, Density: 0.19, Deps: 0.09] | Drag: 7.29 | LOC: 122/99  Hotspot: Lines 123-127)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 7.83 | LOC: 415/91  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/NavigationController.res** (Metric: [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 9.08 | LOC: 194/82  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/NavigationGraph.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.06] | Drag: 7.06 | LOC: 121/103  Hotspot: Lines 92-96)

- [ ] - **../../src/systems/NavigationRenderer.res** (Metric: [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 6.79 | LOC: 248/105  Hotspot: Lines 206-210)

- [ ] - **../../src/systems/PanoramaClusterer.res** (Metric: [Nesting: 1.20, Density: 0.29, Deps: 0.10] | Drag: 10.15 | LOC: 143/80  Hotspot: Lines 132-136)

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 8.10 | LOC: 247/85  Hotspot: Lines 235-239)

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 1.50, Density: 0.26, Deps: 0.11] | Drag: 8.10 | LOC: 303/90  Hotspot: Lines 218-222)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.90 | LOC: 338/157  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 557/224  Hotspot: Lines 370-374)

- [ ] - **../../src/systems/SvgManager.res** (Metric: [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.08 | LOC: 190/85  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 581/227  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 333/207  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 6.87 | LOC: 299/106  Hotspot: Lines 207-211)

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.40 | LOC: 592/237  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 2.84 | LOC: 205/195  Hotspot: Lines 55-59)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 3.24 | LOC: 697/186  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 5.30 | LOC: 415/122  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/NavigationController.res** (Metric: [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 4.68 | LOC: 194/135  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/NavigationGraph.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.06] | Drag: 7.04 | LOC: 121/104  Hotspot: Lines 92-96)

- [ ] - **../../src/systems/NavigationRenderer.res** (Metric: [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 3.78 | LOC: 248/163  Hotspot: Lines 206-210)

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 4.56 | LOC: 247/131  Hotspot: Lines 235-239)

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 1.50, Density: 0.26, Deps: 0.11] | Drag: 3.90 | LOC: 303/156  Hotspot: Lines 218-222)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 2.52 | LOC: 338/218  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/SvgManager.res** (Metric: [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 3.43 | LOC: 190/161  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.28 | LOC: 581/246  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.61 | LOC: 333/226  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 6.29 | LOC: 299/113  Hotspot: Lines 207-211)

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.38 | LOC: 592/239  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 2.78 | LOC: 697/209  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 4.10 | LOC: 415/148  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/NavigationController.res** (Metric: [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 3.94 | LOC: 194/154  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/NavigationRenderer.res** (Metric: [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 3.28 | LOC: 248/181  Hotspot: Lines 206-210)

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 3.31 | LOC: 247/167  Hotspot: Lines 235-239)

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 1.50, Density: 0.26, Deps: 0.11] | Drag: 3.21 | LOC: 303/180  Hotspot: Lines 218-222)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 2.32 | LOC: 338/232  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.24 | LOC: 581/249  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.55 | LOC: 333/230  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 3.96 | LOC: 299/160  Hotspot: Lines 207-211)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 4.10 | LOC: 415/180  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/NavigationController.res** (Metric: [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 3.94 | LOC: 194/180  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 3.31 | LOC: 247/180  Hotspot: Lines 235-239)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 3.96 | LOC: 299/180  Hotspot: Lines 207-211)

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.38 | LOC: 592/250  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/250  Hotspot: Lines 204-208)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 1.50, Density: 0.26, Deps: 0.11] | Drag: 3.21 | LOC: 303/250  Hotspot: Lines 218-222)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 557/250  Hotspot: Lines 370-374)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.24 | LOC: 581/250  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.55 | LOC: 333/250  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/systems/Api.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 592))

- [ ] - **../../src/systems/AudioManager.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 123))

- [ ] - **../../src/systems/CursorPhysics.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 55))

- [ ] - **../../src/systems/DownloadSystem.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 135))

- [ ] - **../../src/systems/EventBus.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 64))

- [ ] - **../../src/systems/ExifParser.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 266))

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 542))

- [ ] - **../../src/systems/Exporter.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 205))

- [ ] - **../../src/systems/FingerprintService.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 77))

- [ ] - **../../src/systems/HotspotLine.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 697))

- [ ] - **../../src/systems/InputSystem.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 78))

- [ ] - **../../src/systems/LinkEditorLogic.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 122))

- [ ] - **../../src/systems/Navigation.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 415))

- [ ] - **../../src/systems/NavigationController.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 194))

- [ ] - **../../src/systems/NavigationFSM.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 79))

- [ ] - **../../src/systems/NavigationGraph.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 121))

- [ ] - **../../src/systems/NavigationRenderer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 248))

- [ ] - **../../src/systems/NavigationUI.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 54))

- [ ] - **../../src/systems/PanoramaClusterer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 143))

- [ ] - **../../src/systems/ProjectData.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 94))

- [ ] - **../../src/systems/ProjectManager.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 247))

- [ ] - **../../src/systems/Resizer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 303))

- [ ] - **../../src/systems/Scene.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 338))

- [ ] - **../../src/systems/Simulation.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 557))

- [ ] - **../../src/systems/SvgManager.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 190))

- [ ] - **../../src/systems/Teaser.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 581))

- [ ] - **../../src/systems/TourTemplates.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 217))

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 333))

- [ ] - **../../src/systems/VideoEncoder.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 100))

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 299))

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Coupling: 0.06] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Coupling: 0.14] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Coupling: 0.11] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 1.65, Density: 0.00, Coupling: 0.01] | Drag: 2.65 | LOC: 557/250  Hotspot: Lines 370-374)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.08] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211)
- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Coupling: 0.22] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Coupling: 0.26] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Coupling: 0.23] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.30] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Coupling: 0.35] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Coupling: 0.36] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Coupling: 0.34] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.49] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211)

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Coupling: 0.52] | Drag: 2.38 | LOC: 592/250  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/ExifParser.res** (Metric: [Nesting: 1.05, Density: 0.00, Coupling: 0.52] | Drag: 2.05 | LOC: 266/250  Hotspot: Lines 49-53)

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: [Nesting: 1.65, Density: 0.00, Coupling: 0.48] | Drag: 2.65 | LOC: 542/250  Hotspot: Lines 204-208)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Coupling: 0.36] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 1.50, Density: 0.26, Coupling: 0.51] | Drag: 3.21 | LOC: 303/250  Hotspot: Lines 218-222)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Coupling: 0.54] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 1.65, Density: 0.00, Coupling: 0.27] | Drag: 2.65 | LOC: 557/250  Hotspot: Lines 370-374)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Coupling: 0.44] | Drag: 2.24 | LOC: 581/250  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Coupling: 0.57] | Drag: 2.55 | LOC: 333/250  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.50] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211)

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Coupling: 0.54] | Drag: 2.38 | LOC: 592/250  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/ExifParser.res** (Metric: [Nesting: 1.05, Density: 0.00, Coupling: 0.53] | Drag: 2.05 | LOC: 266/250  Hotspot: Lines 49-53)

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: [Nesting: 1.65, Density: 0.00, Coupling: 0.49] | Drag: 2.65 | LOC: 542/250  Hotspot: Lines 204-208)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Coupling: 0.37] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Coupling: 0.45] | Drag: 2.24 | LOC: 581/250  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Coupling: 0.58] | Drag: 2.55 | LOC: 333/250  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.51] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211)

