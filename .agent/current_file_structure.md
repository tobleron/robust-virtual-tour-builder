.
├── ANALYSIS_REPORT.md
├── CHANGELOG.md
├── FIX_PROJECT_NAME_BUG.md
├── GEMINI.md
├── MAP.md
├── README.md
├── REQUIREMENTS.txt
├── backend
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── backend.log
│   ├── backend_run.log
│   ├── bin
│   │   └── ffmpeg
│   ├── migrations
│   │   └── 20260124000000_init.sql
│   ├── src
│   │   ├── api
│   │   │   ├── auth.rs
│   │   │   ├── geocoding.rs
│   │   │   ├── media
│   │   │   │   ├── image.rs
│   │   │   │   ├── mod.rs
│   │   │   │   ├── serve.rs
│   │   │   │   ├── similarity.rs
│   │   │   │   └── video.rs
│   │   │   ├── mod.rs
│   │   │   ├── project
│   │   │   │   ├── export.rs
│   │   │   │   ├── mod.rs
│   │   │   │   ├── navigation.rs
│   │   │   │   ├── storage.rs
│   │   │   │   └── validation.rs
│   │   │   ├── telemetry.rs
│   │   │   └── utils.rs
│   │   ├── lib.rs
│   │   ├── main.rs
│   │   ├── metrics.rs
│   │   ├── middleware
│   │   │   ├── mod.rs
│   │   │   ├── quota_check.rs
│   │   │   └── request_tracker.rs
│   │   ├── models
│   │   │   ├── errors.rs
│   │   │   ├── mod.rs
│   │   │   ├── project.rs
│   │   │   └── user.rs
│   │   ├── pathfinder
│   │   │   ├── algorithms.rs
│   │   │   ├── graph.rs
│   │   │   ├── mod.rs
│   │   │   └── utils.rs
│   │   └── services
│   │       ├── auth.rs
│   │       ├── database.rs
│   │       ├── geocoding.rs
│   │       ├── media.rs
│   │       ├── mod.rs
│   │       ├── project
│   │       │   ├── load.rs
│   │       │   ├── mod.rs
│   │       │   ├── package.rs
│   │       │   └── validate.rs
│   │       ├── shutdown.rs
│   │       ├── upload_quota.rs
│   │       └── upload_quota_tests.rs
│   ├── startup.log
│   ├── startup_debug.log
│   ├── startup_debug_v2.log
│   ├── startup_log.txt
│   └── tests
│       └── shutdown_test.rs
├── bin
│   └── tailwindcss
├── build_output.txt
├── build_output_clean.txt
├── build_warnings.txt
├── cache
│   └── geocoding.json
├── components.json
├── css
│   ├── animations.css
│   ├── base.css
│   ├── components
│   │   ├── buttons.css
│   │   ├── error-fallback.css
│   │   ├── floor-nav.css
│   │   ├── label-menu.css
│   │   ├── modals.css
│   │   ├── popover.css
│   │   ├── scene-groups.css
│   │   ├── ui.css
│   │   ├── upload-report.css
│   │   └── viewer.css
│   ├── layout.css
│   ├── legacy.css
│   ├── output.css
│   ├── style.css
│   ├── tailwind.css
│   └── variables.css
├── data
│   └── storage
├── dev.log
├── docs
│   ├── ARCHITECTURE.md
│   ├── AUTOPILOT_SIMULATION_ANALYSIS.md
│   ├── AUTOPILOT_TASKS_SUMMARY.md
│   ├── DESIGN_SYSTEM.md
│   ├── DEVELOPMENT_GUIDELINES.md
│   ├── INITIALIZATION_STANDARDS.md
│   ├── PROJECT_EVOLUTION.md
│   ├── QUALITY_ASSURANCE_AUDITS.md
│   ├── TESTING_STRATEGY.md
│   ├── _pending_integration
│   │   ├── 024_e2e_performance_analysis.md
│   │   ├── ANALYSIS_REPORT_JULES.md
│   │   ├── BUG_ANALYSIS_PROJECT_NAME.md
│   │   ├── SESSION_SUMMARY.md
│   │   └── TASK_ANALYSIS_AND_RENUMBERING.md
│   └── openapi.yaml
├── full_build_output.txt
├── icons.txt
├── index.html
├── jsconfig.json
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
│   │   │   ├── ServiceWorker.ast
│   │   │   ├── ServiceWorker.bs.js
│   │   │   ├── ServiceWorker.cmi
│   │   │   ├── ServiceWorker.cmj
│   │   │   ├── ServiceWorker.cmt
│   │   │   ├── ServiceWorker.res
│   │   │   ├── ServiceWorkerMain.ast
│   │   │   ├── ServiceWorkerMain.bs.js
│   │   │   ├── ServiceWorkerMain.cmi
│   │   │   ├── ServiceWorkerMain.cmj
│   │   │   ├── ServiceWorkerMain.cmt
│   │   │   ├── ServiceWorkerMain.res
│   │   │   ├── components
│   │   │   │   ├── AppErrorBoundary.ast
│   │   │   │   ├── AppErrorBoundary.bs.js
│   │   │   │   ├── AppErrorBoundary.cmi
│   │   │   │   ├── AppErrorBoundary.cmj
│   │   │   │   ├── AppErrorBoundary.cmt
│   │   │   │   ├── AppErrorBoundary.res
│   │   │   │   ├── ErrorFallbackUI.ast
│   │   │   │   ├── ErrorFallbackUI.bs.js
│   │   │   │   ├── ErrorFallbackUI.cmi
│   │   │   │   ├── ErrorFallbackUI.cmj
│   │   │   │   ├── ErrorFallbackUI.cmt
│   │   │   │   ├── ErrorFallbackUI.res
│   │   │   │   ├── HotspotActionMenu.ast
│   │   │   │   ├── HotspotActionMenu.bs.js
│   │   │   │   ├── HotspotActionMenu.cmi
│   │   │   │   ├── HotspotActionMenu.cmj
│   │   │   │   ├── HotspotActionMenu.cmt
│   │   │   │   ├── HotspotActionMenu.res
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
│   │   │   │   ├── PopOver.ast
│   │   │   │   ├── PopOver.bs.js
│   │   │   │   ├── PopOver.cmi
│   │   │   │   ├── PopOver.cmj
│   │   │   │   ├── PopOver.cmt
│   │   │   │   ├── PopOver.res
│   │   │   │   ├── Portal.ast
│   │   │   │   ├── Portal.bs.js
│   │   │   │   ├── Portal.cmi
│   │   │   │   ├── Portal.cmj
│   │   │   │   ├── Portal.cmt
│   │   │   │   ├── Portal.res
│   │   │   │   ├── PreviewArrow.ast
│   │   │   │   ├── PreviewArrow.bs.js
│   │   │   │   ├── PreviewArrow.cmi
│   │   │   │   ├── PreviewArrow.cmj
│   │   │   │   ├── PreviewArrow.cmt
│   │   │   │   ├── PreviewArrow.res
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
│   │   │   │   ├── Tooltip.ast
│   │   │   │   ├── Tooltip.bs.js
│   │   │   │   ├── Tooltip.cmi
│   │   │   │   ├── Tooltip.cmj
│   │   │   │   ├── Tooltip.cmt
│   │   │   │   ├── Tooltip.res
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
│   │   │   │   ├── VisualPipeline.res
│   │   │   │   └── ui
│   │   │   │       ├── LucideIcons.ast
│   │   │   │       ├── LucideIcons.bs.js
│   │   │   │       ├── LucideIcons.cmi
│   │   │   │       ├── LucideIcons.cmj
│   │   │   │       ├── LucideIcons.cmt
│   │   │   │       ├── LucideIcons.res
│   │   │   │       ├── Shadcn.ast
│   │   │   │       ├── Shadcn.bs.js
│   │   │   │       ├── Shadcn.cmi
│   │   │   │       ├── Shadcn.cmj
│   │   │   │       ├── Shadcn.cmt
│   │   │   │       └── Shadcn.res
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
│   │   │   │   ├── JsonTypes.ast
│   │   │   │   ├── JsonTypes.bs.js
│   │   │   │   ├── JsonTypes.cmi
│   │   │   │   ├── JsonTypes.cmj
│   │   │   │   ├── JsonTypes.cmt
│   │   │   │   ├── JsonTypes.res
│   │   │   │   ├── Reducer.ast
│   │   │   │   ├── Reducer.bs.js
│   │   │   │   ├── Reducer.cmi
│   │   │   │   ├── Reducer.cmj
│   │   │   │   ├── Reducer.cmt
│   │   │   │   ├── Reducer.res
│   │   │   │   ├── ReducerHelpers.ast
│   │   │   │   ├── ReducerHelpers.bs.js
│   │   │   │   ├── ReducerHelpers.cmi
│   │   │   │   ├── ReducerHelpers.cmj
│   │   │   │   ├── ReducerHelpers.cmt
│   │   │   │   ├── ReducerHelpers.res
│   │   │   │   ├── SharedTypes.ast
│   │   │   │   ├── SharedTypes.bs.js
│   │   │   │   ├── SharedTypes.cmi
│   │   │   │   ├── SharedTypes.cmj
│   │   │   │   ├── SharedTypes.cmt
│   │   │   │   ├── SharedTypes.res
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
│   │   │   │   ├── Types.res
│   │   │   │   └── reducers
│   │   │   │       ├── HotspotReducer.ast
│   │   │   │       ├── HotspotReducer.bs.js
│   │   │   │       ├── HotspotReducer.cmi
│   │   │   │       ├── HotspotReducer.cmj
│   │   │   │       ├── HotspotReducer.cmt
│   │   │   │       ├── HotspotReducer.res
│   │   │   │       ├── NavigationReducer.ast
│   │   │   │       ├── NavigationReducer.bs.js
│   │   │   │       ├── NavigationReducer.cmi
│   │   │   │       ├── NavigationReducer.cmj
│   │   │   │       ├── NavigationReducer.cmt
│   │   │   │       ├── NavigationReducer.res
│   │   │   │       ├── ProjectReducer.ast
│   │   │   │       ├── ProjectReducer.bs.js
│   │   │   │       ├── ProjectReducer.cmi
│   │   │   │       ├── ProjectReducer.cmj
│   │   │   │       ├── ProjectReducer.cmt
│   │   │   │       ├── ProjectReducer.res
│   │   │   │       ├── RootReducer.ast
│   │   │   │       ├── RootReducer.bs.js
│   │   │   │       ├── RootReducer.cmi
│   │   │   │       ├── RootReducer.cmj
│   │   │   │       ├── RootReducer.cmt
│   │   │   │       ├── RootReducer.res
│   │   │   │       ├── SceneReducer.ast
│   │   │   │       ├── SceneReducer.bs.js
│   │   │   │       ├── SceneReducer.cmi
│   │   │   │       ├── SceneReducer.cmj
│   │   │   │       ├── SceneReducer.cmt
│   │   │   │       ├── SceneReducer.res
│   │   │   │       ├── SimulationReducer.ast
│   │   │   │       ├── SimulationReducer.bs.js
│   │   │   │       ├── SimulationReducer.cmi
│   │   │   │       ├── SimulationReducer.cmj
│   │   │   │       ├── SimulationReducer.cmt
│   │   │   │       ├── SimulationReducer.res
│   │   │   │       ├── TimelineReducer.ast
│   │   │   │       ├── TimelineReducer.bs.js
│   │   │   │       ├── TimelineReducer.cmi
│   │   │   │       ├── TimelineReducer.cmj
│   │   │   │       ├── TimelineReducer.cmt
│   │   │   │       ├── TimelineReducer.res
│   │   │   │       ├── UiReducer.ast
│   │   │   │       ├── UiReducer.bs.js
│   │   │   │       ├── UiReducer.cmi
│   │   │   │       ├── UiReducer.cmj
│   │   │   │       ├── UiReducer.cmt
│   │   │   │       ├── UiReducer.res
│   │   │   │       ├── mod.ast
│   │   │   │       ├── mod.bs.js
│   │   │   │       ├── mod.cmi
│   │   │   │       ├── mod.cmj
│   │   │   │       ├── mod.cmt
│   │   │   │       └── mod.res
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
│   │   │   │   ├── HotspotLineLogic.ast
│   │   │   │   ├── HotspotLineLogic.bs.js
│   │   │   │   ├── HotspotLineLogic.cmi
│   │   │   │   ├── HotspotLineLogic.cmj
│   │   │   │   ├── HotspotLineLogic.cmt
│   │   │   │   ├── HotspotLineLogic.res
│   │   │   │   ├── HotspotLineTypes.ast
│   │   │   │   ├── HotspotLineTypes.bs.js
│   │   │   │   ├── HotspotLineTypes.cmi
│   │   │   │   ├── HotspotLineTypes.cmj
│   │   │   │   ├── HotspotLineTypes.cmt
│   │   │   │   ├── HotspotLineTypes.res
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
│   │   │   │   ├── SimulationDriver.ast
│   │   │   │   ├── SimulationDriver.bs.js
│   │   │   │   ├── SimulationDriver.cmi
│   │   │   │   ├── SimulationDriver.cmj
│   │   │   │   ├── SimulationDriver.cmt
│   │   │   │   ├── SimulationDriver.res
│   │   │   │   ├── SimulationLogic.ast
│   │   │   │   ├── SimulationLogic.bs.js
│   │   │   │   ├── SimulationLogic.cmi
│   │   │   │   ├── SimulationLogic.cmj
│   │   │   │   ├── SimulationLogic.cmt
│   │   │   │   ├── SimulationLogic.res
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
│   │   │   │   ├── SvgManager.ast
│   │   │   │   ├── SvgManager.bs.js
│   │   │   │   ├── SvgManager.cmi
│   │   │   │   ├── SvgManager.cmj
│   │   │   │   ├── SvgManager.cmt
│   │   │   │   ├── SvgManager.res
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
│   │   │   │   ├── TourTemplateAssets.ast
│   │   │   │   ├── TourTemplateAssets.bs.js
│   │   │   │   ├── TourTemplateAssets.cmi
│   │   │   │   ├── TourTemplateAssets.cmj
│   │   │   │   ├── TourTemplateAssets.cmt
│   │   │   │   ├── TourTemplateAssets.res
│   │   │   │   ├── TourTemplateScripts.ast
│   │   │   │   ├── TourTemplateScripts.bs.js
│   │   │   │   ├── TourTemplateScripts.cmi
│   │   │   │   ├── TourTemplateScripts.cmj
│   │   │   │   ├── TourTemplateScripts.cmt
│   │   │   │   ├── TourTemplateScripts.res
│   │   │   │   ├── TourTemplateStyles.ast
│   │   │   │   ├── TourTemplateStyles.bs.js
│   │   │   │   ├── TourTemplateStyles.cmi
│   │   │   │   ├── TourTemplateStyles.cmj
│   │   │   │   ├── TourTemplateStyles.cmt
│   │   │   │   ├── TourTemplateStyles.res
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
│   │   │   │   ├── UploadProcessorLogic.ast
│   │   │   │   ├── UploadProcessorLogic.bs.js
│   │   │   │   ├── UploadProcessorLogic.cmi
│   │   │   │   ├── UploadProcessorLogic.cmj
│   │   │   │   ├── UploadProcessorLogic.cmt
│   │   │   │   ├── UploadProcessorLogic.res
│   │   │   │   ├── UploadProcessorTypes.ast
│   │   │   │   ├── UploadProcessorTypes.bs.js
│   │   │   │   ├── UploadProcessorTypes.cmi
│   │   │   │   ├── UploadProcessorTypes.cmj
│   │   │   │   ├── UploadProcessorTypes.cmt
│   │   │   │   ├── UploadProcessorTypes.res
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
│   │   │       ├── ImageOptimizer.ast
│   │   │       ├── ImageOptimizer.bs.js
│   │   │       ├── ImageOptimizer.cmi
│   │   │       ├── ImageOptimizer.cmj
│   │   │       ├── ImageOptimizer.cmt
│   │   │       ├── ImageOptimizer.cmti
│   │   │       ├── ImageOptimizer.iast
│   │   │       ├── ImageOptimizer.res
│   │   │       ├── ImageOptimizer.resi
│   │   │       ├── LazyLoad.ast
│   │   │       ├── LazyLoad.bs.js
│   │   │       ├── LazyLoad.cmi
│   │   │       ├── LazyLoad.cmj
│   │   │       ├── LazyLoad.cmt
│   │   │       ├── LazyLoad.res
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
│   │   │       ├── RequestQueue.ast
│   │   │       ├── RequestQueue.bs.js
│   │   │       ├── RequestQueue.cmi
│   │   │       ├── RequestQueue.cmj
│   │   │       ├── RequestQueue.cmt
│   │   │       ├── RequestQueue.res
│   │   │       ├── SessionStore.ast
│   │   │       ├── SessionStore.bs.js
│   │   │       ├── SessionStore.cmi
│   │   │       ├── SessionStore.cmj
│   │   │       ├── SessionStore.cmt
│   │   │       ├── SessionStore.res
│   │   │       ├── StateInspector.ast
│   │   │       ├── StateInspector.bs.js
│   │   │       ├── StateInspector.cmi
│   │   │       ├── StateInspector.cmj
│   │   │       ├── StateInspector.cmt
│   │   │       ├── StateInspector.res
│   │   │       ├── TourLogic.ast
│   │   │       ├── TourLogic.bs.js
│   │   │       ├── TourLogic.cmi
│   │   │       ├── TourLogic.cmj
│   │   │       ├── TourLogic.cmt
│   │   │       ├── TourLogic.res
│   │   │       ├── UrlUtils.ast
│   │   │       ├── UrlUtils.bs.js
│   │   │       ├── UrlUtils.cmi
│   │   │       ├── UrlUtils.cmj
│   │   │       ├── UrlUtils.cmt
│   │   │       ├── UrlUtils.res
│   │   │       ├── Version.ast
│   │   │       ├── Version.bs.js
│   │   │       ├── Version.cmi
│   │   │       ├── Version.cmj
│   │   │       ├── Version.cmt
│   │   │       ├── Version.res
│   │   │       ├── VersionData.ast
│   │   │       ├── VersionData.bs.js
│   │   │       ├── VersionData.cmi
│   │   │       ├── VersionData.cmj
│   │   │       ├── VersionData.cmt
│   │   │       └── VersionData.res
│   │   └── tests
│   │       ├── TestRunner.ast
│   │       ├── TestRunner.bs.js
│   │       ├── TestRunner.cmi
│   │       ├── TestRunner.cmj
│   │       ├── TestRunner.cmt
│   │       ├── TestRunner.res
│   │       └── unit
│   │           ├── Actions_v.test.ast
│   │           ├── Actions_v.test.bs.js
│   │           ├── Actions_v.test.cmi
│   │           ├── Actions_v.test.cmj
│   │           ├── Actions_v.test.cmt
│   │           ├── Actions_v.test.res
│   │           ├── AppContext_v.test.ast
│   │           ├── AppContext_v.test.bs.js
│   │           ├── AppContext_v.test.cmi
│   │           ├── AppContext_v.test.cmj
│   │           ├── AppContext_v.test.cmt
│   │           ├── AppContext_v.test.res
│   │           ├── AppErrorBoundary_v.test.ast
│   │           ├── AppErrorBoundary_v.test.bs.js
│   │           ├── AppErrorBoundary_v.test.cmi
│   │           ├── AppErrorBoundary_v.test.cmj
│   │           ├── AppErrorBoundary_v.test.cmt
│   │           ├── AppErrorBoundary_v.test.res
│   │           ├── App_v.test.ast
│   │           ├── App_v.test.bs.js
│   │           ├── App_v.test.cmi
│   │           ├── App_v.test.cmj
│   │           ├── App_v.test.cmt
│   │           ├── App_v.test.res
│   │           ├── AudioManager_v.test.ast
│   │           ├── AudioManager_v.test.bs.js
│   │           ├── AudioManager_v.test.cmi
│   │           ├── AudioManager_v.test.cmj
│   │           ├── AudioManager_v.test.cmt
│   │           ├── AudioManager_v.test.res
│   │           ├── BackendApi_v.test.ast
│   │           ├── BackendApi_v.test.bs.js
│   │           ├── BackendApi_v.test.cmi
│   │           ├── BackendApi_v.test.cmj
│   │           ├── BackendApi_v.test.cmt
│   │           ├── BackendApi_v.test.res
│   │           ├── ColorPalette_v.test.ast
│   │           ├── ColorPalette_v.test.bs.js
│   │           ├── ColorPalette_v.test.cmi
│   │           ├── ColorPalette_v.test.cmj
│   │           ├── ColorPalette_v.test.cmt
│   │           ├── ColorPalette_v.test.res
│   │           ├── Constants_v.test.ast
│   │           ├── Constants_v.test.bs.js
│   │           ├── Constants_v.test.cmi
│   │           ├── Constants_v.test.cmj
│   │           ├── Constants_v.test.cmt
│   │           ├── Constants_v.test.res
│   │           ├── DownloadSystem_v.test.ast
│   │           ├── DownloadSystem_v.test.bs.js
│   │           ├── DownloadSystem_v.test.cmi
│   │           ├── DownloadSystem_v.test.cmj
│   │           ├── DownloadSystem_v.test.cmt
│   │           ├── DownloadSystem_v.test.res
│   │           ├── ErrorFallbackUI_v.test.ast
│   │           ├── ErrorFallbackUI_v.test.bs.js
│   │           ├── ErrorFallbackUI_v.test.cmi
│   │           ├── ErrorFallbackUI_v.test.cmj
│   │           ├── ErrorFallbackUI_v.test.cmt
│   │           ├── ErrorFallbackUI_v.test.res
│   │           ├── EventBus_v.test.ast
│   │           ├── EventBus_v.test.bs.js
│   │           ├── EventBus_v.test.cmi
│   │           ├── EventBus_v.test.cmj
│   │           ├── EventBus_v.test.cmt
│   │           ├── EventBus_v.test.res
│   │           ├── ExifParser_v.test.ast
│   │           ├── ExifParser_v.test.bs.js
│   │           ├── ExifParser_v.test.cmi
│   │           ├── ExifParser_v.test.cmj
│   │           ├── ExifParser_v.test.cmt
│   │           ├── ExifParser_v.test.res
│   │           ├── ExifReportGenerator_v.test.ast
│   │           ├── ExifReportGenerator_v.test.bs.js
│   │           ├── ExifReportGenerator_v.test.cmi
│   │           ├── ExifReportGenerator_v.test.cmj
│   │           ├── ExifReportGenerator_v.test.cmt
│   │           ├── ExifReportGenerator_v.test.res
│   │           ├── Exporter_v.test.ast
│   │           ├── Exporter_v.test.bs.js
│   │           ├── Exporter_v.test.cmi
│   │           ├── Exporter_v.test.cmj
│   │           ├── Exporter_v.test.cmt
│   │           ├── Exporter_v.test.res
│   │           ├── GeoUtils_v.test.ast
│   │           ├── GeoUtils_v.test.bs.js
│   │           ├── GeoUtils_v.test.cmi
│   │           ├── GeoUtils_v.test.cmj
│   │           ├── GeoUtils_v.test.cmt
│   │           ├── GeoUtils_v.test.res
│   │           ├── GlobalStateBridge_v.test.ast
│   │           ├── GlobalStateBridge_v.test.bs.js
│   │           ├── GlobalStateBridge_v.test.cmi
│   │           ├── GlobalStateBridge_v.test.cmj
│   │           ├── GlobalStateBridge_v.test.cmt
│   │           ├── GlobalStateBridge_v.test.res
│   │           ├── HotspotActionMenu_v.test.ast
│   │           ├── HotspotActionMenu_v.test.bs.js
│   │           ├── HotspotActionMenu_v.test.cmi
│   │           ├── HotspotActionMenu_v.test.cmj
│   │           ├── HotspotActionMenu_v.test.cmt
│   │           ├── HotspotActionMenu_v.test.res
│   │           ├── HotspotLineLogic_v.test.ast
│   │           ├── HotspotLineLogic_v.test.bs.js
│   │           ├── HotspotLineLogic_v.test.cmi
│   │           ├── HotspotLineLogic_v.test.cmj
│   │           ├── HotspotLineLogic_v.test.cmt
│   │           ├── HotspotLineLogic_v.test.res
│   │           ├── HotspotLineTypes_v.test.ast
│   │           ├── HotspotLineTypes_v.test.bs.js
│   │           ├── HotspotLineTypes_v.test.cmi
│   │           ├── HotspotLineTypes_v.test.cmj
│   │           ├── HotspotLineTypes_v.test.cmt
│   │           ├── HotspotLineTypes_v.test.res
│   │           ├── HotspotLine_v.test.ast
│   │           ├── HotspotLine_v.test.bs.js
│   │           ├── HotspotLine_v.test.cmi
│   │           ├── HotspotLine_v.test.cmj
│   │           ├── HotspotLine_v.test.cmt
│   │           ├── HotspotLine_v.test.res
│   │           ├── HotspotManager_v.test.ast
│   │           ├── HotspotManager_v.test.bs.js
│   │           ├── HotspotManager_v.test.cmi
│   │           ├── HotspotManager_v.test.cmj
│   │           ├── HotspotManager_v.test.cmt
│   │           ├── HotspotManager_v.test.res
│   │           ├── HotspotReducer_v.test.ast
│   │           ├── HotspotReducer_v.test.bs.js
│   │           ├── HotspotReducer_v.test.cmi
│   │           ├── HotspotReducer_v.test.cmj
│   │           ├── HotspotReducer_v.test.cmt
│   │           ├── HotspotReducer_v.test.res
│   │           ├── ImageOptimizer_v.test.ast
│   │           ├── ImageOptimizer_v.test.bs.js
│   │           ├── ImageOptimizer_v.test.cmi
│   │           ├── ImageOptimizer_v.test.cmj
│   │           ├── ImageOptimizer_v.test.cmt
│   │           ├── ImageOptimizer_v.test.res
│   │           ├── InputSystem_v.test.ast
│   │           ├── InputSystem_v.test.bs.js
│   │           ├── InputSystem_v.test.cmi
│   │           ├── InputSystem_v.test.cmj
│   │           ├── InputSystem_v.test.cmt
│   │           ├── InputSystem_v.test.res
│   │           ├── InteractionsRobustness_v.test.ast
│   │           ├── InteractionsRobustness_v.test.bs.js
│   │           ├── InteractionsRobustness_v.test.cmi
│   │           ├── InteractionsRobustness_v.test.cmj
│   │           ├── InteractionsRobustness_v.test.cmt
│   │           ├── InteractionsRobustness_v.test.res
│   │           ├── JsonTypes_v.test.ast
│   │           ├── JsonTypes_v.test.bs.js
│   │           ├── JsonTypes_v.test.cmi
│   │           ├── JsonTypes_v.test.cmj
│   │           ├── JsonTypes_v.test.cmt
│   │           ├── JsonTypes_v.test.res
│   │           ├── LabelMenu_v.test.ast
│   │           ├── LabelMenu_v.test.bs.js
│   │           ├── LabelMenu_v.test.cmi
│   │           ├── LabelMenu_v.test.cmj
│   │           ├── LabelMenu_v.test.cmt
│   │           ├── LabelMenu_v.test.res
│   │           ├── LazyLoad_v.test.ast
│   │           ├── LazyLoad_v.test.bs.js
│   │           ├── LazyLoad_v.test.cmi
│   │           ├── LazyLoad_v.test.cmj
│   │           ├── LazyLoad_v.test.cmt
│   │           ├── LazyLoad_v.test.res
│   │           ├── LinkModal_v.test.ast
│   │           ├── LinkModal_v.test.bs.js
│   │           ├── LinkModal_v.test.cmi
│   │           ├── LinkModal_v.test.cmj
│   │           ├── LinkModal_v.test.cmt
│   │           ├── LinkModal_v.test.res
│   │           ├── Logger_v.test.ast
│   │           ├── Logger_v.test.bs.js
│   │           ├── Logger_v.test.cmi
│   │           ├── Logger_v.test.cmj
│   │           ├── Logger_v.test.cmt
│   │           ├── Logger_v.test.res
│   │           ├── LucideIcons_v.test.ast
│   │           ├── LucideIcons_v.test.bs.js
│   │           ├── LucideIcons_v.test.cmi
│   │           ├── LucideIcons_v.test.cmj
│   │           ├── LucideIcons_v.test.cmt
│   │           ├── LucideIcons_v.test.res
│   │           ├── Main_v.test.ast
│   │           ├── Main_v.test.bs.js
│   │           ├── Main_v.test.cmi
│   │           ├── Main_v.test.cmj
│   │           ├── Main_v.test.cmt
│   │           ├── Main_v.test.res
│   │           ├── Mod_v.test.ast
│   │           ├── Mod_v.test.bs.js
│   │           ├── Mod_v.test.cmi
│   │           ├── Mod_v.test.cmj
│   │           ├── Mod_v.test.cmt
│   │           ├── Mod_v.test.res
│   │           ├── ModalContext_v.test.ast
│   │           ├── ModalContext_v.test.bs.js
│   │           ├── ModalContext_v.test.cmi
│   │           ├── ModalContext_v.test.cmj
│   │           ├── ModalContext_v.test.cmt
│   │           ├── ModalContext_v.test.res
│   │           ├── NavigationController_v.test.ast
│   │           ├── NavigationController_v.test.bs.js
│   │           ├── NavigationController_v.test.cmi
│   │           ├── NavigationController_v.test.cmj
│   │           ├── NavigationController_v.test.cmt
│   │           ├── NavigationController_v.test.res
│   │           ├── NavigationReducer_v.test.ast
│   │           ├── NavigationReducer_v.test.bs.js
│   │           ├── NavigationReducer_v.test.cmi
│   │           ├── NavigationReducer_v.test.cmj
│   │           ├── NavigationReducer_v.test.cmt
│   │           ├── NavigationReducer_v.test.res
│   │           ├── NavigationRenderer_v.test.ast
│   │           ├── NavigationRenderer_v.test.bs.js
│   │           ├── NavigationRenderer_v.test.cmi
│   │           ├── NavigationRenderer_v.test.cmj
│   │           ├── NavigationRenderer_v.test.cmt
│   │           ├── NavigationRenderer_v.test.res
│   │           ├── NavigationUI_v.test.ast
│   │           ├── NavigationUI_v.test.bs.js
│   │           ├── NavigationUI_v.test.cmi
│   │           ├── NavigationUI_v.test.cmj
│   │           ├── NavigationUI_v.test.cmt
│   │           ├── NavigationUI_v.test.res
│   │           ├── Navigation_v.test.ast
│   │           ├── Navigation_v.test.bs.js
│   │           ├── Navigation_v.test.cmi
│   │           ├── Navigation_v.test.cmj
│   │           ├── Navigation_v.test.cmt
│   │           ├── Navigation_v.test.res
│   │           ├── NotificationContext_v.test.ast
│   │           ├── NotificationContext_v.test.bs.js
│   │           ├── NotificationContext_v.test.cmi
│   │           ├── NotificationContext_v.test.cmj
│   │           ├── NotificationContext_v.test.cmt
│   │           ├── NotificationContext_v.test.res
│   │           ├── PathInterpolation_v.test.ast
│   │           ├── PathInterpolation_v.test.bs.js
│   │           ├── PathInterpolation_v.test.cmi
│   │           ├── PathInterpolation_v.test.cmj
│   │           ├── PathInterpolation_v.test.cmt
│   │           ├── PathInterpolation_v.test.res
│   │           ├── PopOver_v.test.ast
│   │           ├── PopOver_v.test.bs.js
│   │           ├── PopOver_v.test.cmi
│   │           ├── PopOver_v.test.cmj
│   │           ├── PopOver_v.test.cmt
│   │           ├── PopOver_v.test.res
│   │           ├── Portal_v.test.ast
│   │           ├── Portal_v.test.bs.js
│   │           ├── Portal_v.test.cmi
│   │           ├── Portal_v.test.cmj
│   │           ├── Portal_v.test.cmt
│   │           ├── Portal_v.test.res
│   │           ├── PreviewArrow_v.test.ast
│   │           ├── PreviewArrow_v.test.bs.js
│   │           ├── PreviewArrow_v.test.cmi
│   │           ├── PreviewArrow_v.test.cmj
│   │           ├── PreviewArrow_v.test.cmt
│   │           ├── PreviewArrow_v.test.res
│   │           ├── ProgressBar_v.test.ast
│   │           ├── ProgressBar_v.test.bs.js
│   │           ├── ProgressBar_v.test.cmi
│   │           ├── ProgressBar_v.test.cmj
│   │           ├── ProgressBar_v.test.cmt
│   │           ├── ProgressBar_v.test.res
│   │           ├── ProjectData_v.test.ast
│   │           ├── ProjectData_v.test.bs.js
│   │           ├── ProjectData_v.test.cmi
│   │           ├── ProjectData_v.test.cmj
│   │           ├── ProjectData_v.test.cmt
│   │           ├── ProjectData_v.test.res
│   │           ├── ProjectManager_v.test.ast
│   │           ├── ProjectManager_v.test.bs.js
│   │           ├── ProjectManager_v.test.cmi
│   │           ├── ProjectManager_v.test.cmj
│   │           ├── ProjectManager_v.test.cmt
│   │           ├── ProjectManager_v.test.res
│   │           ├── ProjectReducer_v.test.ast
│   │           ├── ProjectReducer_v.test.bs.js
│   │           ├── ProjectReducer_v.test.cmi
│   │           ├── ProjectReducer_v.test.cmj
│   │           ├── ProjectReducer_v.test.cmt
│   │           ├── ProjectReducer_v.test.res
│   │           ├── ReBindings_v.test.ast
│   │           ├── ReBindings_v.test.bs.js
│   │           ├── ReBindings_v.test.cmi
│   │           ├── ReBindings_v.test.cmj
│   │           ├── ReBindings_v.test.cmt
│   │           ├── ReBindings_v.test.res
│   │           ├── ReducerHelpers_v.test.ast
│   │           ├── ReducerHelpers_v.test.bs.js
│   │           ├── ReducerHelpers_v.test.cmi
│   │           ├── ReducerHelpers_v.test.cmj
│   │           ├── ReducerHelpers_v.test.cmt
│   │           ├── ReducerHelpers_v.test.res
│   │           ├── Reducer_v.test.ast
│   │           ├── Reducer_v.test.bs.js
│   │           ├── Reducer_v.test.cmi
│   │           ├── Reducer_v.test.cmj
│   │           ├── Reducer_v.test.cmt
│   │           ├── Reducer_v.test.res
│   │           ├── RequestQueue_v.test.ast
│   │           ├── RequestQueue_v.test.bs.js
│   │           ├── RequestQueue_v.test.cmi
│   │           ├── RequestQueue_v.test.cmj
│   │           ├── RequestQueue_v.test.cmt
│   │           ├── RequestQueue_v.test.res
│   │           ├── Resizer_v.test.ast
│   │           ├── Resizer_v.test.bs.js
│   │           ├── Resizer_v.test.cmi
│   │           ├── Resizer_v.test.cmj
│   │           ├── Resizer_v.test.cmt
│   │           ├── Resizer_v.test.res
│   │           ├── RootReducer_v.test.ast
│   │           ├── RootReducer_v.test.bs.js
│   │           ├── RootReducer_v.test.cmi
│   │           ├── RootReducer_v.test.cmj
│   │           ├── RootReducer_v.test.cmt
│   │           ├── RootReducer_v.test.res
│   │           ├── SceneList_v.test.ast
│   │           ├── SceneList_v.test.bs.js
│   │           ├── SceneList_v.test.cmi
│   │           ├── SceneList_v.test.cmj
│   │           ├── SceneList_v.test.cmt
│   │           ├── SceneList_v.test.res
│   │           ├── SceneReducer_v.test.ast
│   │           ├── SceneReducer_v.test.bs.js
│   │           ├── SceneReducer_v.test.cmi
│   │           ├── SceneReducer_v.test.cmj
│   │           ├── SceneReducer_v.test.cmt
│   │           ├── SceneReducer_v.test.res
│   │           ├── ServerTeaser_v.test.ast
│   │           ├── ServerTeaser_v.test.bs.js
│   │           ├── ServerTeaser_v.test.cmi
│   │           ├── ServerTeaser_v.test.cmj
│   │           ├── ServerTeaser_v.test.cmt
│   │           ├── ServerTeaser_v.test.res
│   │           ├── ServiceWorkerMain_v.test.ast
│   │           ├── ServiceWorkerMain_v.test.bs.js
│   │           ├── ServiceWorkerMain_v.test.cmi
│   │           ├── ServiceWorkerMain_v.test.cmj
│   │           ├── ServiceWorkerMain_v.test.cmt
│   │           ├── ServiceWorkerMain_v.test.res
│   │           ├── ServiceWorker_v.test.ast
│   │           ├── ServiceWorker_v.test.bs.js
│   │           ├── ServiceWorker_v.test.cmi
│   │           ├── ServiceWorker_v.test.cmj
│   │           ├── ServiceWorker_v.test.cmt
│   │           ├── ServiceWorker_v.test.res
│   │           ├── SessionStore_v.test.ast
│   │           ├── SessionStore_v.test.bs.js
│   │           ├── SessionStore_v.test.cmi
│   │           ├── SessionStore_v.test.cmj
│   │           ├── SessionStore_v.test.cmt
│   │           ├── SessionStore_v.test.res
│   │           ├── Shadcn_v.test.ast
│   │           ├── Shadcn_v.test.bs.js
│   │           ├── Shadcn_v.test.cmi
│   │           ├── Shadcn_v.test.cmj
│   │           ├── Shadcn_v.test.cmt
│   │           ├── Shadcn_v.test.res
│   │           ├── SharedTypes_v.test.ast
│   │           ├── SharedTypes_v.test.bs.js
│   │           ├── SharedTypes_v.test.cmi
│   │           ├── SharedTypes_v.test.cmj
│   │           ├── SharedTypes_v.test.cmt
│   │           ├── SharedTypes_v.test.res
│   │           ├── Sidebar_v.test.ast
│   │           ├── Sidebar_v.test.bs.js
│   │           ├── Sidebar_v.test.cmi
│   │           ├── Sidebar_v.test.cmj
│   │           ├── Sidebar_v.test.cmt
│   │           ├── Sidebar_v.test.res
│   │           ├── SimulationChainSkipper_v.test.ast
│   │           ├── SimulationChainSkipper_v.test.bs.js
│   │           ├── SimulationChainSkipper_v.test.cmi
│   │           ├── SimulationChainSkipper_v.test.cmj
│   │           ├── SimulationChainSkipper_v.test.cmt
│   │           ├── SimulationChainSkipper_v.test.res
│   │           ├── SimulationDriver_v.test.ast
│   │           ├── SimulationDriver_v.test.bs.js
│   │           ├── SimulationDriver_v.test.cmi
│   │           ├── SimulationDriver_v.test.cmj
│   │           ├── SimulationDriver_v.test.cmt
│   │           ├── SimulationDriver_v.test.res
│   │           ├── SimulationLogic_v.test.ast
│   │           ├── SimulationLogic_v.test.bs.js
│   │           ├── SimulationLogic_v.test.cmi
│   │           ├── SimulationLogic_v.test.cmj
│   │           ├── SimulationLogic_v.test.cmt
│   │           ├── SimulationLogic_v.test.res
│   │           ├── SimulationNavigation_v.test.ast
│   │           ├── SimulationNavigation_v.test.bs.js
│   │           ├── SimulationNavigation_v.test.cmi
│   │           ├── SimulationNavigation_v.test.cmj
│   │           ├── SimulationNavigation_v.test.cmt
│   │           ├── SimulationNavigation_v.test.res
│   │           ├── SimulationPathGenerator_v.test.ast
│   │           ├── SimulationPathGenerator_v.test.bs.js
│   │           ├── SimulationPathGenerator_v.test.cmi
│   │           ├── SimulationPathGenerator_v.test.cmj
│   │           ├── SimulationPathGenerator_v.test.cmt
│   │           ├── SimulationPathGenerator_v.test.res
│   │           ├── SimulationReducer_v.test.ast
│   │           ├── SimulationReducer_v.test.bs.js
│   │           ├── SimulationReducer_v.test.cmi
│   │           ├── SimulationReducer_v.test.cmj
│   │           ├── SimulationReducer_v.test.cmt
│   │           ├── SimulationReducer_v.test.res
│   │           ├── StateInspector_v.test.ast
│   │           ├── StateInspector_v.test.bs.js
│   │           ├── StateInspector_v.test.cmi
│   │           ├── StateInspector_v.test.cmj
│   │           ├── StateInspector_v.test.cmt
│   │           ├── StateInspector_v.test.res
│   │           ├── State_v.test.ast
│   │           ├── State_v.test.bs.js
│   │           ├── State_v.test.cmi
│   │           ├── State_v.test.cmj
│   │           ├── State_v.test.cmt
│   │           ├── State_v.test.res
│   │           ├── TeaserManager_v.test.ast
│   │           ├── TeaserManager_v.test.bs.js
│   │           ├── TeaserManager_v.test.cmi
│   │           ├── TeaserManager_v.test.cmj
│   │           ├── TeaserManager_v.test.cmt
│   │           ├── TeaserManager_v.test.res
│   │           ├── TeaserPathfinder_v.test.ast
│   │           ├── TeaserPathfinder_v.test.bs.js
│   │           ├── TeaserPathfinder_v.test.cmi
│   │           ├── TeaserPathfinder_v.test.cmj
│   │           ├── TeaserPathfinder_v.test.cmt
│   │           ├── TeaserPathfinder_v.test.res
│   │           ├── TeaserRecorder_v.test.ast
│   │           ├── TeaserRecorder_v.test.bs.js
│   │           ├── TeaserRecorder_v.test.cmi
│   │           ├── TeaserRecorder_v.test.cmj
│   │           ├── TeaserRecorder_v.test.cmt
│   │           ├── TeaserRecorder_v.test.res
│   │           ├── TimelineReducer_v.test.ast
│   │           ├── TimelineReducer_v.test.bs.js
│   │           ├── TimelineReducer_v.test.cmi
│   │           ├── TimelineReducer_v.test.cmj
│   │           ├── TimelineReducer_v.test.cmt
│   │           ├── TimelineReducer_v.test.res
│   │           ├── Tooltip_v.test.ast
│   │           ├── Tooltip_v.test.bs.js
│   │           ├── Tooltip_v.test.cmi
│   │           ├── Tooltip_v.test.cmj
│   │           ├── Tooltip_v.test.cmt
│   │           ├── Tooltip_v.test.res
│   │           ├── TourLogic_v.test.ast
│   │           ├── TourLogic_v.test.bs.js
│   │           ├── TourLogic_v.test.cmi
│   │           ├── TourLogic_v.test.cmj
│   │           ├── TourLogic_v.test.cmt
│   │           ├── TourLogic_v.test.res
│   │           ├── TourTemplateAssets_v.test.ast
│   │           ├── TourTemplateAssets_v.test.bs.js
│   │           ├── TourTemplateAssets_v.test.cmi
│   │           ├── TourTemplateAssets_v.test.cmj
│   │           ├── TourTemplateAssets_v.test.cmt
│   │           ├── TourTemplateAssets_v.test.res
│   │           ├── TourTemplateScripts_v.test.ast
│   │           ├── TourTemplateScripts_v.test.bs.js
│   │           ├── TourTemplateScripts_v.test.cmi
│   │           ├── TourTemplateScripts_v.test.cmj
│   │           ├── TourTemplateScripts_v.test.cmt
│   │           ├── TourTemplateScripts_v.test.res
│   │           ├── TourTemplateStyles_v.test.ast
│   │           ├── TourTemplateStyles_v.test.bs.js
│   │           ├── TourTemplateStyles_v.test.cmi
│   │           ├── TourTemplateStyles_v.test.cmj
│   │           ├── TourTemplateStyles_v.test.cmt
│   │           ├── TourTemplateStyles_v.test.res
│   │           ├── TourTemplates_v.test.ast
│   │           ├── TourTemplates_v.test.bs.js
│   │           ├── TourTemplates_v.test.cmi
│   │           ├── TourTemplates_v.test.cmj
│   │           ├── TourTemplates_v.test.cmt
│   │           ├── TourTemplates_v.test.res
│   │           ├── Types_v.test.ast
│   │           ├── Types_v.test.bs.js
│   │           ├── Types_v.test.cmi
│   │           ├── Types_v.test.cmj
│   │           ├── Types_v.test.cmt
│   │           ├── Types_v.test.res
│   │           ├── UiReducer_v.test.ast
│   │           ├── UiReducer_v.test.bs.js
│   │           ├── UiReducer_v.test.cmi
│   │           ├── UiReducer_v.test.cmj
│   │           ├── UiReducer_v.test.cmt
│   │           ├── UiReducer_v.test.res
│   │           ├── UploadProcessorLogic_v.test.ast
│   │           ├── UploadProcessorLogic_v.test.bs.js
│   │           ├── UploadProcessorLogic_v.test.cmi
│   │           ├── UploadProcessorLogic_v.test.cmj
│   │           ├── UploadProcessorLogic_v.test.cmt
│   │           ├── UploadProcessorLogic_v.test.res
│   │           ├── UploadProcessorTypes_v.test.ast
│   │           ├── UploadProcessorTypes_v.test.bs.js
│   │           ├── UploadProcessorTypes_v.test.cmi
│   │           ├── UploadProcessorTypes_v.test.cmj
│   │           ├── UploadProcessorTypes_v.test.cmt
│   │           ├── UploadProcessorTypes_v.test.res
│   │           ├── UploadProcessor_v.test.ast
│   │           ├── UploadProcessor_v.test.bs.js
│   │           ├── UploadProcessor_v.test.cmi
│   │           ├── UploadProcessor_v.test.cmj
│   │           ├── UploadProcessor_v.test.cmt
│   │           ├── UploadProcessor_v.test.res
│   │           ├── UploadReport_v.test.ast
│   │           ├── UploadReport_v.test.bs.js
│   │           ├── UploadReport_v.test.cmi
│   │           ├── UploadReport_v.test.cmj
│   │           ├── UploadReport_v.test.cmt
│   │           ├── UploadReport_v.test.res
│   │           ├── UrlUtils_v.test.ast
│   │           ├── UrlUtils_v.test.bs.js
│   │           ├── UrlUtils_v.test.cmi
│   │           ├── UrlUtils_v.test.cmj
│   │           ├── UrlUtils_v.test.cmt
│   │           ├── UrlUtils_v.test.res
│   │           ├── VersionData_v.test.ast
│   │           ├── VersionData_v.test.bs.js
│   │           ├── VersionData_v.test.cmi
│   │           ├── VersionData_v.test.cmj
│   │           ├── VersionData_v.test.cmt
│   │           ├── VersionData_v.test.res
│   │           ├── Version_v.test.ast
│   │           ├── Version_v.test.bs.js
│   │           ├── Version_v.test.cmi
│   │           ├── Version_v.test.cmj
│   │           ├── Version_v.test.cmt
│   │           ├── Version_v.test.res
│   │           ├── VideoEncoder_v.test.ast
│   │           ├── VideoEncoder_v.test.bs.js
│   │           ├── VideoEncoder_v.test.cmi
│   │           ├── VideoEncoder_v.test.cmj
│   │           ├── VideoEncoder_v.test.cmt
│   │           ├── VideoEncoder_v.test.res
│   │           ├── ViewerFollow_v.test.ast
│   │           ├── ViewerFollow_v.test.bs.js
│   │           ├── ViewerFollow_v.test.cmi
│   │           ├── ViewerFollow_v.test.cmj
│   │           ├── ViewerFollow_v.test.cmt
│   │           ├── ViewerFollow_v.test.res
│   │           ├── ViewerLoader_v.test.ast
│   │           ├── ViewerLoader_v.test.bs.js
│   │           ├── ViewerLoader_v.test.cmi
│   │           ├── ViewerLoader_v.test.cmj
│   │           ├── ViewerLoader_v.test.cmt
│   │           ├── ViewerLoader_v.test.res
│   │           ├── ViewerManager_v.test.ast
│   │           ├── ViewerManager_v.test.bs.js
│   │           ├── ViewerManager_v.test.cmi
│   │           ├── ViewerManager_v.test.cmj
│   │           ├── ViewerManager_v.test.cmt
│   │           ├── ViewerManager_v.test.res
│   │           ├── ViewerSnapshot_v.test.ast
│   │           ├── ViewerSnapshot_v.test.bs.js
│   │           ├── ViewerSnapshot_v.test.cmi
│   │           ├── ViewerSnapshot_v.test.cmj
│   │           ├── ViewerSnapshot_v.test.cmt
│   │           ├── ViewerSnapshot_v.test.res
│   │           ├── ViewerState_v.test.ast
│   │           ├── ViewerState_v.test.bs.js
│   │           ├── ViewerState_v.test.cmi
│   │           ├── ViewerState_v.test.cmj
│   │           ├── ViewerState_v.test.cmt
│   │           ├── ViewerState_v.test.res
│   │           ├── ViewerTypes_v.test.ast
│   │           ├── ViewerTypes_v.test.bs.js
│   │           ├── ViewerTypes_v.test.cmi
│   │           ├── ViewerTypes_v.test.cmj
│   │           ├── ViewerTypes_v.test.cmt
│   │           ├── ViewerTypes_v.test.res
│   │           ├── ViewerUI_v.test.ast
│   │           ├── ViewerUI_v.test.bs.js
│   │           ├── ViewerUI_v.test.cmi
│   │           ├── ViewerUI_v.test.cmj
│   │           ├── ViewerUI_v.test.cmt
│   │           ├── ViewerUI_v.test.res
│   │           ├── VisualPipeline_v.test.ast
│   │           ├── VisualPipeline_v.test.bs.js
│   │           ├── VisualPipeline_v.test.cmi
│   │           ├── VisualPipeline_v.test.cmj
│   │           ├── VisualPipeline_v.test.cmt
│   │           ├── VisualPipeline_v.test.res
│   │           ├── VitestSmoke.test.ast
│   │           ├── VitestSmoke.test.bs.js
│   │           ├── VitestSmoke.test.cmi
│   │           ├── VitestSmoke.test.cmj
│   │           ├── VitestSmoke.test.cmt
│   │           ├── VitestSmoke.test.res
│   │           └── utils
│   │               ├── TestUtils.ast
│   │               ├── TestUtils.bs.js
│   │               ├── TestUtils.cmi
│   │               ├── TestUtils.cmj
│   │               ├── TestUtils.cmt
│   │               └── TestUtils.res
│   ├── ocaml
│   │   ├── Actions.ast
│   │   ├── Actions.cmi
│   │   ├── Actions.cmj
│   │   ├── Actions.cmt
│   │   ├── Actions.res
│   │   ├── Actions_v.test.ast
│   │   ├── Actions_v.test.cmi
│   │   ├── Actions_v.test.cmj
│   │   ├── Actions_v.test.cmt
│   │   ├── Actions_v.test.res
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
│   │   ├── AppContext_v.test.ast
│   │   ├── AppContext_v.test.cmi
│   │   ├── AppContext_v.test.cmj
│   │   ├── AppContext_v.test.cmt
│   │   ├── AppContext_v.test.res
│   │   ├── AppErrorBoundary.ast
│   │   ├── AppErrorBoundary.cmi
│   │   ├── AppErrorBoundary.cmj
│   │   ├── AppErrorBoundary.cmt
│   │   ├── AppErrorBoundary.res
│   │   ├── AppErrorBoundary_v.test.ast
│   │   ├── AppErrorBoundary_v.test.cmi
│   │   ├── AppErrorBoundary_v.test.cmj
│   │   ├── AppErrorBoundary_v.test.cmt
│   │   ├── AppErrorBoundary_v.test.res
│   │   ├── App_v.test.ast
│   │   ├── App_v.test.cmi
│   │   ├── App_v.test.cmj
│   │   ├── App_v.test.cmt
│   │   ├── App_v.test.res
│   │   ├── AudioManager.ast
│   │   ├── AudioManager.cmi
│   │   ├── AudioManager.cmj
│   │   ├── AudioManager.cmt
│   │   ├── AudioManager.res
│   │   ├── AudioManager_v.test.ast
│   │   ├── AudioManager_v.test.cmi
│   │   ├── AudioManager_v.test.cmj
│   │   ├── AudioManager_v.test.cmt
│   │   ├── AudioManager_v.test.res
│   │   ├── BackendApi.ast
│   │   ├── BackendApi.cmi
│   │   ├── BackendApi.cmj
│   │   ├── BackendApi.cmt
│   │   ├── BackendApi.res
│   │   ├── BackendApi_v.test.ast
│   │   ├── BackendApi_v.test.cmi
│   │   ├── BackendApi_v.test.cmj
│   │   ├── BackendApi_v.test.cmt
│   │   ├── BackendApi_v.test.res
│   │   ├── ColorPalette.ast
│   │   ├── ColorPalette.cmi
│   │   ├── ColorPalette.cmj
│   │   ├── ColorPalette.cmt
│   │   ├── ColorPalette.res
│   │   ├── ColorPalette_v.test.ast
│   │   ├── ColorPalette_v.test.cmi
│   │   ├── ColorPalette_v.test.cmj
│   │   ├── ColorPalette_v.test.cmt
│   │   ├── ColorPalette_v.test.res
│   │   ├── Constants.ast
│   │   ├── Constants.cmi
│   │   ├── Constants.cmj
│   │   ├── Constants.cmt
│   │   ├── Constants.res
│   │   ├── Constants_v.test.ast
│   │   ├── Constants_v.test.cmi
│   │   ├── Constants_v.test.cmj
│   │   ├── Constants_v.test.cmt
│   │   ├── Constants_v.test.res
│   │   ├── DownloadSystem.ast
│   │   ├── DownloadSystem.cmi
│   │   ├── DownloadSystem.cmj
│   │   ├── DownloadSystem.cmt
│   │   ├── DownloadSystem.res
│   │   ├── DownloadSystem_v.test.ast
│   │   ├── DownloadSystem_v.test.cmi
│   │   ├── DownloadSystem_v.test.cmj
│   │   ├── DownloadSystem_v.test.cmt
│   │   ├── DownloadSystem_v.test.res
│   │   ├── ErrorFallbackUI.ast
│   │   ├── ErrorFallbackUI.cmi
│   │   ├── ErrorFallbackUI.cmj
│   │   ├── ErrorFallbackUI.cmt
│   │   ├── ErrorFallbackUI.res
│   │   ├── ErrorFallbackUI_v.test.ast
│   │   ├── ErrorFallbackUI_v.test.cmi
│   │   ├── ErrorFallbackUI_v.test.cmj
│   │   ├── ErrorFallbackUI_v.test.cmt
│   │   ├── ErrorFallbackUI_v.test.res
│   │   ├── EventBus.ast
│   │   ├── EventBus.cmi
│   │   ├── EventBus.cmj
│   │   ├── EventBus.cmt
│   │   ├── EventBus.res
│   │   ├── EventBus_v.test.ast
│   │   ├── EventBus_v.test.cmi
│   │   ├── EventBus_v.test.cmj
│   │   ├── EventBus_v.test.cmt
│   │   ├── EventBus_v.test.res
│   │   ├── ExifParser.ast
│   │   ├── ExifParser.cmi
│   │   ├── ExifParser.cmj
│   │   ├── ExifParser.cmt
│   │   ├── ExifParser.res
│   │   ├── ExifParser_v.test.ast
│   │   ├── ExifParser_v.test.cmi
│   │   ├── ExifParser_v.test.cmj
│   │   ├── ExifParser_v.test.cmt
│   │   ├── ExifParser_v.test.res
│   │   ├── ExifReportGenerator.ast
│   │   ├── ExifReportGenerator.cmi
│   │   ├── ExifReportGenerator.cmj
│   │   ├── ExifReportGenerator.cmt
│   │   ├── ExifReportGenerator.res
│   │   ├── ExifReportGenerator_v.test.ast
│   │   ├── ExifReportGenerator_v.test.cmi
│   │   ├── ExifReportGenerator_v.test.cmj
│   │   ├── ExifReportGenerator_v.test.cmt
│   │   ├── ExifReportGenerator_v.test.res
│   │   ├── Exporter.ast
│   │   ├── Exporter.cmi
│   │   ├── Exporter.cmj
│   │   ├── Exporter.cmt
│   │   ├── Exporter.res
│   │   ├── Exporter_v.test.ast
│   │   ├── Exporter_v.test.cmi
│   │   ├── Exporter_v.test.cmj
│   │   ├── Exporter_v.test.cmt
│   │   ├── Exporter_v.test.res
│   │   ├── GeoUtils.ast
│   │   ├── GeoUtils.cmi
│   │   ├── GeoUtils.cmj
│   │   ├── GeoUtils.cmt
│   │   ├── GeoUtils.res
│   │   ├── GeoUtils_v.test.ast
│   │   ├── GeoUtils_v.test.cmi
│   │   ├── GeoUtils_v.test.cmj
│   │   ├── GeoUtils_v.test.cmt
│   │   ├── GeoUtils_v.test.res
│   │   ├── GlobalStateBridge.ast
│   │   ├── GlobalStateBridge.cmi
│   │   ├── GlobalStateBridge.cmj
│   │   ├── GlobalStateBridge.cmt
│   │   ├── GlobalStateBridge.res
│   │   ├── GlobalStateBridge_v.test.ast
│   │   ├── GlobalStateBridge_v.test.cmi
│   │   ├── GlobalStateBridge_v.test.cmj
│   │   ├── GlobalStateBridge_v.test.cmt
│   │   ├── GlobalStateBridge_v.test.res
│   │   ├── HotspotActionMenu.ast
│   │   ├── HotspotActionMenu.cmi
│   │   ├── HotspotActionMenu.cmj
│   │   ├── HotspotActionMenu.cmt
│   │   ├── HotspotActionMenu.res
│   │   ├── HotspotActionMenu_v.test.ast
│   │   ├── HotspotActionMenu_v.test.cmi
│   │   ├── HotspotActionMenu_v.test.cmj
│   │   ├── HotspotActionMenu_v.test.cmt
│   │   ├── HotspotActionMenu_v.test.res
│   │   ├── HotspotLine.ast
│   │   ├── HotspotLine.cmi
│   │   ├── HotspotLine.cmj
│   │   ├── HotspotLine.cmt
│   │   ├── HotspotLine.res
│   │   ├── HotspotLineLogic.ast
│   │   ├── HotspotLineLogic.cmi
│   │   ├── HotspotLineLogic.cmj
│   │   ├── HotspotLineLogic.cmt
│   │   ├── HotspotLineLogic.res
│   │   ├── HotspotLineLogic_v.test.ast
│   │   ├── HotspotLineLogic_v.test.cmi
│   │   ├── HotspotLineLogic_v.test.cmj
│   │   ├── HotspotLineLogic_v.test.cmt
│   │   ├── HotspotLineLogic_v.test.res
│   │   ├── HotspotLineTypes.ast
│   │   ├── HotspotLineTypes.cmi
│   │   ├── HotspotLineTypes.cmj
│   │   ├── HotspotLineTypes.cmt
│   │   ├── HotspotLineTypes.res
│   │   ├── HotspotLineTypes_v.test.ast
│   │   ├── HotspotLineTypes_v.test.cmi
│   │   ├── HotspotLineTypes_v.test.cmj
│   │   ├── HotspotLineTypes_v.test.cmt
│   │   ├── HotspotLineTypes_v.test.res
│   │   ├── HotspotLine_v.test.ast
│   │   ├── HotspotLine_v.test.cmi
│   │   ├── HotspotLine_v.test.cmj
│   │   ├── HotspotLine_v.test.cmt
│   │   ├── HotspotLine_v.test.res
│   │   ├── HotspotManager.ast
│   │   ├── HotspotManager.cmi
│   │   ├── HotspotManager.cmj
│   │   ├── HotspotManager.cmt
│   │   ├── HotspotManager.res
│   │   ├── HotspotManager_v.test.ast
│   │   ├── HotspotManager_v.test.cmi
│   │   ├── HotspotManager_v.test.cmj
│   │   ├── HotspotManager_v.test.cmt
│   │   ├── HotspotManager_v.test.res
│   │   ├── HotspotReducer.ast
│   │   ├── HotspotReducer.cmi
│   │   ├── HotspotReducer.cmj
│   │   ├── HotspotReducer.cmt
│   │   ├── HotspotReducer.res
│   │   ├── HotspotReducer_v.test.ast
│   │   ├── HotspotReducer_v.test.cmi
│   │   ├── HotspotReducer_v.test.cmj
│   │   ├── HotspotReducer_v.test.cmt
│   │   ├── HotspotReducer_v.test.res
│   │   ├── ImageOptimizer.ast
│   │   ├── ImageOptimizer.cmi
│   │   ├── ImageOptimizer.cmj
│   │   ├── ImageOptimizer.cmt
│   │   ├── ImageOptimizer.cmti
│   │   ├── ImageOptimizer.iast
│   │   ├── ImageOptimizer.res
│   │   ├── ImageOptimizer.resi
│   │   ├── ImageOptimizer_v.test.ast
│   │   ├── ImageOptimizer_v.test.cmi
│   │   ├── ImageOptimizer_v.test.cmj
│   │   ├── ImageOptimizer_v.test.cmt
│   │   ├── ImageOptimizer_v.test.res
│   │   ├── InputSystem.ast
│   │   ├── InputSystem.cmi
│   │   ├── InputSystem.cmj
│   │   ├── InputSystem.cmt
│   │   ├── InputSystem.res
│   │   ├── InputSystem_v.test.ast
│   │   ├── InputSystem_v.test.cmi
│   │   ├── InputSystem_v.test.cmj
│   │   ├── InputSystem_v.test.cmt
│   │   ├── InputSystem_v.test.res
│   │   ├── InteractionsRobustness_v.test.ast
│   │   ├── InteractionsRobustness_v.test.cmi
│   │   ├── InteractionsRobustness_v.test.cmj
│   │   ├── InteractionsRobustness_v.test.cmt
│   │   ├── InteractionsRobustness_v.test.res
│   │   ├── JsonTypes.ast
│   │   ├── JsonTypes.cmi
│   │   ├── JsonTypes.cmj
│   │   ├── JsonTypes.cmt
│   │   ├── JsonTypes.res
│   │   ├── JsonTypes_v.test.ast
│   │   ├── JsonTypes_v.test.cmi
│   │   ├── JsonTypes_v.test.cmj
│   │   ├── JsonTypes_v.test.cmt
│   │   ├── JsonTypes_v.test.res
│   │   ├── LabelMenu.ast
│   │   ├── LabelMenu.cmi
│   │   ├── LabelMenu.cmj
│   │   ├── LabelMenu.cmt
│   │   ├── LabelMenu.res
│   │   ├── LabelMenu_v.test.ast
│   │   ├── LabelMenu_v.test.cmi
│   │   ├── LabelMenu_v.test.cmj
│   │   ├── LabelMenu_v.test.cmt
│   │   ├── LabelMenu_v.test.res
│   │   ├── LazyLoad.ast
│   │   ├── LazyLoad.cmi
│   │   ├── LazyLoad.cmj
│   │   ├── LazyLoad.cmt
│   │   ├── LazyLoad.res
│   │   ├── LazyLoad_v.test.ast
│   │   ├── LazyLoad_v.test.cmi
│   │   ├── LazyLoad_v.test.cmj
│   │   ├── LazyLoad_v.test.cmt
│   │   ├── LazyLoad_v.test.res
│   │   ├── LinkModal.ast
│   │   ├── LinkModal.cmi
│   │   ├── LinkModal.cmj
│   │   ├── LinkModal.cmt
│   │   ├── LinkModal.res
│   │   ├── LinkModal_v.test.ast
│   │   ├── LinkModal_v.test.cmi
│   │   ├── LinkModal_v.test.cmj
│   │   ├── LinkModal_v.test.cmt
│   │   ├── LinkModal_v.test.res
│   │   ├── Logger.ast
│   │   ├── Logger.cmi
│   │   ├── Logger.cmj
│   │   ├── Logger.cmt
│   │   ├── Logger.res
│   │   ├── Logger_v.test.ast
│   │   ├── Logger_v.test.cmi
│   │   ├── Logger_v.test.cmj
│   │   ├── Logger_v.test.cmt
│   │   ├── Logger_v.test.res
│   │   ├── LucideIcons.ast
│   │   ├── LucideIcons.cmi
│   │   ├── LucideIcons.cmj
│   │   ├── LucideIcons.cmt
│   │   ├── LucideIcons.res
│   │   ├── LucideIcons_v.test.ast
│   │   ├── LucideIcons_v.test.cmi
│   │   ├── LucideIcons_v.test.cmj
│   │   ├── LucideIcons_v.test.cmt
│   │   ├── LucideIcons_v.test.res
│   │   ├── Main.ast
│   │   ├── Main.cmi
│   │   ├── Main.cmj
│   │   ├── Main.cmt
│   │   ├── Main.res
│   │   ├── Main_v.test.ast
│   │   ├── Main_v.test.cmi
│   │   ├── Main_v.test.cmj
│   │   ├── Main_v.test.cmt
│   │   ├── Main_v.test.res
│   │   ├── Mod_v.test.ast
│   │   ├── Mod_v.test.cmi
│   │   ├── Mod_v.test.cmj
│   │   ├── Mod_v.test.cmt
│   │   ├── Mod_v.test.res
│   │   ├── ModalContext.ast
│   │   ├── ModalContext.cmi
│   │   ├── ModalContext.cmj
│   │   ├── ModalContext.cmt
│   │   ├── ModalContext.res
│   │   ├── ModalContext_v.test.ast
│   │   ├── ModalContext_v.test.cmi
│   │   ├── ModalContext_v.test.cmj
│   │   ├── ModalContext_v.test.cmt
│   │   ├── ModalContext_v.test.res
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
│   │   ├── NavigationController_v.test.ast
│   │   ├── NavigationController_v.test.cmi
│   │   ├── NavigationController_v.test.cmj
│   │   ├── NavigationController_v.test.cmt
│   │   ├── NavigationController_v.test.res
│   │   ├── NavigationReducer.ast
│   │   ├── NavigationReducer.cmi
│   │   ├── NavigationReducer.cmj
│   │   ├── NavigationReducer.cmt
│   │   ├── NavigationReducer.res
│   │   ├── NavigationReducer_v.test.ast
│   │   ├── NavigationReducer_v.test.cmi
│   │   ├── NavigationReducer_v.test.cmj
│   │   ├── NavigationReducer_v.test.cmt
│   │   ├── NavigationReducer_v.test.res
│   │   ├── NavigationRenderer.ast
│   │   ├── NavigationRenderer.cmi
│   │   ├── NavigationRenderer.cmj
│   │   ├── NavigationRenderer.cmt
│   │   ├── NavigationRenderer.res
│   │   ├── NavigationRenderer_v.test.ast
│   │   ├── NavigationRenderer_v.test.cmi
│   │   ├── NavigationRenderer_v.test.cmj
│   │   ├── NavigationRenderer_v.test.cmt
│   │   ├── NavigationRenderer_v.test.res
│   │   ├── NavigationUI.ast
│   │   ├── NavigationUI.cmi
│   │   ├── NavigationUI.cmj
│   │   ├── NavigationUI.cmt
│   │   ├── NavigationUI.res
│   │   ├── NavigationUI_v.test.ast
│   │   ├── NavigationUI_v.test.cmi
│   │   ├── NavigationUI_v.test.cmj
│   │   ├── NavigationUI_v.test.cmt
│   │   ├── NavigationUI_v.test.res
│   │   ├── Navigation_v.test.ast
│   │   ├── Navigation_v.test.cmi
│   │   ├── Navigation_v.test.cmj
│   │   ├── Navigation_v.test.cmt
│   │   ├── Navigation_v.test.res
│   │   ├── NotificationContext.ast
│   │   ├── NotificationContext.cmi
│   │   ├── NotificationContext.cmj
│   │   ├── NotificationContext.cmt
│   │   ├── NotificationContext.res
│   │   ├── NotificationContext_v.test.ast
│   │   ├── NotificationContext_v.test.cmi
│   │   ├── NotificationContext_v.test.cmj
│   │   ├── NotificationContext_v.test.cmt
│   │   ├── NotificationContext_v.test.res
│   │   ├── PathInterpolation.ast
│   │   ├── PathInterpolation.cmi
│   │   ├── PathInterpolation.cmj
│   │   ├── PathInterpolation.cmt
│   │   ├── PathInterpolation.res
│   │   ├── PathInterpolation_v.test.ast
│   │   ├── PathInterpolation_v.test.cmi
│   │   ├── PathInterpolation_v.test.cmj
│   │   ├── PathInterpolation_v.test.cmt
│   │   ├── PathInterpolation_v.test.res
│   │   ├── PopOver.ast
│   │   ├── PopOver.cmi
│   │   ├── PopOver.cmj
│   │   ├── PopOver.cmt
│   │   ├── PopOver.res
│   │   ├── PopOver_v.test.ast
│   │   ├── PopOver_v.test.cmi
│   │   ├── PopOver_v.test.cmj
│   │   ├── PopOver_v.test.cmt
│   │   ├── PopOver_v.test.res
│   │   ├── Portal.ast
│   │   ├── Portal.cmi
│   │   ├── Portal.cmj
│   │   ├── Portal.cmt
│   │   ├── Portal.res
│   │   ├── Portal_v.test.ast
│   │   ├── Portal_v.test.cmi
│   │   ├── Portal_v.test.cmj
│   │   ├── Portal_v.test.cmt
│   │   ├── Portal_v.test.res
│   │   ├── PreviewArrow.ast
│   │   ├── PreviewArrow.cmi
│   │   ├── PreviewArrow.cmj
│   │   ├── PreviewArrow.cmt
│   │   ├── PreviewArrow.res
│   │   ├── PreviewArrow_v.test.ast
│   │   ├── PreviewArrow_v.test.cmi
│   │   ├── PreviewArrow_v.test.cmj
│   │   ├── PreviewArrow_v.test.cmt
│   │   ├── PreviewArrow_v.test.res
│   │   ├── ProgressBar.ast
│   │   ├── ProgressBar.cmi
│   │   ├── ProgressBar.cmj
│   │   ├── ProgressBar.cmt
│   │   ├── ProgressBar.res
│   │   ├── ProgressBar_v.test.ast
│   │   ├── ProgressBar_v.test.cmi
│   │   ├── ProgressBar_v.test.cmj
│   │   ├── ProgressBar_v.test.cmt
│   │   ├── ProgressBar_v.test.res
│   │   ├── ProjectData.ast
│   │   ├── ProjectData.cmi
│   │   ├── ProjectData.cmj
│   │   ├── ProjectData.cmt
│   │   ├── ProjectData.res
│   │   ├── ProjectData_v.test.ast
│   │   ├── ProjectData_v.test.cmi
│   │   ├── ProjectData_v.test.cmj
│   │   ├── ProjectData_v.test.cmt
│   │   ├── ProjectData_v.test.res
│   │   ├── ProjectManager.ast
│   │   ├── ProjectManager.cmi
│   │   ├── ProjectManager.cmj
│   │   ├── ProjectManager.cmt
│   │   ├── ProjectManager.res
│   │   ├── ProjectManager_v.test.ast
│   │   ├── ProjectManager_v.test.cmi
│   │   ├── ProjectManager_v.test.cmj
│   │   ├── ProjectManager_v.test.cmt
│   │   ├── ProjectManager_v.test.res
│   │   ├── ProjectReducer.ast
│   │   ├── ProjectReducer.cmi
│   │   ├── ProjectReducer.cmj
│   │   ├── ProjectReducer.cmt
│   │   ├── ProjectReducer.res
│   │   ├── ProjectReducer_v.test.ast
│   │   ├── ProjectReducer_v.test.cmi
│   │   ├── ProjectReducer_v.test.cmj
│   │   ├── ProjectReducer_v.test.cmt
│   │   ├── ProjectReducer_v.test.res
│   │   ├── ReBindings.ast
│   │   ├── ReBindings.cmi
│   │   ├── ReBindings.cmj
│   │   ├── ReBindings.cmt
│   │   ├── ReBindings.res
│   │   ├── ReBindings_v.test.ast
│   │   ├── ReBindings_v.test.cmi
│   │   ├── ReBindings_v.test.cmj
│   │   ├── ReBindings_v.test.cmt
│   │   ├── ReBindings_v.test.res
│   │   ├── Reducer.ast
│   │   ├── Reducer.cmi
│   │   ├── Reducer.cmj
│   │   ├── Reducer.cmt
│   │   ├── Reducer.res
│   │   ├── ReducerHelpers.ast
│   │   ├── ReducerHelpers.cmi
│   │   ├── ReducerHelpers.cmj
│   │   ├── ReducerHelpers.cmt
│   │   ├── ReducerHelpers.res
│   │   ├── ReducerHelpers_v.test.ast
│   │   ├── ReducerHelpers_v.test.cmi
│   │   ├── ReducerHelpers_v.test.cmj
│   │   ├── ReducerHelpers_v.test.cmt
│   │   ├── ReducerHelpers_v.test.res
│   │   ├── Reducer_v.test.ast
│   │   ├── Reducer_v.test.cmi
│   │   ├── Reducer_v.test.cmj
│   │   ├── Reducer_v.test.cmt
│   │   ├── Reducer_v.test.res
│   │   ├── RequestQueue.ast
│   │   ├── RequestQueue.cmi
│   │   ├── RequestQueue.cmj
│   │   ├── RequestQueue.cmt
│   │   ├── RequestQueue.res
│   │   ├── RequestQueue_v.test.ast
│   │   ├── RequestQueue_v.test.cmi
│   │   ├── RequestQueue_v.test.cmj
│   │   ├── RequestQueue_v.test.cmt
│   │   ├── RequestQueue_v.test.res
│   │   ├── Resizer.ast
│   │   ├── Resizer.cmi
│   │   ├── Resizer.cmj
│   │   ├── Resizer.cmt
│   │   ├── Resizer.res
│   │   ├── Resizer_v.test.ast
│   │   ├── Resizer_v.test.cmi
│   │   ├── Resizer_v.test.cmj
│   │   ├── Resizer_v.test.cmt
│   │   ├── Resizer_v.test.res
│   │   ├── RootReducer.ast
│   │   ├── RootReducer.cmi
│   │   ├── RootReducer.cmj
│   │   ├── RootReducer.cmt
│   │   ├── RootReducer.res
│   │   ├── RootReducer_v.test.ast
│   │   ├── RootReducer_v.test.cmi
│   │   ├── RootReducer_v.test.cmj
│   │   ├── RootReducer_v.test.cmt
│   │   ├── RootReducer_v.test.res
│   │   ├── SceneList.ast
│   │   ├── SceneList.cmi
│   │   ├── SceneList.cmj
│   │   ├── SceneList.cmt
│   │   ├── SceneList.res
│   │   ├── SceneList_v.test.ast
│   │   ├── SceneList_v.test.cmi
│   │   ├── SceneList_v.test.cmj
│   │   ├── SceneList_v.test.cmt
│   │   ├── SceneList_v.test.res
│   │   ├── SceneReducer.ast
│   │   ├── SceneReducer.cmi
│   │   ├── SceneReducer.cmj
│   │   ├── SceneReducer.cmt
│   │   ├── SceneReducer.res
│   │   ├── SceneReducer_v.test.ast
│   │   ├── SceneReducer_v.test.cmi
│   │   ├── SceneReducer_v.test.cmj
│   │   ├── SceneReducer_v.test.cmt
│   │   ├── SceneReducer_v.test.res
│   │   ├── ServerTeaser.ast
│   │   ├── ServerTeaser.cmi
│   │   ├── ServerTeaser.cmj
│   │   ├── ServerTeaser.cmt
│   │   ├── ServerTeaser.res
│   │   ├── ServerTeaser_v.test.ast
│   │   ├── ServerTeaser_v.test.cmi
│   │   ├── ServerTeaser_v.test.cmj
│   │   ├── ServerTeaser_v.test.cmt
│   │   ├── ServerTeaser_v.test.res
│   │   ├── ServiceWorker.ast
│   │   ├── ServiceWorker.cmi
│   │   ├── ServiceWorker.cmj
│   │   ├── ServiceWorker.cmt
│   │   ├── ServiceWorker.res
│   │   ├── ServiceWorkerMain.ast
│   │   ├── ServiceWorkerMain.cmi
│   │   ├── ServiceWorkerMain.cmj
│   │   ├── ServiceWorkerMain.cmt
│   │   ├── ServiceWorkerMain.res
│   │   ├── ServiceWorkerMain_v.test.ast
│   │   ├── ServiceWorkerMain_v.test.cmi
│   │   ├── ServiceWorkerMain_v.test.cmj
│   │   ├── ServiceWorkerMain_v.test.cmt
│   │   ├── ServiceWorkerMain_v.test.res
│   │   ├── ServiceWorker_v.test.ast
│   │   ├── ServiceWorker_v.test.cmi
│   │   ├── ServiceWorker_v.test.cmj
│   │   ├── ServiceWorker_v.test.cmt
│   │   ├── ServiceWorker_v.test.res
│   │   ├── SessionStore.ast
│   │   ├── SessionStore.cmi
│   │   ├── SessionStore.cmj
│   │   ├── SessionStore.cmt
│   │   ├── SessionStore.res
│   │   ├── SessionStore_v.test.ast
│   │   ├── SessionStore_v.test.cmi
│   │   ├── SessionStore_v.test.cmj
│   │   ├── SessionStore_v.test.cmt
│   │   ├── SessionStore_v.test.res
│   │   ├── Shadcn.ast
│   │   ├── Shadcn.cmi
│   │   ├── Shadcn.cmj
│   │   ├── Shadcn.cmt
│   │   ├── Shadcn.res
│   │   ├── Shadcn_v.test.ast
│   │   ├── Shadcn_v.test.cmi
│   │   ├── Shadcn_v.test.cmj
│   │   ├── Shadcn_v.test.cmt
│   │   ├── Shadcn_v.test.res
│   │   ├── SharedTypes.ast
│   │   ├── SharedTypes.cmi
│   │   ├── SharedTypes.cmj
│   │   ├── SharedTypes.cmt
│   │   ├── SharedTypes.res
│   │   ├── SharedTypes_v.test.ast
│   │   ├── SharedTypes_v.test.cmi
│   │   ├── SharedTypes_v.test.cmj
│   │   ├── SharedTypes_v.test.cmt
│   │   ├── SharedTypes_v.test.res
│   │   ├── Sidebar.ast
│   │   ├── Sidebar.cmi
│   │   ├── Sidebar.cmj
│   │   ├── Sidebar.cmt
│   │   ├── Sidebar.res
│   │   ├── Sidebar_v.test.ast
│   │   ├── Sidebar_v.test.cmi
│   │   ├── Sidebar_v.test.cmj
│   │   ├── Sidebar_v.test.cmt
│   │   ├── Sidebar_v.test.res
│   │   ├── SimulationChainSkipper.ast
│   │   ├── SimulationChainSkipper.cmi
│   │   ├── SimulationChainSkipper.cmj
│   │   ├── SimulationChainSkipper.cmt
│   │   ├── SimulationChainSkipper.res
│   │   ├── SimulationChainSkipper_v.test.ast
│   │   ├── SimulationChainSkipper_v.test.cmi
│   │   ├── SimulationChainSkipper_v.test.cmj
│   │   ├── SimulationChainSkipper_v.test.cmt
│   │   ├── SimulationChainSkipper_v.test.res
│   │   ├── SimulationDriver.ast
│   │   ├── SimulationDriver.cmi
│   │   ├── SimulationDriver.cmj
│   │   ├── SimulationDriver.cmt
│   │   ├── SimulationDriver.res
│   │   ├── SimulationDriver_v.test.ast
│   │   ├── SimulationDriver_v.test.cmi
│   │   ├── SimulationDriver_v.test.cmj
│   │   ├── SimulationDriver_v.test.cmt
│   │   ├── SimulationDriver_v.test.res
│   │   ├── SimulationLogic.ast
│   │   ├── SimulationLogic.cmi
│   │   ├── SimulationLogic.cmj
│   │   ├── SimulationLogic.cmt
│   │   ├── SimulationLogic.res
│   │   ├── SimulationLogic_v.test.ast
│   │   ├── SimulationLogic_v.test.cmi
│   │   ├── SimulationLogic_v.test.cmj
│   │   ├── SimulationLogic_v.test.cmt
│   │   ├── SimulationLogic_v.test.res
│   │   ├── SimulationNavigation.ast
│   │   ├── SimulationNavigation.cmi
│   │   ├── SimulationNavigation.cmj
│   │   ├── SimulationNavigation.cmt
│   │   ├── SimulationNavigation.res
│   │   ├── SimulationNavigation_v.test.ast
│   │   ├── SimulationNavigation_v.test.cmi
│   │   ├── SimulationNavigation_v.test.cmj
│   │   ├── SimulationNavigation_v.test.cmt
│   │   ├── SimulationNavigation_v.test.res
│   │   ├── SimulationPathGenerator.ast
│   │   ├── SimulationPathGenerator.cmi
│   │   ├── SimulationPathGenerator.cmj
│   │   ├── SimulationPathGenerator.cmt
│   │   ├── SimulationPathGenerator.res
│   │   ├── SimulationPathGenerator_v.test.ast
│   │   ├── SimulationPathGenerator_v.test.cmi
│   │   ├── SimulationPathGenerator_v.test.cmj
│   │   ├── SimulationPathGenerator_v.test.cmt
│   │   ├── SimulationPathGenerator_v.test.res
│   │   ├── SimulationReducer.ast
│   │   ├── SimulationReducer.cmi
│   │   ├── SimulationReducer.cmj
│   │   ├── SimulationReducer.cmt
│   │   ├── SimulationReducer.res
│   │   ├── SimulationReducer_v.test.ast
│   │   ├── SimulationReducer_v.test.cmi
│   │   ├── SimulationReducer_v.test.cmj
│   │   ├── SimulationReducer_v.test.cmt
│   │   ├── SimulationReducer_v.test.res
│   │   ├── State.ast
│   │   ├── State.cmi
│   │   ├── State.cmj
│   │   ├── State.cmt
│   │   ├── State.res
│   │   ├── StateInspector.ast
│   │   ├── StateInspector.cmi
│   │   ├── StateInspector.cmj
│   │   ├── StateInspector.cmt
│   │   ├── StateInspector.res
│   │   ├── StateInspector_v.test.ast
│   │   ├── StateInspector_v.test.cmi
│   │   ├── StateInspector_v.test.cmj
│   │   ├── StateInspector_v.test.cmt
│   │   ├── StateInspector_v.test.res
│   │   ├── State_v.test.ast
│   │   ├── State_v.test.cmi
│   │   ├── State_v.test.cmj
│   │   ├── State_v.test.cmt
│   │   ├── State_v.test.res
│   │   ├── SvgManager.ast
│   │   ├── SvgManager.cmi
│   │   ├── SvgManager.cmj
│   │   ├── SvgManager.cmt
│   │   ├── SvgManager.res
│   │   ├── TeaserManager.ast
│   │   ├── TeaserManager.cmi
│   │   ├── TeaserManager.cmj
│   │   ├── TeaserManager.cmt
│   │   ├── TeaserManager.res
│   │   ├── TeaserManager_v.test.ast
│   │   ├── TeaserManager_v.test.cmi
│   │   ├── TeaserManager_v.test.cmj
│   │   ├── TeaserManager_v.test.cmt
│   │   ├── TeaserManager_v.test.res
│   │   ├── TeaserPathfinder.ast
│   │   ├── TeaserPathfinder.cmi
│   │   ├── TeaserPathfinder.cmj
│   │   ├── TeaserPathfinder.cmt
│   │   ├── TeaserPathfinder.res
│   │   ├── TeaserPathfinder_v.test.ast
│   │   ├── TeaserPathfinder_v.test.cmi
│   │   ├── TeaserPathfinder_v.test.cmj
│   │   ├── TeaserPathfinder_v.test.cmt
│   │   ├── TeaserPathfinder_v.test.res
│   │   ├── TeaserRecorder.ast
│   │   ├── TeaserRecorder.cmi
│   │   ├── TeaserRecorder.cmj
│   │   ├── TeaserRecorder.cmt
│   │   ├── TeaserRecorder.res
│   │   ├── TeaserRecorder_v.test.ast
│   │   ├── TeaserRecorder_v.test.cmi
│   │   ├── TeaserRecorder_v.test.cmj
│   │   ├── TeaserRecorder_v.test.cmt
│   │   ├── TeaserRecorder_v.test.res
│   │   ├── TestRunner.ast
│   │   ├── TestRunner.cmi
│   │   ├── TestRunner.cmj
│   │   ├── TestRunner.cmt
│   │   ├── TestRunner.res
│   │   ├── TestUtils.ast
│   │   ├── TestUtils.cmi
│   │   ├── TestUtils.cmj
│   │   ├── TestUtils.cmt
│   │   ├── TestUtils.res
│   │   ├── TimelineReducer.ast
│   │   ├── TimelineReducer.cmi
│   │   ├── TimelineReducer.cmj
│   │   ├── TimelineReducer.cmt
│   │   ├── TimelineReducer.res
│   │   ├── TimelineReducer_v.test.ast
│   │   ├── TimelineReducer_v.test.cmi
│   │   ├── TimelineReducer_v.test.cmj
│   │   ├── TimelineReducer_v.test.cmt
│   │   ├── TimelineReducer_v.test.res
│   │   ├── Tooltip.ast
│   │   ├── Tooltip.cmi
│   │   ├── Tooltip.cmj
│   │   ├── Tooltip.cmt
│   │   ├── Tooltip.res
│   │   ├── Tooltip_v.test.ast
│   │   ├── Tooltip_v.test.cmi
│   │   ├── Tooltip_v.test.cmj
│   │   ├── Tooltip_v.test.cmt
│   │   ├── Tooltip_v.test.res
│   │   ├── TourLogic.ast
│   │   ├── TourLogic.cmi
│   │   ├── TourLogic.cmj
│   │   ├── TourLogic.cmt
│   │   ├── TourLogic.res
│   │   ├── TourLogic_v.test.ast
│   │   ├── TourLogic_v.test.cmi
│   │   ├── TourLogic_v.test.cmj
│   │   ├── TourLogic_v.test.cmt
│   │   ├── TourLogic_v.test.res
│   │   ├── TourTemplateAssets.ast
│   │   ├── TourTemplateAssets.cmi
│   │   ├── TourTemplateAssets.cmj
│   │   ├── TourTemplateAssets.cmt
│   │   ├── TourTemplateAssets.res
│   │   ├── TourTemplateAssets_v.test.ast
│   │   ├── TourTemplateAssets_v.test.cmi
│   │   ├── TourTemplateAssets_v.test.cmj
│   │   ├── TourTemplateAssets_v.test.cmt
│   │   ├── TourTemplateAssets_v.test.res
│   │   ├── TourTemplateScripts.ast
│   │   ├── TourTemplateScripts.cmi
│   │   ├── TourTemplateScripts.cmj
│   │   ├── TourTemplateScripts.cmt
│   │   ├── TourTemplateScripts.res
│   │   ├── TourTemplateScripts_v.test.ast
│   │   ├── TourTemplateScripts_v.test.cmi
│   │   ├── TourTemplateScripts_v.test.cmj
│   │   ├── TourTemplateScripts_v.test.cmt
│   │   ├── TourTemplateScripts_v.test.res
│   │   ├── TourTemplateStyles.ast
│   │   ├── TourTemplateStyles.cmi
│   │   ├── TourTemplateStyles.cmj
│   │   ├── TourTemplateStyles.cmt
│   │   ├── TourTemplateStyles.res
│   │   ├── TourTemplateStyles_v.test.ast
│   │   ├── TourTemplateStyles_v.test.cmi
│   │   ├── TourTemplateStyles_v.test.cmj
│   │   ├── TourTemplateStyles_v.test.cmt
│   │   ├── TourTemplateStyles_v.test.res
│   │   ├── TourTemplates.ast
│   │   ├── TourTemplates.cmi
│   │   ├── TourTemplates.cmj
│   │   ├── TourTemplates.cmt
│   │   ├── TourTemplates.res
│   │   ├── TourTemplates_v.test.ast
│   │   ├── TourTemplates_v.test.cmi
│   │   ├── TourTemplates_v.test.cmj
│   │   ├── TourTemplates_v.test.cmt
│   │   ├── TourTemplates_v.test.res
│   │   ├── Types.ast
│   │   ├── Types.cmi
│   │   ├── Types.cmj
│   │   ├── Types.cmt
│   │   ├── Types.res
│   │   ├── Types_v.test.ast
│   │   ├── Types_v.test.cmi
│   │   ├── Types_v.test.cmj
│   │   ├── Types_v.test.cmt
│   │   ├── Types_v.test.res
│   │   ├── UiReducer.ast
│   │   ├── UiReducer.cmi
│   │   ├── UiReducer.cmj
│   │   ├── UiReducer.cmt
│   │   ├── UiReducer.res
│   │   ├── UiReducer_v.test.ast
│   │   ├── UiReducer_v.test.cmi
│   │   ├── UiReducer_v.test.cmj
│   │   ├── UiReducer_v.test.cmt
│   │   ├── UiReducer_v.test.res
│   │   ├── UploadProcessor.ast
│   │   ├── UploadProcessor.cmi
│   │   ├── UploadProcessor.cmj
│   │   ├── UploadProcessor.cmt
│   │   ├── UploadProcessor.res
│   │   ├── UploadProcessorLogic.ast
│   │   ├── UploadProcessorLogic.cmi
│   │   ├── UploadProcessorLogic.cmj
│   │   ├── UploadProcessorLogic.cmt
│   │   ├── UploadProcessorLogic.res
│   │   ├── UploadProcessorLogic_v.test.ast
│   │   ├── UploadProcessorLogic_v.test.cmi
│   │   ├── UploadProcessorLogic_v.test.cmj
│   │   ├── UploadProcessorLogic_v.test.cmt
│   │   ├── UploadProcessorLogic_v.test.res
│   │   ├── UploadProcessorTypes.ast
│   │   ├── UploadProcessorTypes.cmi
│   │   ├── UploadProcessorTypes.cmj
│   │   ├── UploadProcessorTypes.cmt
│   │   ├── UploadProcessorTypes.res
│   │   ├── UploadProcessorTypes_v.test.ast
│   │   ├── UploadProcessorTypes_v.test.cmi
│   │   ├── UploadProcessorTypes_v.test.cmj
│   │   ├── UploadProcessorTypes_v.test.cmt
│   │   ├── UploadProcessorTypes_v.test.res
│   │   ├── UploadProcessor_v.test.ast
│   │   ├── UploadProcessor_v.test.cmi
│   │   ├── UploadProcessor_v.test.cmj
│   │   ├── UploadProcessor_v.test.cmt
│   │   ├── UploadProcessor_v.test.res
│   │   ├── UploadReport.ast
│   │   ├── UploadReport.cmi
│   │   ├── UploadReport.cmj
│   │   ├── UploadReport.cmt
│   │   ├── UploadReport.res
│   │   ├── UploadReport_v.test.ast
│   │   ├── UploadReport_v.test.cmi
│   │   ├── UploadReport_v.test.cmj
│   │   ├── UploadReport_v.test.cmt
│   │   ├── UploadReport_v.test.res
│   │   ├── UrlUtils.ast
│   │   ├── UrlUtils.cmi
│   │   ├── UrlUtils.cmj
│   │   ├── UrlUtils.cmt
│   │   ├── UrlUtils.res
│   │   ├── UrlUtils_v.test.ast
│   │   ├── UrlUtils_v.test.cmi
│   │   ├── UrlUtils_v.test.cmj
│   │   ├── UrlUtils_v.test.cmt
│   │   ├── UrlUtils_v.test.res
│   │   ├── Version.ast
│   │   ├── Version.cmi
│   │   ├── Version.cmj
│   │   ├── Version.cmt
│   │   ├── Version.res
│   │   ├── VersionData.ast
│   │   ├── VersionData.cmi
│   │   ├── VersionData.cmj
│   │   ├── VersionData.cmt
│   │   ├── VersionData.res
│   │   ├── VersionData_v.test.ast
│   │   ├── VersionData_v.test.cmi
│   │   ├── VersionData_v.test.cmj
│   │   ├── VersionData_v.test.cmt
│   │   ├── VersionData_v.test.res
│   │   ├── Version_v.test.ast
│   │   ├── Version_v.test.cmi
│   │   ├── Version_v.test.cmj
│   │   ├── Version_v.test.cmt
│   │   ├── Version_v.test.res
│   │   ├── VideoEncoder.ast
│   │   ├── VideoEncoder.cmi
│   │   ├── VideoEncoder.cmj
│   │   ├── VideoEncoder.cmt
│   │   ├── VideoEncoder.res
│   │   ├── VideoEncoder_v.test.ast
│   │   ├── VideoEncoder_v.test.cmi
│   │   ├── VideoEncoder_v.test.cmj
│   │   ├── VideoEncoder_v.test.cmt
│   │   ├── VideoEncoder_v.test.res
│   │   ├── ViewerFollow.ast
│   │   ├── ViewerFollow.cmi
│   │   ├── ViewerFollow.cmj
│   │   ├── ViewerFollow.cmt
│   │   ├── ViewerFollow.res
│   │   ├── ViewerFollow_v.test.ast
│   │   ├── ViewerFollow_v.test.cmi
│   │   ├── ViewerFollow_v.test.cmj
│   │   ├── ViewerFollow_v.test.cmt
│   │   ├── ViewerFollow_v.test.res
│   │   ├── ViewerLoader.ast
│   │   ├── ViewerLoader.cmi
│   │   ├── ViewerLoader.cmj
│   │   ├── ViewerLoader.cmt
│   │   ├── ViewerLoader.res
│   │   ├── ViewerLoader_v.test.ast
│   │   ├── ViewerLoader_v.test.cmi
│   │   ├── ViewerLoader_v.test.cmj
│   │   ├── ViewerLoader_v.test.cmt
│   │   ├── ViewerLoader_v.test.res
│   │   ├── ViewerManager.ast
│   │   ├── ViewerManager.cmi
│   │   ├── ViewerManager.cmj
│   │   ├── ViewerManager.cmt
│   │   ├── ViewerManager.res
│   │   ├── ViewerManager_v.test.ast
│   │   ├── ViewerManager_v.test.cmi
│   │   ├── ViewerManager_v.test.cmj
│   │   ├── ViewerManager_v.test.cmt
│   │   ├── ViewerManager_v.test.res
│   │   ├── ViewerSnapshot.ast
│   │   ├── ViewerSnapshot.cmi
│   │   ├── ViewerSnapshot.cmj
│   │   ├── ViewerSnapshot.cmt
│   │   ├── ViewerSnapshot.res
│   │   ├── ViewerSnapshot_v.test.ast
│   │   ├── ViewerSnapshot_v.test.cmi
│   │   ├── ViewerSnapshot_v.test.cmj
│   │   ├── ViewerSnapshot_v.test.cmt
│   │   ├── ViewerSnapshot_v.test.res
│   │   ├── ViewerState.ast
│   │   ├── ViewerState.cmi
│   │   ├── ViewerState.cmj
│   │   ├── ViewerState.cmt
│   │   ├── ViewerState.res
│   │   ├── ViewerState_v.test.ast
│   │   ├── ViewerState_v.test.cmi
│   │   ├── ViewerState_v.test.cmj
│   │   ├── ViewerState_v.test.cmt
│   │   ├── ViewerState_v.test.res
│   │   ├── ViewerTypes.ast
│   │   ├── ViewerTypes.cmi
│   │   ├── ViewerTypes.cmj
│   │   ├── ViewerTypes.cmt
│   │   ├── ViewerTypes.res
│   │   ├── ViewerTypes_v.test.ast
│   │   ├── ViewerTypes_v.test.cmi
│   │   ├── ViewerTypes_v.test.cmj
│   │   ├── ViewerTypes_v.test.cmt
│   │   ├── ViewerTypes_v.test.res
│   │   ├── ViewerUI.ast
│   │   ├── ViewerUI.cmi
│   │   ├── ViewerUI.cmj
│   │   ├── ViewerUI.cmt
│   │   ├── ViewerUI.res
│   │   ├── ViewerUI_v.test.ast
│   │   ├── ViewerUI_v.test.cmi
│   │   ├── ViewerUI_v.test.cmj
│   │   ├── ViewerUI_v.test.cmt
│   │   ├── ViewerUI_v.test.res
│   │   ├── VisualPipeline.ast
│   │   ├── VisualPipeline.cmi
│   │   ├── VisualPipeline.cmj
│   │   ├── VisualPipeline.cmt
│   │   ├── VisualPipeline.res
│   │   ├── VisualPipeline_v.test.ast
│   │   ├── VisualPipeline_v.test.cmi
│   │   ├── VisualPipeline_v.test.cmj
│   │   ├── VisualPipeline_v.test.cmt
│   │   ├── VisualPipeline_v.test.res
│   │   ├── VitestSmoke.test.ast
│   │   ├── VitestSmoke.test.cmi
│   │   ├── VitestSmoke.test.cmj
│   │   ├── VitestSmoke.test.cmt
│   │   ├── VitestSmoke.test.res
│   │   ├── mod.ast
│   │   ├── mod.cmi
│   │   ├── mod.cmj
│   │   ├── mod.cmt
│   │   └── mod.res
│   └── rescript.lock
├── logs
│   ├── error.log
│   ├── log_changes.txt
│   ├── project-guard.log
│   └── telemetry.log
├── old_ref
│   ├── 7aadee4
│   │   ├── CHANGELOG.md
│   │   ├── FIX_PROJECT_NAME_BUG.md
│   │   ├── GEMINI.md
│   │   ├── MAP.md
│   │   ├── README.md
│   │   ├── REQUIREMENTS.txt
│   │   ├── backend
│   │   │   ├── Cargo.lock
│   │   │   ├── Cargo.toml
│   │   │   ├── backend.log
│   │   │   ├── backend_run.log
│   │   │   ├── bin
│   │   │   │   └── ffmpeg
│   │   │   ├── migrations
│   │   │   │   └── 20260124000000_init.sql
│   │   │   ├── src
│   │   │   │   ├── api
│   │   │   │   │   ├── auth.rs
│   │   │   │   │   ├── geocoding.rs
│   │   │   │   │   ├── media
│   │   │   │   │   │   ├── image.rs
│   │   │   │   │   │   ├── mod.rs
│   │   │   │   │   │   ├── serve.rs
│   │   │   │   │   │   ├── similarity.rs
│   │   │   │   │   │   └── video.rs
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   ├── project
│   │   │   │   │   │   ├── export.rs
│   │   │   │   │   │   ├── mod.rs
│   │   │   │   │   │   ├── navigation.rs
│   │   │   │   │   │   ├── storage.rs
│   │   │   │   │   │   └── validation.rs
│   │   │   │   │   ├── telemetry.rs
│   │   │   │   │   └── utils.rs
│   │   │   │   ├── lib.rs
│   │   │   │   ├── main.rs
│   │   │   │   ├── metrics.rs
│   │   │   │   ├── middleware
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   ├── quota_check.rs
│   │   │   │   │   └── request_tracker.rs
│   │   │   │   ├── models
│   │   │   │   │   ├── errors.rs
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   ├── project.rs
│   │   │   │   │   └── user.rs
│   │   │   │   ├── pathfinder
│   │   │   │   │   ├── algorithms.rs
│   │   │   │   │   ├── graph.rs
│   │   │   │   │   ├── mod.rs
│   │   │   │   │   └── utils.rs
│   │   │   │   └── services
│   │   │   │       ├── auth.rs
│   │   │   │       ├── database.rs
│   │   │   │       ├── geocoding.rs
│   │   │   │       ├── media.rs
│   │   │   │       ├── mod.rs
│   │   │   │       ├── project
│   │   │   │       │   ├── load.rs
│   │   │   │       │   ├── mod.rs
│   │   │   │       │   ├── package.rs
│   │   │   │       │   └── validate.rs
│   │   │   │       ├── shutdown.rs
│   │   │   │       ├── upload_quota.rs
│   │   │   │       └── upload_quota_tests.rs
│   │   │   ├── startup.log
│   │   │   ├── startup_debug.log
│   │   │   ├── startup_debug_v2.log
│   │   │   ├── startup_log.txt
│   │   │   └── tests
│   │   │       └── shutdown_test.rs
│   │   ├── build_output.txt
│   │   ├── build_output_clean.txt
│   │   ├── build_warnings.txt
│   │   ├── cache
│   │   │   └── geocoding.json
│   │   ├── components.json
│   │   ├── css
│   │   │   ├── animations.css
│   │   │   ├── base.css
│   │   │   ├── components
│   │   │   │   ├── buttons.css
│   │   │   │   ├── error-fallback.css
│   │   │   │   ├── floor-nav.css
│   │   │   │   ├── label-menu.css
│   │   │   │   ├── modals.css
│   │   │   │   ├── popover.css
│   │   │   │   ├── scene-groups.css
│   │   │   │   ├── ui.css
│   │   │   │   ├── upload-report.css
│   │   │   │   └── viewer.css
│   │   │   ├── layout.css
│   │   │   ├── legacy.css
│   │   │   ├── output.css
│   │   │   ├── style.css
│   │   │   ├── tailwind.css
│   │   │   └── variables.css
│   │   ├── dev.log
│   │   ├── docs
│   │   │   ├── ARCHITECTURE.md
│   │   │   ├── AUTOPILOT_SIMULATION_ANALYSIS.md
│   │   │   ├── AUTOPILOT_TASKS_SUMMARY.md
│   │   │   ├── DESIGN_SYSTEM.md
│   │   │   ├── DEVELOPMENT_GUIDELINES.md
│   │   │   ├── INITIALIZATION_STANDARDS.md
│   │   │   ├── PROJECT_EVOLUTION.md
│   │   │   ├── QUALITY_ASSURANCE_AUDITS.md
│   │   │   ├── TESTING_STRATEGY.md
│   │   │   ├── _pending_integration
│   │   │   │   ├── BUG_ANALYSIS_PROJECT_NAME.md
│   │   │   │   ├── SESSION_SUMMARY.md
│   │   │   │   └── TASK_ANALYSIS_AND_RENUMBERING.md
│   │   │   └── openapi.yaml
│   │   ├── full_build_output.txt
│   │   ├── icons.txt
│   │   ├── index.html
│   │   ├── jsconfig.json
│   │   ├── logs
│   │   │   └── log_changes.txt
│   │   ├── old_ref
│   │   │   ├── REF.md
│   │   │   └── v4.3.6+7_a34c1dd
│   │   │       ├── AGENTS.md
│   │   │       ├── GEMINI.md
│   │   │       ├── README.md
│   │   │       ├── backend
│   │   │       │   ├── Cargo.toml
│   │   │       │   ├── backend.log
│   │   │       │   ├── backend_run.log
│   │   │       │   ├── src
│   │   │       │   │   ├── api
│   │   │       │   │   │   ├── geocoding.rs
│   │   │       │   │   │   ├── media
│   │   │       │   │   │   │   ├── image.rs
│   │   │       │   │   │   │   ├── mod.rs
│   │   │       │   │   │   │   ├── serve.rs
│   │   │       │   │   │   │   ├── similarity.rs
│   │   │       │   │   │   │   └── video.rs
│   │   │       │   │   │   ├── mod.rs
│   │   │       │   │   │   ├── project.rs
│   │   │       │   │   │   ├── telemetry.rs
│   │   │       │   │   │   └── utils.rs
│   │   │       │   │   ├── lib.rs
│   │   │       │   │   ├── main.rs
│   │   │       │   │   ├── metrics.rs
│   │   │       │   │   ├── middleware
│   │   │       │   │   │   ├── mod.rs
│   │   │       │   │   │   ├── quota_check.rs
│   │   │       │   │   │   └── request_tracker.rs
│   │   │       │   │   ├── models
│   │   │       │   │   │   ├── errors.rs
│   │   │       │   │   │   └── mod.rs
│   │   │       │   │   ├── pathfinder
│   │   │       │   │   │   ├── algorithms.rs
│   │   │       │   │   │   ├── graph.rs
│   │   │       │   │   │   ├── mod.rs
│   │   │       │   │   │   └── utils.rs
│   │   │       │   │   └── services
│   │   │       │   │       ├── geocoding.rs
│   │   │       │   │       ├── media.rs
│   │   │       │   │       ├── mod.rs
│   │   │       │   │       ├── project
│   │   │       │   │       │   ├── load.rs
│   │   │       │   │       │   ├── mod.rs
│   │   │       │   │       │   ├── package.rs
│   │   │       │   │       │   └── validate.rs
│   │   │       │   │       ├── shutdown.rs
│   │   │       │   │       ├── upload_quota.rs
│   │   │       │   │       └── upload_quota_tests.rs
│   │   │       │   ├── startup.log
│   │   │       │   ├── startup_debug.log
│   │   │       │   ├── startup_debug_v2.log
│   │   │       │   ├── startup_log.txt
│   │   │       │   └── tests
│   │   │       │       └── shutdown_test.rs
│   │   │       ├── cache
│   │   │       │   └── geocoding.json
│   │   │       ├── css
│   │   │       │   ├── animations.css
│   │   │       │   ├── base.css
│   │   │       │   ├── components
│   │   │       │   │   ├── buttons.css
│   │   │       │   │   ├── error-fallback.css
│   │   │       │   │   ├── floor-nav.css
│   │   │       │   │   ├── label-menu.css
│   │   │       │   │   ├── modals.css
│   │   │       │   │   ├── scene-groups.css
│   │   │       │   │   ├── ui.css
│   │   │       │   │   ├── upload-report.css
│   │   │       │   │   └── viewer.css
│   │   │       │   ├── layout.css
│   │   │       │   ├── legacy.css
│   │   │       │   ├── style.css
│   │   │       │   ├── tailwind.css
│   │   │       │   └── variables.css
│   │   │       ├── dev.log
│   │   │       ├── dev_prefs
│   │   │       │   ├── logging_debugging_system.md
│   │   │       │   └── ui_preferences.md
│   │   │       ├── docs
│   │   │       │   ├── ACCESSIBILITY_SYSTEM.md
│   │   │       │   ├── ARCHITECTURE_DIAGRAM.md
│   │   │       │   ├── AntiGravity Workflow Manual.md
│   │   │       │   ├── BUILD_VERIFICATION_QUICK_REFERENCE.md
│   │   │       │   ├── COLOR_PALETTE_REFERENCE.md
│   │   │       │   ├── CSS_ARCHITECTURE_AND_BEST_PRACTICES.md
│   │   │       │   ├── CSS_MIGRATION_ANALYSIS.md
│   │   │       │   ├── CSS_MIGRATION_SUMMARY.md
│   │   │       │   ├── IMPROVEMENTS.md
│   │   │       │   ├── OBSERVABILITY_AND_ERROR_HANDLING.md
│   │   │       │   ├── PERFORMANCE_AND_METRICS.md
│   │   │       │   ├── PROJECT_GOVERNANCE_AND_STATUS.md
│   │   │       │   ├── RELEASE_v4.0.9.md
│   │   │       │   ├── SECURITY_AND_STABILITY.md
│   │   │       │   ├── TASK_CREATION_FIX_SUMMARY.md
│   │   │       │   ├── TESTING_QUICK_REFERENCE.md
│   │   │       │   ├── TYPOGRAPHY_AND_UI_SYSTEM.md
│   │   │       │   ├── UNIT_TESTING_INTEGRATION.md
│   │   │       │   └── openapi.yaml
│   │   │       ├── index.html
│   │   │       ├── logs
│   │   │       │   └── log_changes.txt
│   │   │       ├── package.json
│   │   │       ├── plans
│   │   │       │   ├── debug_telemetry_fix_plan.md
│   │   │       │   ├── logical_inconsistencies_analysis.md
│   │   │       │   └── step1_cleanup_notes.md
│   │   │       ├── postcss.config.js
│   │   │       ├── public
│   │   │       │   ├── early-boot.js
│   │   │       │   ├── images
│   │   │       │   │   ├── icon-192.png
│   │   │       │   │   ├── icon-512.png
│   │   │       │   │   ├── logo.png
│   │   │       │   │   └── og-preview.png
│   │   │       │   ├── libs
│   │   │       │   │   ├── FileSaver.min.js
│   │   │       │   │   ├── jszip.min.js
│   │   │       │   │   ├── pannellum.css
│   │   │       │   │   └── pannellum.js
│   │   │       │   ├── manifest.json
│   │   │       │   ├── service-worker.js
│   │   │       │   └── sounds
│   │   │       │       └── click.wav
│   │   │       ├── rescript.json
│   │   │       ├── rsbuild.config.mjs
│   │   │       ├── scripts
│   │   │       │   ├── cleanup_logs.sh
│   │   │       │   ├── commit.sh
│   │   │       │   ├── debug-connectivity.js
│   │   │       │   ├── detect-missing-tests.js
│   │   │       │   ├── dev-mode.sh
│   │   │       │   ├── increment-build.js
│   │   │       │   ├── prune-snapshots.sh
│   │   │       │   ├── restore-snapshot.sh
│   │   │       │   ├── setup.sh
│   │   │       │   ├── sync-sw.cjs
│   │   │       │   ├── test-logging.js
│   │   │       │   ├── update-version.js
│   │   │       │   └── watch-file-limits.sh
│   │   │       ├── src
│   │   │       │   ├── App.res
│   │   │       │   ├── Main.res
│   │   │       │   ├── ReBindings.res
│   │   │       │   ├── ServiceWorker.res
│   │   │       │   ├── ServiceWorkerMain.res
│   │   │       │   ├── components
│   │   │       │   │   ├── ErrorFallbackUI.res
│   │   │       │   │   ├── HotspotManager.res
│   │   │       │   │   ├── LabelMenu.res
│   │   │       │   │   ├── LinkModal.res
│   │   │       │   │   ├── ModalContext.res
│   │   │       │   │   ├── NotificationContext.res
│   │   │       │   │   ├── RemaxErrorBoundary.res
│   │   │       │   │   ├── SceneList.res
│   │   │       │   │   ├── Sidebar.res
│   │   │       │   │   ├── UploadReport.res
│   │   │       │   │   ├── ViewerFollow.res
│   │   │       │   │   ├── ViewerLoader.res
│   │   │       │   │   ├── ViewerManager.res
│   │   │       │   │   ├── ViewerSnapshot.res
│   │   │       │   │   ├── ViewerState.res
│   │   │       │   │   ├── ViewerTypes.res
│   │   │       │   │   ├── ViewerUI.res
│   │   │       │   │   └── VisualPipeline.res
│   │   │       │   ├── core
│   │   │       │   │   ├── Actions.res
│   │   │       │   │   ├── AppContext.res
│   │   │       │   │   ├── GlobalStateBridge.res
│   │   │       │   │   ├── JsonTypes.res
│   │   │       │   │   ├── Reducer.res
│   │   │       │   │   ├── ReducerHelpers.res
│   │   │       │   │   ├── SharedTypes.res
│   │   │       │   │   ├── State.res
│   │   │       │   │   ├── Types.res
│   │   │       │   │   └── reducers
│   │   │       │   │       ├── HotspotReducer.res
│   │   │       │   │       ├── NavigationReducer.res
│   │   │       │   │       ├── ProjectReducer.res
│   │   │       │   │       ├── RootReducer.res
│   │   │       │   │       ├── SceneReducer.res
│   │   │       │   │       ├── SimulationReducer.res
│   │   │       │   │       ├── TimelineReducer.res
│   │   │       │   │       ├── UiReducer.res
│   │   │       │   │       └── mod.res
│   │   │       │   ├── index.js
│   │   │       │   ├── systems
│   │   │       │   │   ├── AudioManager.res
│   │   │       │   │   ├── BackendApi.res
│   │   │       │   │   ├── DownloadSystem.res
│   │   │       │   │   ├── EventBus.res
│   │   │       │   │   ├── ExifParser.res
│   │   │       │   │   ├── ExifReportGenerator.res
│   │   │       │   │   ├── Exporter.res
│   │   │       │   │   ├── HotspotLine.res
│   │   │       │   │   ├── InputSystem.res
│   │   │       │   │   ├── Navigation.res
│   │   │       │   │   ├── NavigationController.res
│   │   │       │   │   ├── NavigationRenderer.res
│   │   │       │   │   ├── NavigationUI.res
│   │   │       │   │   ├── ProjectData.res
│   │   │       │   │   ├── ProjectManager.res
│   │   │       │   │   ├── Resizer.res
│   │   │       │   │   ├── ServerTeaser.res
│   │   │       │   │   ├── SimulationChainSkipper.res
│   │   │       │   │   ├── SimulationDriver.res
│   │   │       │   │   ├── SimulationLogic.res
│   │   │       │   │   ├── SimulationNavigation.res
│   │   │       │   │   ├── SimulationPathGenerator.res
│   │   │       │   │   ├── TeaserManager.res
│   │   │       │   │   ├── TeaserPathfinder.res
│   │   │       │   │   ├── TeaserRecorder.res
│   │   │       │   │   ├── TourTemplateAssets.res
│   │   │       │   │   ├── TourTemplateScripts.res
│   │   │       │   │   ├── TourTemplateStyles.res
│   │   │       │   │   ├── TourTemplates.res
│   │   │       │   │   ├── UploadProcessor.res
│   │   │       │   │   └── VideoEncoder.res
│   │   │       │   └── utils
│   │   │       │       ├── ColorPalette.res
│   │   │       │       ├── Constants.res
│   │   │       │       ├── GeoUtils.res
│   │   │       │       ├── ImageOptimizer.res
│   │   │       │       ├── ImageOptimizer.resi
│   │   │       │       ├── LazyLoad.res
│   │   │       │       ├── Logger.res
│   │   │       │       ├── PathInterpolation.res
│   │   │       │       ├── ProgressBar.res
│   │   │       │       ├── RequestQueue.res
│   │   │       │       ├── SessionStore.res
│   │   │       │       ├── StateInspector.res
│   │   │       │       ├── TourLogic.res
│   │   │       │       ├── UrlUtils.res
│   │   │       │       ├── Version.res
│   │   │       │       └── VersionData.res
│   │   │       ├── start_prod.sh
│   │   │       ├── tailwind.config.js
│   │   │       ├── tasks
│   │   │       │   ├── TASKS.md
│   │   │       │   ├── completed
│   │   │       │   │   ├── 175_fix_runtime_safety_getexn_REPORT.md
│   │   │       │   │   ├── 177_fix_error_handling_REPORT.md
│   │   │       │   │   ├── 178_Restore_v420_Viewer_HUD_Labels_and_Prompts_ABORTED.md
│   │   │       │   │   ├── 179_Restore_v420_Visual_Pipeline_ABORTED.md
│   │   │       │   │   ├── 180_Restore_v420_Simulation_Advanced_Mechanics_ABORTED.md
│   │   │       │   │   ├── 181_extract_business_logic_ABORTED.md
│   │   │       │   │   ├── 194_Add_Tests_for_ServiceWorkerMain_REPORT.md
│   │   │       │   │   ├── 195_Add_Tests_for_UrlUtils_REPORT.md
│   │   │       │   │   ├── 196_Add_Tests_for_VersionData_REPORT.md
│   │   │       │   │   ├── 197_Refactor_RootReducer_Pipeline_REPORT.md
│   │   │       │   │   ├── 198_Implement_Session_Persistence_REPORT.md
│   │   │       │   │   ├── 199_Enhance_GlobalState_Safety_REPORT.md
│   │   │       │   │   ├── 200_Detailed_CSS_Styling_Comparison_REPORT.md
│   │   │       │   │   ├── 206_Comprehensive_Migration_Summary_REPORT.md
│   │   │       │   │   ├── 207_Comprehensive_Testing_And_QA_Summary_REPORT.md
│   │   │       │   │   ├── 208_Backend_Systems_And_Optimization_Summary_REPORT.md
│   │   │       │   │   ├── 209_Refactoring_Security_UX_Summary_REPORT.md
│   │   │       │   │   ├── 216_Fix_Waypoint_Persistence_And_Link_Default_REPORT.md
│   │   │       │   │   ├── 217_Fix_Path_Screen_Stickiness_And_Default_Link_REPORT.md
│   │   │       │   │   ├── 218_Fix_Waypoint_Sticking_To_Screen_REPORT.md
│   │   │       │   │   ├── 219_Fix_Hotspot_Disappearance_After_Save_REPORT.md
│   │   │       │   │   ├── 220_Fix_Hotspot_Disappearance_V2_REPORT.md
│   │   │       │   │   ├── 221_Fix_Invisible_Waypoint_After_Save_REPORT.md
│   │   │       │   │   ├── 222_restore_css_design_tokens_REPORT.md
│   │   │       │   │   ├── 223_restore_premium_ui_components_REPORT.md
│   │   │       │   │   ├── 224_restore_linking_mode_visuals_REPORT.md
│   │   │       │   │   ├── 225_restore_simulation_lockdown_REPORT.md
│   │   │       │   │   ├── 226_restore_premium_hotspots_REPORT.md
│   │   │       │   │   ├── 264_fix_upload_failure_REPORT.md
│   │   │       │   │   ├── 265_troubleshoot_yellow_rod_REPORT.md
│   │   │       │   │   ├── 266_refine_linking_visuals_REPORT.md
│   │   │       │   │   ├── 267_update_camera_movement_behavior_REPORT.md
│   │   │       │   │   ├── 268_verify_scenelist_virtualization_ABORTED.md
│   │   │       │   │   ├── 270_auto_select_first_scene_on_start.md
│   │   │       │   │   ├── 271_refactor_sidebar_inline_styles_REPORT.md
│   │   │       │   │   ├── 272_refactor_viewerui_inline_styles_REPORT.md
│   │   │       │   │   ├── 273_centralize_rescript_styling_tokens_REPORT.md
│   │   │       │   │   ├── 274_fix_hotspot_navigation_click_REPORT.md
│   │   │       │   │   ├── 274_migrate_conditional_styles_to_classes_REPORT.md
│   │   │       │   │   ├── 275_complete_css_variable_migration.md
│   │   │       │   │   ├── 276_refactor_uploadreport_inline_styles.md
│   │   │       │   │   ├── 277_design_system_documentation_and_compliance.md
│   │   │       │   │   ├── 278_create_css_gradient_variables.md
│   │   │       │   │   ├── 279_add_color_accessibility_audit.md
│   │   │       │   │   ├── 283_implement_remax_centric_theme.md
│   │   │       │   │   ├── 285_autopilot_ui_fixes_REPORT.md
│   │   │       │   │   ├── 286_refine_hotspot_chevron_click_range_REPORT.md
│   │   │       │   │   ├── 287_merge_navigation_chevron_hit_area_REPORT.md
│   │   │       │   │   └── 288_reduce_shine_animation_speed_REPORT.md
│   │   │       │   ├── current_refactor.md
│   │   │       │   └── postponed
│   │   │       │       ├── 176_fix_security_innerhtml.md
│   │   │       │       ├── 186_implement_backend_geocoding_proxy.md
│   │   │       │       ├── 201_implement_backend_geocoding_cache.md
│   │   │       │       ├── 202_offload_image_similarity_to_backend.md
│   │   │       │       ├── 205_re_evaluate_webp_quality.md
│   │   │       │       ├── 284_theme_switching_infrastructure.md
│   │   │       │       ├── 289_refactor_ui_anchor_positioning.md
│   │   │       │       └── tests
│   │   │       │           ├── 203_expand_test_coverage.md
│   │   │       │           ├── 204_Add_Tests_for_ImageOptimizer.md
│   │   │       │           ├── 210_Add_Tests_for_AppContext.md
│   │   │       │           ├── 211_Add_Tests_for_UiReducer.md
│   │   │       │           ├── 212_Add_Tests_for_NavigationController.md
│   │   │       │           ├── 213_Add_Tests_for_SimulationDriver.md
│   │   │       │           ├── 214_Add_Tests_for_SimulationLogic.md
│   │   │       │           ├── 215_Add_Tests_for_SessionStore.md
│   │   │       │           ├── 269_Add_Tests_for_RequestQueue.md
│   │   │       │           └── 280_visual_regression_testing.md
│   │   │       ├── tests
│   │   │       │   ├── TestRunner.res
│   │   │       │   ├── node-setup.js
│   │   │       │   └── unit
│   │   │       │       ├── ActionsTest.res
│   │   │       │       ├── AppContextTest.res
│   │   │       │       ├── AppTest.res
│   │   │       │       ├── AudioManagerTest.res
│   │   │       │       ├── BackendApiTest.res
│   │   │       │       ├── ConstantsTest.res
│   │   │       │       ├── DownloadSystemTest.res
│   │   │       │       ├── EventBusTest.res
│   │   │       │       ├── ExifParserTest.res
│   │   │       │       ├── ExifReportGeneratorTest.res
│   │   │       │       ├── ExporterTest.res
│   │   │       │       ├── GeoUtilsTest.res
│   │   │       │       ├── GlobalStateBridgeTest.res
│   │   │       │       ├── HotspotLine.test.res
│   │   │       │       ├── HotspotLine_v.test.res
│   │   │       │       ├── HotspotReducerTest.res
│   │   │       │       ├── ImageOptimizerTest.res
│   │   │       │       ├── InputSystemTest.res
│   │   │       │       ├── JsonTypesTest.res
│   │   │       │       ├── LazyLoadTest.res
│   │   │       │       ├── LoggerTest.res
│   │   │       │       ├── MainTest.res
│   │   │       │       ├── NavigationControllerTest.res
│   │   │       │       ├── NavigationReducerTest.res
│   │   │       │       ├── NavigationRendererTest.res
│   │   │       │       ├── NavigationTest.res
│   │   │       │       ├── PathInterpolationTest.res
│   │   │       │       ├── ProgressBarTest.res
│   │   │       │       ├── ProjectDataTest.res
│   │   │       │       ├── ProjectManagerTest.res
│   │   │       │       ├── ProjectReducerTest.res
│   │   │       │       ├── ReBindingsTest.res
│   │   │       │       ├── ReducerHelpersTest.res
│   │   │       │       ├── ReducerTest.res
│   │   │       │       ├── RequestQueueTest.res
│   │   │       │       ├── ResizerTest.res
│   │   │       │       ├── RootReducerTest.res
│   │   │       │       ├── SceneReducerTest.res
│   │   │       │       ├── ServerTeaserTest.res
│   │   │       │       ├── ServiceWorkerMainTest.res
│   │   │       │       ├── ServiceWorkerTest.res
│   │   │       │       ├── SessionStoreTest.res
│   │   │       │       ├── SharedTypesTest.res
│   │   │       │       ├── SimulationChainSkipperTest.res
│   │   │       │       ├── SimulationDriverTest.res
│   │   │       │       ├── SimulationLogicTest.res
│   │   │       │       ├── SimulationNavigationTest.res
│   │   │       │       ├── SimulationPathGeneratorTest.res
│   │   │       │       ├── SimulationReducerTest.res
│   │   │       │       ├── StateInspectorTest.res
│   │   │       │       ├── TeaserManagerTest.res
│   │   │       │       ├── TeaserPathfinderTest.res
│   │   │       │       ├── TeaserRecorderTest.res
│   │   │       │       ├── TimelineReducerTest.res
│   │   │       │       ├── TourLogicTest.res
│   │   │       │       ├── TourTemplateAssetsTest.res
│   │   │       │       ├── TourTemplateScriptsTest.res
│   │   │       │       ├── TourTemplateStylesTest.res
│   │   │       │       ├── TourTemplatesTest.res
│   │   │       │       ├── UiReducerTest.res
│   │   │       │       ├── UploadProcessorTest.res
│   │   │       │       ├── UrlUtilsTest.res
│   │   │       │       ├── VersionDataTest.res
│   │   │       │       ├── VersionTest.res
│   │   │       │       ├── VideoEncoderTest.res
│   │   │       │       ├── ViewerLoaderTest.res
│   │   │       │       └── VitestSmoke.test.res
│   │   │       └── vitest.config.mjs
│   │   ├── package-lock.json
│   │   ├── package.json
│   │   ├── plans
│   │   │   ├── debug_telemetry_fix_plan.md
│   │   │   ├── logical_inconsistencies_analysis.md
│   │   │   └── step1_cleanup_notes.md
│   │   ├── postcss.config.js
│   │   ├── public
│   │   │   ├── early-boot.js
│   │   │   ├── images
│   │   │   │   ├── icon-192.png
│   │   │   │   ├── icon-512.png
│   │   │   │   ├── logo.png
│   │   │   │   └── og-preview.png
│   │   │   ├── libs
│   │   │   │   ├── FileSaver.min.js
│   │   │   │   ├── jszip.min.js
│   │   │   │   ├── pannellum.css
│   │   │   │   └── pannellum.js
│   │   │   ├── manifest.json
│   │   │   ├── service-worker.js
│   │   │   └── sounds
│   │   │       └── click.wav
│   │   ├── rescript.json
│   │   ├── rsbuild.config.mjs
│   │   ├── scripts
│   │   │   ├── check-stale-tests.sh
│   │   │   ├── cleanup_logs.sh
│   │   │   ├── commit.sh
│   │   │   ├── debug-connectivity.js
│   │   │   ├── detect-missing-tests.cjs
│   │   │   ├── dev-mode.sh
│   │   │   ├── generate-test-tasks.cjs
│   │   │   ├── increment-build.js
│   │   │   ├── project-guard.sh
│   │   │   ├── prune-snapshots.sh
│   │   │   ├── restore-snapshot.sh
│   │   │   ├── setup.sh
│   │   │   ├── sync-sw.cjs
│   │   │   ├── test-logging.js
│   │   │   └── update-version.js
│   │   ├── src
│   │   │   ├── App.res
│   │   │   ├── Main.res
│   │   │   ├── ReBindings.res
│   │   │   ├── ServiceWorker.res
│   │   │   ├── ServiceWorkerMain.res
│   │   │   ├── components
│   │   │   │   ├── AppErrorBoundary.res
│   │   │   │   ├── ErrorFallbackUI.res
│   │   │   │   ├── HotspotActionMenu.res
│   │   │   │   ├── HotspotManager.res
│   │   │   │   ├── LabelMenu.res
│   │   │   │   ├── LinkModal.res
│   │   │   │   ├── ModalContext.res
│   │   │   │   ├── NotificationContext.res
│   │   │   │   ├── PopOver.res
│   │   │   │   ├── Portal.res
│   │   │   │   ├── PreviewArrow.res
│   │   │   │   ├── SceneList.res
│   │   │   │   ├── Sidebar.res
│   │   │   │   ├── Tooltip.res
│   │   │   │   ├── UploadReport.res
│   │   │   │   ├── ViewerFollow.res
│   │   │   │   ├── ViewerLoader.res
│   │   │   │   ├── ViewerManager.res
│   │   │   │   ├── ViewerSnapshot.res
│   │   │   │   ├── ViewerState.res
│   │   │   │   ├── ViewerTypes.res
│   │   │   │   ├── ViewerUI.res
│   │   │   │   ├── VisualPipeline.res
│   │   │   │   └── ui
│   │   │   │       ├── LucideIcons.res
│   │   │   │       ├── Shadcn.res
│   │   │   │       ├── button.jsx
│   │   │   │       ├── context-menu.jsx
│   │   │   │       ├── dropdown-menu.jsx
│   │   │   │       ├── popover.jsx
│   │   │   │       └── tooltip.jsx
│   │   │   ├── core
│   │   │   │   ├── Actions.res
│   │   │   │   ├── AppContext.res
│   │   │   │   ├── GlobalStateBridge.res
│   │   │   │   ├── JsonTypes.res
│   │   │   │   ├── Reducer.res
│   │   │   │   ├── ReducerHelpers.res
│   │   │   │   ├── SharedTypes.res
│   │   │   │   ├── State.res
│   │   │   │   ├── Types.res
│   │   │   │   └── reducers
│   │   │   │       ├── HotspotReducer.res
│   │   │   │       ├── NavigationReducer.res
│   │   │   │       ├── ProjectReducer.res
│   │   │   │       ├── RootReducer.res
│   │   │   │       ├── SceneReducer.res
│   │   │   │       ├── SimulationReducer.res
│   │   │   │       ├── TimelineReducer.res
│   │   │   │       ├── UiReducer.res
│   │   │   │       └── mod.res
│   │   │   ├── index.js
│   │   │   ├── systems
│   │   │   │   ├── AudioManager.res
│   │   │   │   ├── BackendApi.res
│   │   │   │   ├── DownloadSystem.res
│   │   │   │   ├── EventBus.res
│   │   │   │   ├── ExifParser.res
│   │   │   │   ├── ExifReportGenerator.res
│   │   │   │   ├── Exporter.res
│   │   │   │   ├── HotspotLine.res
│   │   │   │   ├── HotspotLineLogic.res
│   │   │   │   ├── HotspotLineTypes.res
│   │   │   │   ├── InputSystem.res
│   │   │   │   ├── Navigation.res
│   │   │   │   ├── NavigationController.res
│   │   │   │   ├── NavigationRenderer.res
│   │   │   │   ├── NavigationUI.res
│   │   │   │   ├── ProjectData.res
│   │   │   │   ├── ProjectManager.res
│   │   │   │   ├── Resizer.res
│   │   │   │   ├── ServerTeaser.res
│   │   │   │   ├── SimulationChainSkipper.res
│   │   │   │   ├── SimulationDriver.res
│   │   │   │   ├── SimulationLogic.res
│   │   │   │   ├── SimulationNavigation.res
│   │   │   │   ├── SimulationPathGenerator.res
│   │   │   │   ├── TeaserManager.res
│   │   │   │   ├── TeaserPathfinder.res
│   │   │   │   ├── TeaserRecorder.res
│   │   │   │   ├── TourTemplateAssets.res
│   │   │   │   ├── TourTemplateScripts.res
│   │   │   │   ├── TourTemplateStyles.res
│   │   │   │   ├── TourTemplates.res
│   │   │   │   ├── UploadProcessor.res
│   │   │   │   ├── UploadProcessorLogic.res
│   │   │   │   ├── UploadProcessorTypes.res
│   │   │   │   └── VideoEncoder.res
│   │   │   └── utils
│   │   │       ├── ColorPalette.res
│   │   │       ├── Constants.res
│   │   │       ├── GeoUtils.res
│   │   │       ├── ImageOptimizer.res
│   │   │       ├── ImageOptimizer.resi
│   │   │       ├── LazyLoad.res
│   │   │       ├── Logger.res
│   │   │       ├── PathInterpolation.res
│   │   │       ├── ProgressBar.res
│   │   │       ├── RequestQueue.res
│   │   │       ├── SessionStore.res
│   │   │       ├── StateInspector.res
│   │   │       ├── TourLogic.res
│   │   │       ├── UrlUtils.res
│   │   │       ├── Version.res
│   │   │       └── VersionData.res
│   │   ├── start_prod.sh
│   │   ├── tailwind.config.js
│   │   ├── tasks
│   │   │   ├── TASKS.md
│   │   │   ├── active
│   │   │   │   ├── 005_create_changelog.md
│   │   │   │   └── 409_Update_Tests_ViewerManager.md
│   │   │   ├── completed
│   │   │   │   ├── 298_Refactor_UploadProcessor_REPORT.md
│   │   │   │   ├── 299_Refactor_HotspotLine_REPORT.md
│   │   │   │   ├── 300_Test_NavigationUI_REPORT.md
│   │   │   │   ├── 301_Update_Codebase_Map_REPORT.md
│   │   │   │   ├── 302_Test_Portal_ABORTED.md
│   │   │   │   ├── 303_Test_Tooltip_ABORTED.md
│   │   │   │   ├── 304_Test_mod_ABORTED.md
│   │   │   │   ├── 305_Test_LucideIcons_ABORTED.md
│   │   │   │   ├── 306_Test_State_ABORTED.md
│   │   │   │   ├── 307_Test_PopOver_ABORTED.md
│   │   │   │   ├── 308_Test_Types_REPORT.md
│   │   │   │   ├── 309_Test_Shadcn_ABORTED.md
│   │   │   │   ├── 310_Test_NavigationUI_ABORTED.md
│   │   │   │   ├── 311_Test_Shadcn_ABORTED.md
│   │   │   │   ├── 312_Test_LucideIcons_ABORTED.md
│   │   │   │   ├── 313_Test_HotspotLineLogic_REPORT.md
│   │   │   │   ├── 314_Test_UploadProcessorTypes_REPORT.md
│   │   │   │   ├── 315_Test_HotspotLineTypes_REPORT.md
│   │   │   │   ├── 316_Test_UploadProcessorLogic_REPORT.md
│   │   │   │   ├── 317_Update_Tests_ReBindings_REPORT.md
│   │   │   │   ├── 318_Update_Tests_Actions_REPORT.md
│   │   │   │   ├── 319_Update_Tests_ReducerHelpers_REPORT.md
│   │   │   │   ├── 320_Update_Tests_ProjectReducer_REPORT.md
│   │   │   │   ├── 321_Update_Tests_UiReducer_REPORT.md
│   │   │   │   ├── 322_Update_Tests_Main_REPORT.md
│   │   │   │   ├── 323_Update_Tests_ServiceWorkerMain_REPORT.md
│   │   │   │   ├── 324_Update_Tests_TourLogic_REPORT.md
│   │   │   │   ├── 325_Update_Tests_Logger_REPORT.md
│   │   │   │   ├── 326_Update_Tests_LazyLoad_REPORT.md
│   │   │   │   ├── 327_Update_Tests_RequestQueue_REPORT.md
│   │   │   │   ├── 328_Update_Tests_SessionStore_REPORT.md
│   │   │   │   ├── 329_Update_Tests_VersionData_REPORT.md
│   │   │   │   ├── 330_Update_Tests_LabelMenu_REPORT.md
│   │   │   │   ├── 331_Update_Tests_HotspotManager.md
│   │   │   │   ├── 332_Update_Tests_UploadReport.md
│   │   │   │   ├── 333_Update_Tests_HotspotActionMenu.md
│   │   │   │   ├── 334_Update_Tests_ViewerLoader.md
│   │   │   │   ├── 335_Update_Tests_ViewerUI.md
│   │   │   │   ├── 336_Update_Tests_ViewerTypes.md
│   │   │   │   ├── 337_Update_Tests_Sidebar.md
│   │   │   │   ├── 338_Update_Tests_VisualPipeline.md
│   │   │   │   ├── 339_Update_Tests_NotificationContext.md
│   │   │   │   ├── 340_Update_Tests_ModalContext.md
│   │   │   │   ├── 341_Update_Tests_TourTemplates.md
│   │   │   │   ├── 342_Update_Tests_TourTemplateAssets_UPDATED.md
│   │   │   │   ├── 343_Update_Tests_SimulationPathGenerator_UPDATED.md
│   │   │   │   ├── 344_Update_Tests_ExifReportGenerator_UPDATED.md
│   │   │   │   ├── 345_Update_Tests_UploadProcessor_UPDATED.md
│   │   │   │   ├── 346_Update_Tests_HotspotLine_UPDATED.md
│   │   │   │   ├── 347_Update_Tests_ProjectManager_UPDATED.md
│   │   │   │   ├── 348_Update_Tests_DownloadSystem_UPDATED.md
│   │   │   │   ├── 349_Update_Tests_NavigationRenderer_UPDATED.md
│   │   │   │   ├── 350_Aggregate_Completed_Tasks_REPORT.md
│   │   │   │   ├── 351_Update_Tests_SimulationLogic_UPDATED.md
│   │   │   │   ├── 352_Update_Tests_BackendApi_UPDATED.md
│   │   │   │   ├── 353_Update_Tests_LucideIcons_UPDATED.md
│   │   │   │   ├── 354_Update_Tests_Resizer_UPDATED.md
│   │   │   │   ├── 355_Update_Tests_HotspotLineTypes_UPDATED.md
│   │   │   │   ├── 356_Update_Tests_SceneList_UPDATED.md
│   │   │   │   ├── 357_Update_Tests_ErrorFallbackUI_UPDATED.md
│   │   │   │   ├── 358_Update_Tests_InputSystem_UPDATED.md
│   │   │   │   ├── 359_Update_Tests_SimulationReducer_UPDATED.md
│   │   │   │   ├── 360_Update_Tests_App_UPDATED.md
│   │   │   │   ├── 361_Update_Tests_JsonTypes_UPDATED.md
│   │   │   │   ├── 362_Update_Tests_SimulationChainSkipper_UPDATED.md
│   │   │   │   ├── 363_Update_Tests_SimulationNavigation_UPDATED.md
│   │   │   │   ├── 364_Update_Tests_TourTemplateScripts_UPDATED.md
│   │   │   │   ├── 365_Update_Tests_Constants_UPDATED.md
│   │   │   │   ├── 366_Update_Tests_PathInterpolation_UPDATED.md
│   │   │   │   ├── 367_Update_Tests_ExifParser_UPDATED.md
│   │   │   │   ├── 368_Update_Tests_TeaserPathfinder_UPDATED.md
│   │   │   │   ├── 369_Update_Tests_TeaserManager_UPDATED.md
│   │   │   │   ├── 370_Update_Tests_TeaserRecorder_UPDATED.md
│   │   │   │   ├── 371_Migrate_Tests_Core_Reducers_UPDATED.md
│   │   │   │   ├── 372_Migrate_Tests_Core_Logic_REPORT.md
│   │   │   │   ├── 373_Migrate_Tests_Templates_Exporter_UPDATED.md
│   │   │   │   ├── 374_Migrate_Tests_Utilities_Services.md
│   │   │   │   ├── 374_Migrate_Tests_Utilities_Services_UPDATED.md
│   │   │   │   ├── 375_Migrate_Tests_Media_Specialized_REPORT.md
│   │   │   │   ├── 376_Refactor_project_REPORT.md
│   │   │   │   ├── 405_Update_Tests_Core_Architecture_UPDATED.md
│   │   │   │   ├── 406_Update_Tests_UI_and_Viewer_REPORT.md
│   │   │   │   ├── 407_Update_Tests_Business_Systems_UPDATED.md
│   │   │   │   ├── 408_Update_Tests_Utilities_REPORT.md
│   │   │   │   ├── 409_Update_Tests_ViewerManager_UPDATED.md
│   │   │   │   ├── 410_Add_Tests_App.md
│   │   │   │   └── _CONCISE_SUMMARY.md
│   │   │   ├── pending
│   │   │   │   ├── 94_Update_Codebase_Map.md
│   │   │   │   ├── 95_Aggregate_Completed_Tasks.md
│   │   │   │   └── tests
│   │   │   │       ├── 410_Add_Tests_App.md
│   │   │   │       ├── 411_Update_Tests_Portal.md
│   │   │   │       ├── 412_Update_Tests_UploadProcessorTypes.md
│   │   │   │       ├── 413_Update_Tests_TimelineReducer.md
│   │   │   │       ├── 414_Update_Tests_PopOver.md
│   │   │   │       ├── 415_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 416_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 417_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 418_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 419_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 420_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 421_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 422_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 423_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 424_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 425_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 426_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 427_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 428_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 429_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 430_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 431_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 432_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 433_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 434_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 435_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 436_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 437_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 438_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 439_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 440_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 441_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 442_Update_Tests_ProgressBar.md
│   │   │   │       ├── 443_Update_Tests_Tooltip.md
│   │   │   │       ├── 444_Update_Tests_HotspotReducer.md
│   │   │   │       ├── 445_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 446_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 447_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 448_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 449_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 450_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 451_Update_Tests_SharedTypes.md
│   │   │   │       ├── 452_Update_Tests_NavigationReducer.md
│   │   │   │       ├── 453_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 454_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 455_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 456_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 457_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 458_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 459_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 460_Update_Tests_VideoEncoder.md
│   │   │   │       ├── 461_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 462_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 463_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 464_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 465_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 466_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 467_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 468_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 469_Update_Tests_EventBus.md
│   │   │   │       ├── 470_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 471_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 472_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 473_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 474_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 475_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 476_Add_Tests_PreviewArrow.md
│   │   │   │       ├── 477_Add_Tests_PreviewArrow.md
│   │   │   │       └── 478_Add_Tests_PreviewArrow.md
│   │   │   └── postponed
│   │   │       ├── 003_add_seo_structured_data.md
│   │   │       ├── 004_document_core_web_vitals.md
│   │   │       ├── 006_update_docs_anchor_positioning_standards.md
│   │   │       ├── 015_create_legal_compliance_documents.md
│   │   │       ├── 020_visual_regression_testing.md
│   │   │       ├── 021_theme_switching_infrastructure.md
│   │   │       ├── 022_expand_test_coverage.md
│   │   │       ├── 024_implement_e2e_testing_playwright.md
│   │   │       ├── 025_implement_internationalization.md
│   │   │       ├── 030_implement_sqlite_auth_infrastructure.md
│   │   │       ├── 031_implement_auth_ui_rescript.md
│   │   │       ├── 032_implement_project_dashboard.md
│   │   │       ├── 033_secure_backend_with_jwt.md
│   │   │       └── tests
│   │   │           └── superseded
│   │   │               ├── 377_Update_Tests_ServerTeaser.md
│   │   │               ├── 378_Update_Tests_ProjectData.md
│   │   │               ├── 379_Update_Tests_ColorPalette.md
│   │   │               ├── 380_Update_Tests_ViewerSnapshot.md
│   │   │               ├── 381_Update_Tests_Shadcn.md
│   │   │               ├── 382_Update_Tests_NavigationUI.md
│   │   │               ├── 383_Update_Tests_RootReducer.md
│   │   │               ├── 384_Update_Tests_AppContext.md
│   │   │               ├── 385_Update_Tests_AppErrorBoundary.md
│   │   │               ├── 386_Update_Tests_GlobalStateBridge.md
│   │   │               ├── 387_Update_Tests_UrlUtils.md
│   │   │               ├── 388_Update_Tests_UploadProcessorLogic.md
│   │   │               ├── 389_Update_Tests_ViewerState.md
│   │   │               ├── 390_Update_Tests_Exporter.md
│   │   │               ├── 391_Update_Tests_Types.md
│   │   │               ├── 392_Update_Tests_HotspotLineLogic.md
│   │   │               ├── 393_Update_Tests_AudioManager.md
│   │   │               ├── 394_Update_Tests_SimulationDriver.md
│   │   │               ├── 395_Update_Tests_ViewerFollow.md
│   │   │               ├── 396_Update_Tests_SceneReducer.md
│   │   │               ├── 397_Update_Tests_TourTemplateStyles.md
│   │   │               ├── 398_Update_Tests_State.md
│   │   │               ├── 399_Update_Tests_LinkModal.md
│   │   │               ├── 400_Update_Tests_mod.md
│   │   │               ├── 401_Update_Tests_NavigationController.md
│   │   │               ├── 402_Update_Tests_ImageOptimizer.md
│   │   │               ├── 403_Update_Tests_StateInspector.md
│   │   │               └── 404_Update_Tests_GeoUtils.md
│   │   ├── test_output.txt
│   │   ├── tested_icons.txt
│   │   ├── tests
│   │   │   ├── TestRunner.res
│   │   │   ├── jsx-loader.mjs
│   │   │   ├── node-setup.js
│   │   │   └── unit
│   │   │       ├── Actions_v.test.res
│   │   │       ├── AppContext_v.test.res
│   │   │       ├── AppErrorBoundary_v.test.res
│   │   │       ├── App_v.test.res
│   │   │       ├── AudioManager_v.test.res
│   │   │       ├── BackendApi_v.test.res
│   │   │       ├── ColorPalette_v.test.res
│   │   │       ├── Constants_v.test.res
│   │   │       ├── DownloadSystem_v.test.res
│   │   │       ├── ErrorFallbackUI_v.test.res
│   │   │       ├── EventBus_v.test.res
│   │   │       ├── ExifParser_v.test.res
│   │   │       ├── ExifReportGenerator_v.test.res
│   │   │       ├── Exporter_v.test.res
│   │   │       ├── GeoUtils_v.test.res
│   │   │       ├── GlobalStateBridge_v.test.res
│   │   │       ├── HotspotActionMenu_v.test.res
│   │   │       ├── HotspotLineLogic_v.test.res
│   │   │       ├── HotspotLineTypes_v.test.res
│   │   │       ├── HotspotLine_v.test.res
│   │   │       ├── HotspotLine_v.test.setup.js
│   │   │       ├── HotspotManager_v.test.res
│   │   │       ├── HotspotReducer_v.test.res
│   │   │       ├── ImageOptimizer_v.test.res
│   │   │       ├── InputSystem_v.test.res
│   │   │       ├── JsonTypes_v.test.res
│   │   │       ├── LabelMenu_v.test.res
│   │   │       ├── LabelMenu_v.test.setup.jsx
│   │   │       ├── LazyLoad_v.test.res
│   │   │       ├── LinkModal_v.test.res
│   │   │       ├── Logger_v.test.res
│   │   │       ├── LucideIcons_v.test.res
│   │   │       ├── Main_v.test.res
│   │   │       ├── Mod_v.test.res
│   │   │       ├── ModalContext_v.test.res
│   │   │       ├── NavigationController_v.test.res
│   │   │       ├── NavigationReducer_v.test.res
│   │   │       ├── NavigationRenderer_v.test.res
│   │   │       ├── NavigationUI_v.test.res
│   │   │       ├── Navigation_v.test.res
│   │   │       ├── NotificationContext_v.test.res
│   │   │       ├── PathInterpolation_v.test.res
│   │   │       ├── PopOver_v.test.res
│   │   │       ├── Portal_v.test.res
│   │   │       ├── ProgressBar_v.test.res
│   │   │       ├── ProjectData_v.test.res
│   │   │       ├── ProjectManager_v.test.res
│   │   │       ├── ProjectReducer_v.test.res
│   │   │       ├── ReBindings_v.test.res
│   │   │       ├── ReducerHelpers_v.test.res
│   │   │       ├── Reducer_v.test.res
│   │   │       ├── RequestQueue_v.test.res
│   │   │       ├── Resizer_v.test.res
│   │   │       ├── RootReducer_v.test.res
│   │   │       ├── SceneList_v.test.res
│   │   │       ├── SceneReducer_v.test.res
│   │   │       ├── ServerTeaser_v.test.res
│   │   │       ├── ServiceWorkerMain_v.test.res
│   │   │       ├── ServiceWorker_v.test.res
│   │   │       ├── SessionStore_v.test.res
│   │   │       ├── Shadcn_v.test.res
│   │   │       ├── SharedTypes_v.test.res
│   │   │       ├── Sidebar_v.test.res
│   │   │       ├── SimulationChainSkipper_v.test.res
│   │   │       ├── SimulationDriver_v.test.res
│   │   │       ├── SimulationLogic_v.test.res
│   │   │       ├── SimulationNavigation_v.test.res
│   │   │       ├── SimulationPathGenerator_v.test.res
│   │   │       ├── SimulationReducer_v.test.res
│   │   │       ├── StateInspector_v.test.res
│   │   │       ├── State_v.test.res
│   │   │       ├── TeaserManager_v.test.res
│   │   │       ├── TeaserPathfinder_v.test.res
│   │   │       ├── TeaserRecorder_v.test.res
│   │   │       ├── TimelineReducer_v.test.res
│   │   │       ├── Tooltip_v.test.res
│   │   │       ├── TourLogic_v.test.res
│   │   │       ├── TourTemplateAssets_v.test.res
│   │   │       ├── TourTemplateScripts_v.test.res
│   │   │       ├── TourTemplateStyles_v.test.res
│   │   │       ├── TourTemplates_v.test.res
│   │   │       ├── Types_v.test.res
│   │   │       ├── UiReducer_v.test.res
│   │   │       ├── UploadProcessorLogic_v.test.res
│   │   │       ├── UploadProcessorTypes_v.test.res
│   │   │       ├── UploadProcessor_v.test.res
│   │   │       ├── UploadProcessor_v.test.setup.js
│   │   │       ├── UploadReport_v.test.res
│   │   │       ├── UrlUtils_v.test.res
│   │   │       ├── VersionData_v.test.res
│   │   │       ├── Version_v.test.res
│   │   │       ├── VideoEncoder_v.test.res
│   │   │       ├── ViewerFollow_v.test.res
│   │   │       ├── ViewerLoader_v.test.res
│   │   │       ├── ViewerManager_v.test.res
│   │   │       ├── ViewerSnapshot_v.test.res
│   │   │       ├── ViewerState_v.test.res
│   │   │       ├── ViewerTypes_v.test.res
│   │   │       ├── ViewerUI_v.test.res
│   │   │       ├── VisualPipeline_v.test.res
│   │   │       ├── VitestSmoke.test.res
│   │   │       └── utils
│   │   │           └── TestUtils.res
│   │   └── vitest.config.mjs
│   ├── REF.md
│   └── v4.3.6+7_a34c1dd
│       ├── AGENTS.md
│       ├── GEMINI.md
│       ├── README.md
│       ├── backend
│       │   ├── Cargo.lock
│       │   ├── Cargo.toml
│       │   ├── backend.log
│       │   ├── backend_run.log
│       │   ├── bin
│       │   │   └── ffmpeg
│       │   ├── src
│       │   │   ├── api
│       │   │   │   ├── geocoding.rs
│       │   │   │   ├── media
│       │   │   │   │   ├── image.rs
│       │   │   │   │   ├── mod.rs
│       │   │   │   │   ├── serve.rs
│       │   │   │   │   ├── similarity.rs
│       │   │   │   │   └── video.rs
│       │   │   │   ├── mod.rs
│       │   │   │   ├── project.rs
│       │   │   │   ├── telemetry.rs
│       │   │   │   └── utils.rs
│       │   │   ├── lib.rs
│       │   │   ├── main.rs
│       │   │   ├── metrics.rs
│       │   │   ├── middleware
│       │   │   │   ├── mod.rs
│       │   │   │   ├── quota_check.rs
│       │   │   │   └── request_tracker.rs
│       │   │   ├── models
│       │   │   │   ├── errors.rs
│       │   │   │   └── mod.rs
│       │   │   ├── pathfinder
│       │   │   │   ├── algorithms.rs
│       │   │   │   ├── graph.rs
│       │   │   │   ├── mod.rs
│       │   │   │   └── utils.rs
│       │   │   └── services
│       │   │       ├── geocoding.rs
│       │   │       ├── media.rs
│       │   │       ├── mod.rs
│       │   │       ├── project
│       │   │       │   ├── load.rs
│       │   │       │   ├── mod.rs
│       │   │       │   ├── package.rs
│       │   │       │   └── validate.rs
│       │   │       ├── shutdown.rs
│       │   │       ├── upload_quota.rs
│       │   │       └── upload_quota_tests.rs
│       │   ├── startup.log
│       │   ├── startup_debug.log
│       │   ├── startup_debug_v2.log
│       │   ├── startup_log.txt
│       │   └── tests
│       │       └── shutdown_test.rs
│       ├── cache
│       │   └── geocoding.json
│       ├── css
│       │   ├── animations.css
│       │   ├── base.css
│       │   ├── components
│       │   │   ├── buttons.css
│       │   │   ├── error-fallback.css
│       │   │   ├── floor-nav.css
│       │   │   ├── label-menu.css
│       │   │   ├── modals.css
│       │   │   ├── scene-groups.css
│       │   │   ├── ui.css
│       │   │   ├── upload-report.css
│       │   │   └── viewer.css
│       │   ├── layout.css
│       │   ├── legacy.css
│       │   ├── output.css
│       │   ├── style.css
│       │   ├── tailwind.css
│       │   └── variables.css
│       ├── dev.log
│       ├── dev_prefs
│       │   ├── logging_debugging_system.md
│       │   └── ui_preferences.md
│       ├── docs
│       │   ├── ACCESSIBILITY_SYSTEM.md
│       │   ├── ARCHITECTURE_DIAGRAM.md
│       │   ├── AntiGravity Workflow Manual.md
│       │   ├── BUILD_VERIFICATION_QUICK_REFERENCE.md
│       │   ├── COLOR_PALETTE_REFERENCE.md
│       │   ├── CSS_ARCHITECTURE_AND_BEST_PRACTICES.md
│       │   ├── CSS_MIGRATION_ANALYSIS.md
│       │   ├── CSS_MIGRATION_SUMMARY.md
│       │   ├── IMPROVEMENTS.md
│       │   ├── OBSERVABILITY_AND_ERROR_HANDLING.md
│       │   ├── PERFORMANCE_AND_METRICS.md
│       │   ├── PROJECT_GOVERNANCE_AND_STATUS.md
│       │   ├── RELEASE_v4.0.9.md
│       │   ├── SECURITY_AND_STABILITY.md
│       │   ├── TASK_CREATION_FIX_SUMMARY.md
│       │   ├── TESTING_QUICK_REFERENCE.md
│       │   ├── TYPOGRAPHY_AND_UI_SYSTEM.md
│       │   ├── UNIT_TESTING_INTEGRATION.md
│       │   └── openapi.yaml
│       ├── index.html
│       ├── logs
│       │   └── log_changes.txt
│       ├── package-lock.json
│       ├── package.json
│       ├── plans
│       │   ├── debug_telemetry_fix_plan.md
│       │   ├── logical_inconsistencies_analysis.md
│       │   └── step1_cleanup_notes.md
│       ├── postcss.config.js
│       ├── public
│       │   ├── early-boot.js
│       │   ├── images
│       │   │   ├── icon-192.png
│       │   │   ├── icon-512.png
│       │   │   ├── logo.png
│       │   │   └── og-preview.png
│       │   ├── libs
│       │   │   ├── FileSaver.min.js
│       │   │   ├── jszip.min.js
│       │   │   ├── pannellum.css
│       │   │   └── pannellum.js
│       │   ├── manifest.json
│       │   ├── service-worker.js
│       │   └── sounds
│       │       └── click.wav
│       ├── rescript.json
│       ├── rsbuild.config.mjs
│       ├── scripts
│       │   ├── cleanup_logs.sh
│       │   ├── commit.sh
│       │   ├── debug-connectivity.js
│       │   ├── detect-missing-tests.js
│       │   ├── dev-mode.sh
│       │   ├── increment-build.js
│       │   ├── prune-snapshots.sh
│       │   ├── restore-snapshot.sh
│       │   ├── setup.sh
│       │   ├── sync-sw.cjs
│       │   ├── test-logging.js
│       │   ├── update-version.js
│       │   └── watch-file-limits.sh
│       ├── src
│       │   ├── App.res
│       │   ├── Main.res
│       │   ├── ReBindings.res
│       │   ├── ServiceWorker.res
│       │   ├── ServiceWorkerMain.res
│       │   ├── components
│       │   │   ├── ErrorFallbackUI.res
│       │   │   ├── HotspotManager.res
│       │   │   ├── LabelMenu.res
│       │   │   ├── LinkModal.res
│       │   │   ├── ModalContext.res
│       │   │   ├── NotificationContext.res
│       │   │   ├── RemaxErrorBoundary.res
│       │   │   ├── SceneList.res
│       │   │   ├── Sidebar.res
│       │   │   ├── UploadReport.res
│       │   │   ├── ViewerFollow.res
│       │   │   ├── ViewerLoader.res
│       │   │   ├── ViewerManager.res
│       │   │   ├── ViewerSnapshot.res
│       │   │   ├── ViewerState.res
│       │   │   ├── ViewerTypes.res
│       │   │   ├── ViewerUI.res
│       │   │   └── VisualPipeline.res
│       │   ├── core
│       │   │   ├── Actions.res
│       │   │   ├── AppContext.res
│       │   │   ├── GlobalStateBridge.res
│       │   │   ├── JsonTypes.res
│       │   │   ├── Reducer.res
│       │   │   ├── ReducerHelpers.res
│       │   │   ├── SharedTypes.res
│       │   │   ├── State.res
│       │   │   ├── Types.res
│       │   │   └── reducers
│       │   │       ├── HotspotReducer.res
│       │   │       ├── NavigationReducer.res
│       │   │       ├── ProjectReducer.res
│       │   │       ├── RootReducer.res
│       │   │       ├── SceneReducer.res
│       │   │       ├── SimulationReducer.res
│       │   │       ├── TimelineReducer.res
│       │   │       ├── UiReducer.res
│       │   │       └── mod.res
│       │   ├── index.js
│       │   ├── systems
│       │   │   ├── AudioManager.res
│       │   │   ├── BackendApi.res
│       │   │   ├── DownloadSystem.res
│       │   │   ├── EventBus.res
│       │   │   ├── ExifParser.res
│       │   │   ├── ExifReportGenerator.res
│       │   │   ├── Exporter.res
│       │   │   ├── HotspotLine.res
│       │   │   ├── InputSystem.res
│       │   │   ├── Navigation.res
│       │   │   ├── NavigationController.res
│       │   │   ├── NavigationRenderer.res
│       │   │   ├── NavigationUI.res
│       │   │   ├── ProjectData.res
│       │   │   ├── ProjectManager.res
│       │   │   ├── Resizer.res
│       │   │   ├── ServerTeaser.res
│       │   │   ├── SimulationChainSkipper.res
│       │   │   ├── SimulationDriver.res
│       │   │   ├── SimulationLogic.res
│       │   │   ├── SimulationNavigation.res
│       │   │   ├── SimulationPathGenerator.res
│       │   │   ├── TeaserManager.res
│       │   │   ├── TeaserPathfinder.res
│       │   │   ├── TeaserRecorder.res
│       │   │   ├── TourTemplateAssets.res
│       │   │   ├── TourTemplateScripts.res
│       │   │   ├── TourTemplateStyles.res
│       │   │   ├── TourTemplates.res
│       │   │   ├── UploadProcessor.res
│       │   │   └── VideoEncoder.res
│       │   └── utils
│       │       ├── ColorPalette.res
│       │       ├── Constants.res
│       │       ├── GeoUtils.res
│       │       ├── ImageOptimizer.res
│       │       ├── ImageOptimizer.resi
│       │       ├── LazyLoad.res
│       │       ├── Logger.res
│       │       ├── PathInterpolation.res
│       │       ├── ProgressBar.res
│       │       ├── RequestQueue.res
│       │       ├── SessionStore.res
│       │       ├── StateInspector.res
│       │       ├── TourLogic.res
│       │       ├── UrlUtils.res
│       │       ├── Version.res
│       │       └── VersionData.res
│       ├── start_prod.sh
│       ├── tailwind.config.js
│       ├── tasks
│       │   ├── TASKS.md
│       │   ├── completed
│       │   │   ├── 175_fix_runtime_safety_getexn_REPORT.md
│       │   │   ├── 177_fix_error_handling_REPORT.md
│       │   │   ├── 178_Restore_v420_Viewer_HUD_Labels_and_Prompts_ABORTED.md
│       │   │   ├── 179_Restore_v420_Visual_Pipeline_ABORTED.md
│       │   │   ├── 180_Restore_v420_Simulation_Advanced_Mechanics_ABORTED.md
│       │   │   ├── 181_extract_business_logic_ABORTED.md
│       │   │   ├── 194_Add_Tests_for_ServiceWorkerMain_REPORT.md
│       │   │   ├── 195_Add_Tests_for_UrlUtils_REPORT.md
│       │   │   ├── 196_Add_Tests_for_VersionData_REPORT.md
│       │   │   ├── 197_Refactor_RootReducer_Pipeline_REPORT.md
│       │   │   ├── 198_Implement_Session_Persistence_REPORT.md
│       │   │   ├── 199_Enhance_GlobalState_Safety_REPORT.md
│       │   │   ├── 200_Detailed_CSS_Styling_Comparison_REPORT.md
│       │   │   ├── 206_Comprehensive_Migration_Summary_REPORT.md
│       │   │   ├── 207_Comprehensive_Testing_And_QA_Summary_REPORT.md
│       │   │   ├── 208_Backend_Systems_And_Optimization_Summary_REPORT.md
│       │   │   ├── 209_Refactoring_Security_UX_Summary_REPORT.md
│       │   │   ├── 216_Fix_Waypoint_Persistence_And_Link_Default_REPORT.md
│       │   │   ├── 217_Fix_Path_Screen_Stickiness_And_Default_Link_REPORT.md
│       │   │   ├── 218_Fix_Waypoint_Sticking_To_Screen_REPORT.md
│       │   │   ├── 219_Fix_Hotspot_Disappearance_After_Save_REPORT.md
│       │   │   ├── 220_Fix_Hotspot_Disappearance_V2_REPORT.md
│       │   │   ├── 221_Fix_Invisible_Waypoint_After_Save_REPORT.md
│       │   │   ├── 222_restore_css_design_tokens_REPORT.md
│       │   │   ├── 223_restore_premium_ui_components_REPORT.md
│       │   │   ├── 224_restore_linking_mode_visuals_REPORT.md
│       │   │   ├── 225_restore_simulation_lockdown_REPORT.md
│       │   │   ├── 226_restore_premium_hotspots_REPORT.md
│       │   │   ├── 264_fix_upload_failure_REPORT.md
│       │   │   ├── 265_troubleshoot_yellow_rod_REPORT.md
│       │   │   ├── 266_refine_linking_visuals_REPORT.md
│       │   │   ├── 267_update_camera_movement_behavior_REPORT.md
│       │   │   ├── 268_verify_scenelist_virtualization_ABORTED.md
│       │   │   ├── 270_auto_select_first_scene_on_start.md
│       │   │   ├── 271_refactor_sidebar_inline_styles_REPORT.md
│       │   │   ├── 272_refactor_viewerui_inline_styles_REPORT.md
│       │   │   ├── 273_centralize_rescript_styling_tokens_REPORT.md
│       │   │   ├── 274_fix_hotspot_navigation_click_REPORT.md
│       │   │   ├── 274_migrate_conditional_styles_to_classes_REPORT.md
│       │   │   ├── 275_complete_css_variable_migration.md
│       │   │   ├── 276_refactor_uploadreport_inline_styles.md
│       │   │   ├── 277_design_system_documentation_and_compliance.md
│       │   │   ├── 278_create_css_gradient_variables.md
│       │   │   ├── 279_add_color_accessibility_audit.md
│       │   │   ├── 283_implement_remax_centric_theme.md
│       │   │   ├── 285_autopilot_ui_fixes_REPORT.md
│       │   │   ├── 286_refine_hotspot_chevron_click_range_REPORT.md
│       │   │   ├── 287_merge_navigation_chevron_hit_area_REPORT.md
│       │   │   └── 288_reduce_shine_animation_speed_REPORT.md
│       │   ├── current_refactor.md
│       │   └── postponed
│       │       ├── 176_fix_security_innerhtml.md
│       │       ├── 186_implement_backend_geocoding_proxy.md
│       │       ├── 201_implement_backend_geocoding_cache.md
│       │       ├── 202_offload_image_similarity_to_backend.md
│       │       ├── 205_re_evaluate_webp_quality.md
│       │       ├── 284_theme_switching_infrastructure.md
│       │       ├── 289_refactor_ui_anchor_positioning.md
│       │       └── tests
│       │           ├── 203_expand_test_coverage.md
│       │           ├── 204_Add_Tests_for_ImageOptimizer.md
│       │           ├── 210_Add_Tests_for_AppContext.md
│       │           ├── 211_Add_Tests_for_UiReducer.md
│       │           ├── 212_Add_Tests_for_NavigationController.md
│       │           ├── 213_Add_Tests_for_SimulationDriver.md
│       │           ├── 214_Add_Tests_for_SimulationLogic.md
│       │           ├── 215_Add_Tests_for_SessionStore.md
│       │           ├── 269_Add_Tests_for_RequestQueue.md
│       │           └── 280_visual_regression_testing.md
│       ├── tests
│       │   ├── TestRunner.res
│       │   ├── node-setup.js
│       │   └── unit
│       │       ├── ActionsTest.res
│       │       ├── AppContextTest.res
│       │       ├── AppTest.res
│       │       ├── AudioManagerTest.res
│       │       ├── BackendApiTest.res
│       │       ├── ConstantsTest.res
│       │       ├── DownloadSystemTest.res
│       │       ├── EventBusTest.res
│       │       ├── ExifParserTest.res
│       │       ├── ExifReportGeneratorTest.res
│       │       ├── ExporterTest.res
│       │       ├── GeoUtilsTest.res
│       │       ├── GlobalStateBridgeTest.res
│       │       ├── HotspotLine.test.res
│       │       ├── HotspotLine_v.test.res
│       │       ├── HotspotReducerTest.res
│       │       ├── ImageOptimizerTest.res
│       │       ├── InputSystemTest.res
│       │       ├── JsonTypesTest.res
│       │       ├── LazyLoadTest.res
│       │       ├── LoggerTest.res
│       │       ├── MainTest.res
│       │       ├── NavigationControllerTest.res
│       │       ├── NavigationReducerTest.res
│       │       ├── NavigationRendererTest.res
│       │       ├── NavigationTest.res
│       │       ├── PathInterpolationTest.res
│       │       ├── ProgressBarTest.res
│       │       ├── ProjectDataTest.res
│       │       ├── ProjectManagerTest.res
│       │       ├── ProjectReducerTest.res
│       │       ├── ReBindingsTest.res
│       │       ├── ReducerHelpersTest.res
│       │       ├── ReducerTest.res
│       │       ├── RequestQueueTest.res
│       │       ├── ResizerTest.res
│       │       ├── RootReducerTest.res
│       │       ├── SceneReducerTest.res
│       │       ├── ServerTeaserTest.res
│       │       ├── ServiceWorkerMainTest.res
│       │       ├── ServiceWorkerTest.res
│       │       ├── SessionStoreTest.res
│       │       ├── SharedTypesTest.res
│       │       ├── SimulationChainSkipperTest.res
│       │       ├── SimulationDriverTest.res
│       │       ├── SimulationLogicTest.res
│       │       ├── SimulationNavigationTest.res
│       │       ├── SimulationPathGeneratorTest.res
│       │       ├── SimulationReducerTest.res
│       │       ├── StateInspectorTest.res
│       │       ├── TeaserManagerTest.res
│       │       ├── TeaserPathfinderTest.res
│       │       ├── TeaserRecorderTest.res
│       │       ├── TimelineReducerTest.res
│       │       ├── TourLogicTest.res
│       │       ├── TourTemplateAssetsTest.res
│       │       ├── TourTemplateScriptsTest.res
│       │       ├── TourTemplateStylesTest.res
│       │       ├── TourTemplatesTest.res
│       │       ├── UiReducerTest.res
│       │       ├── UploadProcessorTest.res
│       │       ├── UrlUtilsTest.res
│       │       ├── VersionDataTest.res
│       │       ├── VersionTest.res
│       │       ├── VideoEncoderTest.res
│       │       ├── ViewerLoaderTest.res
│       │       └── VitestSmoke.test.res
│       └── vitest.config.mjs
├── package-lock.json
├── package.json
├── plans
│   ├── debug_telemetry_fix_plan.md
│   ├── logical_inconsistencies_analysis.md
│   └── step1_cleanup_notes.md
├── postcss.config.js
├── public
│   ├── early-boot.js
│   ├── images
│   │   ├── icon-192.png
│   │   ├── icon-512.png
│   │   ├── logo.png
│   │   └── og-preview.png
│   ├── libs
│   │   ├── FileSaver.min.js
│   │   ├── jszip.min.js
│   │   ├── pannellum.css
│   │   └── pannellum.js
│   ├── manifest.json
│   ├── service-worker.js
│   └── sounds
│       └── click.wav
├── rescript.json
├── rsbuild.config.mjs
├── scripts
│   ├── check-stale-tests.sh
│   ├── cleanup_logs.sh
│   ├── commit.sh
│   ├── debug-connectivity.js
│   ├── detect-missing-tests.cjs
│   ├── dev-mode.sh
│   ├── fast-commit.sh
│   ├── generate-test-tasks.cjs
│   ├── increment-build.js
│   ├── pre-push.sh
│   ├── project-guard.sh
│   ├── prune-snapshots.sh
│   ├── restore-snapshot.sh
│   ├── setup.sh
│   ├── sync-sw.cjs
│   ├── test-logging.js
│   ├── update-changelog.js
│   ├── update-readme.js
│   └── update-version.js
├── src
│   ├── App.bs.js
│   ├── App.res
│   ├── Dummy.bs.js
│   ├── Main.bs.js
│   ├── Main.res
│   ├── ReBindings.bs.js
│   ├── ReBindings.res
│   ├── ServiceWorker.bs.js
│   ├── ServiceWorker.res
│   ├── ServiceWorkerMain.bs.js
│   ├── ServiceWorkerMain.res
│   ├── components
│   │   ├── AppErrorBoundary.bs.js
│   │   ├── AppErrorBoundary.res
│   │   ├── ErrorFallbackUI.bs.js
│   │   ├── ErrorFallbackUI.res
│   │   ├── HotspotActionMenu.bs.js
│   │   ├── HotspotActionMenu.res
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
│   │   ├── PopOver.bs.js
│   │   ├── PopOver.res
│   │   ├── Portal.bs.js
│   │   ├── Portal.res
│   │   ├── PreviewArrow.bs.js
│   │   ├── PreviewArrow.res
│   │   ├── SceneList.bs.js
│   │   ├── SceneList.res
│   │   ├── Sidebar.bs.js
│   │   ├── Sidebar.res
│   │   ├── Tooltip.bs.js
│   │   ├── Tooltip.res
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
│   │   ├── VisualPipeline.res
│   │   └── ui
│   │       ├── LucideIcons.bs.js
│   │       ├── LucideIcons.res
│   │       ├── Shadcn.bs.js
│   │       ├── Shadcn.res
│   │       ├── button.jsx
│   │       ├── context-menu.jsx
│   │       ├── dropdown-menu.jsx
│   │       ├── popover.jsx
│   │       ├── sonner.jsx
│   │       └── tooltip.jsx
│   ├── core
│   │   ├── Actions.bs.js
│   │   ├── Actions.res
│   │   ├── AppContext.bs.js
│   │   ├── AppContext.res
│   │   ├── GlobalStateBridge.bs.js
│   │   ├── GlobalStateBridge.res
│   │   ├── JsonTypes.bs.js
│   │   ├── JsonTypes.res
│   │   ├── Reducer.bs.js
│   │   ├── Reducer.res
│   │   ├── ReducerHelpers.bs.js
│   │   ├── ReducerHelpers.res
│   │   ├── SharedTypes.bs.js
│   │   ├── SharedTypes.res
│   │   ├── State.bs.js
│   │   ├── State.res
│   │   ├── Types.bs.js
│   │   ├── Types.res
│   │   └── reducers
│   │       ├── HotspotReducer.bs.js
│   │       ├── HotspotReducer.res
│   │       ├── NavigationReducer.bs.js
│   │       ├── NavigationReducer.res
│   │       ├── ProjectReducer.bs.js
│   │       ├── ProjectReducer.res
│   │       ├── RootReducer.bs.js
│   │       ├── RootReducer.res
│   │       ├── SceneReducer.bs.js
│   │       ├── SceneReducer.res
│   │       ├── SimulationReducer.bs.js
│   │       ├── SimulationReducer.res
│   │       ├── TimelineReducer.bs.js
│   │       ├── TimelineReducer.res
│   │       ├── UiReducer.bs.js
│   │       ├── UiReducer.res
│   │       ├── mod.bs.js
│   │       └── mod.res
│   ├── index.js
│   ├── lib
│   │   └── utils.js
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
│   │   ├── HotspotLineLogic.bs.js
│   │   ├── HotspotLineLogic.res
│   │   ├── HotspotLineTypes.bs.js
│   │   ├── HotspotLineTypes.res
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
│   │   ├── SimulationDriver.bs.js
│   │   ├── SimulationDriver.res
│   │   ├── SimulationLogic.bs.js
│   │   ├── SimulationLogic.res
│   │   ├── SimulationNavigation.bs.js
│   │   ├── SimulationNavigation.res
│   │   ├── SimulationPathGenerator.bs.js
│   │   ├── SimulationPathGenerator.res
│   │   ├── SvgManager.bs.js
│   │   ├── SvgManager.res
│   │   ├── TeaserManager.bs.js
│   │   ├── TeaserManager.res
│   │   ├── TeaserPathfinder.bs.js
│   │   ├── TeaserPathfinder.res
│   │   ├── TeaserRecorder.bs.js
│   │   ├── TeaserRecorder.res
│   │   ├── TourTemplateAssets.bs.js
│   │   ├── TourTemplateAssets.res
│   │   ├── TourTemplateScripts.bs.js
│   │   ├── TourTemplateScripts.res
│   │   ├── TourTemplateStyles.bs.js
│   │   ├── TourTemplateStyles.res
│   │   ├── TourTemplates.bs.js
│   │   ├── TourTemplates.res
│   │   ├── UploadProcessor.bs.js
│   │   ├── UploadProcessor.res
│   │   ├── UploadProcessorLogic.bs.js
│   │   ├── UploadProcessorLogic.res
│   │   ├── UploadProcessorTypes.bs.js
│   │   ├── UploadProcessorTypes.res
│   │   ├── VideoEncoder.bs.js
│   │   └── VideoEncoder.res
│   └── utils
│       ├── ColorPalette.bs.js
│       ├── ColorPalette.res
│       ├── Constants.bs.js
│       ├── Constants.res
│       ├── GeoUtils.bs.js
│       ├── GeoUtils.res
│       ├── ImageOptimizer.bs.js
│       ├── ImageOptimizer.res
│       ├── ImageOptimizer.resi
│       ├── LazyLoad.bs.js
│       ├── LazyLoad.res
│       ├── Logger.bs.js
│       ├── Logger.res
│       ├── PathInterpolation.bs.js
│       ├── PathInterpolation.res
│       ├── ProgressBar.bs.js
│       ├── ProgressBar.res
│       ├── RequestQueue.bs.js
│       ├── RequestQueue.res
│       ├── SessionStore.bs.js
│       ├── SessionStore.res
│       ├── StateInspector.bs.js
│       ├── StateInspector.res
│       ├── TourLogic.bs.js
│       ├── TourLogic.res
│       ├── UrlUtils.bs.js
│       ├── UrlUtils.res
│       ├── Version.bs.js
│       ├── Version.res
│       ├── VersionData.bs.js
│       └── VersionData.res
├── start_prod.sh
├── tailwind.config.js
├── tasks
│   ├── TASKS.md
│   ├── active
│   │   └── 005_create_changelog.md
│   ├── completed
│   │   ├── 347_Update_Tests_ProjectManager_UPDATED.md
│   │   ├── 348_Update_Tests_DownloadSystem_UPDATED.md
│   │   ├── 349_Update_Tests_NavigationRenderer_UPDATED.md
│   │   ├── 350_Aggregate_Completed_Tasks_REPORT.md
│   │   ├── 351_Update_Tests_SimulationLogic_UPDATED.md
│   │   ├── 352_Update_Tests_BackendApi_UPDATED.md
│   │   ├── 353_Update_Tests_LucideIcons_UPDATED.md
│   │   ├── 354_Update_Tests_Resizer_UPDATED.md
│   │   ├── 355_Update_Tests_HotspotLineTypes_UPDATED.md
│   │   ├── 356_Update_Tests_SceneList_UPDATED.md
│   │   ├── 357_Update_Tests_ErrorFallbackUI_UPDATED.md
│   │   ├── 358_Update_Tests_InputSystem_UPDATED.md
│   │   ├── 359_Update_Tests_SimulationReducer_UPDATED.md
│   │   ├── 360_Update_Tests_App_UPDATED.md
│   │   ├── 361_Update_Tests_JsonTypes_UPDATED.md
│   │   ├── 362_Update_Tests_SimulationChainSkipper_UPDATED.md
│   │   ├── 363_Update_Tests_SimulationNavigation_UPDATED.md
│   │   ├── 364_Update_Tests_TourTemplateScripts_UPDATED.md
│   │   ├── 365_Update_Tests_Constants_UPDATED.md
│   │   ├── 366_Update_Tests_PathInterpolation_UPDATED.md
│   │   ├── 367_Update_Tests_ExifParser_UPDATED.md
│   │   ├── 368_Update_Tests_TeaserPathfinder_UPDATED.md
│   │   ├── 369_Update_Tests_TeaserManager_UPDATED.md
│   │   ├── 370_Update_Tests_TeaserRecorder_UPDATED.md
│   │   ├── 371_Migrate_Tests_Core_Reducers_UPDATED.md
│   │   ├── 372_Migrate_Tests_Core_Logic_REPORT.md
│   │   ├── 373_Migrate_Tests_Templates_Exporter_UPDATED.md
│   │   ├── 374_Migrate_Tests_Utilities_Services.md
│   │   ├── 374_Migrate_Tests_Utilities_Services_UPDATED.md
│   │   ├── 375_Migrate_Tests_Media_Specialized_REPORT.md
│   │   ├── 376_Refactor_project_REPORT.md
│   │   ├── 405_Update_Tests_Core_Architecture_UPDATED.md
│   │   ├── 406_Update_Tests_UI_and_Viewer_REPORT.md
│   │   ├── 407_Update_Tests_Business_Systems_UPDATED.md
│   │   ├── 408_Update_Tests_Utilities_REPORT.md
│   │   ├── 409_Update_Tests_ViewerManager_UPDATED.md
│   │   ├── 410_Add_Tests_App.md
│   │   ├── 504_Test_Group_GUI_Update_DONE.md
│   │   ├── 505_Test_Group_Reducers_Update_DONE.md
│   │   ├── 506_Test_Group_Core_Update_DONE.md
│   │   ├── 507_Test_Group_Simulation_Update_DONE.md
│   │   ├── 508_Test_Group_Utils_Integration_Update_DONE.md
│   │   ├── 510_tech_debt_and_type_safety_restoration_REPORT.md
│   │   ├── 511_Update_Codebase_Map_REPORT.md
│   │   ├── 535_Perf_Lower_Spline_Density_REPORT.md
│   │   ├── 536_Perf_Adjust_Pannellum_Friction_REPORT.md
│   │   ├── 537_Perf_Precalculate_Projection_Constants_REPORT.md
│   │   ├── 538_Perf_Loop_Consolidation_REPORT.md
│   │   ├── 539_REBOOT_SVG_Element_Reuse.md
│   │   ├── 569_Perf_Split_AppContext_REPORT.md
│   │   ├── 570_Perf_Implement_Memoization.md
│   │   ├── 571_Perf_Debounce_Input_Updates_REPORT.md
│   │   ├── 95_Aggregate_Completed_Tasks_REPORT.md
│   │   └── _CONCISE_SUMMARY.md
│   ├── pending
│   │   ├── 580_Refactor_ViewerUI.md
│   │   ├── 581_Refactor_ViewerManager.md
│   │   ├── 582_Refactor_ViewerLoader.md
│   │   ├── 583_Refactor_HotspotLineLogic.md
│   │   ├── 584_Refactor_BackendApi.md
│   │   ├── 585_Refactor_UploadProcessorLogic.md
│   │   ├── 586_Refactor_TeaserManager.md
│   │   ├── 587_Refactor_Navigation.md
│   │   ├── 588_Refactor_ReducerHelpers.md
│   │   └── tests
│   │       ├── 512_Test_ViewerManager_Update.md
│   │       ├── 513_Test_ViewerFollow_Update.md
│   │       ├── 514_Test_UploadProcessor_Update.md
│   │       ├── 515_Test_Sidebar_Update.md
│   │       ├── 516_Test_Exporter_Update.md
│   │       ├── 517_Test_ProjectManager_Update.md
│   │       ├── 518_Test_HotspotLine_Update.md
│   │       ├── 519_Test_ProjectData_Update.md
│   │       ├── 520_Test_BackendApi_Update.md
│   │       ├── 521_Test_ExifReportGenerator_Update.md
│   │       ├── 522_Test_UploadProcessorLogic_Update.md
│   │       ├── 523_Test_ServerTeaser_Update.md
│   │       ├── 524_Test_TourTemplates_Update.md
│   │       ├── 525_Test_ServiceWorker_Update.md
│   │       ├── 526_Test_SceneList_Update.md
│   │       ├── 527_Test_PreviewArrow_Update.md
│   │       ├── 528_Test_ViewerUI_Update.md
│   │       ├── 529_Test_UploadReport_Update.md
│   │       ├── 530_Test_DownloadSystem_Update.md
│   │       ├── 531_Test_VersionData_Update.md
│   │       ├── 532_Test_LucideIcons_Update.md
│   │       ├── 533_Test_Shadcn_Update.md
│   │       ├── 534_Test_Navigation_Update.md
│   │       ├── 540_Test_HotspotLineLogic_Update.md
│   │       ├── 541_Test_ViewerLoader_Update.md
│   │       ├── 542_Test_SessionStore_Update.md
│   │       ├── 543_Test_InputSystem_Update.md
│   │       ├── 544_Test_TeaserRecorder_Update.md
│   │       ├── 545_Test_TeaserManager_Update.md
│   │       ├── 546_Test_Types_Update.md
│   │       ├── 547_Test_UiReducer_Update.md
│   │       ├── 548_Test_NavigationController_Update.md
│   │       ├── 549_Test_SvgManager_New.md
│   │       ├── 550_Test_HotspotManager_Update.md
│   │       ├── 551_Test_LinkModal_Update.md
│   │       ├── 552_Test_SceneReducer_Update.md
│   │       ├── 553_Test_RequestQueue_Update.md
│   │       ├── 554_Test_LazyLoad_Update.md
│   │       ├── 555_Test_PathInterpolation_Update.md
│   │       ├── 556_Test_StateInspector_Update.md
│   │       ├── 557_Test_NavigationUI_Update.md
│   │       ├── 558_Test_SimulationNavigation_Update.md
│   │       ├── 559_Test_GlobalStateBridge_Update.md
│   │       ├── 560_Test_Logger_Update.md
│   │       ├── 561_Test_Reducer_Update.md
│   │       ├── 562_Test_SimulationPathGenerator_Update.md
│   │       ├── 563_Test_Constants_Update.md
│   │       ├── 564_Test_GeoUtils_Update.md
│   │       ├── 565_Test_UrlUtils_Update.md
│   │       ├── 566_Test_NotificationContext_Update.md
│   │       ├── 567_Test_TourTemplateAssets_Update.md
│   │       ├── 568_Test_ModalContext_Update.md
│   │       ├── 572_Test_RootReducer_Update.md
│   │       ├── 589_Test_TourTemplateStyles_Update.md
│   │       ├── 590_Test_SimulationChainSkipper_Update.md
│   │       ├── 591_Test_TourLogic_Update.md
│   │       ├── 592_Test_VisualPipeline_Update.md
│   │       └── 593_Test_TourTemplateScripts_Update.md
│   └── postponed
│       ├── 003_add_seo_structured_data.md
│       ├── 004_document_core_web_vitals.md
│       ├── 006_update_docs_anchor_positioning_standards.md
│       ├── 015_create_legal_compliance_documents.md
│       ├── 020_visual_regression_testing.md
│       ├── 021_theme_switching_infrastructure.md
│       ├── 022_expand_test_coverage.md
│       ├── 024_implement_e2e_testing_playwright.md
│       ├── 025_implement_internationalization.md
│       ├── 030_implement_sqlite_auth_infrastructure.md
│       ├── 031_implement_auth_ui_rescript.md
│       ├── 032_implement_project_dashboard.md
│       ├── 033_secure_backend_with_jwt.md
│       └── tests
├── test_output.txt
├── tested_icons.txt
├── tests
│   ├── TestRunner.bs.js
│   ├── TestRunner.res
│   ├── jsx-loader.mjs
│   ├── node-setup.js
│   └── unit
│       ├── ActionsTest.bs.js
│       ├── Actions_v.test.bs.js
│       ├── Actions_v.test.res
│       ├── AppContext_v.test.bs.js
│       ├── AppContext_v.test.res
│       ├── AppErrorBoundary_v.test.bs.js
│       ├── AppErrorBoundary_v.test.res
│       ├── App_v.test.bs.js
│       ├── App_v.test.res
│       ├── AudioManager_v.test.bs.js
│       ├── AudioManager_v.test.res
│       ├── BackendApi_v.test.bs.js
│       ├── BackendApi_v.test.res
│       ├── ColorPalette_v.test.bs.js
│       ├── ColorPalette_v.test.res
│       ├── Constants_v.test.bs.js
│       ├── Constants_v.test.res
│       ├── DownloadSystem_v.test.bs.js
│       ├── DownloadSystem_v.test.res
│       ├── ErrorFallbackUI_v.test.bs.js
│       ├── ErrorFallbackUI_v.test.res
│       ├── EventBusTest.bs.js
│       ├── EventBus_v.test.bs.js
│       ├── EventBus_v.test.res
│       ├── ExifParser_v.test.bs.js
│       ├── ExifParser_v.test.res
│       ├── ExifReportGenerator_v.test.bs.js
│       ├── ExifReportGenerator_v.test.res
│       ├── Exporter_v.test.bs.js
│       ├── Exporter_v.test.res
│       ├── GeoUtils_v.test.bs.js
│       ├── GeoUtils_v.test.res
│       ├── GlobalStateBridgeTest.bs.js
│       ├── GlobalStateBridge_v.test.bs.js
│       ├── GlobalStateBridge_v.test.res
│       ├── HotspotActionMenu_v.test.bs.js
│       ├── HotspotActionMenu_v.test.res
│       ├── HotspotLineLogic_v.test.bs.js
│       ├── HotspotLineLogic_v.test.res
│       ├── HotspotLineTypes_v.test.bs.js
│       ├── HotspotLineTypes_v.test.res
│       ├── HotspotLine_v.test.bs.js
│       ├── HotspotLine_v.test.res
│       ├── HotspotLine_v.test.setup.js
│       ├── HotspotManager_v.test.bs.js
│       ├── HotspotManager_v.test.res
│       ├── HotspotReducer_v.test.bs.js
│       ├── HotspotReducer_v.test.res
│       ├── ImageOptimizer_v.test.bs.js
│       ├── ImageOptimizer_v.test.res
│       ├── InputSystem_v.test.bs.js
│       ├── InputSystem_v.test.res
│       ├── InteractionsRobustness_v.test.bs.js
│       ├── InteractionsRobustness_v.test.res
│       ├── JsonTypes_v.test.bs.js
│       ├── JsonTypes_v.test.res
│       ├── LabelMenu_v.test.bs.js
│       ├── LabelMenu_v.test.res
│       ├── LabelMenu_v.test.setup.jsx
│       ├── LazyLoad_v.test.bs.js
│       ├── LazyLoad_v.test.res
│       ├── LinkModal_v.test.bs.js
│       ├── LinkModal_v.test.res
│       ├── Logger_v.test.bs.js
│       ├── Logger_v.test.res
│       ├── LucideIcons_v.test.bs.js
│       ├── LucideIcons_v.test.res
│       ├── Main_v.test.bs.js
│       ├── Main_v.test.res
│       ├── Mod_v.test.bs.js
│       ├── Mod_v.test.res
│       ├── ModalContext_v.test.bs.js
│       ├── ModalContext_v.test.res
│       ├── NavigationController_v.test.bs.js
│       ├── NavigationController_v.test.res
│       ├── NavigationReducer_v.test.bs.js
│       ├── NavigationReducer_v.test.res
│       ├── NavigationRenderer_v.test.bs.js
│       ├── NavigationRenderer_v.test.res
│       ├── NavigationUI_v.test.bs.js
│       ├── NavigationUI_v.test.res
│       ├── Navigation_v.test.bs.js
│       ├── Navigation_v.test.res
│       ├── NotificationContext_v.test.bs.js
│       ├── NotificationContext_v.test.res
│       ├── PathInterpolation_v.test.bs.js
│       ├── PathInterpolation_v.test.res
│       ├── PopOver_v.test.bs.js
│       ├── PopOver_v.test.res
│       ├── Portal_v.test.bs.js
│       ├── Portal_v.test.res
│       ├── PreviewArrow_v.test.bs.js
│       ├── PreviewArrow_v.test.res
│       ├── ProgressBar_v.test.bs.js
│       ├── ProgressBar_v.test.res
│       ├── ProjectData_v.test.bs.js
│       ├── ProjectData_v.test.res
│       ├── ProjectManager_v.test.bs.js
│       ├── ProjectManager_v.test.res
│       ├── ProjectReducer_v.test.bs.js
│       ├── ProjectReducer_v.test.res
│       ├── ReBindings_v.test.bs.js
│       ├── ReBindings_v.test.res
│       ├── ReducerHelpers_v.test.bs.js
│       ├── ReducerHelpers_v.test.res
│       ├── Reducer_v.test.bs.js
│       ├── Reducer_v.test.res
│       ├── RequestQueue_v.test.bs.js
│       ├── RequestQueue_v.test.res
│       ├── Resizer_v.test.bs.js
│       ├── Resizer_v.test.res
│       ├── RootReducer_v.test.bs.js
│       ├── RootReducer_v.test.res
│       ├── SceneList_v.test.bs.js
│       ├── SceneList_v.test.res
│       ├── SceneReducer_v.test.bs.js
│       ├── SceneReducer_v.test.res
│       ├── ServerTeaser_v.test.bs.js
│       ├── ServerTeaser_v.test.res
│       ├── ServiceWorkerMain_v.test.bs.js
│       ├── ServiceWorkerMain_v.test.res
│       ├── ServiceWorker_v.test.bs.js
│       ├── ServiceWorker_v.test.res
│       ├── SessionStore_v.test.bs.js
│       ├── SessionStore_v.test.res
│       ├── Shadcn_v.test.bs.js
│       ├── Shadcn_v.test.res
│       ├── SharedTypesTest.bs.js
│       ├── SharedTypes_v.test.bs.js
│       ├── SharedTypes_v.test.res
│       ├── Sidebar_v.test.bs.js
│       ├── Sidebar_v.test.res
│       ├── SimulationChainSkipper_v.test.bs.js
│       ├── SimulationChainSkipper_v.test.res
│       ├── SimulationDriver_v.test.bs.js
│       ├── SimulationDriver_v.test.res
│       ├── SimulationLogic_v.test.bs.js
│       ├── SimulationLogic_v.test.res
│       ├── SimulationNavigation_v.test.bs.js
│       ├── SimulationNavigation_v.test.res
│       ├── SimulationPathGenerator_v.test.bs.js
│       ├── SimulationPathGenerator_v.test.res
│       ├── SimulationReducer_v.test.bs.js
│       ├── SimulationReducer_v.test.res
│       ├── StateInspectorTest.bs.js
│       ├── StateInspector_v.test.bs.js
│       ├── StateInspector_v.test.res
│       ├── State_v.test.bs.js
│       ├── State_v.test.res
│       ├── TeaserManager_v.test.bs.js
│       ├── TeaserManager_v.test.res
│       ├── TeaserPathfinder_v.test.bs.js
│       ├── TeaserPathfinder_v.test.res
│       ├── TeaserRecorder_v.test.bs.js
│       ├── TeaserRecorder_v.test.res
│       ├── TimelineReducer_v.test.bs.js
│       ├── TimelineReducer_v.test.res
│       ├── Tooltip_v.test.bs.js
│       ├── Tooltip_v.test.res
│       ├── TourLogic_v.test.bs.js
│       ├── TourLogic_v.test.res
│       ├── TourTemplateAssets_v.test.bs.js
│       ├── TourTemplateAssets_v.test.res
│       ├── TourTemplateScripts_v.test.bs.js
│       ├── TourTemplateScripts_v.test.res
│       ├── TourTemplateStyles_v.test.bs.js
│       ├── TourTemplateStyles_v.test.res
│       ├── TourTemplates_v.test.bs.js
│       ├── TourTemplates_v.test.res
│       ├── Types_v.test.bs.js
│       ├── Types_v.test.res
│       ├── UiReducer_v.test.bs.js
│       ├── UiReducer_v.test.res
│       ├── UploadProcessorLogic_v.test.bs.js
│       ├── UploadProcessorLogic_v.test.res
│       ├── UploadProcessorTypes_v.test.bs.js
│       ├── UploadProcessorTypes_v.test.res
│       ├── UploadProcessor_v.test.bs.js
│       ├── UploadProcessor_v.test.res
│       ├── UploadProcessor_v.test.setup.js
│       ├── UploadReport_v.test.bs.js
│       ├── UploadReport_v.test.res
│       ├── UrlUtils_v.test.bs.js
│       ├── UrlUtils_v.test.res
│       ├── VersionData_v.test.bs.js
│       ├── VersionData_v.test.res
│       ├── Version_v.test.bs.js
│       ├── Version_v.test.res
│       ├── VideoEncoder_v.test.bs.js
│       ├── VideoEncoder_v.test.res
│       ├── ViewerFollow_v.test.bs.js
│       ├── ViewerFollow_v.test.res
│       ├── ViewerLoader_v.test.bs.js
│       ├── ViewerLoader_v.test.res
│       ├── ViewerManager_v.test.bs.js
│       ├── ViewerManager_v.test.res
│       ├── ViewerSnapshot_v.test.bs.js
│       ├── ViewerSnapshot_v.test.res
│       ├── ViewerState_v.test.bs.js
│       ├── ViewerState_v.test.res
│       ├── ViewerTypes_v.test.bs.js
│       ├── ViewerTypes_v.test.res
│       ├── ViewerUI_v.test.bs.js
│       ├── ViewerUI_v.test.res
│       ├── VisualPipeline_v.test.bs.js
│       ├── VisualPipeline_v.test.res
│       ├── VitestSmoke.test.bs.js
│       ├── VitestSmoke.test.res
│       └── utils
│           ├── TestUtils.bs.js
│           └── TestUtils.res
└── vitest.config.mjs

177 directories, 4177 files
