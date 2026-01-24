.
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
│   │   ├── src
│   │   │   ├── App.ast
│   │   │   ├── Main.ast
│   │   │   ├── ReBindings.ast
│   │   │   ├── ServiceWorker.ast
│   │   │   ├── ServiceWorkerMain.ast
│   │   │   ├── components
│   │   │   │   ├── AppErrorBoundary.ast
│   │   │   │   ├── ErrorFallbackUI.ast
│   │   │   │   ├── HotspotActionMenu.ast
│   │   │   │   ├── HotspotManager.ast
│   │   │   │   ├── LabelMenu.ast
│   │   │   │   ├── LinkModal.ast
│   │   │   │   ├── ModalContext.ast
│   │   │   │   ├── NotificationContext.ast
│   │   │   │   ├── PopOver.ast
│   │   │   │   ├── Portal.ast
│   │   │   │   ├── PreviewArrow.ast
│   │   │   │   ├── SceneList.ast
│   │   │   │   ├── Sidebar.ast
│   │   │   │   ├── Tooltip.ast
│   │   │   │   ├── UploadReport.ast
│   │   │   │   ├── ViewerFollow.ast
│   │   │   │   ├── ViewerLoader.ast
│   │   │   │   ├── ViewerManager.ast
│   │   │   │   ├── ViewerSnapshot.ast
│   │   │   │   ├── ViewerState.ast
│   │   │   │   ├── ViewerTypes.ast
│   │   │   │   ├── VisualPipeline.ast
│   │   │   │   └── ui
│   │   │   │       ├── LucideIcons.ast
│   │   │   │       └── Shadcn.ast
│   │   │   ├── core
│   │   │   │   ├── Actions.ast
│   │   │   │   ├── AppContext.ast
│   │   │   │   ├── GlobalStateBridge.ast
│   │   │   │   ├── JsonTypes.ast
│   │   │   │   ├── Reducer.ast
│   │   │   │   ├── ReducerHelpers.ast
│   │   │   │   ├── SharedTypes.ast
│   │   │   │   ├── State.ast
│   │   │   │   ├── Types.ast
│   │   │   │   └── reducers
│   │   │   │       ├── HotspotReducer.ast
│   │   │   │       ├── NavigationReducer.ast
│   │   │   │       ├── ProjectReducer.ast
│   │   │   │       ├── RootReducer.ast
│   │   │   │       ├── SceneReducer.ast
│   │   │   │       ├── SimulationReducer.ast
│   │   │   │       ├── TimelineReducer.ast
│   │   │   │       ├── UiReducer.ast
│   │   │   │       └── mod.ast
│   │   │   ├── systems
│   │   │   │   ├── AudioManager.ast
│   │   │   │   ├── BackendApi.ast
│   │   │   │   ├── DownloadSystem.ast
│   │   │   │   ├── EventBus.ast
│   │   │   │   ├── ExifParser.ast
│   │   │   │   ├── ExifReportGenerator.ast
│   │   │   │   ├── Exporter.ast
│   │   │   │   ├── HotspotLine.ast
│   │   │   │   ├── HotspotLineLogic.ast
│   │   │   │   ├── HotspotLineTypes.ast
│   │   │   │   ├── InputSystem.ast
│   │   │   │   ├── Navigation.ast
│   │   │   │   ├── NavigationController.ast
│   │   │   │   ├── NavigationRenderer.ast
│   │   │   │   ├── NavigationUI.ast
│   │   │   │   ├── ProjectData.ast
│   │   │   │   ├── ProjectManager.ast
│   │   │   │   ├── Resizer.ast
│   │   │   │   ├── ServerTeaser.ast
│   │   │   │   ├── SimulationChainSkipper.ast
│   │   │   │   ├── SimulationDriver.ast
│   │   │   │   ├── SimulationLogic.ast
│   │   │   │   ├── SimulationNavigation.ast
│   │   │   │   ├── SimulationPathGenerator.ast
│   │   │   │   ├── TeaserManager.ast
│   │   │   │   ├── TeaserPathfinder.ast
│   │   │   │   ├── TeaserRecorder.ast
│   │   │   │   ├── TourTemplateAssets.ast
│   │   │   │   ├── TourTemplateScripts.ast
│   │   │   │   ├── TourTemplateStyles.ast
│   │   │   │   ├── TourTemplates.ast
│   │   │   │   ├── UploadProcessor.ast
│   │   │   │   ├── UploadProcessorLogic.ast
│   │   │   │   ├── UploadProcessorTypes.ast
│   │   │   │   └── VideoEncoder.ast
│   │   │   └── utils
│   │   │       ├── ColorPalette.ast
│   │   │       ├── Constants.ast
│   │   │       ├── GeoUtils.ast
│   │   │       ├── ImageOptimizer.ast
│   │   │       ├── ImageOptimizer.iast
│   │   │       ├── LazyLoad.ast
│   │   │       ├── Logger.ast
│   │   │       ├── PathInterpolation.ast
│   │   │       ├── ProgressBar.ast
│   │   │       ├── RequestQueue.ast
│   │   │       ├── SessionStore.ast
│   │   │       ├── StateInspector.ast
│   │   │       ├── TourLogic.ast
│   │   │       ├── UrlUtils.ast
│   │   │       ├── Version.ast
│   │   │       └── VersionData.ast
│   │   └── tests
│   │       ├── TestRunner.ast
│   │       └── unit
│   │           ├── Actions_v.test.ast
│   │           ├── AppContext_v.test.ast
│   │           ├── AppErrorBoundary_v.test.ast
│   │           ├── App_v.test.ast
│   │           ├── AudioManager_v.test.ast
│   │           ├── BackendApi_v.test.ast
│   │           ├── ColorPalette_v.test.ast
│   │           ├── Constants_v.test.ast
│   │           ├── DownloadSystem_v.test.ast
│   │           ├── ErrorFallbackUI_v.test.ast
│   │           ├── EventBus_v.test.ast
│   │           ├── ExifParser_v.test.ast
│   │           ├── ExifReportGenerator_v.test.ast
│   │           ├── Exporter_v.test.ast
│   │           ├── GeoUtils_v.test.ast
│   │           ├── GlobalStateBridge_v.test.ast
│   │           ├── HotspotActionMenu_v.test.ast
│   │           ├── HotspotLineLogic_v.test.ast
│   │           ├── HotspotLineTypes_v.test.ast
│   │           ├── HotspotLine_v.test.ast
│   │           ├── HotspotManager_v.test.ast
│   │           ├── HotspotReducer_v.test.ast
│   │           ├── ImageOptimizer_v.test.ast
│   │           ├── InputSystem_v.test.ast
│   │           ├── JsonTypes_v.test.ast
│   │           ├── LabelMenu_v.test.ast
│   │           ├── LazyLoad_v.test.ast
│   │           ├── LinkModal_v.test.ast
│   │           ├── Logger_v.test.ast
│   │           ├── LucideIcons_v.test.ast
│   │           ├── Main_v.test.ast
│   │           ├── Mod_v.test.ast
│   │           ├── ModalContext_v.test.ast
│   │           ├── NavigationController_v.test.ast
│   │           ├── NavigationReducer_v.test.ast
│   │           ├── NavigationRenderer_v.test.ast
│   │           ├── NavigationUI_v.test.ast
│   │           ├── Navigation_v.test.ast
│   │           ├── NotificationContext_v.test.ast
│   │           ├── PathInterpolation_v.test.ast
│   │           ├── PopOver_v.test.ast
│   │           ├── Portal_v.test.ast
│   │           ├── ProgressBar_v.test.ast
│   │           ├── ProjectData_v.test.ast
│   │           ├── ProjectManager_v.test.ast
│   │           ├── ProjectReducer_v.test.ast
│   │           ├── ReBindings_v.test.ast
│   │           ├── ReducerHelpers_v.test.ast
│   │           ├── Reducer_v.test.ast
│   │           ├── RequestQueue_v.test.ast
│   │           ├── Resizer_v.test.ast
│   │           ├── RootReducer_v.test.ast
│   │           ├── SceneList_v.test.ast
│   │           ├── SceneReducer_v.test.ast
│   │           ├── ServerTeaser_v.test.ast
│   │           ├── ServiceWorkerMain_v.test.ast
│   │           ├── ServiceWorker_v.test.ast
│   │           ├── SessionStore_v.test.ast
│   │           ├── Shadcn_v.test.ast
│   │           ├── SharedTypes_v.test.ast
│   │           ├── Sidebar_v.test.ast
│   │           ├── SimulationChainSkipper_v.test.ast
│   │           ├── SimulationDriver_v.test.ast
│   │           ├── SimulationLogic_v.test.ast
│   │           ├── SimulationNavigation_v.test.ast
│   │           ├── SimulationPathGenerator_v.test.ast
│   │           ├── SimulationReducer_v.test.ast
│   │           ├── StateInspector_v.test.ast
│   │           ├── State_v.test.ast
│   │           ├── TeaserManager_v.test.ast
│   │           ├── TeaserPathfinder_v.test.ast
│   │           ├── TeaserRecorder_v.test.ast
│   │           ├── TimelineReducer_v.test.ast
│   │           ├── Tooltip_v.test.ast
│   │           ├── TourLogic_v.test.ast
│   │           ├── TourTemplateAssets_v.test.ast
│   │           ├── TourTemplateScripts_v.test.ast
│   │           ├── TourTemplateStyles_v.test.ast
│   │           ├── TourTemplates_v.test.ast
│   │           ├── Types_v.test.ast
│   │           ├── UiReducer_v.test.ast
│   │           ├── UploadProcessorLogic_v.test.ast
│   │           ├── UploadProcessorTypes_v.test.ast
│   │           ├── UploadProcessor_v.test.ast
│   │           ├── UploadReport_v.test.ast
│   │           ├── UrlUtils_v.test.ast
│   │           ├── VersionData_v.test.ast
│   │           ├── Version_v.test.ast
│   │           ├── VideoEncoder_v.test.ast
│   │           ├── ViewerFollow_v.test.ast
│   │           ├── ViewerLoader_v.test.ast
│   │           ├── ViewerManager_v.test.ast
│   │           ├── ViewerSnapshot_v.test.ast
│   │           ├── ViewerState_v.test.ast
│   │           ├── ViewerTypes_v.test.ast
│   │           ├── ViewerUI_v.test.ast
│   │           ├── VisualPipeline_v.test.ast
│   │           ├── VitestSmoke.test.ast
│   │           └── utils
│   │               └── TestUtils.ast
│   ├── ocaml
│   │   ├── Actions.ast
│   │   ├── Actions_v.test.ast
│   │   ├── App.ast
│   │   ├── AppContext.ast
│   │   ├── AppContext_v.test.ast
│   │   ├── AppErrorBoundary.ast
│   │   ├── AppErrorBoundary_v.test.ast
│   │   ├── App_v.test.ast
│   │   ├── AudioManager.ast
│   │   ├── AudioManager_v.test.ast
│   │   ├── BackendApi.ast
│   │   ├── BackendApi_v.test.ast
│   │   ├── ColorPalette.ast
│   │   ├── ColorPalette_v.test.ast
│   │   ├── Constants.ast
│   │   ├── Constants_v.test.ast
│   │   ├── DownloadSystem.ast
│   │   ├── DownloadSystem_v.test.ast
│   │   ├── ErrorFallbackUI.ast
│   │   ├── ErrorFallbackUI_v.test.ast
│   │   ├── EventBus.ast
│   │   ├── EventBus_v.test.ast
│   │   ├── ExifParser.ast
│   │   ├── ExifParser_v.test.ast
│   │   ├── ExifReportGenerator.ast
│   │   ├── ExifReportGenerator_v.test.ast
│   │   ├── Exporter.ast
│   │   ├── Exporter_v.test.ast
│   │   ├── GeoUtils.ast
│   │   ├── GeoUtils_v.test.ast
│   │   ├── GlobalStateBridge.ast
│   │   ├── GlobalStateBridge_v.test.ast
│   │   ├── HotspotActionMenu.ast
│   │   ├── HotspotActionMenu_v.test.ast
│   │   ├── HotspotLine.ast
│   │   ├── HotspotLineLogic.ast
│   │   ├── HotspotLineLogic_v.test.ast
│   │   ├── HotspotLineTypes.ast
│   │   ├── HotspotLineTypes_v.test.ast
│   │   ├── HotspotLine_v.test.ast
│   │   ├── HotspotManager.ast
│   │   ├── HotspotManager_v.test.ast
│   │   ├── HotspotReducer.ast
│   │   ├── HotspotReducer_v.test.ast
│   │   ├── ImageOptimizer.ast
│   │   ├── ImageOptimizer.iast
│   │   ├── ImageOptimizer_v.test.ast
│   │   ├── InputSystem.ast
│   │   ├── InputSystem_v.test.ast
│   │   ├── JsonTypes.ast
│   │   ├── JsonTypes_v.test.ast
│   │   ├── LabelMenu.ast
│   │   ├── LabelMenu_v.test.ast
│   │   ├── LazyLoad.ast
│   │   ├── LazyLoad_v.test.ast
│   │   ├── LinkModal.ast
│   │   ├── LinkModal_v.test.ast
│   │   ├── Logger.ast
│   │   ├── Logger_v.test.ast
│   │   ├── LucideIcons.ast
│   │   ├── LucideIcons_v.test.ast
│   │   ├── Main.ast
│   │   ├── Main_v.test.ast
│   │   ├── Mod_v.test.ast
│   │   ├── ModalContext.ast
│   │   ├── ModalContext_v.test.ast
│   │   ├── Navigation.ast
│   │   ├── NavigationController.ast
│   │   ├── NavigationController_v.test.ast
│   │   ├── NavigationReducer.ast
│   │   ├── NavigationReducer_v.test.ast
│   │   ├── NavigationRenderer.ast
│   │   ├── NavigationRenderer_v.test.ast
│   │   ├── NavigationUI.ast
│   │   ├── NavigationUI_v.test.ast
│   │   ├── Navigation_v.test.ast
│   │   ├── NotificationContext.ast
│   │   ├── NotificationContext_v.test.ast
│   │   ├── PathInterpolation.ast
│   │   ├── PathInterpolation_v.test.ast
│   │   ├── PopOver.ast
│   │   ├── PopOver_v.test.ast
│   │   ├── Portal.ast
│   │   ├── Portal_v.test.ast
│   │   ├── PreviewArrow.ast
│   │   ├── ProgressBar.ast
│   │   ├── ProgressBar_v.test.ast
│   │   ├── ProjectData.ast
│   │   ├── ProjectData_v.test.ast
│   │   ├── ProjectManager.ast
│   │   ├── ProjectManager_v.test.ast
│   │   ├── ProjectReducer.ast
│   │   ├── ProjectReducer_v.test.ast
│   │   ├── ReBindings.ast
│   │   ├── ReBindings_v.test.ast
│   │   ├── Reducer.ast
│   │   ├── ReducerHelpers.ast
│   │   ├── ReducerHelpers_v.test.ast
│   │   ├── Reducer_v.test.ast
│   │   ├── RequestQueue.ast
│   │   ├── RequestQueue_v.test.ast
│   │   ├── Resizer.ast
│   │   ├── Resizer_v.test.ast
│   │   ├── RootReducer.ast
│   │   ├── RootReducer_v.test.ast
│   │   ├── SceneList.ast
│   │   ├── SceneList_v.test.ast
│   │   ├── SceneReducer.ast
│   │   ├── SceneReducer_v.test.ast
│   │   ├── ServerTeaser.ast
│   │   ├── ServerTeaser_v.test.ast
│   │   ├── ServiceWorker.ast
│   │   ├── ServiceWorkerMain.ast
│   │   ├── ServiceWorkerMain_v.test.ast
│   │   ├── ServiceWorker_v.test.ast
│   │   ├── SessionStore.ast
│   │   ├── SessionStore_v.test.ast
│   │   ├── Shadcn.ast
│   │   ├── Shadcn_v.test.ast
│   │   ├── SharedTypes.ast
│   │   ├── SharedTypes_v.test.ast
│   │   ├── Sidebar.ast
│   │   ├── Sidebar_v.test.ast
│   │   ├── SimulationChainSkipper.ast
│   │   ├── SimulationChainSkipper_v.test.ast
│   │   ├── SimulationDriver.ast
│   │   ├── SimulationDriver_v.test.ast
│   │   ├── SimulationLogic.ast
│   │   ├── SimulationLogic_v.test.ast
│   │   ├── SimulationNavigation.ast
│   │   ├── SimulationNavigation_v.test.ast
│   │   ├── SimulationPathGenerator.ast
│   │   ├── SimulationPathGenerator_v.test.ast
│   │   ├── SimulationReducer.ast
│   │   ├── SimulationReducer_v.test.ast
│   │   ├── State.ast
│   │   ├── StateInspector.ast
│   │   ├── StateInspector_v.test.ast
│   │   ├── State_v.test.ast
│   │   ├── TeaserManager.ast
│   │   ├── TeaserManager_v.test.ast
│   │   ├── TeaserPathfinder.ast
│   │   ├── TeaserPathfinder_v.test.ast
│   │   ├── TeaserRecorder.ast
│   │   ├── TeaserRecorder_v.test.ast
│   │   ├── TestRunner.ast
│   │   ├── TestUtils.ast
│   │   ├── TimelineReducer.ast
│   │   ├── TimelineReducer_v.test.ast
│   │   ├── Tooltip.ast
│   │   ├── Tooltip_v.test.ast
│   │   ├── TourLogic.ast
│   │   ├── TourLogic_v.test.ast
│   │   ├── TourTemplateAssets.ast
│   │   ├── TourTemplateAssets_v.test.ast
│   │   ├── TourTemplateScripts.ast
│   │   ├── TourTemplateScripts_v.test.ast
│   │   ├── TourTemplateStyles.ast
│   │   ├── TourTemplateStyles_v.test.ast
│   │   ├── TourTemplates.ast
│   │   ├── TourTemplates_v.test.ast
│   │   ├── Types.ast
│   │   ├── Types_v.test.ast
│   │   ├── UiReducer.ast
│   │   ├── UiReducer_v.test.ast
│   │   ├── UploadProcessor.ast
│   │   ├── UploadProcessorLogic.ast
│   │   ├── UploadProcessorLogic_v.test.ast
│   │   ├── UploadProcessorTypes.ast
│   │   ├── UploadProcessorTypes_v.test.ast
│   │   ├── UploadProcessor_v.test.ast
│   │   ├── UploadReport.ast
│   │   ├── UploadReport_v.test.ast
│   │   ├── UrlUtils.ast
│   │   ├── UrlUtils_v.test.ast
│   │   ├── Version.ast
│   │   ├── VersionData.ast
│   │   ├── VersionData_v.test.ast
│   │   ├── Version_v.test.ast
│   │   ├── VideoEncoder.ast
│   │   ├── VideoEncoder_v.test.ast
│   │   ├── ViewerFollow.ast
│   │   ├── ViewerFollow_v.test.ast
│   │   ├── ViewerLoader.ast
│   │   ├── ViewerLoader_v.test.ast
│   │   ├── ViewerManager.ast
│   │   ├── ViewerManager_v.test.ast
│   │   ├── ViewerSnapshot.ast
│   │   ├── ViewerSnapshot_v.test.ast
│   │   ├── ViewerState.ast
│   │   ├── ViewerState_v.test.ast
│   │   ├── ViewerTypes.ast
│   │   ├── ViewerTypes_v.test.ast
│   │   ├── ViewerUI_v.test.ast
│   │   ├── VisualPipeline.ast
│   │   ├── VisualPipeline_v.test.ast
│   │   ├── VitestSmoke.test.ast
│   │   └── mod.ast
│   └── rescript.lock
├── logs
│   ├── error.log
│   ├── log_changes.txt
│   ├── project-guard.log
│   └── telemetry.log
├── old_ref
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
│   ├── generate-test-tasks.cjs
│   ├── increment-build.js
│   ├── project-guard.sh
│   ├── prune-snapshots.sh
│   ├── restore-snapshot.sh
│   ├── setup.sh
│   ├── sync-sw.cjs
│   ├── test-logging.js
│   └── update-version.js
├── src
│   ├── App.res
│   ├── Dummy.bs.js
│   ├── Main.res
│   ├── ReBindings.res
│   ├── ServiceWorker.res
│   ├── ServiceWorkerMain.res
│   ├── components
│   │   ├── AppErrorBoundary.res
│   │   ├── ErrorFallbackUI.res
│   │   ├── HotspotActionMenu.res
│   │   ├── HotspotManager.res
│   │   ├── LabelMenu.res
│   │   ├── LinkModal.res
│   │   ├── ModalContext.res
│   │   ├── NotificationContext.res
│   │   ├── PopOver.res
│   │   ├── Portal.res
│   │   ├── PreviewArrow.res
│   │   ├── SceneList.res
│   │   ├── Sidebar.res
│   │   ├── Tooltip.res
│   │   ├── UploadReport.res
│   │   ├── ViewerFollow.res
│   │   ├── ViewerLoader.res
│   │   ├── ViewerManager.res
│   │   ├── ViewerSnapshot.res
│   │   ├── ViewerState.res
│   │   ├── ViewerTypes.res
│   │   ├── ViewerUI.res
│   │   ├── VisualPipeline.res
│   │   └── ui
│   │       ├── LucideIcons.res
│   │       ├── Shadcn.res
│   │       ├── button.jsx
│   │       ├── context-menu.jsx
│   │       ├── dropdown-menu.jsx
│   │       ├── popover.jsx
│   │       └── tooltip.jsx
│   ├── core
│   │   ├── Actions.res
│   │   ├── AppContext.res
│   │   ├── GlobalStateBridge.res
│   │   ├── JsonTypes.res
│   │   ├── Reducer.res
│   │   ├── ReducerHelpers.res
│   │   ├── SharedTypes.res
│   │   ├── State.res
│   │   ├── Types.res
│   │   └── reducers
│   │       ├── HotspotReducer.res
│   │       ├── NavigationReducer.res
│   │       ├── ProjectReducer.res
│   │       ├── RootReducer.res
│   │       ├── SceneReducer.res
│   │       ├── SimulationReducer.res
│   │       ├── TimelineReducer.res
│   │       ├── UiReducer.res
│   │       └── mod.res
│   ├── index.js
│   ├── lib
│   │   └── utils.js
│   ├── systems
│   │   ├── AudioManager.res
│   │   ├── BackendApi.res
│   │   ├── DownloadSystem.res
│   │   ├── EventBus.res
│   │   ├── ExifParser.res
│   │   ├── ExifReportGenerator.res
│   │   ├── Exporter.res
│   │   ├── HotspotLine.res
│   │   ├── HotspotLineLogic.res
│   │   ├── HotspotLineTypes.res
│   │   ├── InputSystem.res
│   │   ├── Navigation.res
│   │   ├── NavigationController.res
│   │   ├── NavigationRenderer.res
│   │   ├── NavigationUI.res
│   │   ├── ProjectData.res
│   │   ├── ProjectManager.res
│   │   ├── Resizer.res
│   │   ├── ServerTeaser.res
│   │   ├── SimulationChainSkipper.res
│   │   ├── SimulationDriver.res
│   │   ├── SimulationLogic.res
│   │   ├── SimulationNavigation.res
│   │   ├── SimulationPathGenerator.res
│   │   ├── TeaserManager.res
│   │   ├── TeaserPathfinder.res
│   │   ├── TeaserRecorder.res
│   │   ├── TourTemplateAssets.res
│   │   ├── TourTemplateScripts.res
│   │   ├── TourTemplateStyles.res
│   │   ├── TourTemplates.res
│   │   ├── UploadProcessor.res
│   │   ├── UploadProcessorLogic.res
│   │   ├── UploadProcessorTypes.res
│   │   └── VideoEncoder.res
│   └── utils
│       ├── ColorPalette.res
│       ├── Constants.res
│       ├── GeoUtils.res
│       ├── ImageOptimizer.res
│       ├── ImageOptimizer.resi
│       ├── LazyLoad.res
│       ├── Logger.res
│       ├── PathInterpolation.res
│       ├── ProgressBar.res
│       ├── RequestQueue.res
│       ├── SessionStore.res
│       ├── StateInspector.res
│       ├── TourLogic.res
│       ├── UrlUtils.res
│       ├── Version.res
│       └── VersionData.res
├── start_prod.sh
├── tailwind.config.js
├── tasks
│   ├── TASKS.md
│   ├── active
│   │   ├── 005_create_changelog.md
│   │   └── 409_Update_Tests_ViewerManager.md
│   ├── completed
│   │   ├── 298_Refactor_UploadProcessor_REPORT.md
│   │   ├── 299_Refactor_HotspotLine_REPORT.md
│   │   ├── 300_Test_NavigationUI_REPORT.md
│   │   ├── 301_Update_Codebase_Map_REPORT.md
│   │   ├── 302_Test_Portal_ABORTED.md
│   │   ├── 303_Test_Tooltip_ABORTED.md
│   │   ├── 304_Test_mod_ABORTED.md
│   │   ├── 305_Test_LucideIcons_ABORTED.md
│   │   ├── 306_Test_State_ABORTED.md
│   │   ├── 307_Test_PopOver_ABORTED.md
│   │   ├── 308_Test_Types_REPORT.md
│   │   ├── 309_Test_Shadcn_ABORTED.md
│   │   ├── 310_Test_NavigationUI_ABORTED.md
│   │   ├── 311_Test_Shadcn_ABORTED.md
│   │   ├── 312_Test_LucideIcons_ABORTED.md
│   │   ├── 313_Test_HotspotLineLogic_REPORT.md
│   │   ├── 314_Test_UploadProcessorTypes_REPORT.md
│   │   ├── 315_Test_HotspotLineTypes_REPORT.md
│   │   ├── 316_Test_UploadProcessorLogic_REPORT.md
│   │   ├── 317_Update_Tests_ReBindings_REPORT.md
│   │   ├── 318_Update_Tests_Actions_REPORT.md
│   │   ├── 319_Update_Tests_ReducerHelpers_REPORT.md
│   │   ├── 320_Update_Tests_ProjectReducer_REPORT.md
│   │   ├── 321_Update_Tests_UiReducer_REPORT.md
│   │   ├── 322_Update_Tests_Main_REPORT.md
│   │   ├── 323_Update_Tests_ServiceWorkerMain_REPORT.md
│   │   ├── 324_Update_Tests_TourLogic_REPORT.md
│   │   ├── 325_Update_Tests_Logger_REPORT.md
│   │   ├── 326_Update_Tests_LazyLoad_REPORT.md
│   │   ├── 327_Update_Tests_RequestQueue_REPORT.md
│   │   ├── 328_Update_Tests_SessionStore_REPORT.md
│   │   ├── 329_Update_Tests_VersionData_REPORT.md
│   │   ├── 330_Update_Tests_LabelMenu_REPORT.md
│   │   ├── 331_Update_Tests_HotspotManager.md
│   │   ├── 332_Update_Tests_UploadReport.md
│   │   ├── 333_Update_Tests_HotspotActionMenu.md
│   │   ├── 334_Update_Tests_ViewerLoader.md
│   │   ├── 335_Update_Tests_ViewerUI.md
│   │   ├── 336_Update_Tests_ViewerTypes.md
│   │   ├── 337_Update_Tests_Sidebar.md
│   │   ├── 338_Update_Tests_VisualPipeline.md
│   │   ├── 339_Update_Tests_NotificationContext.md
│   │   ├── 340_Update_Tests_ModalContext.md
│   │   ├── 341_Update_Tests_TourTemplates.md
│   │   ├── 342_Update_Tests_TourTemplateAssets_UPDATED.md
│   │   ├── 343_Update_Tests_SimulationPathGenerator_UPDATED.md
│   │   ├── 344_Update_Tests_ExifReportGenerator_UPDATED.md
│   │   ├── 345_Update_Tests_UploadProcessor_UPDATED.md
│   │   ├── 346_Update_Tests_HotspotLine_UPDATED.md
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
│   │   └── _CONCISE_SUMMARY.md
│   ├── pending
│   │   ├── 94_Update_Codebase_Map.md
│   │   ├── 95_Aggregate_Completed_Tasks.md
│   │   └── tests
│   │       ├── 410_Add_Tests_App.md
│   │       ├── 411_Update_Tests_Portal.md
│   │       ├── 412_Update_Tests_UploadProcessorTypes.md
│   │       ├── 413_Update_Tests_TimelineReducer.md
│   │       ├── 414_Update_Tests_PopOver.md
│   │       ├── 415_Add_Tests_PreviewArrow.md
│   │       ├── 416_Add_Tests_PreviewArrow.md
│   │       ├── 417_Add_Tests_PreviewArrow.md
│   │       ├── 418_Add_Tests_PreviewArrow.md
│   │       ├── 419_Add_Tests_PreviewArrow.md
│   │       ├── 420_Add_Tests_PreviewArrow.md
│   │       ├── 421_Add_Tests_PreviewArrow.md
│   │       ├── 422_Add_Tests_PreviewArrow.md
│   │       ├── 423_Add_Tests_PreviewArrow.md
│   │       ├── 424_Add_Tests_PreviewArrow.md
│   │       ├── 425_Add_Tests_PreviewArrow.md
│   │       ├── 426_Add_Tests_PreviewArrow.md
│   │       ├── 427_Add_Tests_PreviewArrow.md
│   │       ├── 428_Add_Tests_PreviewArrow.md
│   │       ├── 429_Add_Tests_PreviewArrow.md
│   │       ├── 430_Add_Tests_PreviewArrow.md
│   │       ├── 431_Add_Tests_PreviewArrow.md
│   │       ├── 432_Add_Tests_PreviewArrow.md
│   │       ├── 433_Add_Tests_PreviewArrow.md
│   │       ├── 434_Add_Tests_PreviewArrow.md
│   │       ├── 435_Add_Tests_PreviewArrow.md
│   │       ├── 436_Add_Tests_PreviewArrow.md
│   │       ├── 437_Add_Tests_PreviewArrow.md
│   │       ├── 438_Add_Tests_PreviewArrow.md
│   │       ├── 439_Add_Tests_PreviewArrow.md
│   │       ├── 440_Add_Tests_PreviewArrow.md
│   │       ├── 441_Add_Tests_PreviewArrow.md
│   │       ├── 442_Update_Tests_ProgressBar.md
│   │       ├── 443_Update_Tests_Tooltip.md
│   │       ├── 444_Update_Tests_HotspotReducer.md
│   │       ├── 445_Add_Tests_PreviewArrow.md
│   │       ├── 446_Add_Tests_PreviewArrow.md
│   │       ├── 447_Add_Tests_PreviewArrow.md
│   │       ├── 448_Add_Tests_PreviewArrow.md
│   │       ├── 449_Add_Tests_PreviewArrow.md
│   │       ├── 450_Add_Tests_PreviewArrow.md
│   │       ├── 451_Update_Tests_SharedTypes.md
│   │       ├── 452_Update_Tests_NavigationReducer.md
│   │       └── 453_Add_Tests_PreviewArrow.md
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
│           └── superseded
│               ├── 377_Update_Tests_ServerTeaser.md
│               ├── 378_Update_Tests_ProjectData.md
│               ├── 379_Update_Tests_ColorPalette.md
│               ├── 380_Update_Tests_ViewerSnapshot.md
│               ├── 381_Update_Tests_Shadcn.md
│               ├── 382_Update_Tests_NavigationUI.md
│               ├── 383_Update_Tests_RootReducer.md
│               ├── 384_Update_Tests_AppContext.md
│               ├── 385_Update_Tests_AppErrorBoundary.md
│               ├── 386_Update_Tests_GlobalStateBridge.md
│               ├── 387_Update_Tests_UrlUtils.md
│               ├── 388_Update_Tests_UploadProcessorLogic.md
│               ├── 389_Update_Tests_ViewerState.md
│               ├── 390_Update_Tests_Exporter.md
│               ├── 391_Update_Tests_Types.md
│               ├── 392_Update_Tests_HotspotLineLogic.md
│               ├── 393_Update_Tests_AudioManager.md
│               ├── 394_Update_Tests_SimulationDriver.md
│               ├── 395_Update_Tests_ViewerFollow.md
│               ├── 396_Update_Tests_SceneReducer.md
│               ├── 397_Update_Tests_TourTemplateStyles.md
│               ├── 398_Update_Tests_State.md
│               ├── 399_Update_Tests_LinkModal.md
│               ├── 400_Update_Tests_mod.md
│               ├── 401_Update_Tests_NavigationController.md
│               ├── 402_Update_Tests_ImageOptimizer.md
│               ├── 403_Update_Tests_StateInspector.md
│               └── 404_Update_Tests_GeoUtils.md
├── test_output.txt
├── tested_icons.txt
├── tests
│   ├── TestRunner.res
│   ├── jsx-loader.mjs
│   ├── node-setup.js
│   └── unit
│       ├── ActionsTest.bs.js
│       ├── Actions_v.test.res
│       ├── AppContext_v.test.res
│       ├── AppErrorBoundary_v.test.res
│       ├── App_v.test.res
│       ├── AudioManager_v.test.res
│       ├── BackendApi_v.test.res
│       ├── ColorPalette_v.test.res
│       ├── Constants_v.test.res
│       ├── DownloadSystem_v.test.res
│       ├── ErrorFallbackUI_v.test.res
│       ├── EventBusTest.bs.js
│       ├── EventBus_v.test.res
│       ├── ExifParser_v.test.res
│       ├── ExifReportGenerator_v.test.res
│       ├── Exporter_v.test.res
│       ├── GeoUtils_v.test.res
│       ├── GlobalStateBridgeTest.bs.js
│       ├── GlobalStateBridge_v.test.res
│       ├── HotspotActionMenu_v.test.res
│       ├── HotspotLineLogic_v.test.res
│       ├── HotspotLineTypes_v.test.res
│       ├── HotspotLine_v.test.res
│       ├── HotspotLine_v.test.setup.js
│       ├── HotspotManager_v.test.res
│       ├── HotspotReducer_v.test.res
│       ├── ImageOptimizer_v.test.res
│       ├── InputSystem_v.test.res
│       ├── JsonTypes_v.test.res
│       ├── LabelMenu_v.test.res
│       ├── LabelMenu_v.test.setup.jsx
│       ├── LazyLoad_v.test.res
│       ├── LinkModal_v.test.res
│       ├── Logger_v.test.res
│       ├── LucideIcons_v.test.res
│       ├── Main_v.test.res
│       ├── Mod_v.test.res
│       ├── ModalContext_v.test.res
│       ├── NavigationController_v.test.res
│       ├── NavigationReducer_v.test.res
│       ├── NavigationRenderer_v.test.res
│       ├── NavigationUI_v.test.res
│       ├── Navigation_v.test.res
│       ├── NotificationContext_v.test.res
│       ├── PathInterpolation_v.test.res
│       ├── PopOver_v.test.res
│       ├── Portal_v.test.res
│       ├── ProgressBar_v.test.res
│       ├── ProjectData_v.test.res
│       ├── ProjectManager_v.test.res
│       ├── ProjectReducer_v.test.res
│       ├── ReBindings_v.test.res
│       ├── ReducerHelpers_v.test.res
│       ├── Reducer_v.test.res
│       ├── RequestQueue_v.test.res
│       ├── Resizer_v.test.res
│       ├── RootReducer_v.test.res
│       ├── SceneList_v.test.res
│       ├── SceneReducer_v.test.res
│       ├── ServerTeaser_v.test.res
│       ├── ServiceWorkerMain_v.test.res
│       ├── ServiceWorker_v.test.res
│       ├── SessionStore_v.test.res
│       ├── Shadcn_v.test.res
│       ├── SharedTypesTest.bs.js
│       ├── SharedTypes_v.test.res
│       ├── Sidebar_v.test.res
│       ├── SimulationChainSkipper_v.test.res
│       ├── SimulationDriver_v.test.res
│       ├── SimulationLogic_v.test.res
│       ├── SimulationNavigation_v.test.res
│       ├── SimulationPathGenerator_v.test.res
│       ├── SimulationReducer_v.test.res
│       ├── StateInspectorTest.bs.js
│       ├── StateInspector_v.test.res
│       ├── State_v.test.res
│       ├── TeaserManager_v.test.res
│       ├── TeaserPathfinder_v.test.res
│       ├── TeaserRecorder_v.test.res
│       ├── TimelineReducer_v.test.res
│       ├── Tooltip_v.test.res
│       ├── TourLogic_v.test.res
│       ├── TourTemplateAssets_v.test.res
│       ├── TourTemplateScripts_v.test.res
│       ├── TourTemplateStyles_v.test.res
│       ├── TourTemplates_v.test.res
│       ├── Types_v.test.res
│       ├── UiReducer_v.test.res
│       ├── UploadProcessorLogic_v.test.res
│       ├── UploadProcessorTypes_v.test.res
│       ├── UploadProcessor_v.test.res
│       ├── UploadProcessor_v.test.setup.js
│       ├── UploadReport_v.test.res
│       ├── UrlUtils_v.test.res
│       ├── VersionData_v.test.res
│       ├── Version_v.test.res
│       ├── VideoEncoder_v.test.res
│       ├── ViewerFollow_v.test.res
│       ├── ViewerLoader_v.test.res
│       ├── ViewerManager_v.test.res
│       ├── ViewerSnapshot_v.test.res
│       ├── ViewerState_v.test.res
│       ├── ViewerTypes_v.test.res
│       ├── ViewerUI_v.test.res
│       ├── VisualPipeline_v.test.res
│       ├── VitestSmoke.test.res
│       └── utils
│           └── TestUtils.res
└── vitest.config.mjs

98 directories, 1286 files
