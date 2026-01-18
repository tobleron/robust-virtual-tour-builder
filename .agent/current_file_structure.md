.
|-- AGENTS.md
|-- GEMINI.md
|-- README.md
|-- backend
|   |-- Cargo.lock
|   |-- Cargo.toml
|   |-- backend.log
|   |-- bin
|   |   `-- ffmpeg
|   |-- src
|   |   |-- api
|   |   |   |-- geocoding.rs
|   |   |   |-- media
|   |   |   |   |-- image.rs
|   |   |   |   |-- mod.rs
|   |   |   |   |-- serve.rs
|   |   |   |   |-- similarity.rs
|   |   |   |   `-- video.rs
|   |   |   |-- mod.rs
|   |   |   |-- project.rs
|   |   |   |-- telemetry.rs
|   |   |   `-- utils.rs
|   |   |-- lib.rs
|   |   |-- main.rs
|   |   |-- metrics.rs
|   |   |-- middleware
|   |   |   |-- mod.rs
|   |   |   |-- quota_check.rs
|   |   |   `-- request_tracker.rs
|   |   |-- models
|   |   |   |-- errors.rs
|   |   |   `-- mod.rs
|   |   |-- pathfinder
|   |   |   |-- algorithms.rs
|   |   |   |-- graph.rs
|   |   |   |-- mod.rs
|   |   |   `-- utils.rs
|   |   `-- services
|   |       |-- geocoding.rs
|   |       |-- media.rs
|   |       |-- mod.rs
|   |       |-- project
|   |       |   |-- load.rs
|   |       |   |-- mod.rs
|   |       |   |-- package.rs
|   |       |   `-- validate.rs
|   |       |-- shutdown.rs
|   |       |-- upload_quota.rs
|   |       `-- upload_quota_tests.rs
|   |-- startup_log.txt
|   `-- tests
|       `-- shutdown_test.rs
|-- bin
|   `-- tailwindcss
|-- cache
|   `-- geocoding.json
|-- css
|   |-- animations.css
|   |-- base.css
|   |-- components
|   |   |-- buttons.css
|   |   |-- floor-nav.css
|   |   |-- modals.css
|   |   |-- ui.css
|   |   `-- viewer.css
|   |-- layout.css
|   |-- legacy.css
|   |-- output.css
|   |-- style.css
|   |-- tailwind.css
|   `-- variables.css
|-- dev.log
|-- dev_prefs
|   |-- logging_debugging_system.md
|   `-- ui_preferences.md
|-- docs
|   |-- ACCESSIBILITY_AUDIT_RESULTS.md
|   |-- ACCESSIBILITY_GUIDE.md
|   |-- ARCHITECTURE_DIAGRAM.md
|   |-- AntiGravity\ Workflow\ Manual.md
|   |-- BACKEND_OPTIMIZATION_OPPORTUNITIES.md
|   |-- BACKEND_OPTIMIZATION_SUMMARY.md
|   |-- CONTAINER_BASED_FONT_SIZING.md
|   |-- DEBUGGING_GUIDE.md
|   |-- FONT_ANALYSIS.md
|   |-- FONT_IMPLEMENTATION.md
|   |-- FONT_SIZE_ANALYSIS.md
|   |-- FONT_SIZE_IMPLEMENTATION.md
|   |-- IMPROVEMENTS.md
|   |-- LOGGING_ARCHITECTURE.md
|   |-- LONG_TEXT_BEST_PRACTICES.md
|   |-- MANUAL_LOGGING_TEST.md
|   |-- MIGRATION_STATUS_ANALYSIS.md
|   |-- PERFORMANCE_ANALYSIS_FRONTEND_VS_BACKEND.md
|   |-- PERFORMANCE_OPTIMIZATIONS.md
|   |-- PRIORITY_RATIONALE.md
|   |-- PROFESSIONAL_METRICS_REPORT.md
|   |-- PROJECT_ANALYSIS_REPORT.md
|   |-- PROJECT_EVALUATION_2026.md
|   |-- PROJECT_STANDARDS_AND_WORKFLOWS.md
|   |-- RELEASE_v4.0.9.md
|   |-- RESPONSIVE_FONT_SIZING.md
|   |-- SECURITY_ANALYSIS_REPORT.md
|   |-- SECURITY_FIXES_COMPLETE.md
|   |-- SECURITY_FIXES_IMPLEMENTED.md
|   |-- SECURITY_UPGRADES_ADDITIONAL.md
|   |-- SIMULATION_MODE_IMPLEMENTATION.md
|   |-- SIMULATION_TELEMETRY.md
|   |-- TESTING_QUICK_REFERENCE.md
|   |-- TYPOGRAPHY.md
|   |-- UNIT_TESTING_INTEGRATION.md
|   |-- module_size_report.md
|   |-- navigation_improvements_applied.md
|   `-- openapi.yaml
|-- index.html
|-- lib
|   |-- bs
|   |-- ocaml
|   `-- rescript.lock
|-- logs
|   |-- error.log
|   |-- log_changes.txt
|   `-- telemetry.log
|-- package-lock.json
|-- package.json
|-- plans
|   |-- debug_telemetry_fix_plan.md
|   |-- logical_inconsistencies_analysis.md
|   `-- step1_cleanup_notes.md
|-- postcss.config.js
|-- public
|   |-- early-boot.js
|   |-- images
|   |   |-- icon-192.png
|   |   |-- icon-512.png
|   |   |-- logo.png
|   |   `-- og-preview.png
|   |-- libs
|   |   |-- FileSaver.min.js
|   |   |-- jszip.min.js
|   |   |-- pannellum.css
|   |   `-- pannellum.js
|   |-- manifest.json
|   `-- service-worker.js
|-- rescript.json
|-- rsbuild.config.mjs
|-- scripts
|   |-- cleanup_logs.sh
|   |-- commit.sh
|   |-- debug-connectivity.js
|   |-- detect-missing-tests.js
|   |-- dev-mode.sh
|   |-- ensure-watcher.sh
|   |-- increment-build.js
|   |-- prune-snapshots.sh
|   |-- restore-snapshot.sh
|   |-- setup.sh
|   |-- sync-sw.cjs
|   |-- test-logging.js
|   |-- update-version.js
|   `-- watch-file-limits.sh
|-- sounds
|   `-- click.wav
|-- src
|   |-- App.res
|   |-- Dummy.bs.js
|   |-- Main.res
|   |-- ReBindings.res
|   |-- ServiceWorker.res
|   |-- components
|   |   |-- HotspotManager.res
|   |   |-- LabelMenu.res
|   |   |-- LinkModal.res
|   |   |-- ModalContext.res
|   |   |-- NotificationContext.res
|   |   |-- RemaxErrorBoundary.res
|   |   |-- SafeErrorBoundary.js
|   |   |-- SceneList.res
|   |   |-- Sidebar.res
|   |   |-- UploadReport.res
|   |   |-- ViewerFollow.res
|   |   |-- ViewerLoader.res
|   |   |-- ViewerManager.res
|   |   |-- ViewerSnapshot.res
|   |   |-- ViewerState.res
|   |   |-- ViewerTypes.res
|   |   |-- ViewerUI.res
|   |   `-- VisualPipeline.res
|   |-- core
|   |   |-- Actions.res
|   |   |-- AppContext.res
|   |   |-- GlobalStateBridge.res
|   |   |-- JsonTypes.res
|   |   |-- Reducer.res
|   |   |-- ReducerHelpers.res
|   |   |-- SharedTypes.res
|   |   |-- State.res
|   |   |-- Types.res
|   |   `-- reducers
|   |       |-- HotspotReducer.res
|   |       |-- NavigationReducer.res
|   |       |-- ProjectReducer.res
|   |       |-- RootReducer.res
|   |       |-- SceneReducer.res
|   |       |-- TimelineReducer.res
|   |       |-- UiReducer.res
|   |       `-- mod.res
|   |-- index.js
|   |-- systems
|   |   |-- AudioManager.res
|   |   |-- BackendApi.res
|   |   |-- DownloadSystem.res
|   |   |-- EventBus.res
|   |   |-- ExifParser.res
|   |   |-- ExifReportGenerator.res
|   |   |-- Exporter.res
|   |   |-- HotspotLine.res
|   |   |-- InputSystem.res
|   |   |-- Navigation.res
|   |   |-- NavigationController.res
|   |   |-- NavigationRenderer.res
|   |   |-- NavigationUI.res
|   |   |-- ProjectData.res
|   |   |-- ProjectManager.res
|   |   |-- Resizer.res
|   |   |-- ServerTeaser.res
|   |   |-- SimulationChainSkipper.res
|   |   |-- SimulationNavigation.res
|   |   |-- SimulationPathGenerator.res
|   |   |-- SimulationSystem.res
|   |   |-- TeaserManager.res
|   |   |-- TeaserPathfinder.res
|   |   |-- TeaserRecorder.res
|   |   |-- TourTemplateAssets.res
|   |   |-- TourTemplateScripts.res
|   |   |-- TourTemplateStyles.res
|   |   |-- TourTemplates.res
|   |   |-- UploadProcessor.res
|   |   `-- VideoEncoder.res
|   |-- utils
|   |   |-- ColorPalette.res
|   |   |-- Constants.res
|   |   |-- GeoUtils.res
|   |   |-- ImageOptimizer.res
|   |   |-- ImageOptimizer.resi
|   |   |-- LazyLoad.res
|   |   |-- Logger.res
|   |   |-- PathInterpolation.res
|   |   |-- ProgressBar.res
|   |   |-- StateInspector.res
|   |   |-- TourLogic.res
|   |   `-- Version.res
|   `-- version.js
|-- start_prod.sh
|-- tailwind.config.js
|-- tasks
|   |-- TASKS.md
|   |-- active
|   |   `-- refactor_styles_css.md
|   |-- cancelled
|   |-- completed
|   |   |-- 01_Architecture_Functional_State_REPORT.md
|   |   |-- 02_Implement_App_Context_REPORT.md
|   |   |-- 03_Refactor_Components_REPORT.md
|   |   |-- 04_Functional_ProjectManager_REPORT.md
|   |   |-- 05_Purify_Navigation_REPORT.md
|   |   |-- 06_Final_Cleanup_REPORT.md
|   |   |-- 100_Add_Tests_for_SharedTypes.md
|   |   |-- 101_Add_Tests_for_BackendApi.md
|   |   |-- 101_Add_Tests_for_BackendApi_REPORT.md
|   |   |-- 102_Add_Tests_for_ProjectManager.md
|   |   |-- 102_Add_Tests_for_ProjectManager_REPORT.md
|   |   |-- 103_Add_Tests_for_Resizer.md
|   |   |-- 103_Add_Tests_for_Resizer_REPORT.md
|   |   |-- 104_Add_Tests_for_UploadProcessor.md
|   |   |-- 104_Add_Tests_for_UploadProcessor_REPORT.md
|   |   |-- 105_Install_Rsbuild.md
|   |   |-- 105_Install_Rsbuild_REPORT.md
|   |   |-- 106_Configure_Rsbuild_Entry.md
|   |   |-- 106_Configure_Rsbuild_Entry_REPORT.md
|   |   |-- 107_Integrate_Tailwind_Rsbuild.md
|   |   |-- 107_Integrate_Tailwind_Rsbuild_REPORT.md
|   |   |-- 108_Finalize_Rsbuild_Prod.md
|   |   |-- 108_Finalize_Rsbuild_Prod_REPORT.md
|   |   |-- 109_Cleanup_Legacy_Scripts.md
|   |   |-- 10_ReScript_Migrate_Resizer_REPORT.md
|   |   |-- 110_Add_Tests_for_TeaserManager_REPORT.md
|   |   |-- 111_Add_Tests_for_TourTemplateAssets_REPORT.md
|   |   |-- 112_Add_Tests_for_TourTemplateScripts_REPORT.md
|   |   |-- 113_Add_Tests_for_TourTemplateStyles_REPORT.md
|   |   |-- 114_Add_Tests_for_StateInspector_REPORT.md
|   |   |-- 115_Add_Tests_ViewerLoader_Navigation.md
|   |   |-- 116_Update_ServiceWorker_Cache_Paths.md
|   |   |-- 117_Add_OpenAPI_Documentation.md
|   |   |-- 118_Run_Accessibility_Audit.md
|   |   |-- 119_Eliminate_ObjMagic_Patterns_REPORT.md
|   |   |-- 11_ReScript_Migrate_ProjectManager_REPORT.md
|   |   |-- 120_Add_Meta_Description_OG_Tags.md
|   |   |-- 121_Add_Prometheus_Metrics_REPORT.md
|   |   |-- 122_Split_Large_Backend_Modules.md
|   |   |-- 123_Add_GitHub_Actions_CI.md
|   |   |-- 124_Add_Tests_for_ReBindings.md
|   |   |-- 125_Add_Tests_for_ExifReportGenerator.md
|   |   |-- 126_Add_Tests_for_TeaserRecorder.md
|   |   |-- 127_Add_Tests_for_Logger.md
|   |   |-- 128_Implement_SceneList_Virtualization.md
|   |   |-- 129_Accessibility_And_SEO_Improvements.md
|   |   |-- 12_ReScript_Migrate_UI_Components_REPORT.md
|   |   |-- 130_Reduce_Obj_Magic_Usage.md
|   |   |-- 131_Security_And_SW_Hardening.md
|   |   |-- 131_Security_And_SW_Hardening_REPORT.md
|   |   |-- 132_Comprehensive_Project_Analysis_REPORT.md
|   |   |-- 133_Add_Tests_for_JsonTypes.md
|   |   |-- 134_Add_Tests_for_ReducerHelpers.md
|   |   |-- 135_Add_Tests_for_AudioManager.md
|   |   |-- 136_Add_Tests_for_DownloadSystem_REPORT.md
|   |   |-- 137_Add_Tests_for_InputSystem_REPORT.md
|   |   |-- 138_Add_Tests_for_ProjectData_REPORT.md
|   |   |-- 139_Add_Tests_for_VideoEncoder_REPORT.md
|   |   |-- 140_Add_Tests_for_LazyLoad.md
|   |   |-- 141_Add_Tests_for_ProgressBar_REPORT.md
|   |   |-- 142_Add_Tests_for_Exporter.md
|   |   |-- 143_Add_Tests_for_Main_REPORT.md
|   |   |-- 144_Add_Tests_for_ServiceWorker_REPORT.md
|   |   |-- 145_Add_Tests_for_Actions_REPORT.md
|   |   |-- 146_Add_Tests_for_GlobalStateBridge_REPORT.md
|   |   |-- 147_Add_Tests_for_RootReducer_REPORT.md
|   |   |-- 148_Add_Tests_for_EventBus_REPORT.md
|   |   |-- 149_Add_Tests_for_NavigationReducer_REPORT.md
|   |   |-- 14_ReScript_Migrate_Viewer_REPORT.md
|   |   |-- 150_Add_Tests_for_ProjectReducer_REPORT.md
|   |   |-- 151_Add_Tests_for_TimelineReducer_REPORT.md
|   |   |-- 152_Add_Tests_for_NavigationRenderer_REPORT.md
|   |   |-- 153_Add_Tests_for_SimulationNavigation_REPORT.md
|   |   |-- 154_Add_Tests_for_SimulationPathGenerator_REPORT.md
|   |   |-- 155_Add_Tests_for_TeaserPathfinder_REPORT.md
|   |   |-- 156_Add_Tests_for_SimulationChainSkipper_REPORT.md
|   |   |-- 157_Add_Tests_for_ServerTeaser_REPORT.md
|   |   |-- 158_Add_Tests_for_TourTemplates_REPORT.md
|   |   |-- 159_Add_Tests_for_Constants.md
|   |   |-- 159_Add_Tests_for_Constants_Report.md
|   |   |-- 15_Backend_SingleZIP_Load_REPORT.md
|   |   |-- 160_Add_Tests_for_Version_REPORT.md
|   |   |-- 161_Setup_Vitest_Infrastructure.md
|   |   |-- 162_Add_React_Error_Boundary_REPORT.md
|   |   |-- 163_Secure_Production_Logging_REPORT.md
|   |   |-- 164_Fix_ReScript_Deprecations.md
|   |   |-- 164_Fix_ReScript_Deprecations_REPORT.md
|   |   |-- 165_Implement_Dynamic_SEO_REPORT.md
|   |   |-- 166_Add_Tests_for_App_REPORT.md
|   |   |-- 168_Add_Tests_for_HotspotLine_REPORT.md
|   |   |-- 16_Backend_Project_Validation_REPORT.md
|   |   |-- 174_Restore_v420_Linking_Mechanics_REPORT.md
|   |   |-- 17_Backend_Filename_Suggestion_REPORT.md
|   |   |-- 18_Frontend_SingleZIP_Integration_REPORT.md
|   |   |-- 19_Cleanup_Duplicate_Utilities_REPORT.md
|   |   |-- 20_Cleanup_Legacy_CSS_and_Backups_REPORT.md
|   |   |-- 21_Migrate_Viewer_Snapshot_System_REPORT.md
|   |   |-- 22_Migrate_Viewer_Dual_Pannellum_REPORT.md
|   |   |-- 23_Migrate_Visual_Pipeline_REPORT.md
|   |   |-- 24_Migrate_Exporter_Systems_REPORT.md
|   |   |-- 25_Migrate_Exif_Report_Generator.md
|   |   |-- 26_Unified_Backend_API_Module_REPORT.md
|   |   |-- 27_Migrate_Supporting_Systems_REPORT.md
|   |   |-- 28_Migrate_Cache_Video_Systems_REPORT.md
|   |   |-- 29_Refactor_Teaser_Logic_REPORT.md
|   |   |-- 30_Eliminate_JS_Adapters_REPORT.md
|   |   |-- 30_Logging_Backend_Endpoints_REPORT.md
|   |   |-- 31_Final_Polish_And_Cleanup_REPORT.md
|   |   |-- 31_Logging_Rust_Internal_Tracing_REPORT.md
|   |   |-- 32_Logging_Migrate_Navigation_REPORT.md
|   |   |-- 33_Logging_Migrate_ViewerLoader_REPORT.md
|   |   |-- 34_Logging_Migrate_HotspotManager_REPORT.md
|   |   |-- 34_Logging_Project_Persistence_REPORT.md
|   |   |-- 35_Logging_Migrate_SimulationSystem_REPORT.md
|   |   |-- 36_Logging_Migrate_Exporter_REPORT.md
|   |   |-- 37_Logging_Migrate_UploadProcessor_REPORT.md
|   |   |-- 38_Logging_Migrate_InputSystem_REPORT.md
|   |   |-- 39_Logging_Migrate_NavigationRenderer_REPORT.md
|   |   |-- 40_Logging_Migrate_VideoEncoder_REPORT.md
|   |   |-- 41_Logging_Migrate_Store_REPORT.md
|   |   |-- 42_Logging_Migrate_TeaserSystem_REPORT.md
|   |   |-- 43_Logging_Migrate_Sidebar_REPORT.md
|   |   |-- 44_Logging_Debug_Shortcuts_REPORT.md
|   |   |-- 45_Logging_Migrate_Remaining_Modules_REPORT.md
|   |   |-- 46_Logging_Rotation_Cleanup_REPORT.md
|   |   |-- 47_Logging_Integration_Tests_REPORT.md
|   |   |-- 48_Backend_Pure_Validation_Refactor_REPORT.md
|   |   |-- 49_Backend_Standardize_Logging_REPORT.md
|   |   |-- 50_Backend_Remove_Unwrap_REPORT.md
|   |   |-- 51_Backend_LogError_Endpoint_REPORT.md
|   |   |-- 52_Backend_Functional_Iterators_REPORT.md
|   |   |-- 53_Migrate_Logging_System_REPORT.md
|   |   |-- 54_Migrate_EventBus_REPORT.md
|   |   |-- 55_Migrate_UI_Contexts_REPORT.md
|   |   |-- 56_Backend_Project_Loading_REPORT.md
|   |   |-- 57_Backend_Pathfinding_REPORT.md
|   |   |-- 58_Migrate_Entry_Point_REPORT.md
|   |   |-- 59_Backend_Reverse_Geocoding_Endpoint_REPORT.md
|   |   |-- 60_Backend_Remove_Unwrap_Calls_REPORT.md
|   |   |-- 61_Backend_Geocoding_Cache_Layer_REPORT.md
|   |   |-- 62_Backend_Batch_Similarity_Endpoint_REPORT.md
|   |   |-- 63_Refactor_SimulationSystem_State_REPORT.md
|   |   |-- 64_Migrate_Constants_To_ReScript_REPORT.md
|   |   |-- 65_Cleanup_Dead_Code_REPORT.md
|   |   |-- 66_Extract_Backend_Domain_Types_REPORT.md
|   |   |-- 67_Extract_Media_Service_REPORT.md
|   |   |-- 68_Extract_Project_Service_REPORT.md
|   |   |-- 69_Extract_Geocoding_Service_REPORT.md
|   |   |-- 71_Pathfinder_Hardening_REPORT.md
|   |   |-- 73_Refactor_media_REPORT.md
|   |   |-- 74_Refactor_SimulationSystem_REPORT.md
|   |   |-- 75_Fix_IndexHTML_Critical_Bugs_REPORT.md
|   |   |-- 76_Fix_ReScript_Shadowing_Warnings_REPORT.md
|   |   |-- 77_Eliminate_ObjMagic_BackendApi_REPORT.md
|   |   |-- 78_Improve_Error_Handling_BackendApi_REPORT.md
|   |   |-- 79_Remove_Unused_Backend_Import_REPORT.md
|   |   |-- 80_Add_Frontend_Unit_Tests_REPORT.md
|   |   |-- 81_Expand_Backend_Test_Coverage_REPORT.md
|   |   |-- 82_Add_Rust_Documentation_Comments_REPORT.md
|   |   |-- 83_Implement_Code_Splitting_REPORT.md
|   |   |-- 84_Implement_Service_Worker_REPORT.md
|   |   |-- 85_Refactor_TourTemplates_Module_REPORT.md
|   |   |-- 86_Refactor_Reducer_Module.md
|   |   |-- 87_Centralized_Version_Management_REPORT.md
|   |   |-- 88_Eliminate_ObjMagic_Reducer_REPORT.md
|   |   |-- 89_Eliminate_ObjMagic_Main.md
|   |   |-- 90_Secure_GlobalStateBridge_REPORT.md
|   |   |-- 91_Implement_Reducer_Slicing_REPORT.md
|   |   |-- 92_Backend_Upload_Quota_System.md
|   |   |-- 93_Backend_Graceful_Shutdown_REPORT.md
|   |   |-- 94_Remove_Dead_ImageAnalysis.md
|   |   |-- 94_Remove_Dead_ImageAnalysis_REPORT.md
|   |   |-- 95_Wire_Backend_Similarity.md
|   |   |-- 95_Wire_Backend_Similarity_REPORT.md
|   |   |-- 96_Migrate_Constants_To_Rescript.md
|   |   |-- 96_Migrate_Constants_To_Rescript_REPORT.md
|   |   |-- 97_Migrate_To_Vite_ABORTED.md
|   |   |-- 97_Migrate_To_Vite_ABORTED_REPORT.md
|   |   |-- 98_Backend_Safety_Audit.md
|   |   |-- 98_Backend_Safety_Audit_REPORT.md
|   |   |-- 99_Unify_Types.md
|   |   |-- 99_Unify_Types_REPORT.md
|   |   `-- CONSOLIDATED_TASK_SUMMARIES_REPORT.md
|   |-- current_refactor.md
|   `-- pending
|       |-- 175_Restore_v420_Viewer_HUD_Labels_and_Prompts.md
|       |-- 176_Restore_v420_Visual_Pipeline.md
|       |-- 177_Restore_v420_Simulation_Advanced_Mechanics.md
|       |-- 178_extract_business_logic.md
|       |-- 179_fix_error_handling.md
|       |-- 180_expand_test_coverage.md
|       |-- 181_Add_Tests_for_ImageOptimizer.md
|       `-- re_evaluate_webp_quality.md
|-- tests
|   |-- TestRunner.res
|   |-- node-setup.js
|   `-- unit
|       |-- ActionsTest.res
|       |-- AppTest.res
|       |-- AudioManagerTest.res
|       |-- BackendApiTest.res
|       |-- ConstantsTest.res
|       |-- DownloadSystemTest.res
|       |-- EventBusTest.res
|       |-- ExifParserTest.res
|       |-- ExifReportGeneratorTest.res
|       |-- ExporterTest.res
|       |-- GeoUtilsTest.res
|       |-- GlobalStateBridgeTest.res
|       |-- HotspotLine.test.res
|       |-- HotspotLine_v.test.res
|       |-- HotspotReducerTest.res
|       |-- ImageOptimizerTest.res
|       |-- InputSystemTest.res
|       |-- JsonTypesTest.res
|       |-- LazyLoadTest.res
|       |-- LoggerTest.res
|       |-- MainTest.res
|       |-- NavigationReducerTest.res
|       |-- NavigationRendererTest.res
|       |-- NavigationTest.res
|       |-- PathInterpolationTest.res
|       |-- ProgressBarTest.res
|       |-- ProjectDataTest.res
|       |-- ProjectManagerTest.res
|       |-- ProjectReducerTest.res
|       |-- ReBindingsTest.res
|       |-- ReducerHelpersTest.res
|       |-- ReducerTest.res
|       |-- ResizerTest.res
|       |-- RootReducerTest.res
|       |-- SceneReducerTest.res
|       |-- ServerTeaserTest.res
|       |-- ServiceWorkerTest.res
|       |-- SharedTypesTest.res
|       |-- SimulationChainSkipperTest.res
|       |-- SimulationNavigationTest.res
|       |-- SimulationPathGeneratorTest.res
|       |-- SimulationSystemTest.res
|       |-- StateInspectorTest.res
|       |-- TeaserManagerTest.res
|       |-- TeaserPathfinderTest.res
|       |-- TeaserRecorderTest.res
|       |-- TimelineReducerTest.res
|       |-- TourLogicTest.res
|       |-- TourTemplateAssetsTest.res
|       |-- TourTemplateScriptsTest.res
|       |-- TourTemplateStylesTest.res
|       |-- TourTemplatesTest.res
|       |-- UploadProcessorTest.res
|       |-- VersionTest.res
|       |-- VideoEncoderTest.res
|       |-- ViewerLoaderTest.res
|       `-- VitestSmoke.test.res
`-- vitest.config.mjs

41 directories, 476 files
