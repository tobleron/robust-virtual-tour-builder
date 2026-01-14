.
├── backend
│   ├── backend.log
│   ├── bin
│   │   └── ffmpeg
│   ├── Cargo.lock
│   ├── Cargo.toml
│   └── src
│       ├── api
│       │   ├── geocoding.rs
│       │   ├── media
│       │   │   ├── image.rs
│       │   │   ├── mod.rs
│       │   │   ├── serve.rs
│       │   │   ├── similarity.rs
│       │   │   └── video.rs
│       │   ├── mod.rs
│       │   ├── project.rs
│       │   ├── telemetry.rs
│       │   └── utils.rs
│       ├── main.rs
│       ├── models
│       │   ├── errors.rs
│       │   └── mod.rs
│       ├── pathfinder.rs
│       └── services
│           ├── geocoding.rs
│           ├── media.rs
│           ├── mod.rs
│           └── project.rs
├── bin
│   └── tailwindcss
├── css
│   ├── output.css
│   ├── style.css
│   └── tailwind.css
├── dev_prefs
│   └── logging_debugging_system.md
├── docs
│   ├── ACCESSIBILITY_GUIDE.md
│   ├── AntiGravity Workflow Manual.md
│   ├── ARCHITECTURE_DIAGRAM.md
│   ├── BACKEND_OPTIMIZATION_OPPORTUNITIES.md
│   ├── BACKEND_OPTIMIZATION_SUMMARY.md
│   ├── CONTAINER_BASED_FONT_SIZING.md
│   ├── FONT_ANALYSIS.md
│   ├── FONT_IMPLEMENTATION.md
│   ├── FONT_SIZE_ANALYSIS.md
│   ├── FONT_SIZE_IMPLEMENTATION.md
│   ├── IMPROVEMENTS.md
│   ├── LOGGING_ARCHITECTURE.md
│   ├── LONG_TEXT_BEST_PRACTICES.md
│   ├── MANUAL_LOGGING_TEST.md
│   ├── MIGRATION_STATUS_ANALYSIS.md
│   ├── module_size_report.md
│   ├── navigation_improvements_applied.md
│   ├── PERFORMANCE_ANALYSIS_FRONTEND_VS_BACKEND.md
│   ├── PERFORMANCE_OPTIMIZATIONS.md
│   ├── PROJECT_ANALYSIS_REPORT.md
│   ├── PROJECT_STANDARDS_AND_WORKFLOWS.md
│   ├── RELEASE_v4.0.9.md
│   ├── RESPONSIVE_FONT_SIZING.md
│   ├── SECURITY_ANALYSIS_REPORT.md
│   ├── SECURITY_FIXES_COMPLETE.md
│   ├── SECURITY_FIXES_IMPLEMENTED.md
│   ├── SECURITY_UPGRADES_ADDITIONAL.md
│   ├── SIMULATION_MODE_IMPLEMENTATION.md
│   ├── SIMULATION_TELEMETRY.md
│   └── TYPOGRAPHY.md
├── GEMINI.md
├── images
│   └── logo.png
├── index.html
├── lib
│   ├── bs
│   │   ├── build.ninja
│   │   ├── compiler-info.json
│   │   ├── src
│   │   │   ├── App.ast
│   │   │   ├── App.bs.js
│   │   │   ├── App.cmi
│   │   │   ├── App.cmj
│   │   │   ├── App.cmt
│   │   │   ├── App.res
│   │   │   ├── components
│   │   │   │   ├── HotspotManager.ast
│   │   │   │   ├── HotspotManager.bs.js
│   │   │   │   ├── HotspotManager.cmi
│   │   │   │   ├── HotspotManager.cmj
│   │   │   │   ├── HotspotManager.cmt
│   │   │   │   ├── HotspotManager.res
│   │   │   │   ├── LabelMenu.ast
│   │   │   │   ├── LabelMenu.bs.js
│   │   │   │   ├── LabelMenu.cmi
│   │   │   │   ├── LabelMenu.cmj
│   │   │   │   ├── LabelMenu.cmt
│   │   │   │   ├── LabelMenu.res
│   │   │   │   ├── LinkModal.ast
│   │   │   │   ├── LinkModal.bs.js
│   │   │   │   ├── LinkModal.cmi
│   │   │   │   ├── LinkModal.cmj
│   │   │   │   ├── LinkModal.cmt
│   │   │   │   ├── LinkModal.res
│   │   │   │   ├── ModalContext.ast
│   │   │   │   ├── ModalContext.bs.js
│   │   │   │   ├── ModalContext.cmi
│   │   │   │   ├── ModalContext.cmj
│   │   │   │   ├── ModalContext.cmt
│   │   │   │   ├── ModalContext.res
│   │   │   │   ├── NotificationContext.ast
│   │   │   │   ├── NotificationContext.bs.js
│   │   │   │   ├── NotificationContext.cmi
│   │   │   │   ├── NotificationContext.cmj
│   │   │   │   ├── NotificationContext.cmt
│   │   │   │   ├── NotificationContext.res
│   │   │   │   ├── SceneList.ast
│   │   │   │   ├── SceneList.bs.js
│   │   │   │   ├── SceneList.cmi
│   │   │   │   ├── SceneList.cmj
│   │   │   │   ├── SceneList.cmt
│   │   │   │   ├── SceneList.res
│   │   │   │   ├── Sidebar.ast
│   │   │   │   ├── Sidebar.bs.js
│   │   │   │   ├── Sidebar.cmi
│   │   │   │   ├── Sidebar.cmj
│   │   │   │   ├── Sidebar.cmt
│   │   │   │   ├── Sidebar.res
│   │   │   │   ├── UploadReport.ast
│   │   │   │   ├── UploadReport.bs.js
│   │   │   │   ├── UploadReport.cmi
│   │   │   │   ├── UploadReport.cmj
│   │   │   │   ├── UploadReport.cmt
│   │   │   │   ├── UploadReport.res
│   │   │   │   ├── ViewerFollow.ast
│   │   │   │   ├── ViewerFollow.bs.js
│   │   │   │   ├── ViewerFollow.cmi
│   │   │   │   ├── ViewerFollow.cmj
│   │   │   │   ├── ViewerFollow.cmt
│   │   │   │   ├── ViewerFollow.res
│   │   │   │   ├── ViewerLoader.ast
│   │   │   │   ├── ViewerLoader.bs.js
│   │   │   │   ├── ViewerLoader.cmi
│   │   │   │   ├── ViewerLoader.cmj
│   │   │   │   ├── ViewerLoader.cmt
│   │   │   │   ├── ViewerLoader.res
│   │   │   │   ├── ViewerManager.ast
│   │   │   │   ├── ViewerManager.bs.js
│   │   │   │   ├── ViewerManager.cmi
│   │   │   │   ├── ViewerManager.cmj
│   │   │   │   ├── ViewerManager.cmt
│   │   │   │   ├── ViewerManager.res
│   │   │   │   ├── ViewerSnapshot.ast
│   │   │   │   ├── ViewerSnapshot.bs.js
│   │   │   │   ├── ViewerSnapshot.cmi
│   │   │   │   ├── ViewerSnapshot.cmj
│   │   │   │   ├── ViewerSnapshot.cmt
│   │   │   │   ├── ViewerSnapshot.res
│   │   │   │   ├── ViewerState.ast
│   │   │   │   ├── ViewerState.bs.js
│   │   │   │   ├── ViewerState.cmi
│   │   │   │   ├── ViewerState.cmj
│   │   │   │   ├── ViewerState.cmt
│   │   │   │   ├── ViewerState.res
│   │   │   │   ├── ViewerTypes.ast
│   │   │   │   ├── ViewerTypes.bs.js
│   │   │   │   ├── ViewerTypes.cmi
│   │   │   │   ├── ViewerTypes.cmj
│   │   │   │   ├── ViewerTypes.cmt
│   │   │   │   ├── ViewerTypes.res
│   │   │   │   ├── ViewerUI.ast
│   │   │   │   ├── ViewerUI.bs.js
│   │   │   │   ├── ViewerUI.cmi
│   │   │   │   ├── ViewerUI.cmj
│   │   │   │   ├── ViewerUI.cmt
│   │   │   │   ├── ViewerUI.res
│   │   │   │   ├── VisualPipeline.ast
│   │   │   │   ├── VisualPipeline.bs.js
│   │   │   │   ├── VisualPipeline.cmi
│   │   │   │   ├── VisualPipeline.cmj
│   │   │   │   ├── VisualPipeline.cmt
│   │   │   │   └── VisualPipeline.res
│   │   │   ├── core
│   │   │   │   ├── Actions.ast
│   │   │   │   ├── Actions.bs.js
│   │   │   │   ├── Actions.cmi
│   │   │   │   ├── Actions.cmj
│   │   │   │   ├── Actions.cmt
│   │   │   │   ├── Actions.res
│   │   │   │   ├── AppContext.ast
│   │   │   │   ├── AppContext.bs.js
│   │   │   │   ├── AppContext.cmi
│   │   │   │   ├── AppContext.cmj
│   │   │   │   ├── AppContext.cmt
│   │   │   │   ├── AppContext.res
│   │   │   │   ├── GlobalStateBridge.ast
│   │   │   │   ├── GlobalStateBridge.bs.js
│   │   │   │   ├── GlobalStateBridge.cmi
│   │   │   │   ├── GlobalStateBridge.cmj
│   │   │   │   ├── GlobalStateBridge.cmt
│   │   │   │   ├── GlobalStateBridge.res
│   │   │   │   ├── Reducer.ast
│   │   │   │   ├── Reducer.bs.js
│   │   │   │   ├── Reducer.cmi
│   │   │   │   ├── Reducer.cmj
│   │   │   │   ├── Reducer.cmt
│   │   │   │   ├── Reducer.res
│   │   │   │   ├── State.ast
│   │   │   │   ├── State.bs.js
│   │   │   │   ├── State.cmi
│   │   │   │   ├── State.cmj
│   │   │   │   ├── State.cmt
│   │   │   │   ├── State.res
│   │   │   │   ├── Types.ast
│   │   │   │   ├── Types.bs.js
│   │   │   │   ├── Types.cmi
│   │   │   │   ├── Types.cmj
│   │   │   │   ├── Types.cmt
│   │   │   │   └── Types.res
│   │   │   ├── Main.ast
│   │   │   ├── Main.bs.js
│   │   │   ├── Main.cmi
│   │   │   ├── Main.cmj
│   │   │   ├── Main.cmt
│   │   │   ├── Main.res
│   │   │   ├── ReBindings.ast
│   │   │   ├── ReBindings.bs.js
│   │   │   ├── ReBindings.cmi
│   │   │   ├── ReBindings.cmj
│   │   │   ├── ReBindings.cmt
│   │   │   ├── ReBindings.res
│   │   │   ├── systems
│   │   │   │   ├── AudioManager.ast
│   │   │   │   ├── AudioManager.bs.js
│   │   │   │   ├── AudioManager.cmi
│   │   │   │   ├── AudioManager.cmj
│   │   │   │   ├── AudioManager.cmt
│   │   │   │   ├── AudioManager.res
│   │   │   │   ├── BackendApi.ast
│   │   │   │   ├── BackendApi.bs.js
│   │   │   │   ├── BackendApi.cmi
│   │   │   │   ├── BackendApi.cmj
│   │   │   │   ├── BackendApi.cmt
│   │   │   │   ├── BackendApi.res
│   │   │   │   ├── DownloadSystem.ast
│   │   │   │   ├── DownloadSystem.bs.js
│   │   │   │   ├── DownloadSystem.cmi
│   │   │   │   ├── DownloadSystem.cmj
│   │   │   │   ├── DownloadSystem.cmt
│   │   │   │   ├── DownloadSystem.res
│   │   │   │   ├── EventBus.ast
│   │   │   │   ├── EventBus.bs.js
│   │   │   │   ├── EventBus.cmi
│   │   │   │   ├── EventBus.cmj
│   │   │   │   ├── EventBus.cmt
│   │   │   │   ├── EventBus.res
│   │   │   │   ├── ExifParser.ast
│   │   │   │   ├── ExifParser.bs.js
│   │   │   │   ├── ExifParser.cmi
│   │   │   │   ├── ExifParser.cmj
│   │   │   │   ├── ExifParser.cmt
│   │   │   │   ├── ExifParser.res
│   │   │   │   ├── ExifReportGenerator.ast
│   │   │   │   ├── ExifReportGenerator.bs.js
│   │   │   │   ├── ExifReportGenerator.cmi
│   │   │   │   ├── ExifReportGenerator.cmj
│   │   │   │   ├── ExifReportGenerator.cmt
│   │   │   │   ├── ExifReportGenerator.res
│   │   │   │   ├── Exporter.ast
│   │   │   │   ├── Exporter.bs.js
│   │   │   │   ├── Exporter.cmi
│   │   │   │   ├── Exporter.cmj
│   │   │   │   ├── Exporter.cmt
│   │   │   │   ├── Exporter.res
│   │   │   │   ├── HotspotLine.ast
│   │   │   │   ├── HotspotLine.bs.js
│   │   │   │   ├── HotspotLine.cmi
│   │   │   │   ├── HotspotLine.cmj
│   │   │   │   ├── HotspotLine.cmt
│   │   │   │   ├── HotspotLine.res
│   │   │   │   ├── ImageAnalysis.ast
│   │   │   │   ├── ImageAnalysis.bs.js
│   │   │   │   ├── ImageAnalysis.cmi
│   │   │   │   ├── ImageAnalysis.cmj
│   │   │   │   ├── ImageAnalysis.cmt
│   │   │   │   ├── ImageAnalysis.res
│   │   │   │   ├── InputSystem.ast
│   │   │   │   ├── InputSystem.bs.js
│   │   │   │   ├── InputSystem.cmi
│   │   │   │   ├── InputSystem.cmj
│   │   │   │   ├── InputSystem.cmt
│   │   │   │   ├── InputSystem.res
│   │   │   │   ├── Navigation.ast
│   │   │   │   ├── Navigation.bs.js
│   │   │   │   ├── Navigation.cmi
│   │   │   │   ├── Navigation.cmj
│   │   │   │   ├── Navigation.cmt
│   │   │   │   ├── Navigation.res
│   │   │   │   ├── NavigationController.ast
│   │   │   │   ├── NavigationController.bs.js
│   │   │   │   ├── NavigationController.cmi
│   │   │   │   ├── NavigationController.cmj
│   │   │   │   ├── NavigationController.cmt
│   │   │   │   ├── NavigationController.res
│   │   │   │   ├── NavigationRenderer.ast
│   │   │   │   ├── NavigationRenderer.bs.js
│   │   │   │   ├── NavigationRenderer.cmi
│   │   │   │   ├── NavigationRenderer.cmj
│   │   │   │   ├── NavigationRenderer.cmt
│   │   │   │   ├── NavigationRenderer.res
│   │   │   │   ├── NavigationUI.ast
│   │   │   │   ├── NavigationUI.bs.js
│   │   │   │   ├── NavigationUI.cmi
│   │   │   │   ├── NavigationUI.cmj
│   │   │   │   ├── NavigationUI.cmt
│   │   │   │   ├── NavigationUI.res
│   │   │   │   ├── ProjectData.ast
│   │   │   │   ├── ProjectData.bs.js
│   │   │   │   ├── ProjectData.cmi
│   │   │   │   ├── ProjectData.cmj
│   │   │   │   ├── ProjectData.cmt
│   │   │   │   ├── ProjectData.res
│   │   │   │   ├── ProjectManager.ast
│   │   │   │   ├── ProjectManager.bs.js
│   │   │   │   ├── ProjectManager.cmi
│   │   │   │   ├── ProjectManager.cmj
│   │   │   │   ├── ProjectManager.cmt
│   │   │   │   ├── ProjectManager.res
│   │   │   │   ├── Resizer.ast
│   │   │   │   ├── Resizer.bs.js
│   │   │   │   ├── Resizer.cmi
│   │   │   │   ├── Resizer.cmj
│   │   │   │   ├── Resizer.cmt
│   │   │   │   ├── Resizer.res
│   │   │   │   ├── ServerTeaser.ast
│   │   │   │   ├── ServerTeaser.bs.js
│   │   │   │   ├── ServerTeaser.cmi
│   │   │   │   ├── ServerTeaser.cmj
│   │   │   │   ├── ServerTeaser.cmt
│   │   │   │   ├── ServerTeaser.res
│   │   │   │   ├── SimulationChainSkipper.ast
│   │   │   │   ├── SimulationChainSkipper.bs.js
│   │   │   │   ├── SimulationChainSkipper.cmi
│   │   │   │   ├── SimulationChainSkipper.cmj
│   │   │   │   ├── SimulationChainSkipper.cmt
│   │   │   │   ├── SimulationChainSkipper.res
│   │   │   │   ├── SimulationNavigation.ast
│   │   │   │   ├── SimulationNavigation.bs.js
│   │   │   │   ├── SimulationNavigation.cmi
│   │   │   │   ├── SimulationNavigation.cmj
│   │   │   │   ├── SimulationNavigation.cmt
│   │   │   │   ├── SimulationNavigation.res
│   │   │   │   ├── SimulationPathGenerator.ast
│   │   │   │   ├── SimulationPathGenerator.bs.js
│   │   │   │   ├── SimulationPathGenerator.cmi
│   │   │   │   ├── SimulationPathGenerator.cmj
│   │   │   │   ├── SimulationPathGenerator.cmt
│   │   │   │   ├── SimulationPathGenerator.res
│   │   │   │   ├── SimulationSystem.ast
│   │   │   │   ├── SimulationSystem.bs.js
│   │   │   │   ├── SimulationSystem.cmi
│   │   │   │   ├── SimulationSystem.cmj
│   │   │   │   ├── SimulationSystem.cmt
│   │   │   │   ├── SimulationSystem.res
│   │   │   │   ├── TeaserManager.ast
│   │   │   │   ├── TeaserManager.bs.js
│   │   │   │   ├── TeaserManager.cmi
│   │   │   │   ├── TeaserManager.cmj
│   │   │   │   ├── TeaserManager.cmt
│   │   │   │   ├── TeaserManager.res
│   │   │   │   ├── TeaserPathfinder.ast
│   │   │   │   ├── TeaserPathfinder.bs.js
│   │   │   │   ├── TeaserPathfinder.cmi
│   │   │   │   ├── TeaserPathfinder.cmj
│   │   │   │   ├── TeaserPathfinder.cmt
│   │   │   │   ├── TeaserPathfinder.res
│   │   │   │   ├── TeaserRecorder.ast
│   │   │   │   ├── TeaserRecorder.bs.js
│   │   │   │   ├── TeaserRecorder.cmi
│   │   │   │   ├── TeaserRecorder.cmj
│   │   │   │   ├── TeaserRecorder.cmt
│   │   │   │   ├── TeaserRecorder.res
│   │   │   │   ├── TourTemplates.ast
│   │   │   │   ├── TourTemplates.bs.js
│   │   │   │   ├── TourTemplates.cmi
│   │   │   │   ├── TourTemplates.cmj
│   │   │   │   ├── TourTemplates.cmt
│   │   │   │   ├── TourTemplates.res
│   │   │   │   ├── UploadProcessor.ast
│   │   │   │   ├── UploadProcessor.bs.js
│   │   │   │   ├── UploadProcessor.cmi
│   │   │   │   ├── UploadProcessor.cmj
│   │   │   │   ├── UploadProcessor.cmt
│   │   │   │   ├── UploadProcessor.res
│   │   │   │   ├── VideoEncoder.ast
│   │   │   │   ├── VideoEncoder.bs.js
│   │   │   │   ├── VideoEncoder.cmi
│   │   │   │   ├── VideoEncoder.cmj
│   │   │   │   ├── VideoEncoder.cmt
│   │   │   │   └── VideoEncoder.res
│   │   │   └── utils
│   │   │       ├── ColorPalette.ast
│   │   │       ├── ColorPalette.bs.js
│   │   │       ├── ColorPalette.cmi
│   │   │       ├── ColorPalette.cmj
│   │   │       ├── ColorPalette.cmt
│   │   │       ├── ColorPalette.res
│   │   │       ├── Constants.ast
│   │   │       ├── Constants.bs.js
│   │   │       ├── Constants.cmi
│   │   │       ├── Constants.cmj
│   │   │       ├── Constants.cmt
│   │   │       ├── Constants.res
│   │   │       ├── GeoUtils.ast
│   │   │       ├── GeoUtils.bs.js
│   │   │       ├── GeoUtils.cmi
│   │   │       ├── GeoUtils.cmj
│   │   │       ├── GeoUtils.cmt
│   │   │       ├── GeoUtils.res
│   │   │       ├── Logger.ast
│   │   │       ├── Logger.bs.js
│   │   │       ├── Logger.cmi
│   │   │       ├── Logger.cmj
│   │   │       ├── Logger.cmt
│   │   │       ├── Logger.res
│   │   │       ├── PathInterpolation.ast
│   │   │       ├── PathInterpolation.bs.js
│   │   │       ├── PathInterpolation.cmi
│   │   │       ├── PathInterpolation.cmj
│   │   │       ├── PathInterpolation.cmt
│   │   │       ├── PathInterpolation.res
│   │   │       ├── ProgressBar.ast
│   │   │       ├── ProgressBar.bs.js
│   │   │       ├── ProgressBar.cmi
│   │   │       ├── ProgressBar.cmj
│   │   │       ├── ProgressBar.cmt
│   │   │       ├── ProgressBar.res
│   │   │       ├── TourLogic.ast
│   │   │       ├── TourLogic.bs.js
│   │   │       ├── TourLogic.cmi
│   │   │       ├── TourLogic.cmj
│   │   │       ├── TourLogic.cmt
│   │   │       └── TourLogic.res
│   │   └── tests
│   │       ├── TestRunner.ast
│   │       ├── TestRunner.bs.js
│   │       ├── TestRunner.cmi
│   │       ├── TestRunner.cmj
│   │       ├── TestRunner.cmt
│   │       ├── TestRunner.res
│   │       └── unit
│   │           ├── GeoUtilsTest.ast
│   │           ├── GeoUtilsTest.bs.js
│   │           ├── GeoUtilsTest.cmi
│   │           ├── GeoUtilsTest.cmj
│   │           ├── GeoUtilsTest.cmt
│   │           ├── GeoUtilsTest.res
│   │           ├── PathInterpolationTest.ast
│   │           ├── PathInterpolationTest.bs.js
│   │           ├── PathInterpolationTest.cmi
│   │           ├── PathInterpolationTest.cmj
│   │           ├── PathInterpolationTest.cmt
│   │           ├── PathInterpolationTest.res
│   │           ├── ReducerTest.ast
│   │           ├── ReducerTest.bs.js
│   │           ├── ReducerTest.cmi
│   │           ├── ReducerTest.cmj
│   │           ├── ReducerTest.cmt
│   │           ├── ReducerTest.res
│   │           ├── SimulationSystemTest.ast
│   │           ├── SimulationSystemTest.bs.js
│   │           ├── SimulationSystemTest.cmi
│   │           ├── SimulationSystemTest.cmj
│   │           ├── SimulationSystemTest.cmt
│   │           ├── SimulationSystemTest.res
│   │           ├── TourLogicTest.ast
│   │           ├── TourLogicTest.bs.js
│   │           ├── TourLogicTest.cmi
│   │           ├── TourLogicTest.cmj
│   │           ├── TourLogicTest.cmt
│   │           └── TourLogicTest.res
│   ├── ocaml
│   │   ├── Actions.ast
│   │   ├── Actions.cmi
│   │   ├── Actions.cmj
│   │   ├── Actions.cmt
│   │   ├── Actions.res
│   │   ├── App.ast
│   │   ├── App.cmi
│   │   ├── App.cmj
│   │   ├── App.cmt
│   │   ├── App.res
│   │   ├── AppContext.ast
│   │   ├── AppContext.cmi
│   │   ├── AppContext.cmj
│   │   ├── AppContext.cmt
│   │   ├── AppContext.res
│   │   ├── AudioManager.ast
│   │   ├── AudioManager.cmi
│   │   ├── AudioManager.cmj
│   │   ├── AudioManager.cmt
│   │   ├── AudioManager.res
│   │   ├── BackendApi.ast
│   │   ├── BackendApi.cmi
│   │   ├── BackendApi.cmj
│   │   ├── BackendApi.cmt
│   │   ├── BackendApi.res
│   │   ├── ColorPalette.ast
│   │   ├── ColorPalette.cmi
│   │   ├── ColorPalette.cmj
│   │   ├── ColorPalette.cmt
│   │   ├── ColorPalette.res
│   │   ├── Constants.ast
│   │   ├── Constants.cmi
│   │   ├── Constants.cmj
│   │   ├── Constants.cmt
│   │   ├── Constants.res
│   │   ├── DownloadSystem.ast
│   │   ├── DownloadSystem.cmi
│   │   ├── DownloadSystem.cmj
│   │   ├── DownloadSystem.cmt
│   │   ├── DownloadSystem.res
│   │   ├── EventBus.ast
│   │   ├── EventBus.cmi
│   │   ├── EventBus.cmj
│   │   ├── EventBus.cmt
│   │   ├── EventBus.res
│   │   ├── ExifParser.ast
│   │   ├── ExifParser.cmi
│   │   ├── ExifParser.cmj
│   │   ├── ExifParser.cmt
│   │   ├── ExifParser.res
│   │   ├── ExifReportGenerator.ast
│   │   ├── ExifReportGenerator.cmi
│   │   ├── ExifReportGenerator.cmj
│   │   ├── ExifReportGenerator.cmt
│   │   ├── ExifReportGenerator.res
│   │   ├── Exporter.ast
│   │   ├── Exporter.cmi
│   │   ├── Exporter.cmj
│   │   ├── Exporter.cmt
│   │   ├── Exporter.res
│   │   ├── GeoUtils.ast
│   │   ├── GeoUtils.cmi
│   │   ├── GeoUtils.cmj
│   │   ├── GeoUtils.cmt
│   │   ├── GeoUtils.res
│   │   ├── GeoUtilsTest.ast
│   │   ├── GeoUtilsTest.cmi
│   │   ├── GeoUtilsTest.cmj
│   │   ├── GeoUtilsTest.cmt
│   │   ├── GeoUtilsTest.res
│   │   ├── GlobalStateBridge.ast
│   │   ├── GlobalStateBridge.cmi
│   │   ├── GlobalStateBridge.cmj
│   │   ├── GlobalStateBridge.cmt
│   │   ├── GlobalStateBridge.res
│   │   ├── HotspotLine.ast
│   │   ├── HotspotLine.cmi
│   │   ├── HotspotLine.cmj
│   │   ├── HotspotLine.cmt
│   │   ├── HotspotLine.res
│   │   ├── HotspotManager.ast
│   │   ├── HotspotManager.cmi
│   │   ├── HotspotManager.cmj
│   │   ├── HotspotManager.cmt
│   │   ├── HotspotManager.res
│   │   ├── ImageAnalysis.ast
│   │   ├── ImageAnalysis.cmi
│   │   ├── ImageAnalysis.cmj
│   │   ├── ImageAnalysis.cmt
│   │   ├── ImageAnalysis.res
│   │   ├── InputSystem.ast
│   │   ├── InputSystem.cmi
│   │   ├── InputSystem.cmj
│   │   ├── InputSystem.cmt
│   │   ├── InputSystem.res
│   │   ├── LabelMenu.ast
│   │   ├── LabelMenu.cmi
│   │   ├── LabelMenu.cmj
│   │   ├── LabelMenu.cmt
│   │   ├── LabelMenu.res
│   │   ├── LinkModal.ast
│   │   ├── LinkModal.cmi
│   │   ├── LinkModal.cmj
│   │   ├── LinkModal.cmt
│   │   ├── LinkModal.res
│   │   ├── Logger.ast
│   │   ├── Logger.cmi
│   │   ├── Logger.cmj
│   │   ├── Logger.cmt
│   │   ├── Logger.res
│   │   ├── Main.ast
│   │   ├── Main.cmi
│   │   ├── Main.cmj
│   │   ├── Main.cmt
│   │   ├── Main.res
│   │   ├── ModalContext.ast
│   │   ├── ModalContext.cmi
│   │   ├── ModalContext.cmj
│   │   ├── ModalContext.cmt
│   │   ├── ModalContext.res
│   │   ├── Navigation.ast
│   │   ├── Navigation.cmi
│   │   ├── Navigation.cmj
│   │   ├── Navigation.cmt
│   │   ├── Navigation.res
│   │   ├── NavigationController.ast
│   │   ├── NavigationController.cmi
│   │   ├── NavigationController.cmj
│   │   ├── NavigationController.cmt
│   │   ├── NavigationController.res
│   │   ├── NavigationRenderer.ast
│   │   ├── NavigationRenderer.cmi
│   │   ├── NavigationRenderer.cmj
│   │   ├── NavigationRenderer.cmt
│   │   ├── NavigationRenderer.res
│   │   ├── NavigationUI.ast
│   │   ├── NavigationUI.cmi
│   │   ├── NavigationUI.cmj
│   │   ├── NavigationUI.cmt
│   │   ├── NavigationUI.res
│   │   ├── NotificationContext.ast
│   │   ├── NotificationContext.cmi
│   │   ├── NotificationContext.cmj
│   │   ├── NotificationContext.cmt
│   │   ├── NotificationContext.res
│   │   ├── PathInterpolation.ast
│   │   ├── PathInterpolation.cmi
│   │   ├── PathInterpolation.cmj
│   │   ├── PathInterpolation.cmt
│   │   ├── PathInterpolation.res
│   │   ├── PathInterpolationTest.ast
│   │   ├── PathInterpolationTest.cmi
│   │   ├── PathInterpolationTest.cmj
│   │   ├── PathInterpolationTest.cmt
│   │   ├── PathInterpolationTest.res
│   │   ├── ProgressBar.ast
│   │   ├── ProgressBar.cmi
│   │   ├── ProgressBar.cmj
│   │   ├── ProgressBar.cmt
│   │   ├── ProgressBar.res
│   │   ├── ProjectData.ast
│   │   ├── ProjectData.cmi
│   │   ├── ProjectData.cmj
│   │   ├── ProjectData.cmt
│   │   ├── ProjectData.res
│   │   ├── ProjectManager.ast
│   │   ├── ProjectManager.cmi
│   │   ├── ProjectManager.cmj
│   │   ├── ProjectManager.cmt
│   │   ├── ProjectManager.res
│   │   ├── ReBindings.ast
│   │   ├── ReBindings.cmi
│   │   ├── ReBindings.cmj
│   │   ├── ReBindings.cmt
│   │   ├── ReBindings.res
│   │   ├── Reducer.ast
│   │   ├── Reducer.cmi
│   │   ├── Reducer.cmj
│   │   ├── Reducer.cmt
│   │   ├── Reducer.res
│   │   ├── ReducerTest.ast
│   │   ├── ReducerTest.cmi
│   │   ├── ReducerTest.cmj
│   │   ├── ReducerTest.cmt
│   │   ├── ReducerTest.res
│   │   ├── Resizer.ast
│   │   ├── Resizer.cmi
│   │   ├── Resizer.cmj
│   │   ├── Resizer.cmt
│   │   ├── Resizer.res
│   │   ├── SceneList.ast
│   │   ├── SceneList.cmi
│   │   ├── SceneList.cmj
│   │   ├── SceneList.cmt
│   │   ├── SceneList.res
│   │   ├── ServerTeaser.ast
│   │   ├── ServerTeaser.cmi
│   │   ├── ServerTeaser.cmj
│   │   ├── ServerTeaser.cmt
│   │   ├── ServerTeaser.res
│   │   ├── Sidebar.ast
│   │   ├── Sidebar.cmi
│   │   ├── Sidebar.cmj
│   │   ├── Sidebar.cmt
│   │   ├── Sidebar.res
│   │   ├── SimulationChainSkipper.ast
│   │   ├── SimulationChainSkipper.cmi
│   │   ├── SimulationChainSkipper.cmj
│   │   ├── SimulationChainSkipper.cmt
│   │   ├── SimulationChainSkipper.res
│   │   ├── SimulationNavigation.ast
│   │   ├── SimulationNavigation.cmi
│   │   ├── SimulationNavigation.cmj
│   │   ├── SimulationNavigation.cmt
│   │   ├── SimulationNavigation.res
│   │   ├── SimulationPathGenerator.ast
│   │   ├── SimulationPathGenerator.cmi
│   │   ├── SimulationPathGenerator.cmj
│   │   ├── SimulationPathGenerator.cmt
│   │   ├── SimulationPathGenerator.res
│   │   ├── SimulationSystem.ast
│   │   ├── SimulationSystem.cmi
│   │   ├── SimulationSystem.cmj
│   │   ├── SimulationSystem.cmt
│   │   ├── SimulationSystem.res
│   │   ├── SimulationSystemTest.ast
│   │   ├── SimulationSystemTest.cmi
│   │   ├── SimulationSystemTest.cmj
│   │   ├── SimulationSystemTest.cmt
│   │   ├── SimulationSystemTest.res
│   │   ├── State.ast
│   │   ├── State.cmi
│   │   ├── State.cmj
│   │   ├── State.cmt
│   │   ├── State.res
│   │   ├── TeaserManager.ast
│   │   ├── TeaserManager.cmi
│   │   ├── TeaserManager.cmj
│   │   ├── TeaserManager.cmt
│   │   ├── TeaserManager.res
│   │   ├── TeaserPathfinder.ast
│   │   ├── TeaserPathfinder.cmi
│   │   ├── TeaserPathfinder.cmj
│   │   ├── TeaserPathfinder.cmt
│   │   ├── TeaserPathfinder.res
│   │   ├── TeaserRecorder.ast
│   │   ├── TeaserRecorder.cmi
│   │   ├── TeaserRecorder.cmj
│   │   ├── TeaserRecorder.cmt
│   │   ├── TeaserRecorder.res
│   │   ├── TestRunner.ast
│   │   ├── TestRunner.cmi
│   │   ├── TestRunner.cmj
│   │   ├── TestRunner.cmt
│   │   ├── TestRunner.res
│   │   ├── TourLogic.ast
│   │   ├── TourLogic.cmi
│   │   ├── TourLogic.cmj
│   │   ├── TourLogic.cmt
│   │   ├── TourLogic.res
│   │   ├── TourLogicTest.ast
│   │   ├── TourLogicTest.cmi
│   │   ├── TourLogicTest.cmj
│   │   ├── TourLogicTest.cmt
│   │   ├── TourLogicTest.res
│   │   ├── TourTemplates.cmi
│   │   ├── TourTemplates.cmj
│   │   ├── TourTemplates.cmt
│   │   ├── TourTemplates.res
│   │   ├── Types.ast
│   │   ├── Types.cmi
│   │   ├── Types.cmj
│   │   ├── Types.cmt
│   │   ├── Types.res
│   │   ├── UploadProcessor.ast
│   │   ├── UploadProcessor.cmi
│   │   ├── UploadProcessor.cmj
│   │   ├── UploadProcessor.cmt
│   │   ├── UploadProcessor.res
│   │   ├── UploadReport.ast
│   │   ├── UploadReport.cmi
│   │   ├── UploadReport.cmj
│   │   ├── UploadReport.cmt
│   │   ├── UploadReport.res
│   │   ├── VideoEncoder.ast
│   │   ├── VideoEncoder.cmi
│   │   ├── VideoEncoder.cmj
│   │   ├── VideoEncoder.cmt
│   │   ├── VideoEncoder.res
│   │   ├── ViewerFollow.ast
│   │   ├── ViewerFollow.cmi
│   │   ├── ViewerFollow.cmj
│   │   ├── ViewerFollow.cmt
│   │   ├── ViewerFollow.res
│   │   ├── ViewerLoader.ast
│   │   ├── ViewerLoader.cmi
│   │   ├── ViewerLoader.cmj
│   │   ├── ViewerLoader.cmt
│   │   ├── ViewerLoader.res
│   │   ├── ViewerManager.ast
│   │   ├── ViewerManager.cmi
│   │   ├── ViewerManager.cmj
│   │   ├── ViewerManager.cmt
│   │   ├── ViewerManager.res
│   │   ├── ViewerSnapshot.ast
│   │   ├── ViewerSnapshot.cmi
│   │   ├── ViewerSnapshot.cmj
│   │   ├── ViewerSnapshot.cmt
│   │   ├── ViewerSnapshot.res
│   │   ├── ViewerState.ast
│   │   ├── ViewerState.cmi
│   │   ├── ViewerState.cmj
│   │   ├── ViewerState.cmt
│   │   ├── ViewerState.res
│   │   ├── ViewerTypes.ast
│   │   ├── ViewerTypes.cmi
│   │   ├── ViewerTypes.cmj
│   │   ├── ViewerTypes.cmt
│   │   ├── ViewerTypes.res
│   │   ├── ViewerUI.ast
│   │   ├── ViewerUI.cmi
│   │   ├── ViewerUI.cmj
│   │   ├── ViewerUI.cmt
│   │   ├── ViewerUI.res
│   │   ├── VisualPipeline.ast
│   │   ├── VisualPipeline.cmi
│   │   ├── VisualPipeline.cmj
│   │   ├── VisualPipeline.cmt
│   │   └── VisualPipeline.res
│   └── rescript.lock
├── logs
│   └── log_changes.txt
├── package-lock.json
├── package.json
├── plans
│   ├── debug_telemetry_fix_plan.md
│   ├── logical_inconsistencies_analysis.md
│   └── step1_cleanup_notes.md
├── README.md
├── rescript.json
├── scripts
│   ├── cleanup_logs.sh
│   ├── commit.sh
│   ├── dev-mode.sh
│   ├── ensure-watcher.sh
│   ├── restore-snapshot.sh
│   ├── setup.sh
│   ├── test-logging.js
│   └── watch-file-limits.sh
├── sounds
│   └── click.wav
├── src
│   ├── App.bs.js
│   ├── App.res
│   ├── components
│   │   ├── HotspotManager.bs.js
│   │   ├── HotspotManager.res
│   │   ├── LabelMenu.bs.js
│   │   ├── LabelMenu.res
│   │   ├── LinkModal.bs.js
│   │   ├── LinkModal.res
│   │   ├── ModalContext.bs.js
│   │   ├── ModalContext.res
│   │   ├── NotificationContext.bs.js
│   │   ├── NotificationContext.res
│   │   ├── SceneList.bs.js
│   │   ├── SceneList.res
│   │   ├── Sidebar.bs.js
│   │   ├── Sidebar.res
│   │   ├── UploadReport.bs.js
│   │   ├── UploadReport.res
│   │   ├── ViewerFollow.bs.js
│   │   ├── ViewerFollow.res
│   │   ├── ViewerLoader.bs.js
│   │   ├── ViewerLoader.res
│   │   ├── ViewerManager.bs.js
│   │   ├── ViewerManager.res
│   │   ├── ViewerSnapshot.bs.js
│   │   ├── ViewerSnapshot.res
│   │   ├── ViewerState.bs.js
│   │   ├── ViewerState.res
│   │   ├── ViewerTypes.bs.js
│   │   ├── ViewerTypes.res
│   │   ├── ViewerUI.bs.js
│   │   ├── ViewerUI.res
│   │   ├── VisualPipeline.bs.js
│   │   └── VisualPipeline.res
│   ├── core
│   │   ├── Actions.bs.js
│   │   ├── Actions.res
│   │   ├── AppContext.bs.js
│   │   ├── AppContext.res
│   │   ├── GlobalStateBridge.bs.js
│   │   ├── GlobalStateBridge.res
│   │   ├── Reducer.bs.js
│   │   ├── Reducer.res
│   │   ├── State.bs.js
│   │   ├── State.res
│   │   ├── Types.bs.js
│   │   └── Types.res
│   ├── libs
│   │   ├── FileSaver.min.js
│   │   ├── jszip.min.js
│   │   ├── pannellum.css
│   │   └── pannellum.js
│   ├── Main.bs.js
│   ├── Main.res
│   ├── ReBindings.bs.js
│   ├── ReBindings.res
│   ├── systems
│   │   ├── AudioManager.bs.js
│   │   ├── AudioManager.res
│   │   ├── BackendApi.bs.js
│   │   ├── BackendApi.res
│   │   ├── DownloadSystem.bs.js
│   │   ├── DownloadSystem.res
│   │   ├── EventBus.bs.js
│   │   ├── EventBus.res
│   │   ├── ExifParser.bs.js
│   │   ├── ExifParser.res
│   │   ├── ExifReportGenerator.bs.js
│   │   ├── ExifReportGenerator.res
│   │   ├── Exporter.bs.js
│   │   ├── Exporter.res
│   │   ├── HotspotLine.bs.js
│   │   ├── HotspotLine.res
│   │   ├── ImageAnalysis.bs.js
│   │   ├── ImageAnalysis.res
│   │   ├── InputSystem.bs.js
│   │   ├── InputSystem.res
│   │   ├── Navigation.bs.js
│   │   ├── Navigation.res
│   │   ├── NavigationController.bs.js
│   │   ├── NavigationController.res
│   │   ├── NavigationRenderer.bs.js
│   │   ├── NavigationRenderer.res
│   │   ├── NavigationUI.bs.js
│   │   ├── NavigationUI.res
│   │   ├── ProjectData.bs.js
│   │   ├── ProjectData.res
│   │   ├── ProjectManager.bs.js
│   │   ├── ProjectManager.res
│   │   ├── Resizer.bs.js
│   │   ├── Resizer.res
│   │   ├── ServerTeaser.bs.js
│   │   ├── ServerTeaser.res
│   │   ├── SimulationChainSkipper.bs.js
│   │   ├── SimulationChainSkipper.res
│   │   ├── SimulationNavigation.bs.js
│   │   ├── SimulationNavigation.res
│   │   ├── SimulationPathGenerator.bs.js
│   │   ├── SimulationPathGenerator.res
│   │   ├── SimulationSystem.bs.js
│   │   ├── SimulationSystem.res
│   │   ├── TeaserManager.bs.js
│   │   ├── TeaserManager.res
│   │   ├── TeaserPathfinder.bs.js
│   │   ├── TeaserPathfinder.res
│   │   ├── TeaserRecorder.bs.js
│   │   ├── TeaserRecorder.res
│   │   ├── TourTemplates.bs.js
│   │   ├── TourTemplates.res
│   │   ├── UploadProcessor.bs.js
│   │   ├── UploadProcessor.res
│   │   ├── VideoEncoder.bs.js
│   │   └── VideoEncoder.res
│   ├── utils
│   │   ├── ColorPalette.bs.js
│   │   ├── ColorPalette.res
│   │   ├── Constants.bs.js
│   │   ├── Constants.res
│   │   ├── GeoUtils.bs.js
│   │   ├── GeoUtils.res
│   │   ├── Logger.bs.js
│   │   ├── Logger.res
│   │   ├── PathInterpolation.bs.js
│   │   ├── PathInterpolation.res
│   │   ├── ProgressBar.bs.js
│   │   ├── ProgressBar.res
│   │   ├── TourLogic.bs.js
│   │   └── TourLogic.res
│   └── version.js
├── start_dev.sh
├── start_prod.sh
├── tailwind.config.js
├── tasks
│   ├── completed
│   │   ├── 01_Architecture_Functional_State_REPORT.md
│   │   ├── 02_Implement_App_Context_REPORT.md
│   │   ├── 03_Refactor_Components_REPORT.md
│   │   ├── 04_Functional_ProjectManager_REPORT.md
│   │   ├── 05_Purify_Navigation_REPORT.md
│   │   ├── 06_Final_Cleanup_REPORT.md
│   │   ├── 10_ReScript_Migrate_Resizer_REPORT.md
│   │   ├── 11_ReScript_Migrate_ProjectManager_REPORT.md
│   │   ├── 12_ReScript_Migrate_UI_Components_REPORT.md
│   │   ├── 14_ReScript_Migrate_Viewer_REPORT.md
│   │   ├── 15_Backend_SingleZIP_Load_REPORT.md
│   │   ├── 16_Backend_Project_Validation_REPORT.md
│   │   ├── 17_Backend_Filename_Suggestion_REPORT.md
│   │   ├── 18_Frontend_SingleZIP_Integration_REPORT.md
│   │   ├── 19_Cleanup_Duplicate_Utilities_REPORT.md
│   │   ├── 20_Cleanup_Legacy_CSS_and_Backups_REPORT.md
│   │   ├── 21_Migrate_Viewer_Snapshot_System_REPORT.md
│   │   ├── 22_Migrate_Viewer_Dual_Pannellum_REPORT.md
│   │   ├── 23_Migrate_Visual_Pipeline_REPORT.md
│   │   ├── 24_Migrate_Exporter_Systems_REPORT.md
│   │   ├── 25_Migrate_Exif_Report_Generator.md
│   │   ├── 26_Unified_Backend_API_Module_REPORT.md
│   │   ├── 27_Migrate_Supporting_Systems_REPORT.md
│   │   ├── 28_Migrate_Cache_Video_Systems_REPORT.md
│   │   ├── 29_Refactor_Teaser_Logic_REPORT.md
│   │   ├── 30_Eliminate_JS_Adapters_REPORT.md
│   │   ├── 30_Logging_Backend_Endpoints_REPORT.md
│   │   ├── 31_Final_Polish_And_Cleanup_REPORT.md
│   │   ├── 31_Logging_Rust_Internal_Tracing_REPORT.md
│   │   ├── 32_Logging_Migrate_Navigation_REPORT.md
│   │   ├── 33_Logging_Migrate_ViewerLoader_REPORT.md
│   │   ├── 34_Logging_Migrate_HotspotManager_REPORT.md
│   │   ├── 34_Logging_Project_Persistence_REPORT.md
│   │   ├── 35_Logging_Migrate_SimulationSystem_REPORT.md
│   │   ├── 36_Logging_Migrate_Exporter_REPORT.md
│   │   ├── 37_Logging_Migrate_UploadProcessor_REPORT.md
│   │   ├── 38_Logging_Migrate_InputSystem_REPORT.md
│   │   ├── 39_Logging_Migrate_NavigationRenderer_REPORT.md
│   │   ├── 40_Logging_Migrate_VideoEncoder_REPORT.md
│   │   ├── 41_Logging_Migrate_Store_REPORT.md
│   │   ├── 42_Logging_Migrate_TeaserSystem_REPORT.md
│   │   ├── 43_Logging_Migrate_Sidebar_REPORT.md
│   │   ├── 44_Logging_Debug_Shortcuts_REPORT.md
│   │   ├── 45_Logging_Migrate_Remaining_Modules_REPORT.md
│   │   ├── 46_Logging_Rotation_Cleanup_REPORT.md
│   │   ├── 47_Logging_Integration_Tests_REPORT.md
│   │   ├── 48_Backend_Pure_Validation_Refactor_REPORT.md
│   │   ├── 49_Backend_Standardize_Logging_REPORT.md
│   │   ├── 50_Backend_Remove_Unwrap_REPORT.md
│   │   ├── 51_Backend_LogError_Endpoint_REPORT.md
│   │   ├── 52_Backend_Functional_Iterators_REPORT.md
│   │   ├── 53_Migrate_Logging_System_REPORT.md
│   │   ├── 54_Migrate_EventBus_REPORT.md
│   │   ├── 55_Migrate_UI_Contexts_REPORT.md
│   │   ├── 56_Backend_Project_Loading_REPORT.md
│   │   ├── 57_Backend_Pathfinding_REPORT.md
│   │   ├── 58_Migrate_Entry_Point_REPORT.md
│   │   ├── 59_Backend_Reverse_Geocoding_Endpoint_REPORT.md
│   │   ├── 60_Backend_Remove_Unwrap_Calls_REPORT.md
│   │   ├── 61_Backend_Geocoding_Cache_Layer_REPORT.md
│   │   ├── 62_Backend_Batch_Similarity_Endpoint_REPORT.md
│   │   ├── 63_Refactor_SimulationSystem_State_REPORT.md
│   │   ├── 64_Migrate_Constants_To_ReScript_REPORT.md
│   │   ├── 65_Cleanup_Dead_Code_REPORT.md
│   │   ├── 66_Extract_Backend_Domain_Types_REPORT.md
│   │   ├── 67_Extract_Media_Service_REPORT.md
│   │   ├── 68_Extract_Project_Service_REPORT.md
│   │   ├── 69_Extract_Geocoding_Service_REPORT.md
│   │   ├── 71_Pathfinder_Hardening_REPORT.md
│   │   ├── 73_Refactor_media_REPORT.md
│   │   ├── 74_Refactor_SimulationSystem_REPORT.md
│   │   ├── 75_Fix_IndexHTML_Critical_Bugs_REPORT.md
│   │   ├── 76_Fix_ReScript_Shadowing_Warnings_REPORT.md
│   │   ├── 77_Eliminate_ObjMagic_BackendApi_REPORT.md
│   │   ├── 78_Improve_Error_Handling_BackendApi_REPORT.md
│   │   ├── 79_Remove_Unused_Backend_Import_REPORT.md
│   │   ├── 80_Add_Frontend_Unit_Tests_REPORT.md
│   │   ├── 81_Expand_Backend_Test_Coverage_REPORT.md
│   │   ├── CONSOLIDATED_TASK_SUMMARIES_REPORT.md
│   │   └── README.md
│   ├── pending
│   │   ├── 82_Add_Rust_Documentation_Comments.md
│   │   ├── 83_Implement_Code_Splitting.md
│   │   ├── 84_Implement_Service_Worker.md
│   │   ├── 85_Refactor_TourTemplates_Module.md
│   │   ├── 86_Refactor_Reducer_Module.md
│   │   ├── 87_Update_Version_References.md
│   │   └── 88_Eliminate_ObjMagic_Reducer.md
│   └── README.md
└── tests
    ├── integration
    ├── TestRunner.bs.js
    ├── TestRunner.res
    └── unit
        ├── GeoUtilsTest.bs.js
        ├── GeoUtilsTest.res
        ├── PathInterpolationTest.bs.js
        ├── PathInterpolationTest.res
        ├── ReducerTest.bs.js
        ├── ReducerTest.res
        ├── SimulationSystemTest.bs.js
        ├── SimulationSystemTest.res
        ├── TourLogicTest.bs.js
        └── TourLogicTest.res

39 directories, 1033 files
