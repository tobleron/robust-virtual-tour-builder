.
├── AGENTS.md
├── backend
│   ├── backend.log
│   ├── bin
│   │   └── ffmpeg
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── src
│   │   ├── api
│   │   │   ├── geocoding.rs
│   │   │   ├── media
│   │   │   │   ├── image.rs
│   │   │   │   ├── mod.rs
│   │   │   │   ├── serve.rs
│   │   │   │   ├── similarity.rs
│   │   │   │   └── video.rs
│   │   │   ├── mod.rs
│   │   │   ├── project.rs
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
│   │   │   └── mod.rs
│   │   ├── pathfinder
│   │   │   ├── algorithms.rs
│   │   │   ├── graph.rs
│   │   │   ├── mod.rs
│   │   │   └── utils.rs
│   │   └── services
│   │       ├── geocoding.rs
│   │       ├── media.rs
│   │       ├── mod.rs
│   │       ├── project
│   │       │   ├── load.rs
│   │       │   ├── mod.rs
│   │       │   ├── package.rs
│   │       │   └── validate.rs
│   │       ├── shutdown.rs
│   │       ├── upload_quota_tests.rs
│   │       └── upload_quota.rs
│   ├── startup_log.txt
│   └── tests
│       └── shutdown_test.rs
├── bin
│   └── tailwindcss
├── cache
│   └── geocoding.json
├── css
│   ├── animations.css
│   ├── base.css
│   ├── components
│   │   ├── buttons.css
│   │   ├── floor-nav.css
│   │   ├── modals.css
│   │   ├── ui.css
│   │   └── viewer.css
│   ├── layout.css
│   ├── legacy.css
│   ├── output.css
│   ├── style.css
│   ├── tailwind.css
│   └── variables.css
├── dev_prefs
│   ├── logging_debugging_system.md
│   └── ui_preferences.md
├── dev.log
├── docs
│   ├── ACCESSIBILITY_SYSTEM.md
│   ├── AntiGravity Workflow Manual.md
│   ├── ARCHITECTURE_DIAGRAM.md
│   ├── DEBUGGING_GUIDE.md
│   ├── IMPROVEMENTS.md
│   ├── LOGGING_AND_SIMULATION.md
│   ├── openapi.yaml
│   ├── PERFORMANCE_AND_METRICS.md
│   ├── PROJECT_GOVERNANCE_AND_STATUS.md
│   ├── RELEASE_v4.0.9.md
│   ├── SECURITY_AND_STABILITY.md
│   ├── TESTING_QUICK_REFERENCE.md
│   ├── TYPOGRAPHY_AND_UI_SYSTEM.md
│   └── UNIT_TESTING_INTEGRATION.md
├── GEMINI.md
├── index.html
├── lib
│   ├── bs
│   │   ├── build.ninja
│   │   ├── src
│   │   │   ├── components
│   │   │   │   ├── ErrorFallbackUI.ast
│   │   │   │   ├── HotspotManager.ast
│   │   │   │   ├── LabelMenu.ast
│   │   │   │   ├── LinkModal.ast
│   │   │   │   ├── ModalContext.ast
│   │   │   │   ├── NotificationContext.ast
│   │   │   │   ├── RemaxErrorBoundary.ast
│   │   │   │   ├── SceneList.ast
│   │   │   │   ├── Sidebar.ast
│   │   │   │   ├── UploadReport.ast
│   │   │   │   ├── ViewerFollow.ast
│   │   │   │   ├── ViewerLoader.ast
│   │   │   │   ├── ViewerManager.ast
│   │   │   │   ├── ViewerSnapshot.ast
│   │   │   │   ├── ViewerState.ast
│   │   │   │   ├── ViewerTypes.ast
│   │   │   │   ├── ViewerUI.ast
│   │   │   │   └── VisualPipeline.ast
│   │   │   ├── core
│   │   │   │   ├── Actions.ast
│   │   │   │   ├── AppContext.ast
│   │   │   │   ├── GlobalStateBridge.ast
│   │   │   │   ├── JsonTypes.ast
│   │   │   │   ├── Reducer.ast
│   │   │   │   ├── ReducerHelpers.ast
│   │   │   │   ├── reducers
│   │   │   │   │   ├── HotspotReducer.ast
│   │   │   │   │   ├── mod.ast
│   │   │   │   │   ├── NavigationReducer.ast
│   │   │   │   │   ├── ProjectReducer.ast
│   │   │   │   │   ├── RootReducer.ast
│   │   │   │   │   ├── SceneReducer.ast
│   │   │   │   │   ├── SimulationReducer.ast
│   │   │   │   │   ├── TimelineReducer.ast
│   │   │   │   │   └── UiReducer.ast
│   │   │   │   ├── SharedTypes.ast
│   │   │   │   ├── State.ast
│   │   │   │   └── Types.ast
│   │   │   ├── Main.ast
│   │   │   ├── ReBindings.ast
│   │   │   ├── ServiceWorker.ast
│   │   │   ├── ServiceWorkerMain.ast
│   │   │   ├── systems
│   │   │   │   ├── AudioManager.ast
│   │   │   │   ├── BackendApi.ast
│   │   │   │   ├── DownloadSystem.ast
│   │   │   │   ├── EventBus.ast
│   │   │   │   ├── ExifParser.ast
│   │   │   │   ├── ExifReportGenerator.ast
│   │   │   │   ├── Exporter.ast
│   │   │   │   ├── HotspotLine.ast
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
│   │   │   │   ├── TourTemplates.ast
│   │   │   │   ├── TourTemplateScripts.ast
│   │   │   │   ├── TourTemplateStyles.ast
│   │   │   │   ├── UploadProcessor.ast
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
│   │   │       ├── SessionStore.ast
│   │   │       ├── StateInspector.ast
│   │   │       ├── TourLogic.ast
│   │   │       ├── UrlUtils.ast
│   │   │       ├── Version.ast
│   │   │       └── VersionData.ast
│   │   └── tests
│   │       ├── TestRunner.ast
│   │       └── unit
│   │           ├── ActionsTest.ast
│   │           ├── AppContextTest.ast
│   │           ├── AppTest.ast
│   │           ├── AudioManagerTest.ast
│   │           ├── BackendApiTest.ast
│   │           ├── ConstantsTest.ast
│   │           ├── DownloadSystemTest.ast
│   │           ├── EventBusTest.ast
│   │           ├── ExifParserTest.ast
│   │           ├── ExifReportGeneratorTest.ast
│   │           ├── ExporterTest.ast
│   │           ├── GeoUtilsTest.ast
│   │           ├── GlobalStateBridgeTest.ast
│   │           ├── HotspotLine_v.test.ast
│   │           ├── HotspotLine.test.ast
│   │           ├── HotspotReducerTest.ast
│   │           ├── ImageOptimizerTest.ast
│   │           ├── InputSystemTest.ast
│   │           ├── JsonTypesTest.ast
│   │           ├── LazyLoadTest.ast
│   │           ├── LoggerTest.ast
│   │           ├── MainTest.ast
│   │           ├── NavigationControllerTest.ast
│   │           ├── NavigationReducerTest.ast
│   │           ├── NavigationRendererTest.ast
│   │           ├── NavigationTest.ast
│   │           ├── PathInterpolationTest.ast
│   │           ├── ProgressBarTest.ast
│   │           ├── ProjectDataTest.ast
│   │           ├── ProjectManagerTest.ast
│   │           ├── ProjectReducerTest.ast
│   │           ├── ReBindingsTest.ast
│   │           ├── ReducerHelpersTest.ast
│   │           ├── ReducerTest.ast
│   │           ├── ResizerTest.ast
│   │           ├── RootReducerTest.ast
│   │           ├── SceneReducerTest.ast
│   │           ├── ServerTeaserTest.ast
│   │           ├── ServiceWorkerMainTest.ast
│   │           ├── ServiceWorkerTest.ast
│   │           ├── SessionStoreTest.ast
│   │           ├── SharedTypesTest.ast
│   │           ├── SimulationChainSkipperTest.ast
│   │           ├── SimulationDriverTest.ast
│   │           ├── SimulationLogicTest.ast
│   │           ├── SimulationNavigationTest.ast
│   │           ├── SimulationPathGeneratorTest.ast
│   │           ├── SimulationReducerTest.ast
│   │           ├── StateInspectorTest.ast
│   │           ├── TeaserManagerTest.ast
│   │           ├── TeaserPathfinderTest.ast
│   │           ├── TeaserRecorderTest.ast
│   │           ├── TimelineReducerTest.ast
│   │           ├── TourLogicTest.ast
│   │           ├── TourTemplateAssetsTest.ast
│   │           ├── TourTemplateScriptsTest.ast
│   │           ├── TourTemplatesTest.ast
│   │           ├── TourTemplateStylesTest.ast
│   │           ├── UiReducerTest.ast
│   │           ├── UploadProcessorTest.ast
│   │           ├── UrlUtilsTest.ast
│   │           ├── VersionDataTest.ast
│   │           ├── VersionTest.ast
│   │           ├── VideoEncoderTest.ast
│   │           ├── ViewerLoaderTest.ast
│   │           └── VitestSmoke.test.ast
│   ├── ocaml
│   │   ├── Actions.ast
│   │   ├── ActionsTest.ast
│   │   ├── AppContext.ast
│   │   ├── AppContextTest.ast
│   │   ├── AppTest.ast
│   │   ├── AudioManager.ast
│   │   ├── AudioManagerTest.ast
│   │   ├── BackendApi.ast
│   │   ├── BackendApiTest.ast
│   │   ├── ColorPalette.ast
│   │   ├── Constants.ast
│   │   ├── ConstantsTest.ast
│   │   ├── DownloadSystem.ast
│   │   ├── DownloadSystemTest.ast
│   │   ├── ErrorFallbackUI.ast
│   │   ├── EventBus.ast
│   │   ├── EventBusTest.ast
│   │   ├── ExifParser.ast
│   │   ├── ExifParserTest.ast
│   │   ├── ExifReportGenerator.ast
│   │   ├── ExifReportGeneratorTest.ast
│   │   ├── Exporter.ast
│   │   ├── ExporterTest.ast
│   │   ├── GeoUtils.ast
│   │   ├── GeoUtilsTest.ast
│   │   ├── GlobalStateBridge.ast
│   │   ├── GlobalStateBridgeTest.ast
│   │   ├── HotspotLine_v.test.ast
│   │   ├── HotspotLine.ast
│   │   ├── HotspotLine.test.ast
│   │   ├── HotspotManager.ast
│   │   ├── HotspotReducer.ast
│   │   ├── HotspotReducerTest.ast
│   │   ├── ImageOptimizer.ast
│   │   ├── ImageOptimizer.iast
│   │   ├── ImageOptimizerTest.ast
│   │   ├── InputSystem.ast
│   │   ├── InputSystemTest.ast
│   │   ├── JsonTypes.ast
│   │   ├── JsonTypesTest.ast
│   │   ├── LabelMenu.ast
│   │   ├── LazyLoad.ast
│   │   ├── LazyLoadTest.ast
│   │   ├── LinkModal.ast
│   │   ├── Logger.ast
│   │   ├── LoggerTest.ast
│   │   ├── Main.ast
│   │   ├── MainTest.ast
│   │   ├── mod.ast
│   │   ├── ModalContext.ast
│   │   ├── Navigation.ast
│   │   ├── NavigationController.ast
│   │   ├── NavigationControllerTest.ast
│   │   ├── NavigationReducer.ast
│   │   ├── NavigationReducerTest.ast
│   │   ├── NavigationRenderer.ast
│   │   ├── NavigationRendererTest.ast
│   │   ├── NavigationTest.ast
│   │   ├── NavigationUI.ast
│   │   ├── NotificationContext.ast
│   │   ├── PathInterpolation.ast
│   │   ├── PathInterpolationTest.ast
│   │   ├── ProgressBar.ast
│   │   ├── ProgressBarTest.ast
│   │   ├── ProjectData.ast
│   │   ├── ProjectDataTest.ast
│   │   ├── ProjectManager.ast
│   │   ├── ProjectManagerTest.ast
│   │   ├── ProjectReducer.ast
│   │   ├── ProjectReducerTest.ast
│   │   ├── ReBindings.ast
│   │   ├── ReBindingsTest.ast
│   │   ├── Reducer.ast
│   │   ├── ReducerHelpers.ast
│   │   ├── ReducerHelpersTest.ast
│   │   ├── ReducerTest.ast
│   │   ├── RemaxErrorBoundary.ast
│   │   ├── Resizer.ast
│   │   ├── ResizerTest.ast
│   │   ├── RootReducer.ast
│   │   ├── RootReducerTest.ast
│   │   ├── SceneList.ast
│   │   ├── SceneReducer.ast
│   │   ├── SceneReducerTest.ast
│   │   ├── ServerTeaser.ast
│   │   ├── ServerTeaserTest.ast
│   │   ├── ServiceWorker.ast
│   │   ├── ServiceWorkerMain.ast
│   │   ├── ServiceWorkerMainTest.ast
│   │   ├── ServiceWorkerTest.ast
│   │   ├── SessionStore.ast
│   │   ├── SessionStoreTest.ast
│   │   ├── SharedTypes.ast
│   │   ├── SharedTypesTest.ast
│   │   ├── Sidebar.ast
│   │   ├── SimulationChainSkipper.ast
│   │   ├── SimulationChainSkipperTest.ast
│   │   ├── SimulationDriver.ast
│   │   ├── SimulationDriverTest.ast
│   │   ├── SimulationLogic.ast
│   │   ├── SimulationLogicTest.ast
│   │   ├── SimulationNavigation.ast
│   │   ├── SimulationNavigationTest.ast
│   │   ├── SimulationPathGenerator.ast
│   │   ├── SimulationPathGeneratorTest.ast
│   │   ├── SimulationReducer.ast
│   │   ├── SimulationReducerTest.ast
│   │   ├── State.ast
│   │   ├── StateInspector.ast
│   │   ├── StateInspectorTest.ast
│   │   ├── TeaserManager.ast
│   │   ├── TeaserManagerTest.ast
│   │   ├── TeaserPathfinder.ast
│   │   ├── TeaserPathfinderTest.ast
│   │   ├── TeaserRecorder.ast
│   │   ├── TeaserRecorderTest.ast
│   │   ├── TestRunner.ast
│   │   ├── TimelineReducer.ast
│   │   ├── TimelineReducerTest.ast
│   │   ├── TourLogic.ast
│   │   ├── TourLogicTest.ast
│   │   ├── TourTemplateAssets.ast
│   │   ├── TourTemplateAssetsTest.ast
│   │   ├── TourTemplates.ast
│   │   ├── TourTemplateScripts.ast
│   │   ├── TourTemplateScriptsTest.ast
│   │   ├── TourTemplatesTest.ast
│   │   ├── TourTemplateStyles.ast
│   │   ├── TourTemplateStylesTest.ast
│   │   ├── Types.ast
│   │   ├── UiReducer.ast
│   │   ├── UiReducerTest.ast
│   │   ├── UploadProcessor.ast
│   │   ├── UploadProcessorTest.ast
│   │   ├── UploadReport.ast
│   │   ├── UrlUtils.ast
│   │   ├── UrlUtilsTest.ast
│   │   ├── Version.ast
│   │   ├── VersionData.ast
│   │   ├── VersionDataTest.ast
│   │   ├── VersionTest.ast
│   │   ├── VideoEncoder.ast
│   │   ├── VideoEncoderTest.ast
│   │   ├── ViewerFollow.ast
│   │   ├── ViewerLoader.ast
│   │   ├── ViewerLoaderTest.ast
│   │   ├── ViewerManager.ast
│   │   ├── ViewerSnapshot.ast
│   │   ├── ViewerState.ast
│   │   ├── ViewerTypes.ast
│   │   ├── ViewerUI.ast
│   │   ├── VisualPipeline.ast
│   │   └── VitestSmoke.test.ast
│   └── rescript.lock
├── logs
│   ├── error.log
│   ├── log_changes.txt
│   └── telemetry.log
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
├── README.md
├── rescript.json
├── rsbuild.config.mjs
├── scripts
│   ├── cleanup_logs.sh
│   ├── commit.sh
│   ├── debug-connectivity.js
│   ├── detect-missing-tests.js
│   ├── dev-mode.sh
│   ├── ensure-watcher.sh
│   ├── increment-build.js
│   ├── prune-snapshots.sh
│   ├── restore-snapshot.sh
│   ├── setup.sh
│   ├── sync-sw.cjs
│   ├── test-logging.js
│   ├── update-version.js
│   └── watch-file-limits.sh
├── src
│   ├── App.res
│   ├── components
│   │   ├── ErrorFallbackUI.res
│   │   ├── HotspotManager.res
│   │   ├── LabelMenu.res
│   │   ├── LinkModal.res
│   │   ├── ModalContext.res
│   │   ├── NotificationContext.res
│   │   ├── RemaxErrorBoundary.res
│   │   ├── SceneList.res
│   │   ├── Sidebar.res
│   │   ├── UploadReport.res
│   │   ├── ViewerFollow.res
│   │   ├── ViewerLoader.res
│   │   ├── ViewerManager.res
│   │   ├── ViewerSnapshot.res
│   │   ├── ViewerState.res
│   │   ├── ViewerTypes.res
│   │   ├── ViewerUI.res
│   │   └── VisualPipeline.res
│   ├── core
│   │   ├── Actions.res
│   │   ├── AppContext.res
│   │   ├── GlobalStateBridge.res
│   │   ├── JsonTypes.res
│   │   ├── Reducer.res
│   │   ├── ReducerHelpers.res
│   │   ├── reducers
│   │   │   ├── HotspotReducer.res
│   │   │   ├── mod.res
│   │   │   ├── NavigationReducer.res
│   │   │   ├── ProjectReducer.res
│   │   │   ├── RootReducer.res
│   │   │   ├── SceneReducer.res
│   │   │   ├── SimulationReducer.res
│   │   │   ├── TimelineReducer.res
│   │   │   └── UiReducer.res
│   │   ├── SharedTypes.res
│   │   ├── State.res
│   │   └── Types.res
│   ├── Dummy.bs.js
│   ├── index.js
│   ├── Main.res
│   ├── ReBindings.res
│   ├── ServiceWorker.res
│   ├── ServiceWorkerMain.res
│   ├── systems
│   │   ├── AudioManager.res
│   │   ├── BackendApi.res
│   │   ├── DownloadSystem.res
│   │   ├── EventBus.res
│   │   ├── ExifParser.res
│   │   ├── ExifReportGenerator.res
│   │   ├── Exporter.res
│   │   ├── HotspotLine.res
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
│   │   ├── TourTemplates.res
│   │   ├── TourTemplateScripts.res
│   │   ├── TourTemplateStyles.res
│   │   ├── UploadProcessor.res
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
│       ├── SessionStore.res
│       ├── StateInspector.res
│       ├── TourLogic.res
│       ├── UrlUtils.res
│       ├── Version.res
│       └── VersionData.res
├── start_prod.sh
├── tailwind.config.js
├── tasks
│   ├── active
│   │   └── 200_Restore_Optimum_UI_Mechanics.md
│   ├── cancelled
│   ├── completed
│   │   ├── 175_fix_runtime_safety_getexn_REPORT.md
│   │   ├── 194_Add_Tests_for_ServiceWorkerMain_REPORT.md
│   │   ├── 195_Add_Tests_for_UrlUtils_REPORT.md
│   │   ├── 196_Add_Tests_for_VersionData_REPORT.md
│   │   ├── 197_Refactor_RootReducer_Pipeline_REPORT.md
│   │   ├── 198_Implement_Session_Persistence_REPORT.md
│   │   ├── 199_Enhance_GlobalState_Safety_REPORT.md
│   │   ├── 206_Comprehensive_Migration_Summary_REPORT.md
│   │   ├── 207_Comprehensive_Testing_And_QA_Summary_REPORT.md
│   │   ├── 208_Backend_Systems_And_Optimization_Summary_REPORT.md
│   │   └── 209_Refactoring_Security_UX_Summary_REPORT.md
│   ├── current_refactor.md
│   ├── pending
│   │   ├── 176_fix_security_innerhtml.md
│   │   ├── 177_fix_error_handling.md
│   │   ├── 178_Restore_v420_Viewer_HUD_Labels_and_Prompts.md
│   │   ├── 179_Restore_v420_Visual_Pipeline.md
│   │   ├── 180_Restore_v420_Simulation_Advanced_Mechanics.md
│   │   ├── 181_extract_business_logic.md
│   │   ├── 186_implement_backend_geocoding_proxy.md
│   │   ├── 201_implement_backend_geocoding_cache.md
│   │   ├── 202_offload_image_similarity_to_backend.md
│   │   ├── 203_expand_test_coverage.md
│   │   ├── 204_Add_Tests_for_ImageOptimizer.md
│   │   ├── 205_re_evaluate_webp_quality.md
│   │   ├── 210_Add_Tests_for_AppContext.md
│   │   ├── 211_Add_Tests_for_UiReducer.md
│   │   ├── 212_Add_Tests_for_NavigationController.md
│   │   ├── 213_Add_Tests_for_SimulationDriver.md
│   │   ├── 214_Add_Tests_for_SimulationLogic.md
│   │   └── 215_Add_Tests_for_SessionStore.md
│   └── TASKS.md
├── tests
│   ├── node-setup.js
│   ├── TestRunner.res
│   └── unit
│       ├── ActionsTest.res
│       ├── AppContextTest.res
│       ├── AppTest.res
│       ├── AudioManagerTest.res
│       ├── BackendApiTest.res
│       ├── ConstantsTest.res
│       ├── DownloadSystemTest.res
│       ├── EventBusTest.res
│       ├── ExifParserTest.res
│       ├── ExifReportGeneratorTest.res
│       ├── ExporterTest.res
│       ├── GeoUtilsTest.res
│       ├── GlobalStateBridgeTest.res
│       ├── HotspotLine_v.test.res
│       ├── HotspotLine.test.res
│       ├── HotspotReducerTest.res
│       ├── ImageOptimizerTest.res
│       ├── InputSystemTest.res
│       ├── JsonTypesTest.res
│       ├── LazyLoadTest.res
│       ├── LoggerTest.res
│       ├── MainTest.res
│       ├── NavigationControllerTest.res
│       ├── NavigationReducerTest.res
│       ├── NavigationRendererTest.res
│       ├── NavigationTest.res
│       ├── PathInterpolationTest.res
│       ├── ProgressBarTest.res
│       ├── ProjectDataTest.res
│       ├── ProjectManagerTest.res
│       ├── ProjectReducerTest.res
│       ├── ReBindingsTest.res
│       ├── ReducerHelpersTest.res
│       ├── ReducerTest.res
│       ├── ResizerTest.res
│       ├── RootReducerTest.res
│       ├── SceneReducerTest.res
│       ├── ServerTeaserTest.res
│       ├── ServiceWorkerMainTest.res
│       ├── ServiceWorkerTest.res
│       ├── SessionStoreTest.res
│       ├── SharedTypesTest.res
│       ├── SimulationChainSkipperTest.res
│       ├── SimulationDriverTest.res
│       ├── SimulationLogicTest.res
│       ├── SimulationNavigationTest.res
│       ├── SimulationPathGeneratorTest.res
│       ├── SimulationReducerTest.res
│       ├── StateInspectorTest.res
│       ├── TeaserManagerTest.res
│       ├── TeaserPathfinderTest.res
│       ├── TeaserRecorderTest.res
│       ├── TimelineReducerTest.res
│       ├── TourLogicTest.res
│       ├── TourTemplateAssetsTest.res
│       ├── TourTemplateScriptsTest.res
│       ├── TourTemplatesTest.res
│       ├── TourTemplateStylesTest.res
│       ├── UiReducerTest.res
│       ├── UploadProcessorTest.res
│       ├── UrlUtilsTest.res
│       ├── VersionDataTest.res
│       ├── VersionTest.res
│       ├── VideoEncoderTest.res
│       ├── ViewerLoaderTest.res
│       └── VitestSmoke.test.res
└── vitest.config.mjs

49 directories, 611 files
