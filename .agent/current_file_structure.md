.
├── CHANGELOG.md
├── GEMINI.md
├── LICENSE
├── MAP.md
├── README.md
├── _dev-system
│   ├── DASHBOARD.html
│   ├── README.md
│   ├── analyzer
│   │   ├── Cargo.lock
│   │   ├── Cargo.toml
│   │   ├── src
│   │   │   ├── append_part2.pl
│   │   │   ├── append_part2.py
│   │   │   ├── chunk3b.rs
│   │   │   ├── consolidator.rs
│   │   │   ├── drivers
│   │   │   │   ├── config.rs
│   │   │   │   ├── css.rs
│   │   │   │   ├── html.rs
│   │   │   │   ├── mod.rs
│   │   │   │   ├── rescript.rs
│   │   │   │   └── rust.rs
│   │   │   ├── feedback.rs
│   │   │   ├── graph
│   │   │   │   └── mod.rs
│   │   │   ├── guard.rs
│   │   │   ├── lib.rs
│   │   │   ├── main.rs
│   │   │   ├── main.rs.backup
│   │   │   ├── part2.rs
│   │   │   ├── rescript_auto_discovery.rs
│   │   │   ├── resolver.rs
│   │   │   └── state.rs
│   │   ├── test_manual_resolver
│   │   └── tests
│   │       ├── dependency_test.rs
│   │       └── rescript_parser_test.rs
│   ├── analyzer_state.json
│   ├── config
│   │   ├── deprecated
│   │   │   └── templates_v1.json
│   │   └── efficiency.json
│   └── plans
│       ├── CONFIG_PLAN.md
│       ├── CSS_PLAN.md
│       ├── RESCRIPT_PLAN.md
│       ├── RUST_PLAN.md
│       ├── SYSTEM_PLAN.md
│       └── metadata.json
├── app_test_fail.txt
├── app_test_fail_2.txt
├── backend
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── bin
│   │   └── ffmpeg
│   ├── data
│   │   ├── database.db
│   │   └── storage
│   ├── migrations
│   │   ├── 20260124000000_init.sql
│   │   └── 20260128000000_core_schema.sql
│   ├── src
│   │   ├── api
│   │   │   ├── auth.rs
│   │   │   ├── geocoding.rs
│   │   │   ├── media
│   │   │   │   ├── image.rs
│   │   │   │   ├── image_logic.rs
│   │   │   │   ├── mod.rs
│   │   │   │   ├── serve.rs
│   │   │   │   ├── similarity.rs
│   │   │   │   ├── video.rs
│   │   │   │   └── video_logic.rs
│   │   │   ├── mod.rs
│   │   │   ├── project.rs
│   │   │   ├── project_logic.rs
│   │   │   ├── telemetry.rs
│   │   │   └── utils.rs
│   │   ├── lib.rs
│   │   ├── main.rs
│   │   ├── metrics.rs
│   │   ├── middleware.rs
│   │   ├── models.rs
│   │   ├── pathfinder
│   │   │   ├── algorithms.rs
│   │   │   └── graph.rs
│   │   ├── pathfinder.rs
│   │   └── services
│   │       ├── auth.rs
│   │       ├── database.rs
│   │       ├── geocoding.rs
│   │       ├── media
│   │       │   ├── analysis.rs
│   │       │   ├── analysis_exif.rs
│   │       │   ├── analysis_quality.rs
│   │       │   ├── mod.rs
│   │       │   ├── naming.rs
│   │       │   ├── resizing.rs
│   │       │   ├── storage.rs
│   │       │   └── webp.rs
│   │       ├── mod.rs
│   │       ├── project
│   │       │   ├── load.rs
│   │       │   ├── mod.rs
│   │       │   ├── package.rs
│   │       │   └── validate.rs
│   │       ├── shutdown.rs
│   │       ├── upload_quota.rs
│   │       └── upload_quota_tests.rs
│   ├── startup_log.txt
│   └── tests
│       └── shutdown_test.rs
├── bin
│   └── tailwindcss
├── build_output.txt
├── cache
│   └── geocoding.json
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
│   │   ├── viewer-hotspots.css
│   │   ├── viewer-ui.css
│   │   └── viewer.css
│   ├── layout.css
│   ├── legacy.css
│   ├── output.css
│   ├── style.css
│   ├── tailwind.css
│   └── variables.css
├── data
│   └── storage
├── docs
│   ├── GENERAL_MECHANICS.md
│   ├── PRIVACY_POLICY.md
│   ├── PROJECT_HISTORY.md
│   ├── PROJECT_SPECS.md
│   ├── TERMS_OF_SERVICE.md
│   ├── _pending_integration
│   │   ├── ANALYSIS_DEV_SYSTEM_ACCURACY.md
│   │   └── analysis_1108_1114_1112_1113_1116.md
│   ├── openapi.yaml
│   └── tmp
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
│   │   │   │   ├── FloorNavigation.ast
│   │   │   │   ├── FloorNavigation.bs.js
│   │   │   │   ├── FloorNavigation.cmi
│   │   │   │   ├── FloorNavigation.cmj
│   │   │   │   ├── FloorNavigation.cmt
│   │   │   │   ├── FloorNavigation.res
│   │   │   │   ├── HotspotActionMenu.ast
│   │   │   │   ├── HotspotActionMenu.bs.js
│   │   │   │   ├── HotspotActionMenu.cmi
│   │   │   │   ├── HotspotActionMenu.cmj
│   │   │   │   ├── HotspotActionMenu.cmt
│   │   │   │   ├── HotspotActionMenu.res
│   │   │   │   ├── HotspotLayer.ast
│   │   │   │   ├── HotspotLayer.bs.js
│   │   │   │   ├── HotspotLayer.cmi
│   │   │   │   ├── HotspotLayer.cmj
│   │   │   │   ├── HotspotLayer.cmt
│   │   │   │   ├── HotspotLayer.res
│   │   │   │   ├── HotspotManager.ast
│   │   │   │   ├── HotspotManager.bs.js
│   │   │   │   ├── HotspotManager.cmi
│   │   │   │   ├── HotspotManager.cmj
│   │   │   │   ├── HotspotManager.cmt
│   │   │   │   ├── HotspotManager.res
│   │   │   │   ├── HotspotMenuLayer.ast
│   │   │   │   ├── HotspotMenuLayer.bs.js
│   │   │   │   ├── HotspotMenuLayer.cmi
│   │   │   │   ├── HotspotMenuLayer.cmj
│   │   │   │   ├── HotspotMenuLayer.cmt
│   │   │   │   ├── HotspotMenuLayer.res
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
│   │   │   │   ├── NotificationLayer.ast
│   │   │   │   ├── NotificationLayer.bs.js
│   │   │   │   ├── NotificationLayer.cmi
│   │   │   │   ├── NotificationLayer.cmj
│   │   │   │   ├── NotificationLayer.cmt
│   │   │   │   ├── NotificationLayer.res
│   │   │   │   ├── PersistentLabel.ast
│   │   │   │   ├── PersistentLabel.bs.js
│   │   │   │   ├── PersistentLabel.cmi
│   │   │   │   ├── PersistentLabel.cmj
│   │   │   │   ├── PersistentLabel.cmt
│   │   │   │   ├── PersistentLabel.res
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
│   │   │   │   ├── QualityIndicator.ast
│   │   │   │   ├── QualityIndicator.bs.js
│   │   │   │   ├── QualityIndicator.cmi
│   │   │   │   ├── QualityIndicator.cmj
│   │   │   │   ├── QualityIndicator.cmt
│   │   │   │   ├── QualityIndicator.res
│   │   │   │   ├── ReturnPrompt.ast
│   │   │   │   ├── ReturnPrompt.bs.js
│   │   │   │   ├── ReturnPrompt.cmi
│   │   │   │   ├── ReturnPrompt.cmj
│   │   │   │   ├── ReturnPrompt.cmt
│   │   │   │   ├── ReturnPrompt.res
│   │   │   │   ├── SceneList
│   │   │   │   │   ├── SceneItem.ast
│   │   │   │   │   ├── SceneItem.bs.js
│   │   │   │   │   ├── SceneItem.cmi
│   │   │   │   │   ├── SceneItem.cmj
│   │   │   │   │   ├── SceneItem.cmt
│   │   │   │   │   └── SceneItem.res
│   │   │   │   ├── SceneList.ast
│   │   │   │   ├── SceneList.bs.js
│   │   │   │   ├── SceneList.cmi
│   │   │   │   ├── SceneList.cmj
│   │   │   │   ├── SceneList.cmt
│   │   │   │   ├── SceneList.res
│   │   │   │   ├── Sidebar
│   │   │   │   │   ├── SidebarActions.ast
│   │   │   │   │   ├── SidebarActions.bs.js
│   │   │   │   │   ├── SidebarActions.cmi
│   │   │   │   │   ├── SidebarActions.cmj
│   │   │   │   │   ├── SidebarActions.cmt
│   │   │   │   │   ├── SidebarActions.res
│   │   │   │   │   ├── SidebarBranding.ast
│   │   │   │   │   ├── SidebarBranding.bs.js
│   │   │   │   │   ├── SidebarBranding.cmi
│   │   │   │   │   ├── SidebarBranding.cmj
│   │   │   │   │   ├── SidebarBranding.cmt
│   │   │   │   │   ├── SidebarBranding.res
│   │   │   │   │   ├── SidebarLogic.ast
│   │   │   │   │   ├── SidebarLogic.bs.js
│   │   │   │   │   ├── SidebarLogic.cmi
│   │   │   │   │   ├── SidebarLogic.cmj
│   │   │   │   │   ├── SidebarLogic.cmt
│   │   │   │   │   ├── SidebarLogic.res
│   │   │   │   │   ├── SidebarProcessing.ast
│   │   │   │   │   ├── SidebarProcessing.bs.js
│   │   │   │   │   ├── SidebarProcessing.cmi
│   │   │   │   │   ├── SidebarProcessing.cmj
│   │   │   │   │   ├── SidebarProcessing.cmt
│   │   │   │   │   ├── SidebarProcessing.res
│   │   │   │   │   ├── SidebarProjectInfo.ast
│   │   │   │   │   ├── SidebarProjectInfo.bs.js
│   │   │   │   │   ├── SidebarProjectInfo.cmi
│   │   │   │   │   ├── SidebarProjectInfo.cmj
│   │   │   │   │   ├── SidebarProjectInfo.cmt
│   │   │   │   │   └── SidebarProjectInfo.res
│   │   │   │   ├── Sidebar.ast
│   │   │   │   ├── Sidebar.bs.js
│   │   │   │   ├── Sidebar.cmi
│   │   │   │   ├── Sidebar.cmj
│   │   │   │   ├── Sidebar.cmt
│   │   │   │   ├── Sidebar.res
│   │   │   │   ├── SnapshotOverlay.ast
│   │   │   │   ├── SnapshotOverlay.bs.js
│   │   │   │   ├── SnapshotOverlay.cmi
│   │   │   │   ├── SnapshotOverlay.cmj
│   │   │   │   ├── SnapshotOverlay.cmt
│   │   │   │   ├── SnapshotOverlay.res
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
│   │   │   │   ├── UtilityBar.ast
│   │   │   │   ├── UtilityBar.bs.js
│   │   │   │   ├── UtilityBar.cmi
│   │   │   │   ├── UtilityBar.cmj
│   │   │   │   ├── UtilityBar.cmt
│   │   │   │   ├── UtilityBar.res
│   │   │   │   ├── ViewerHUD.ast
│   │   │   │   ├── ViewerHUD.bs.js
│   │   │   │   ├── ViewerHUD.cmi
│   │   │   │   ├── ViewerHUD.cmj
│   │   │   │   ├── ViewerHUD.cmt
│   │   │   │   ├── ViewerHUD.res
│   │   │   │   ├── ViewerLabelMenu.ast
│   │   │   │   ├── ViewerLabelMenu.bs.js
│   │   │   │   ├── ViewerLabelMenu.cmi
│   │   │   │   ├── ViewerLabelMenu.cmj
│   │   │   │   ├── ViewerLabelMenu.cmt
│   │   │   │   ├── ViewerLabelMenu.res
│   │   │   │   ├── ViewerLoader.ast
│   │   │   │   ├── ViewerLoader.bs.js
│   │   │   │   ├── ViewerLoader.cmi
│   │   │   │   ├── ViewerLoader.cmj
│   │   │   │   ├── ViewerLoader.cmt
│   │   │   │   ├── ViewerLoader.res
│   │   │   │   ├── ViewerManager
│   │   │   │   │   ├── ViewerManagerLifecycle.ast
│   │   │   │   │   ├── ViewerManagerLifecycle.bs.js
│   │   │   │   │   ├── ViewerManagerLifecycle.cmi
│   │   │   │   │   ├── ViewerManagerLifecycle.cmj
│   │   │   │   │   ├── ViewerManagerLifecycle.cmt
│   │   │   │   │   └── ViewerManagerLifecycle.res
│   │   │   │   ├── ViewerManager.ast
│   │   │   │   ├── ViewerManager.bs.js
│   │   │   │   ├── ViewerManager.cmi
│   │   │   │   ├── ViewerManager.cmj
│   │   │   │   ├── ViewerManager.cmt
│   │   │   │   ├── ViewerManager.res
│   │   │   │   ├── ViewerManagerLogic.ast
│   │   │   │   ├── ViewerManagerLogic.bs.js
│   │   │   │   ├── ViewerManagerLogic.cmi
│   │   │   │   ├── ViewerManagerLogic.cmj
│   │   │   │   ├── ViewerManagerLogic.cmt
│   │   │   │   ├── ViewerManagerLogic.res
│   │   │   │   ├── ViewerSnapshot.ast
│   │   │   │   ├── ViewerSnapshot.bs.js
│   │   │   │   ├── ViewerSnapshot.cmi
│   │   │   │   ├── ViewerSnapshot.cmj
│   │   │   │   ├── ViewerSnapshot.cmt
│   │   │   │   ├── ViewerSnapshot.res
│   │   │   │   ├── ViewerUI.ast
│   │   │   │   ├── ViewerUI.bs.js
│   │   │   │   ├── ViewerUI.cmi
│   │   │   │   ├── ViewerUI.cmj
│   │   │   │   ├── ViewerUI.cmt
│   │   │   │   ├── ViewerUI.res
│   │   │   │   ├── VisualPipeline
│   │   │   │   │   ├── VisualPipelineStyles.ast
│   │   │   │   │   ├── VisualPipelineStyles.bs.js
│   │   │   │   │   ├── VisualPipelineStyles.cmi
│   │   │   │   │   ├── VisualPipelineStyles.cmj
│   │   │   │   │   ├── VisualPipelineStyles.cmt
│   │   │   │   │   └── VisualPipelineStyles.res
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
│   │   │   │   ├── Reducer.ast
│   │   │   │   ├── Reducer.bs.js
│   │   │   │   ├── Reducer.cmi
│   │   │   │   ├── Reducer.cmj
│   │   │   │   ├── Reducer.cmt
│   │   │   │   ├── Reducer.res
│   │   │   │   ├── SceneCache.ast
│   │   │   │   ├── SceneCache.bs.js
│   │   │   │   ├── SceneCache.cmi
│   │   │   │   ├── SceneCache.cmj
│   │   │   │   ├── SceneCache.cmt
│   │   │   │   ├── SceneCache.res
│   │   │   │   ├── SceneHelpers.ast
│   │   │   │   ├── SceneHelpers.bs.js
│   │   │   │   ├── SceneHelpers.cmi
│   │   │   │   ├── SceneHelpers.cmj
│   │   │   │   ├── SceneHelpers.cmt
│   │   │   │   ├── SceneHelpers.res
│   │   │   │   ├── Schemas.ast
│   │   │   │   ├── Schemas.bs.js
│   │   │   │   ├── Schemas.cmi
│   │   │   │   ├── Schemas.cmj
│   │   │   │   ├── Schemas.cmt
│   │   │   │   ├── Schemas.res
│   │   │   │   ├── SharedTypes.ast
│   │   │   │   ├── SharedTypes.bs.js
│   │   │   │   ├── SharedTypes.cmi
│   │   │   │   ├── SharedTypes.cmj
│   │   │   │   ├── SharedTypes.cmt
│   │   │   │   ├── SharedTypes.res
│   │   │   │   ├── SimHelpers.ast
│   │   │   │   ├── SimHelpers.bs.js
│   │   │   │   ├── SimHelpers.cmi
│   │   │   │   ├── SimHelpers.cmj
│   │   │   │   ├── SimHelpers.cmt
│   │   │   │   ├── SimHelpers.res
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
│   │   │   │   ├── UiHelpers.ast
│   │   │   │   ├── UiHelpers.bs.js
│   │   │   │   ├── UiHelpers.cmi
│   │   │   │   ├── UiHelpers.cmj
│   │   │   │   ├── UiHelpers.cmt
│   │   │   │   ├── UiHelpers.res
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
│   │   │   │   └── interfaces
│   │   │   │       ├── ViewerDriver.ast
│   │   │   │       ├── ViewerDriver.bs.js
│   │   │   │       ├── ViewerDriver.cmi
│   │   │   │       ├── ViewerDriver.cmj
│   │   │   │       ├── ViewerDriver.cmt
│   │   │   │       └── ViewerDriver.res
│   │   │   ├── i18n
│   │   │   │   ├── I18n.ast
│   │   │   │   ├── I18n.bs.js
│   │   │   │   ├── I18n.cmi
│   │   │   │   ├── I18n.cmj
│   │   │   │   ├── I18n.cmt
│   │   │   │   └── I18n.res
│   │   │   ├── systems
│   │   │   │   ├── Api
│   │   │   │   │   ├── ApiTypes.ast
│   │   │   │   │   ├── ApiTypes.bs.js
│   │   │   │   │   ├── ApiTypes.cmi
│   │   │   │   │   ├── ApiTypes.cmj
│   │   │   │   │   ├── ApiTypes.cmt
│   │   │   │   │   ├── ApiTypes.res
│   │   │   │   │   ├── AuthenticatedClient.ast
│   │   │   │   │   ├── AuthenticatedClient.bs.js
│   │   │   │   │   ├── AuthenticatedClient.cmi
│   │   │   │   │   ├── AuthenticatedClient.cmj
│   │   │   │   │   ├── AuthenticatedClient.cmt
│   │   │   │   │   ├── AuthenticatedClient.res
│   │   │   │   │   ├── MediaApi.ast
│   │   │   │   │   ├── MediaApi.bs.js
│   │   │   │   │   ├── MediaApi.cmi
│   │   │   │   │   ├── MediaApi.cmj
│   │   │   │   │   ├── MediaApi.cmt
│   │   │   │   │   └── MediaApi.res
│   │   │   │   ├── Api.ast
│   │   │   │   ├── Api.bs.js
│   │   │   │   ├── Api.cmi
│   │   │   │   ├── Api.cmj
│   │   │   │   ├── Api.cmt
│   │   │   │   ├── Api.res
│   │   │   │   ├── ApiLogic.ast
│   │   │   │   ├── ApiLogic.bs.js
│   │   │   │   ├── ApiLogic.cmi
│   │   │   │   ├── ApiLogic.cmj
│   │   │   │   ├── ApiLogic.cmt
│   │   │   │   ├── ApiLogic.res
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
│   │   │   │   ├── CursorPhysics.ast
│   │   │   │   ├── CursorPhysics.bs.js
│   │   │   │   ├── CursorPhysics.cmi
│   │   │   │   ├── CursorPhysics.cmj
│   │   │   │   ├── CursorPhysics.cmt
│   │   │   │   ├── CursorPhysics.res
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
│   │   │   │   ├── ExifReportGeneratorLogic.ast
│   │   │   │   ├── ExifReportGeneratorLogic.bs.js
│   │   │   │   ├── ExifReportGeneratorLogic.cmi
│   │   │   │   ├── ExifReportGeneratorLogic.cmj
│   │   │   │   ├── ExifReportGeneratorLogic.cmt
│   │   │   │   ├── ExifReportGeneratorLogic.res
│   │   │   │   ├── Exporter.ast
│   │   │   │   ├── Exporter.bs.js
│   │   │   │   ├── Exporter.cmi
│   │   │   │   ├── Exporter.cmj
│   │   │   │   ├── Exporter.cmt
│   │   │   │   ├── Exporter.res
│   │   │   │   ├── FingerprintService.ast
│   │   │   │   ├── FingerprintService.bs.js
│   │   │   │   ├── FingerprintService.cmi
│   │   │   │   ├── FingerprintService.cmj
│   │   │   │   ├── FingerprintService.cmt
│   │   │   │   ├── FingerprintService.res
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
│   │   │   │   ├── ImageValidator.ast
│   │   │   │   ├── ImageValidator.bs.js
│   │   │   │   ├── ImageValidator.cmi
│   │   │   │   ├── ImageValidator.cmj
│   │   │   │   ├── ImageValidator.cmt
│   │   │   │   ├── ImageValidator.res
│   │   │   │   ├── InputSystem.ast
│   │   │   │   ├── InputSystem.bs.js
│   │   │   │   ├── InputSystem.cmi
│   │   │   │   ├── InputSystem.cmj
│   │   │   │   ├── InputSystem.cmt
│   │   │   │   ├── InputSystem.res
│   │   │   │   ├── LinkEditorLogic.ast
│   │   │   │   ├── LinkEditorLogic.bs.js
│   │   │   │   ├── LinkEditorLogic.cmi
│   │   │   │   ├── LinkEditorLogic.cmj
│   │   │   │   ├── LinkEditorLogic.cmt
│   │   │   │   ├── LinkEditorLogic.res
│   │   │   │   ├── Navigation.ast
│   │   │   │   ├── Navigation.bs.js
│   │   │   │   ├── Navigation.cmi
│   │   │   │   ├── Navigation.cmj
│   │   │   │   ├── Navigation.cmt
│   │   │   │   ├── Navigation.res
│   │   │   │   ├── NavigationFSM.ast
│   │   │   │   ├── NavigationFSM.bs.js
│   │   │   │   ├── NavigationFSM.cmi
│   │   │   │   ├── NavigationFSM.cmj
│   │   │   │   ├── NavigationFSM.cmt
│   │   │   │   ├── NavigationFSM.res
│   │   │   │   ├── NavigationGraph.ast
│   │   │   │   ├── NavigationGraph.bs.js
│   │   │   │   ├── NavigationGraph.cmi
│   │   │   │   ├── NavigationGraph.cmj
│   │   │   │   ├── NavigationGraph.cmt
│   │   │   │   ├── NavigationGraph.res
│   │   │   │   ├── NavigationLogic.ast
│   │   │   │   ├── NavigationLogic.bs.js
│   │   │   │   ├── NavigationLogic.cmi
│   │   │   │   ├── NavigationLogic.cmj
│   │   │   │   ├── NavigationLogic.cmt
│   │   │   │   ├── NavigationLogic.res
│   │   │   │   ├── PannellumAdapter.ast
│   │   │   │   ├── PannellumAdapter.bs.js
│   │   │   │   ├── PannellumAdapter.cmi
│   │   │   │   ├── PannellumAdapter.cmj
│   │   │   │   ├── PannellumAdapter.cmt
│   │   │   │   ├── PannellumAdapter.res
│   │   │   │   ├── PannellumLifecycle.ast
│   │   │   │   ├── PannellumLifecycle.bs.js
│   │   │   │   ├── PannellumLifecycle.cmi
│   │   │   │   ├── PannellumLifecycle.cmj
│   │   │   │   ├── PannellumLifecycle.cmt
│   │   │   │   ├── PannellumLifecycle.res
│   │   │   │   ├── PanoramaClusterer.ast
│   │   │   │   ├── PanoramaClusterer.bs.js
│   │   │   │   ├── PanoramaClusterer.cmi
│   │   │   │   ├── PanoramaClusterer.cmj
│   │   │   │   ├── PanoramaClusterer.cmt
│   │   │   │   ├── PanoramaClusterer.res
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
│   │   │   │   ├── Scene.ast
│   │   │   │   ├── Scene.bs.js
│   │   │   │   ├── Scene.cmi
│   │   │   │   ├── Scene.cmj
│   │   │   │   ├── Scene.cmt
│   │   │   │   ├── Scene.res
│   │   │   │   ├── ServerTeaser.ast
│   │   │   │   ├── ServerTeaser.bs.js
│   │   │   │   ├── ServerTeaser.cmi
│   │   │   │   ├── ServerTeaser.cmj
│   │   │   │   ├── ServerTeaser.cmt
│   │   │   │   ├── ServerTeaser.res
│   │   │   │   ├── Simulation.ast
│   │   │   │   ├── Simulation.bs.js
│   │   │   │   ├── Simulation.cmi
│   │   │   │   ├── Simulation.cmj
│   │   │   │   ├── Simulation.cmt
│   │   │   │   ├── Simulation.res
│   │   │   │   ├── SimulationLogic.ast
│   │   │   │   ├── SimulationLogic.bs.js
│   │   │   │   ├── SimulationLogic.cmi
│   │   │   │   ├── SimulationLogic.cmj
│   │   │   │   ├── SimulationLogic.cmt
│   │   │   │   ├── SimulationLogic.res
│   │   │   │   ├── SvgManager.ast
│   │   │   │   ├── SvgManager.bs.js
│   │   │   │   ├── SvgManager.cmi
│   │   │   │   ├── SvgManager.cmj
│   │   │   │   ├── SvgManager.cmt
│   │   │   │   ├── SvgManager.res
│   │   │   │   ├── Teaser.ast
│   │   │   │   ├── Teaser.bs.js
│   │   │   │   ├── Teaser.cmi
│   │   │   │   ├── Teaser.cmj
│   │   │   │   ├── Teaser.cmt
│   │   │   │   ├── Teaser.res
│   │   │   │   ├── TeaserLogic.ast
│   │   │   │   ├── TeaserLogic.bs.js
│   │   │   │   ├── TeaserLogic.cmi
│   │   │   │   ├── TeaserLogic.cmj
│   │   │   │   ├── TeaserLogic.cmt
│   │   │   │   ├── TeaserLogic.res
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
│   │   │   │   ├── TeaserState.ast
│   │   │   │   ├── TeaserState.bs.js
│   │   │   │   ├── TeaserState.cmi
│   │   │   │   ├── TeaserState.cmj
│   │   │   │   ├── TeaserState.cmt
│   │   │   │   ├── TeaserState.res
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
│   │   │   │   ├── UploadTypes.ast
│   │   │   │   ├── UploadTypes.bs.js
│   │   │   │   ├── UploadTypes.cmi
│   │   │   │   ├── UploadTypes.cmj
│   │   │   │   ├── UploadTypes.cmt
│   │   │   │   ├── UploadTypes.res
│   │   │   │   ├── VideoEncoder.ast
│   │   │   │   ├── VideoEncoder.bs.js
│   │   │   │   ├── VideoEncoder.cmi
│   │   │   │   ├── VideoEncoder.cmj
│   │   │   │   ├── VideoEncoder.cmt
│   │   │   │   ├── VideoEncoder.res
│   │   │   │   ├── ViewerFollow.ast
│   │   │   │   ├── ViewerFollow.bs.js
│   │   │   │   ├── ViewerFollow.cmi
│   │   │   │   ├── ViewerFollow.cmj
│   │   │   │   ├── ViewerFollow.cmt
│   │   │   │   ├── ViewerFollow.res
│   │   │   │   ├── ViewerLogic.ast
│   │   │   │   ├── ViewerLogic.bs.js
│   │   │   │   ├── ViewerLogic.cmi
│   │   │   │   ├── ViewerLogic.cmj
│   │   │   │   ├── ViewerLogic.cmt
│   │   │   │   ├── ViewerLogic.res
│   │   │   │   ├── ViewerPool.ast
│   │   │   │   ├── ViewerPool.bs.js
│   │   │   │   ├── ViewerPool.cmi
│   │   │   │   ├── ViewerPool.cmj
│   │   │   │   ├── ViewerPool.cmt
│   │   │   │   ├── ViewerPool.res
│   │   │   │   ├── ViewerSystem.ast
│   │   │   │   ├── ViewerSystem.bs.js
│   │   │   │   ├── ViewerSystem.cmi
│   │   │   │   ├── ViewerSystem.cmj
│   │   │   │   ├── ViewerSystem.cmt
│   │   │   │   └── ViewerSystem.res
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
│   │   │       ├── PersistenceLayer.ast
│   │   │       ├── PersistenceLayer.bs.js
│   │   │       ├── PersistenceLayer.cmi
│   │   │       ├── PersistenceLayer.cmj
│   │   │       ├── PersistenceLayer.cmt
│   │   │       ├── PersistenceLayer.res
│   │   │       ├── ProgressBar.ast
│   │   │       ├── ProgressBar.bs.js
│   │   │       ├── ProgressBar.cmi
│   │   │       ├── ProgressBar.cmj
│   │   │       ├── ProgressBar.cmt
│   │   │       ├── ProgressBar.res
│   │   │       ├── ProjectionMath.ast
│   │   │       ├── ProjectionMath.bs.js
│   │   │       ├── ProjectionMath.cmi
│   │   │       ├── ProjectionMath.cmj
│   │   │       ├── ProjectionMath.cmt
│   │   │       ├── ProjectionMath.res
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
│   │   │       └── Version.res
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
│   │           ├── ApiTypes_v.test.ast
│   │           ├── ApiTypes_v.test.bs.js
│   │           ├── ApiTypes_v.test.cmi
│   │           ├── ApiTypes_v.test.cmj
│   │           ├── ApiTypes_v.test.cmt
│   │           ├── ApiTypes_v.test.res
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
│   │           ├── AuthenticatedClient_v.test.ast
│   │           ├── AuthenticatedClient_v.test.bs.js
│   │           ├── AuthenticatedClient_v.test.cmi
│   │           ├── AuthenticatedClient_v.test.cmj
│   │           ├── AuthenticatedClient_v.test.cmt
│   │           ├── AuthenticatedClient_v.test.res
│   │           ├── BackendApi_v.test.ast
│   │           ├── BackendApi_v.test.bs.js
│   │           ├── BackendApi_v.test.cmi
│   │           ├── BackendApi_v.test.cmj
│   │           ├── BackendApi_v.test.cmt
│   │           ├── BackendApi_v.test.res
│   │           ├── Bindings_Unified_v.test.ast
│   │           ├── Bindings_Unified_v.test.bs.js
│   │           ├── Bindings_Unified_v.test.cmi
│   │           ├── Bindings_Unified_v.test.cmj
│   │           ├── Bindings_Unified_v.test.cmt
│   │           ├── Bindings_Unified_v.test.res
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
│   │           ├── CursorPhysics_v.test.ast
│   │           ├── CursorPhysics_v.test.bs.js
│   │           ├── CursorPhysics_v.test.cmi
│   │           ├── CursorPhysics_v.test.cmj
│   │           ├── CursorPhysics_v.test.cmt
│   │           ├── CursorPhysics_v.test.res
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
│   │           ├── ExifReportGeneratorLogicExtraction_v.test.ast
│   │           ├── ExifReportGeneratorLogicExtraction_v.test.bs.js
│   │           ├── ExifReportGeneratorLogicExtraction_v.test.cmi
│   │           ├── ExifReportGeneratorLogicExtraction_v.test.cmj
│   │           ├── ExifReportGeneratorLogicExtraction_v.test.cmt
│   │           ├── ExifReportGeneratorLogicExtraction_v.test.res
│   │           ├── ExifReportGeneratorLogicGroups_v.test.ast
│   │           ├── ExifReportGeneratorLogicGroups_v.test.bs.js
│   │           ├── ExifReportGeneratorLogicGroups_v.test.cmi
│   │           ├── ExifReportGeneratorLogicGroups_v.test.cmj
│   │           ├── ExifReportGeneratorLogicGroups_v.test.cmt
│   │           ├── ExifReportGeneratorLogicGroups_v.test.res
│   │           ├── ExifReportGeneratorLogicLocation_v.test.ast
│   │           ├── ExifReportGeneratorLogicLocation_v.test.bs.js
│   │           ├── ExifReportGeneratorLogicLocation_v.test.cmi
│   │           ├── ExifReportGeneratorLogicLocation_v.test.cmj
│   │           ├── ExifReportGeneratorLogicLocation_v.test.cmt
│   │           ├── ExifReportGeneratorLogicLocation_v.test.res
│   │           ├── ExifReportGeneratorUtils_v.test.ast
│   │           ├── ExifReportGeneratorUtils_v.test.bs.js
│   │           ├── ExifReportGeneratorUtils_v.test.cmi
│   │           ├── ExifReportGeneratorUtils_v.test.cmj
│   │           ├── ExifReportGeneratorUtils_v.test.cmt
│   │           ├── ExifReportGeneratorUtils_v.test.res
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
│   │           ├── FinalAsyncCheck_v.test.ast
│   │           ├── FinalAsyncCheck_v.test.bs.js
│   │           ├── FinalAsyncCheck_v.test.cmi
│   │           ├── FinalAsyncCheck_v.test.cmj
│   │           ├── FinalAsyncCheck_v.test.cmt
│   │           ├── FinalAsyncCheck_v.test.res
│   │           ├── FingerprintService_v.test.ast
│   │           ├── FingerprintService_v.test.bs.js
│   │           ├── FingerprintService_v.test.cmi
│   │           ├── FingerprintService_v.test.cmj
│   │           ├── FingerprintService_v.test.cmt
│   │           ├── FingerprintService_v.test.res
│   │           ├── FloorNavigation_v.test.ast
│   │           ├── FloorNavigation_v.test.bs.js
│   │           ├── FloorNavigation_v.test.cmi
│   │           ├── FloorNavigation_v.test.cmj
│   │           ├── FloorNavigation_v.test.cmt
│   │           ├── FloorNavigation_v.test.res
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
│   │           ├── HotspotLayer_v.test.ast
│   │           ├── HotspotLayer_v.test.bs.js
│   │           ├── HotspotLayer_v.test.cmi
│   │           ├── HotspotLayer_v.test.cmj
│   │           ├── HotspotLayer_v.test.cmt
│   │           ├── HotspotLayer_v.test.res
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
│   │           ├── HotspotMenuLayer_v.test.ast
│   │           ├── HotspotMenuLayer_v.test.bs.js
│   │           ├── HotspotMenuLayer_v.test.cmi
│   │           ├── HotspotMenuLayer_v.test.cmj
│   │           ├── HotspotMenuLayer_v.test.cmt
│   │           ├── HotspotMenuLayer_v.test.res
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
│   │           ├── ImageValidator_v.test.ast
│   │           ├── ImageValidator_v.test.bs.js
│   │           ├── ImageValidator_v.test.cmi
│   │           ├── ImageValidator_v.test.cmj
│   │           ├── ImageValidator_v.test.cmt
│   │           ├── ImageValidator_v.test.res
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
│   │           ├── LinkEditorLogic_v.test.ast
│   │           ├── LinkEditorLogic_v.test.bs.js
│   │           ├── LinkEditorLogic_v.test.cmi
│   │           ├── LinkEditorLogic_v.test.cmj
│   │           ├── LinkEditorLogic_v.test.cmt
│   │           ├── LinkEditorLogic_v.test.res
│   │           ├── LinkModal_v.test.ast
│   │           ├── LinkModal_v.test.bs.js
│   │           ├── LinkModal_v.test.cmi
│   │           ├── LinkModal_v.test.cmj
│   │           ├── LinkModal_v.test.cmt
│   │           ├── LinkModal_v.test.res
│   │           ├── LoggerLogic_v.test.ast
│   │           ├── LoggerLogic_v.test.bs.js
│   │           ├── LoggerLogic_v.test.cmi
│   │           ├── LoggerLogic_v.test.cmj
│   │           ├── LoggerLogic_v.test.cmt
│   │           ├── LoggerLogic_v.test.res
│   │           ├── LoggerTelemetry_v.test.ast
│   │           ├── LoggerTelemetry_v.test.bs.js
│   │           ├── LoggerTelemetry_v.test.cmi
│   │           ├── LoggerTelemetry_v.test.cmj
│   │           ├── LoggerTelemetry_v.test.cmt
│   │           ├── LoggerTelemetry_v.test.res
│   │           ├── LoggerTypes_v.test.ast
│   │           ├── LoggerTypes_v.test.bs.js
│   │           ├── LoggerTypes_v.test.cmi
│   │           ├── LoggerTypes_v.test.cmj
│   │           ├── LoggerTypes_v.test.cmt
│   │           ├── LoggerTypes_v.test.res
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
│   │           ├── MediaApi_v.test.ast
│   │           ├── MediaApi_v.test.bs.js
│   │           ├── MediaApi_v.test.cmi
│   │           ├── MediaApi_v.test.cmj
│   │           ├── MediaApi_v.test.cmt
│   │           ├── MediaApi_v.test.res
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
│   │           ├── NavigationFSM_v.test.ast
│   │           ├── NavigationFSM_v.test.bs.js
│   │           ├── NavigationFSM_v.test.cmi
│   │           ├── NavigationFSM_v.test.cmj
│   │           ├── NavigationFSM_v.test.cmt
│   │           ├── NavigationFSM_v.test.res
│   │           ├── NavigationGraph_v.test.ast
│   │           ├── NavigationGraph_v.test.bs.js
│   │           ├── NavigationGraph_v.test.cmi
│   │           ├── NavigationGraph_v.test.cmj
│   │           ├── NavigationGraph_v.test.cmt
│   │           ├── NavigationGraph_v.test.res
│   │           ├── NavigationReducer_v.test.ast
│   │           ├── NavigationReducer_v.test.bs.js
│   │           ├── NavigationReducer_v.test.cmi
│   │           ├── NavigationReducer_v.test.cmj
│   │           ├── NavigationReducer_v.test.cmt
│   │           ├── NavigationReducer_v.test.res
│   │           ├── NotificationContext_v.test.ast
│   │           ├── NotificationContext_v.test.bs.js
│   │           ├── NotificationContext_v.test.cmi
│   │           ├── NotificationContext_v.test.cmj
│   │           ├── NotificationContext_v.test.cmt
│   │           ├── NotificationContext_v.test.res
│   │           ├── NotificationLayer_v.test.ast
│   │           ├── NotificationLayer_v.test.bs.js
│   │           ├── NotificationLayer_v.test.cmi
│   │           ├── NotificationLayer_v.test.cmj
│   │           ├── NotificationLayer_v.test.cmt
│   │           ├── NotificationLayer_v.test.res
│   │           ├── PannellumAdapter_v.test.ast
│   │           ├── PannellumAdapter_v.test.bs.js
│   │           ├── PannellumAdapter_v.test.cmi
│   │           ├── PannellumAdapter_v.test.cmj
│   │           ├── PannellumAdapter_v.test.cmt
│   │           ├── PannellumAdapter_v.test.res
│   │           ├── PannellumLifecycle_v.test.ast
│   │           ├── PannellumLifecycle_v.test.bs.js
│   │           ├── PannellumLifecycle_v.test.cmi
│   │           ├── PannellumLifecycle_v.test.cmj
│   │           ├── PannellumLifecycle_v.test.cmt
│   │           ├── PannellumLifecycle_v.test.res
│   │           ├── PanoramaClusterer_v.test.ast
│   │           ├── PanoramaClusterer_v.test.bs.js
│   │           ├── PanoramaClusterer_v.test.cmi
│   │           ├── PanoramaClusterer_v.test.cmj
│   │           ├── PanoramaClusterer_v.test.cmt
│   │           ├── PanoramaClusterer_v.test.res
│   │           ├── PathInterpolation_v.test.ast
│   │           ├── PathInterpolation_v.test.bs.js
│   │           ├── PathInterpolation_v.test.cmi
│   │           ├── PathInterpolation_v.test.cmj
│   │           ├── PathInterpolation_v.test.cmt
│   │           ├── PathInterpolation_v.test.res
│   │           ├── PersistentLabel_v.test.ast
│   │           ├── PersistentLabel_v.test.bs.js
│   │           ├── PersistentLabel_v.test.cmi
│   │           ├── PersistentLabel_v.test.cmj
│   │           ├── PersistentLabel_v.test.cmt
│   │           ├── PersistentLabel_v.test.res
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
│   │           ├── ProjectApi_v.test.ast
│   │           ├── ProjectApi_v.test.bs.js
│   │           ├── ProjectApi_v.test.cmi
│   │           ├── ProjectApi_v.test.cmj
│   │           ├── ProjectApi_v.test.cmt
│   │           ├── ProjectApi_v.test.res
│   │           ├── ProjectData_v.test.ast
│   │           ├── ProjectData_v.test.bs.js
│   │           ├── ProjectData_v.test.cmi
│   │           ├── ProjectData_v.test.cmj
│   │           ├── ProjectData_v.test.cmt
│   │           ├── ProjectData_v.test.res
│   │           ├── ProjectManagerLogic_v.test.ast
│   │           ├── ProjectManagerLogic_v.test.bs.js
│   │           ├── ProjectManagerLogic_v.test.cmi
│   │           ├── ProjectManagerLogic_v.test.cmj
│   │           ├── ProjectManagerLogic_v.test.cmt
│   │           ├── ProjectManagerLogic_v.test.res
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
│   │           ├── ProjectionMath_v.test.ast
│   │           ├── ProjectionMath_v.test.bs.js
│   │           ├── ProjectionMath_v.test.cmi
│   │           ├── ProjectionMath_v.test.cmj
│   │           ├── ProjectionMath_v.test.cmt
│   │           ├── ProjectionMath_v.test.res
│   │           ├── QualityIndicator_v.test.ast
│   │           ├── QualityIndicator_v.test.bs.js
│   │           ├── QualityIndicator_v.test.cmi
│   │           ├── QualityIndicator_v.test.cmj
│   │           ├── QualityIndicator_v.test.cmt
│   │           ├── QualityIndicator_v.test.res
│   │           ├── ReBindings_v.test.ast
│   │           ├── ReBindings_v.test.bs.js
│   │           ├── ReBindings_v.test.cmi
│   │           ├── ReBindings_v.test.cmj
│   │           ├── ReBindings_v.test.cmt
│   │           ├── ReBindings_v.test.res
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
│   │           ├── ReturnPrompt_v.test.ast
│   │           ├── ReturnPrompt_v.test.bs.js
│   │           ├── ReturnPrompt_v.test.cmi
│   │           ├── ReturnPrompt_v.test.cmj
│   │           ├── ReturnPrompt_v.test.cmt
│   │           ├── ReturnPrompt_v.test.res
│   │           ├── RootReducer_v.test.ast
│   │           ├── RootReducer_v.test.bs.js
│   │           ├── RootReducer_v.test.cmi
│   │           ├── RootReducer_v.test.cmj
│   │           ├── RootReducer_v.test.cmt
│   │           ├── RootReducer_v.test.res
│   │           ├── SceneCache_v.test.ast
│   │           ├── SceneCache_v.test.bs.js
│   │           ├── SceneCache_v.test.cmi
│   │           ├── SceneCache_v.test.cmj
│   │           ├── SceneCache_v.test.cmt
│   │           ├── SceneCache_v.test.res
│   │           ├── SceneHelpers_v.test.ast
│   │           ├── SceneHelpers_v.test.bs.js
│   │           ├── SceneHelpers_v.test.cmi
│   │           ├── SceneHelpers_v.test.cmj
│   │           ├── SceneHelpers_v.test.cmt
│   │           ├── SceneHelpers_v.test.res
│   │           ├── SceneList_v.test.ast
│   │           ├── SceneList_v.test.bs.js
│   │           ├── SceneList_v.test.cmi
│   │           ├── SceneList_v.test.cmj
│   │           ├── SceneList_v.test.cmt
│   │           ├── SceneList_v.test.res
│   │           ├── SceneLoader_Lifecycle_Unified_v.test.ast
│   │           ├── SceneLoader_Lifecycle_Unified_v.test.bs.js
│   │           ├── SceneLoader_Lifecycle_Unified_v.test.cmi
│   │           ├── SceneLoader_Lifecycle_Unified_v.test.cmj
│   │           ├── SceneLoader_Lifecycle_Unified_v.test.cmt
│   │           ├── SceneLoader_Lifecycle_Unified_v.test.res
│   │           ├── SceneLoader_v.test.ast
│   │           ├── SceneLoader_v.test.bs.js
│   │           ├── SceneLoader_v.test.cmi
│   │           ├── SceneLoader_v.test.cmj
│   │           ├── SceneLoader_v.test.cmt
│   │           ├── SceneLoader_v.test.res
│   │           ├── SceneReducer_v.test.ast
│   │           ├── SceneReducer_v.test.bs.js
│   │           ├── SceneReducer_v.test.cmi
│   │           ├── SceneReducer_v.test.cmj
│   │           ├── SceneReducer_v.test.cmt
│   │           ├── SceneReducer_v.test.res
│   │           ├── SceneSwitcher_v.test.ast
│   │           ├── SceneSwitcher_v.test.bs.js
│   │           ├── SceneSwitcher_v.test.cmi
│   │           ├── SceneSwitcher_v.test.cmj
│   │           ├── SceneSwitcher_v.test.cmt
│   │           ├── SceneSwitcher_v.test.res
│   │           ├── SceneTransitionManager_v.test.ast
│   │           ├── SceneTransitionManager_v.test.bs.js
│   │           ├── SceneTransitionManager_v.test.cmi
│   │           ├── SceneTransitionManager_v.test.cmj
│   │           ├── SceneTransitionManager_v.test.cmt
│   │           ├── SceneTransitionManager_v.test.res
│   │           ├── Schemas_v.test.ast
│   │           ├── Schemas_v.test.bs.js
│   │           ├── Schemas_v.test.cmi
│   │           ├── Schemas_v.test.cmj
│   │           ├── Schemas_v.test.cmt
│   │           ├── Schemas_v.test.res
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
│   │           ├── SimHelpers_v.test.ast
│   │           ├── SimHelpers_v.test.bs.js
│   │           ├── SimHelpers_v.test.cmi
│   │           ├── SimHelpers_v.test.cmj
│   │           ├── SimHelpers_v.test.cmt
│   │           ├── SimHelpers_v.test.res
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
│   │           ├── SnapshotOverlay_v.test.ast
│   │           ├── SnapshotOverlay_v.test.bs.js
│   │           ├── SnapshotOverlay_v.test.cmi
│   │           ├── SnapshotOverlay_v.test.cmj
│   │           ├── SnapshotOverlay_v.test.cmt
│   │           ├── SnapshotOverlay_v.test.res
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
│   │           ├── SvgManager_v.test.ast
│   │           ├── SvgManager_v.test.bs.js
│   │           ├── SvgManager_v.test.cmi
│   │           ├── SvgManager_v.test.cmj
│   │           ├── SvgManager_v.test.cmt
│   │           ├── SvgManager_v.test.res
│   │           ├── SvgRenderer_v.test.ast
│   │           ├── SvgRenderer_v.test.bs.js
│   │           ├── SvgRenderer_v.test.cmi
│   │           ├── SvgRenderer_v.test.cmj
│   │           ├── SvgRenderer_v.test.cmt
│   │           ├── SvgRenderer_v.test.res
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
│   │           ├── TeaserPlayback_v.test.ast
│   │           ├── TeaserPlayback_v.test.bs.js
│   │           ├── TeaserPlayback_v.test.cmi
│   │           ├── TeaserPlayback_v.test.cmj
│   │           ├── TeaserPlayback_v.test.cmt
│   │           ├── TeaserPlayback_v.test.res
│   │           ├── TeaserRecorder_v.test.ast
│   │           ├── TeaserRecorder_v.test.bs.js
│   │           ├── TeaserRecorder_v.test.cmi
│   │           ├── TeaserRecorder_v.test.cmj
│   │           ├── TeaserRecorder_v.test.cmt
│   │           ├── TeaserRecorder_v.test.res
│   │           ├── TeaserState_v.test.ast
│   │           ├── TeaserState_v.test.bs.js
│   │           ├── TeaserState_v.test.cmi
│   │           ├── TeaserState_v.test.cmj
│   │           ├── TeaserState_v.test.cmt
│   │           ├── TeaserState_v.test.res
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
│   │           ├── UiHelpers_v.test.ast
│   │           ├── UiHelpers_v.test.bs.js
│   │           ├── UiHelpers_v.test.cmi
│   │           ├── UiHelpers_v.test.cmj
│   │           ├── UiHelpers_v.test.cmt
│   │           ├── UiHelpers_v.test.res
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
│   │           ├── UtilityBar_v.test.ast
│   │           ├── UtilityBar_v.test.bs.js
│   │           ├── UtilityBar_v.test.cmi
│   │           ├── UtilityBar_v.test.cmj
│   │           ├── UtilityBar_v.test.cmt
│   │           ├── UtilityBar_v.test.res
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
│   │           ├── ViewerHUD_v.test.ast
│   │           ├── ViewerHUD_v.test.bs.js
│   │           ├── ViewerHUD_v.test.cmi
│   │           ├── ViewerHUD_v.test.cmj
│   │           ├── ViewerHUD_v.test.cmt
│   │           ├── ViewerHUD_v.test.res
│   │           ├── ViewerLabelMenu_v.test.ast
│   │           ├── ViewerLabelMenu_v.test.bs.js
│   │           ├── ViewerLabelMenu_v.test.cmi
│   │           ├── ViewerLabelMenu_v.test.cmj
│   │           ├── ViewerLabelMenu_v.test.cmt
│   │           ├── ViewerLabelMenu_v.test.res
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
│   │           ├── ViewerPool_v.test.ast
│   │           ├── ViewerPool_v.test.bs.js
│   │           ├── ViewerPool_v.test.cmi
│   │           ├── ViewerPool_v.test.cmj
│   │           ├── ViewerPool_v.test.cmt
│   │           ├── ViewerPool_v.test.res
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
│   │   ├── Api.ast
│   │   ├── Api.cmi
│   │   ├── Api.cmj
│   │   ├── Api.cmt
│   │   ├── Api.res
│   │   ├── ApiLogic.ast
│   │   ├── ApiLogic.cmi
│   │   ├── ApiLogic.cmj
│   │   ├── ApiLogic.cmt
│   │   ├── ApiLogic.res
│   │   ├── ApiTypes.res
│   │   ├── ApiTypes_v.test.ast
│   │   ├── ApiTypes_v.test.cmi
│   │   ├── ApiTypes_v.test.cmj
│   │   ├── ApiTypes_v.test.cmt
│   │   ├── ApiTypes_v.test.res
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
│   │   ├── AuthenticatedClient.res
│   │   ├── AuthenticatedClient_v.test.ast
│   │   ├── AuthenticatedClient_v.test.cmi
│   │   ├── AuthenticatedClient_v.test.cmj
│   │   ├── AuthenticatedClient_v.test.cmt
│   │   ├── AuthenticatedClient_v.test.res
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
│   │   ├── Bindings_Unified_v.test.ast
│   │   ├── Bindings_Unified_v.test.cmi
│   │   ├── Bindings_Unified_v.test.cmj
│   │   ├── Bindings_Unified_v.test.cmt
│   │   ├── Bindings_Unified_v.test.res
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
│   │   ├── CursorPhysics.ast
│   │   ├── CursorPhysics.cmi
│   │   ├── CursorPhysics.cmj
│   │   ├── CursorPhysics.cmt
│   │   ├── CursorPhysics.res
│   │   ├── CursorPhysics_v.test.ast
│   │   ├── CursorPhysics_v.test.cmi
│   │   ├── CursorPhysics_v.test.cmj
│   │   ├── CursorPhysics_v.test.cmt
│   │   ├── CursorPhysics_v.test.res
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
│   │   ├── ExifReportGeneratorLogic.ast
│   │   ├── ExifReportGeneratorLogic.cmi
│   │   ├── ExifReportGeneratorLogic.cmj
│   │   ├── ExifReportGeneratorLogic.cmt
│   │   ├── ExifReportGeneratorLogic.res
│   │   ├── ExifReportGeneratorLogicExtraction_v.test.ast
│   │   ├── ExifReportGeneratorLogicExtraction_v.test.cmi
│   │   ├── ExifReportGeneratorLogicExtraction_v.test.cmj
│   │   ├── ExifReportGeneratorLogicExtraction_v.test.cmt
│   │   ├── ExifReportGeneratorLogicExtraction_v.test.res
│   │   ├── ExifReportGeneratorLogicGroups_v.test.ast
│   │   ├── ExifReportGeneratorLogicGroups_v.test.cmi
│   │   ├── ExifReportGeneratorLogicGroups_v.test.cmj
│   │   ├── ExifReportGeneratorLogicGroups_v.test.cmt
│   │   ├── ExifReportGeneratorLogicGroups_v.test.res
│   │   ├── ExifReportGeneratorLogicLocation_v.test.ast
│   │   ├── ExifReportGeneratorLogicLocation_v.test.cmi
│   │   ├── ExifReportGeneratorLogicLocation_v.test.cmj
│   │   ├── ExifReportGeneratorLogicLocation_v.test.cmt
│   │   ├── ExifReportGeneratorLogicLocation_v.test.res
│   │   ├── ExifReportGeneratorUtils_v.test.ast
│   │   ├── ExifReportGeneratorUtils_v.test.cmi
│   │   ├── ExifReportGeneratorUtils_v.test.cmj
│   │   ├── ExifReportGeneratorUtils_v.test.cmt
│   │   ├── ExifReportGeneratorUtils_v.test.res
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
│   │   ├── FinalAsyncCheck_v.test.ast
│   │   ├── FinalAsyncCheck_v.test.cmi
│   │   ├── FinalAsyncCheck_v.test.cmj
│   │   ├── FinalAsyncCheck_v.test.cmt
│   │   ├── FinalAsyncCheck_v.test.res
│   │   ├── FingerprintService.ast
│   │   ├── FingerprintService.cmi
│   │   ├── FingerprintService.cmj
│   │   ├── FingerprintService.cmt
│   │   ├── FingerprintService.res
│   │   ├── FingerprintService_v.test.ast
│   │   ├── FingerprintService_v.test.cmi
│   │   ├── FingerprintService_v.test.cmj
│   │   ├── FingerprintService_v.test.cmt
│   │   ├── FingerprintService_v.test.res
│   │   ├── FloorNavigation.ast
│   │   ├── FloorNavigation.cmi
│   │   ├── FloorNavigation.cmj
│   │   ├── FloorNavigation.cmt
│   │   ├── FloorNavigation.res
│   │   ├── FloorNavigation_v.test.ast
│   │   ├── FloorNavigation_v.test.cmi
│   │   ├── FloorNavigation_v.test.cmj
│   │   ├── FloorNavigation_v.test.cmt
│   │   ├── FloorNavigation_v.test.res
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
│   │   ├── HotspotLayer.ast
│   │   ├── HotspotLayer.cmi
│   │   ├── HotspotLayer.cmj
│   │   ├── HotspotLayer.cmt
│   │   ├── HotspotLayer.res
│   │   ├── HotspotLayer_v.test.ast
│   │   ├── HotspotLayer_v.test.cmi
│   │   ├── HotspotLayer_v.test.cmj
│   │   ├── HotspotLayer_v.test.cmt
│   │   ├── HotspotLayer_v.test.res
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
│   │   ├── HotspotMenuLayer.ast
│   │   ├── HotspotMenuLayer.cmi
│   │   ├── HotspotMenuLayer.cmj
│   │   ├── HotspotMenuLayer.cmt
│   │   ├── HotspotMenuLayer.res
│   │   ├── HotspotMenuLayer_v.test.ast
│   │   ├── HotspotMenuLayer_v.test.cmi
│   │   ├── HotspotMenuLayer_v.test.cmj
│   │   ├── HotspotMenuLayer_v.test.cmt
│   │   ├── HotspotMenuLayer_v.test.res
│   │   ├── HotspotReducer_v.test.ast
│   │   ├── HotspotReducer_v.test.cmi
│   │   ├── HotspotReducer_v.test.cmj
│   │   ├── HotspotReducer_v.test.cmt
│   │   ├── HotspotReducer_v.test.res
│   │   ├── I18n.ast
│   │   ├── I18n.cmi
│   │   ├── I18n.cmj
│   │   ├── I18n.cmt
│   │   ├── I18n.res
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
│   │   ├── ImageValidator.ast
│   │   ├── ImageValidator.cmi
│   │   ├── ImageValidator.cmj
│   │   ├── ImageValidator.cmt
│   │   ├── ImageValidator.res
│   │   ├── ImageValidator_v.test.ast
│   │   ├── ImageValidator_v.test.cmi
│   │   ├── ImageValidator_v.test.cmj
│   │   ├── ImageValidator_v.test.cmt
│   │   ├── ImageValidator_v.test.res
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
│   │   ├── LinkEditorLogic.ast
│   │   ├── LinkEditorLogic.cmi
│   │   ├── LinkEditorLogic.cmj
│   │   ├── LinkEditorLogic.cmt
│   │   ├── LinkEditorLogic.res
│   │   ├── LinkEditorLogic_v.test.ast
│   │   ├── LinkEditorLogic_v.test.cmi
│   │   ├── LinkEditorLogic_v.test.cmj
│   │   ├── LinkEditorLogic_v.test.cmt
│   │   ├── LinkEditorLogic_v.test.res
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
│   │   ├── LoggerLogic_v.test.ast
│   │   ├── LoggerLogic_v.test.cmi
│   │   ├── LoggerLogic_v.test.cmj
│   │   ├── LoggerLogic_v.test.cmt
│   │   ├── LoggerLogic_v.test.res
│   │   ├── LoggerTelemetry_v.test.ast
│   │   ├── LoggerTelemetry_v.test.cmi
│   │   ├── LoggerTelemetry_v.test.cmj
│   │   ├── LoggerTelemetry_v.test.cmt
│   │   ├── LoggerTelemetry_v.test.res
│   │   ├── LoggerTypes_v.test.ast
│   │   ├── LoggerTypes_v.test.cmi
│   │   ├── LoggerTypes_v.test.cmj
│   │   ├── LoggerTypes_v.test.cmt
│   │   ├── LoggerTypes_v.test.res
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
│   │   ├── MediaApi.res
│   │   ├── MediaApi_v.test.ast
│   │   ├── MediaApi_v.test.cmi
│   │   ├── MediaApi_v.test.cmj
│   │   ├── MediaApi_v.test.cmt
│   │   ├── MediaApi_v.test.res
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
│   │   ├── NavigationFSM.ast
│   │   ├── NavigationFSM.cmi
│   │   ├── NavigationFSM.cmj
│   │   ├── NavigationFSM.cmt
│   │   ├── NavigationFSM.res
│   │   ├── NavigationFSM_v.test.ast
│   │   ├── NavigationFSM_v.test.cmi
│   │   ├── NavigationFSM_v.test.cmj
│   │   ├── NavigationFSM_v.test.cmt
│   │   ├── NavigationFSM_v.test.res
│   │   ├── NavigationGraph.ast
│   │   ├── NavigationGraph.cmi
│   │   ├── NavigationGraph.cmj
│   │   ├── NavigationGraph.cmt
│   │   ├── NavigationGraph.res
│   │   ├── NavigationGraph_v.test.ast
│   │   ├── NavigationGraph_v.test.cmi
│   │   ├── NavigationGraph_v.test.cmj
│   │   ├── NavigationGraph_v.test.cmt
│   │   ├── NavigationGraph_v.test.res
│   │   ├── NavigationLogic.ast
│   │   ├── NavigationLogic.cmi
│   │   ├── NavigationLogic.cmj
│   │   ├── NavigationLogic.cmt
│   │   ├── NavigationLogic.res
│   │   ├── NavigationReducer_v.test.ast
│   │   ├── NavigationReducer_v.test.cmi
│   │   ├── NavigationReducer_v.test.cmj
│   │   ├── NavigationReducer_v.test.cmt
│   │   ├── NavigationReducer_v.test.res
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
│   │   ├── NotificationLayer.ast
│   │   ├── NotificationLayer.cmi
│   │   ├── NotificationLayer.cmj
│   │   ├── NotificationLayer.cmt
│   │   ├── NotificationLayer.res
│   │   ├── NotificationLayer_v.test.ast
│   │   ├── NotificationLayer_v.test.cmi
│   │   ├── NotificationLayer_v.test.cmj
│   │   ├── NotificationLayer_v.test.cmt
│   │   ├── NotificationLayer_v.test.res
│   │   ├── PannellumAdapter.ast
│   │   ├── PannellumAdapter.cmi
│   │   ├── PannellumAdapter.cmj
│   │   ├── PannellumAdapter.cmt
│   │   ├── PannellumAdapter.res
│   │   ├── PannellumAdapter_v.test.ast
│   │   ├── PannellumAdapter_v.test.cmi
│   │   ├── PannellumAdapter_v.test.cmj
│   │   ├── PannellumAdapter_v.test.cmt
│   │   ├── PannellumAdapter_v.test.res
│   │   ├── PannellumLifecycle.ast
│   │   ├── PannellumLifecycle.cmi
│   │   ├── PannellumLifecycle.cmj
│   │   ├── PannellumLifecycle.cmt
│   │   ├── PannellumLifecycle.res
│   │   ├── PannellumLifecycle_v.test.ast
│   │   ├── PannellumLifecycle_v.test.cmi
│   │   ├── PannellumLifecycle_v.test.cmj
│   │   ├── PannellumLifecycle_v.test.cmt
│   │   ├── PannellumLifecycle_v.test.res
│   │   ├── PanoramaClusterer.ast
│   │   ├── PanoramaClusterer.cmi
│   │   ├── PanoramaClusterer.cmj
│   │   ├── PanoramaClusterer.cmt
│   │   ├── PanoramaClusterer.res
│   │   ├── PanoramaClusterer_v.test.ast
│   │   ├── PanoramaClusterer_v.test.cmi
│   │   ├── PanoramaClusterer_v.test.cmj
│   │   ├── PanoramaClusterer_v.test.cmt
│   │   ├── PanoramaClusterer_v.test.res
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
│   │   ├── PersistenceLayer.ast
│   │   ├── PersistenceLayer.cmi
│   │   ├── PersistenceLayer.cmj
│   │   ├── PersistenceLayer.cmt
│   │   ├── PersistenceLayer.res
│   │   ├── PersistentLabel.ast
│   │   ├── PersistentLabel.cmi
│   │   ├── PersistentLabel.cmj
│   │   ├── PersistentLabel.cmt
│   │   ├── PersistentLabel.res
│   │   ├── PersistentLabel_v.test.ast
│   │   ├── PersistentLabel_v.test.cmi
│   │   ├── PersistentLabel_v.test.cmj
│   │   ├── PersistentLabel_v.test.cmt
│   │   ├── PersistentLabel_v.test.res
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
│   │   ├── ProjectApi_v.test.ast
│   │   ├── ProjectApi_v.test.cmi
│   │   ├── ProjectApi_v.test.cmj
│   │   ├── ProjectApi_v.test.cmt
│   │   ├── ProjectApi_v.test.res
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
│   │   ├── ProjectManagerLogic_v.test.ast
│   │   ├── ProjectManagerLogic_v.test.cmi
│   │   ├── ProjectManagerLogic_v.test.cmj
│   │   ├── ProjectManagerLogic_v.test.cmt
│   │   ├── ProjectManagerLogic_v.test.res
│   │   ├── ProjectManager_v.test.ast
│   │   ├── ProjectManager_v.test.cmi
│   │   ├── ProjectManager_v.test.cmj
│   │   ├── ProjectManager_v.test.cmt
│   │   ├── ProjectManager_v.test.res
│   │   ├── ProjectReducer_v.test.ast
│   │   ├── ProjectReducer_v.test.cmi
│   │   ├── ProjectReducer_v.test.cmj
│   │   ├── ProjectReducer_v.test.cmt
│   │   ├── ProjectReducer_v.test.res
│   │   ├── ProjectionMath.ast
│   │   ├── ProjectionMath.cmi
│   │   ├── ProjectionMath.cmj
│   │   ├── ProjectionMath.cmt
│   │   ├── ProjectionMath.res
│   │   ├── ProjectionMath_v.test.ast
│   │   ├── ProjectionMath_v.test.cmi
│   │   ├── ProjectionMath_v.test.cmj
│   │   ├── ProjectionMath_v.test.cmt
│   │   ├── ProjectionMath_v.test.res
│   │   ├── QualityIndicator.ast
│   │   ├── QualityIndicator.cmi
│   │   ├── QualityIndicator.cmj
│   │   ├── QualityIndicator.cmt
│   │   ├── QualityIndicator.res
│   │   ├── QualityIndicator_v.test.ast
│   │   ├── QualityIndicator_v.test.cmi
│   │   ├── QualityIndicator_v.test.cmj
│   │   ├── QualityIndicator_v.test.cmt
│   │   ├── QualityIndicator_v.test.res
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
│   │   ├── ReturnPrompt.ast
│   │   ├── ReturnPrompt.cmi
│   │   ├── ReturnPrompt.cmj
│   │   ├── ReturnPrompt.cmt
│   │   ├── ReturnPrompt.res
│   │   ├── ReturnPrompt_v.test.ast
│   │   ├── ReturnPrompt_v.test.cmi
│   │   ├── ReturnPrompt_v.test.cmj
│   │   ├── ReturnPrompt_v.test.cmt
│   │   ├── ReturnPrompt_v.test.res
│   │   ├── RootReducer_v.test.ast
│   │   ├── RootReducer_v.test.cmi
│   │   ├── RootReducer_v.test.cmj
│   │   ├── RootReducer_v.test.cmt
│   │   ├── RootReducer_v.test.res
│   │   ├── Scene.ast
│   │   ├── Scene.cmi
│   │   ├── Scene.cmj
│   │   ├── Scene.cmt
│   │   ├── Scene.res
│   │   ├── SceneCache.ast
│   │   ├── SceneCache.cmi
│   │   ├── SceneCache.cmj
│   │   ├── SceneCache.cmt
│   │   ├── SceneCache.res
│   │   ├── SceneCache_v.test.ast
│   │   ├── SceneCache_v.test.cmi
│   │   ├── SceneCache_v.test.cmj
│   │   ├── SceneCache_v.test.cmt
│   │   ├── SceneCache_v.test.res
│   │   ├── SceneHelpers.ast
│   │   ├── SceneHelpers.cmi
│   │   ├── SceneHelpers.cmj
│   │   ├── SceneHelpers.cmt
│   │   ├── SceneHelpers.res
│   │   ├── SceneHelpers_v.test.ast
│   │   ├── SceneHelpers_v.test.cmi
│   │   ├── SceneHelpers_v.test.cmj
│   │   ├── SceneHelpers_v.test.cmt
│   │   ├── SceneHelpers_v.test.res
│   │   ├── SceneItem.ast
│   │   ├── SceneItem.cmi
│   │   ├── SceneItem.cmj
│   │   ├── SceneItem.cmt
│   │   ├── SceneItem.res
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
│   │   ├── SceneLoader_Lifecycle_Unified_v.test.ast
│   │   ├── SceneLoader_Lifecycle_Unified_v.test.cmi
│   │   ├── SceneLoader_Lifecycle_Unified_v.test.cmj
│   │   ├── SceneLoader_Lifecycle_Unified_v.test.cmt
│   │   ├── SceneLoader_Lifecycle_Unified_v.test.res
│   │   ├── SceneLoader_v.test.ast
│   │   ├── SceneLoader_v.test.cmi
│   │   ├── SceneLoader_v.test.cmj
│   │   ├── SceneLoader_v.test.cmt
│   │   ├── SceneLoader_v.test.res
│   │   ├── SceneReducer_v.test.ast
│   │   ├── SceneReducer_v.test.cmi
│   │   ├── SceneReducer_v.test.cmj
│   │   ├── SceneReducer_v.test.cmt
│   │   ├── SceneReducer_v.test.res
│   │   ├── SceneSwitcher_v.test.ast
│   │   ├── SceneSwitcher_v.test.cmi
│   │   ├── SceneSwitcher_v.test.cmj
│   │   ├── SceneSwitcher_v.test.cmt
│   │   ├── SceneSwitcher_v.test.res
│   │   ├── SceneTransitionManager_v.test.ast
│   │   ├── SceneTransitionManager_v.test.cmi
│   │   ├── SceneTransitionManager_v.test.cmj
│   │   ├── SceneTransitionManager_v.test.cmt
│   │   ├── SceneTransitionManager_v.test.res
│   │   ├── Schemas.ast
│   │   ├── Schemas.cmi
│   │   ├── Schemas.cmj
│   │   ├── Schemas.cmt
│   │   ├── Schemas.res
│   │   ├── Schemas_v.test.ast
│   │   ├── Schemas_v.test.cmi
│   │   ├── Schemas_v.test.cmj
│   │   ├── Schemas_v.test.cmt
│   │   ├── Schemas_v.test.res
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
│   │   ├── SidebarActions.ast
│   │   ├── SidebarActions.cmi
│   │   ├── SidebarActions.cmj
│   │   ├── SidebarActions.cmt
│   │   ├── SidebarActions.res
│   │   ├── SidebarBranding.ast
│   │   ├── SidebarBranding.cmi
│   │   ├── SidebarBranding.cmj
│   │   ├── SidebarBranding.cmt
│   │   ├── SidebarBranding.res
│   │   ├── SidebarLogic.ast
│   │   ├── SidebarLogic.cmi
│   │   ├── SidebarLogic.cmj
│   │   ├── SidebarLogic.cmt
│   │   ├── SidebarLogic.res
│   │   ├── SidebarProcessing.ast
│   │   ├── SidebarProcessing.cmi
│   │   ├── SidebarProcessing.cmj
│   │   ├── SidebarProcessing.cmt
│   │   ├── SidebarProcessing.res
│   │   ├── SidebarProjectInfo.ast
│   │   ├── SidebarProjectInfo.cmi
│   │   ├── SidebarProjectInfo.cmj
│   │   ├── SidebarProjectInfo.cmt
│   │   ├── SidebarProjectInfo.res
│   │   ├── Sidebar_v.test.ast
│   │   ├── Sidebar_v.test.cmi
│   │   ├── Sidebar_v.test.cmj
│   │   ├── Sidebar_v.test.cmt
│   │   ├── Sidebar_v.test.res
│   │   ├── SimHelpers.ast
│   │   ├── SimHelpers.cmi
│   │   ├── SimHelpers.cmj
│   │   ├── SimHelpers.cmt
│   │   ├── SimHelpers.res
│   │   ├── SimHelpers_v.test.ast
│   │   ├── SimHelpers_v.test.cmi
│   │   ├── SimHelpers_v.test.cmj
│   │   ├── SimHelpers_v.test.cmt
│   │   ├── SimHelpers_v.test.res
│   │   ├── Simulation.ast
│   │   ├── Simulation.cmi
│   │   ├── Simulation.cmj
│   │   ├── Simulation.cmt
│   │   ├── Simulation.res
│   │   ├── SimulationChainSkipper_v.test.ast
│   │   ├── SimulationChainSkipper_v.test.cmi
│   │   ├── SimulationChainSkipper_v.test.cmj
│   │   ├── SimulationChainSkipper_v.test.cmt
│   │   ├── SimulationChainSkipper_v.test.res
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
│   │   ├── SimulationNavigation_v.test.ast
│   │   ├── SimulationNavigation_v.test.cmi
│   │   ├── SimulationNavigation_v.test.cmj
│   │   ├── SimulationNavigation_v.test.cmt
│   │   ├── SimulationNavigation_v.test.res
│   │   ├── SimulationPathGenerator_v.test.ast
│   │   ├── SimulationPathGenerator_v.test.cmi
│   │   ├── SimulationPathGenerator_v.test.cmj
│   │   ├── SimulationPathGenerator_v.test.cmt
│   │   ├── SimulationPathGenerator_v.test.res
│   │   ├── SimulationReducer_v.test.ast
│   │   ├── SimulationReducer_v.test.cmi
│   │   ├── SimulationReducer_v.test.cmj
│   │   ├── SimulationReducer_v.test.cmt
│   │   ├── SimulationReducer_v.test.res
│   │   ├── SnapshotOverlay.ast
│   │   ├── SnapshotOverlay.cmi
│   │   ├── SnapshotOverlay.cmj
│   │   ├── SnapshotOverlay.cmt
│   │   ├── SnapshotOverlay.res
│   │   ├── SnapshotOverlay_v.test.ast
│   │   ├── SnapshotOverlay_v.test.cmi
│   │   ├── SnapshotOverlay_v.test.cmj
│   │   ├── SnapshotOverlay_v.test.cmt
│   │   ├── SnapshotOverlay_v.test.res
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
│   │   ├── SvgManager_v.test.ast
│   │   ├── SvgManager_v.test.cmi
│   │   ├── SvgManager_v.test.cmj
│   │   ├── SvgManager_v.test.cmt
│   │   ├── SvgManager_v.test.res
│   │   ├── SvgRenderer_v.test.ast
│   │   ├── SvgRenderer_v.test.cmi
│   │   ├── SvgRenderer_v.test.cmj
│   │   ├── SvgRenderer_v.test.cmt
│   │   ├── SvgRenderer_v.test.res
│   │   ├── Teaser.ast
│   │   ├── Teaser.cmi
│   │   ├── Teaser.cmj
│   │   ├── Teaser.cmt
│   │   ├── Teaser.res
│   │   ├── TeaserLogic.ast
│   │   ├── TeaserLogic.cmi
│   │   ├── TeaserLogic.cmj
│   │   ├── TeaserLogic.cmt
│   │   ├── TeaserLogic.res
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
│   │   ├── TeaserPlayback_v.test.ast
│   │   ├── TeaserPlayback_v.test.cmi
│   │   ├── TeaserPlayback_v.test.cmj
│   │   ├── TeaserPlayback_v.test.cmt
│   │   ├── TeaserPlayback_v.test.res
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
│   │   ├── TeaserState.ast
│   │   ├── TeaserState.cmi
│   │   ├── TeaserState.cmj
│   │   ├── TeaserState.cmt
│   │   ├── TeaserState.res
│   │   ├── TeaserState_v.test.ast
│   │   ├── TeaserState_v.test.cmi
│   │   ├── TeaserState_v.test.cmj
│   │   ├── TeaserState_v.test.cmt
│   │   ├── TeaserState_v.test.res
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
│   │   ├── TourTemplateAssets_v.test.ast
│   │   ├── TourTemplateAssets_v.test.cmi
│   │   ├── TourTemplateAssets_v.test.cmj
│   │   ├── TourTemplateAssets_v.test.cmt
│   │   ├── TourTemplateAssets_v.test.res
│   │   ├── TourTemplateScripts_v.test.ast
│   │   ├── TourTemplateScripts_v.test.cmi
│   │   ├── TourTemplateScripts_v.test.cmj
│   │   ├── TourTemplateScripts_v.test.cmt
│   │   ├── TourTemplateScripts_v.test.res
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
│   │   ├── UiHelpers.ast
│   │   ├── UiHelpers.cmi
│   │   ├── UiHelpers.cmj
│   │   ├── UiHelpers.cmt
│   │   ├── UiHelpers.res
│   │   ├── UiHelpers_v.test.ast
│   │   ├── UiHelpers_v.test.cmi
│   │   ├── UiHelpers_v.test.cmj
│   │   ├── UiHelpers_v.test.cmt
│   │   ├── UiHelpers_v.test.res
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
│   │   ├── UploadProcessorLogic_v.test.ast
│   │   ├── UploadProcessorLogic_v.test.cmi
│   │   ├── UploadProcessorLogic_v.test.cmj
│   │   ├── UploadProcessorLogic_v.test.cmt
│   │   ├── UploadProcessorLogic_v.test.res
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
│   │   ├── UploadTypes.ast
│   │   ├── UploadTypes.cmi
│   │   ├── UploadTypes.cmj
│   │   ├── UploadTypes.cmt
│   │   ├── UploadTypes.res
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
│   │   ├── UtilityBar.ast
│   │   ├── UtilityBar.cmi
│   │   ├── UtilityBar.cmj
│   │   ├── UtilityBar.cmt
│   │   ├── UtilityBar.res
│   │   ├── UtilityBar_v.test.ast
│   │   ├── UtilityBar_v.test.cmi
│   │   ├── UtilityBar_v.test.cmj
│   │   ├── UtilityBar_v.test.cmt
│   │   ├── UtilityBar_v.test.res
│   │   ├── Version.ast
│   │   ├── Version.cmi
│   │   ├── Version.cmj
│   │   ├── Version.cmt
│   │   ├── Version.res
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
│   │   ├── ViewerDriver.ast
│   │   ├── ViewerDriver.cmi
│   │   ├── ViewerDriver.cmj
│   │   ├── ViewerDriver.cmt
│   │   ├── ViewerDriver.res
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
│   │   ├── ViewerHUD.ast
│   │   ├── ViewerHUD.cmi
│   │   ├── ViewerHUD.cmj
│   │   ├── ViewerHUD.cmt
│   │   ├── ViewerHUD.res
│   │   ├── ViewerHUD_v.test.ast
│   │   ├── ViewerHUD_v.test.cmi
│   │   ├── ViewerHUD_v.test.cmj
│   │   ├── ViewerHUD_v.test.cmt
│   │   ├── ViewerHUD_v.test.res
│   │   ├── ViewerLabelMenu.ast
│   │   ├── ViewerLabelMenu.cmi
│   │   ├── ViewerLabelMenu.cmj
│   │   ├── ViewerLabelMenu.cmt
│   │   ├── ViewerLabelMenu.res
│   │   ├── ViewerLabelMenu_v.test.ast
│   │   ├── ViewerLabelMenu_v.test.cmi
│   │   ├── ViewerLabelMenu_v.test.cmj
│   │   ├── ViewerLabelMenu_v.test.cmt
│   │   ├── ViewerLabelMenu_v.test.res
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
│   │   ├── ViewerLogic.ast
│   │   ├── ViewerLogic.cmi
│   │   ├── ViewerLogic.cmj
│   │   ├── ViewerLogic.cmt
│   │   ├── ViewerLogic.res
│   │   ├── ViewerManager.ast
│   │   ├── ViewerManager.cmi
│   │   ├── ViewerManager.cmj
│   │   ├── ViewerManager.cmt
│   │   ├── ViewerManager.res
│   │   ├── ViewerManagerLifecycle.ast
│   │   ├── ViewerManagerLifecycle.cmi
│   │   ├── ViewerManagerLifecycle.cmj
│   │   ├── ViewerManagerLifecycle.cmt
│   │   ├── ViewerManagerLifecycle.res
│   │   ├── ViewerManagerLogic.ast
│   │   ├── ViewerManagerLogic.cmi
│   │   ├── ViewerManagerLogic.cmj
│   │   ├── ViewerManagerLogic.cmt
│   │   ├── ViewerManagerLogic.res
│   │   ├── ViewerManager_v.test.ast
│   │   ├── ViewerManager_v.test.cmi
│   │   ├── ViewerManager_v.test.cmj
│   │   ├── ViewerManager_v.test.cmt
│   │   ├── ViewerManager_v.test.res
│   │   ├── ViewerPool.ast
│   │   ├── ViewerPool.cmi
│   │   ├── ViewerPool.cmj
│   │   ├── ViewerPool.cmt
│   │   ├── ViewerPool.res
│   │   ├── ViewerPool_v.test.ast
│   │   ├── ViewerPool_v.test.cmi
│   │   ├── ViewerPool_v.test.cmj
│   │   ├── ViewerPool_v.test.cmt
│   │   ├── ViewerPool_v.test.res
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
│   │   ├── ViewerSystem.ast
│   │   ├── ViewerSystem.cmi
│   │   ├── ViewerSystem.cmj
│   │   ├── ViewerSystem.cmt
│   │   ├── ViewerSystem.res
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
│   │   ├── VisualPipelineStyles.ast
│   │   ├── VisualPipelineStyles.cmi
│   │   ├── VisualPipelineStyles.cmj
│   │   ├── VisualPipelineStyles.cmt
│   │   ├── VisualPipelineStyles.res
│   │   ├── VisualPipeline_v.test.ast
│   │   ├── VisualPipeline_v.test.cmi
│   │   ├── VisualPipeline_v.test.cmj
│   │   ├── VisualPipeline_v.test.cmt
│   │   ├── VisualPipeline_v.test.res
│   │   ├── VitestSmoke.test.ast
│   │   ├── VitestSmoke.test.cmi
│   │   ├── VitestSmoke.test.cmj
│   │   ├── VitestSmoke.test.cmt
│   │   └── VitestSmoke.test.res
│   └── rescript.lock
├── logs
│   ├── error.log
│   ├── log_changes.txt
│   └── project-guard.log
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
│   ├── robots.txt
│   ├── service-worker.js
│   └── sounds
│       └── click.wav
├── rescript.json
├── rsbuild.config.mjs
├── scripts
│   ├── bump-version.js
│   ├── cleanup_logs.sh
│   ├── commit.sh
│   ├── debug-connectivity.js
│   ├── dev-system.sh
│   ├── fast-commit.sh
│   ├── generate-test-tasks.cjs.deprecated
│   ├── increment-build.js
│   ├── pre-push.sh
│   ├── project-guard.sh
│   ├── prune-snapshots.sh
│   ├── restore-snapshot.sh
│   ├── setup.sh
│   ├── sync-sw.cjs
│   ├── test-logging.js
│   ├── triple-commit.sh
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
│   │   ├── FloorNavigation.bs.js
│   │   ├── FloorNavigation.res
│   │   ├── HotspotActionMenu.bs.js
│   │   ├── HotspotActionMenu.res
│   │   ├── HotspotLayer.bs.js
│   │   ├── HotspotLayer.res
│   │   ├── HotspotManager.bs.js
│   │   ├── HotspotManager.res
│   │   ├── HotspotMenuLayer.bs.js
│   │   ├── HotspotMenuLayer.res
│   │   ├── LabelMenu.bs.js
│   │   ├── LabelMenu.res
│   │   ├── LinkModal.bs.js
│   │   ├── LinkModal.res
│   │   ├── ModalContext.bs.js
│   │   ├── ModalContext.res
│   │   ├── NotificationContext.bs.js
│   │   ├── NotificationContext.res
│   │   ├── NotificationLayer.bs.js
│   │   ├── NotificationLayer.res
│   │   ├── PersistentLabel.bs.js
│   │   ├── PersistentLabel.res
│   │   ├── PopOver.bs.js
│   │   ├── PopOver.res
│   │   ├── Portal.bs.js
│   │   ├── Portal.res
│   │   ├── PreviewArrow.bs.js
│   │   ├── PreviewArrow.res
│   │   ├── QualityIndicator.bs.js
│   │   ├── QualityIndicator.res
│   │   ├── ReturnPrompt.bs.js
│   │   ├── ReturnPrompt.res
│   │   ├── SceneList
│   │   │   ├── SceneItem.bs.js
│   │   │   └── SceneItem.res
│   │   ├── SceneList.bs.js
│   │   ├── SceneList.res
│   │   ├── Sidebar
│   │   │   ├── SidebarActions.bs.js
│   │   │   ├── SidebarActions.res
│   │   │   ├── SidebarBranding.bs.js
│   │   │   ├── SidebarBranding.res
│   │   │   ├── SidebarLogic.bs.js
│   │   │   ├── SidebarLogic.res
│   │   │   ├── SidebarProcessing.bs.js
│   │   │   ├── SidebarProcessing.res
│   │   │   ├── SidebarProjectInfo.bs.js
│   │   │   └── SidebarProjectInfo.res
│   │   ├── Sidebar.bs.js
│   │   ├── Sidebar.res
│   │   ├── SnapshotOverlay.bs.js
│   │   ├── SnapshotOverlay.res
│   │   ├── Tooltip.bs.js
│   │   ├── Tooltip.res
│   │   ├── UploadReport.bs.js
│   │   ├── UploadReport.res
│   │   ├── UtilityBar.bs.js
│   │   ├── UtilityBar.res
│   │   ├── ViewerHUD.bs.js
│   │   ├── ViewerHUD.res
│   │   ├── ViewerLabelMenu.bs.js
│   │   ├── ViewerLabelMenu.res
│   │   ├── ViewerLoader.bs.js
│   │   ├── ViewerLoader.res
│   │   ├── ViewerManager
│   │   │   ├── ViewerManagerLifecycle.bs.js
│   │   │   └── ViewerManagerLifecycle.res
│   │   ├── ViewerManager.bs.js
│   │   ├── ViewerManager.res
│   │   ├── ViewerManagerLogic.bs.js
│   │   ├── ViewerManagerLogic.res
│   │   ├── ViewerSnapshot.bs.js
│   │   ├── ViewerSnapshot.res
│   │   ├── ViewerUI.bs.js
│   │   ├── ViewerUI.res
│   │   ├── VisualPipeline
│   │   │   ├── VisualPipelineStyles.bs.js
│   │   │   └── VisualPipelineStyles.res
│   │   ├── VisualPipeline.bs.js
│   │   ├── VisualPipeline.res
│   │   └── ui
│   │       ├── LucideIcons.bs.js
│   │       ├── LucideIcons.res
│   │       ├── Shadcn.bs.js
│   │       ├── Shadcn.res
│   │       ├── button.jsx
│   │       ├── checkbox.jsx
│   │       ├── context-menu.jsx
│   │       ├── dropdown-menu.jsx
│   │       ├── input.jsx
│   │       ├── label.jsx
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
│   │   ├── Reducer.bs.js
│   │   ├── Reducer.res
│   │   ├── SceneCache.bs.js
│   │   ├── SceneCache.res
│   │   ├── SceneHelpers.bs.js
│   │   ├── SceneHelpers.res
│   │   ├── Schemas.bs.js
│   │   ├── Schemas.res
│   │   ├── SharedTypes.bs.js
│   │   ├── SharedTypes.res
│   │   ├── SimHelpers.bs.js
│   │   ├── SimHelpers.res
│   │   ├── State.bs.js
│   │   ├── State.res
│   │   ├── Types.bs.js
│   │   ├── Types.res
│   │   ├── UiHelpers.bs.js
│   │   ├── UiHelpers.res
│   │   ├── ViewerState.bs.js
│   │   ├── ViewerState.res
│   │   ├── ViewerTypes.bs.js
│   │   ├── ViewerTypes.res
│   │   └── interfaces
│   │       ├── ViewerDriver.bs.js
│   │       └── ViewerDriver.res
│   ├── i18n
│   │   ├── I18n.bs.js
│   │   ├── I18n.res
│   │   └── locales
│   │       ├── en.json
│   │       └── es.json
│   ├── index.js
│   ├── lib
│   │   └── utils.js
│   ├── systems
│   │   ├── Api
│   │   ├── Api.bs.js
│   │   ├── Api.res
│   │   ├── ApiLogic.bs.js
│   │   ├── ApiLogic.res
│   │   ├── AudioManager.bs.js
│   │   ├── AudioManager.res
│   │   ├── BackendApi.bs.js
│   │   ├── BackendApi.res
│   │   ├── CursorPhysics.bs.js
│   │   ├── CursorPhysics.res
│   │   ├── DownloadSystem.bs.js
│   │   ├── DownloadSystem.res
│   │   ├── EventBus.bs.js
│   │   ├── EventBus.res
│   │   ├── ExifParser.bs.js
│   │   ├── ExifParser.res
│   │   ├── ExifReportGenerator.bs.js
│   │   ├── ExifReportGenerator.res
│   │   ├── ExifReportGeneratorLogic.bs.js
│   │   ├── ExifReportGeneratorLogic.res
│   │   ├── Exporter.bs.js
│   │   ├── Exporter.res
│   │   ├── FingerprintService.bs.js
│   │   ├── FingerprintService.res
│   │   ├── HotspotLine.bs.js
│   │   ├── HotspotLine.res
│   │   ├── HotspotLineLogic.bs.js
│   │   ├── HotspotLineLogic.res
│   │   ├── ImageValidator.bs.js
│   │   ├── ImageValidator.res
│   │   ├── InputSystem.bs.js
│   │   ├── InputSystem.res
│   │   ├── LinkEditorLogic.bs.js
│   │   ├── LinkEditorLogic.res
│   │   ├── Navigation.bs.js
│   │   ├── Navigation.res
│   │   ├── NavigationFSM.bs.js
│   │   ├── NavigationFSM.res
│   │   ├── NavigationGraph.bs.js
│   │   ├── NavigationGraph.res
│   │   ├── NavigationLogic.bs.js
│   │   ├── NavigationLogic.res
│   │   ├── PannellumAdapter.bs.js
│   │   ├── PannellumAdapter.res
│   │   ├── PannellumLifecycle.bs.js
│   │   ├── PannellumLifecycle.res
│   │   ├── PanoramaClusterer.bs.js
│   │   ├── PanoramaClusterer.res
│   │   ├── ProjectData.bs.js
│   │   ├── ProjectData.res
│   │   ├── ProjectManager.bs.js
│   │   ├── ProjectManager.res
│   │   ├── Resizer.bs.js
│   │   ├── Resizer.res
│   │   ├── Scene.bs.js
│   │   ├── Scene.res
│   │   ├── ServerTeaser.bs.js
│   │   ├── ServerTeaser.res
│   │   ├── Simulation.bs.js
│   │   ├── Simulation.res
│   │   ├── SimulationLogic.bs.js
│   │   ├── SimulationLogic.res
│   │   ├── SvgManager.bs.js
│   │   ├── SvgManager.res
│   │   ├── Teaser.bs.js
│   │   ├── Teaser.res
│   │   ├── TeaserLogic.bs.js
│   │   ├── TeaserLogic.res
│   │   ├── TeaserManager.bs.js
│   │   ├── TeaserManager.res
│   │   ├── TeaserPathfinder.bs.js
│   │   ├── TeaserPathfinder.res
│   │   ├── TeaserRecorder.bs.js
│   │   ├── TeaserRecorder.res
│   │   ├── TeaserState.bs.js
│   │   ├── TeaserState.res
│   │   ├── TourTemplates.bs.js
│   │   ├── TourTemplates.res
│   │   ├── UploadProcessor.bs.js
│   │   ├── UploadProcessor.res
│   │   ├── UploadTypes.bs.js
│   │   ├── UploadTypes.res
│   │   ├── VideoEncoder.bs.js
│   │   ├── VideoEncoder.res
│   │   ├── ViewerFollow.bs.js
│   │   ├── ViewerFollow.res
│   │   ├── ViewerLogic.bs.js
│   │   ├── ViewerLogic.res
│   │   ├── ViewerPool.bs.js
│   │   ├── ViewerPool.res
│   │   ├── ViewerSystem.bs.js
│   │   └── ViewerSystem.res
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
│       ├── PersistenceLayer.bs.js
│       ├── PersistenceLayer.res
│       ├── ProgressBar.bs.js
│       ├── ProgressBar.res
│       ├── ProjectionMath.bs.js
│       ├── ProjectionMath.res
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
│       └── Version.res
├── start_prod.sh
├── stripped_sidebar.res
├── stripped_sidebar_fixed.res
├── tailwind.config.js
├── tasks
│   ├── TASKS.md
│   ├── active
│   ├── completed
│   │   ├── 003_Aggregate_Completed_Tasks_DONE.md
│   │   ├── 1004_Refactor_HotspotLineLogic_DONE.md
│   │   ├── 1041_Refactor_UploadProcessorLogicLogic_DONE.md
│   │   ├── 1063_Classify_Map_Entries_DONE.md
│   │   ├── 1064_Refactor_Schemas_DONE.md
│   │   ├── 1069_Classify_Ambiguous_Files_Headers_DONE.md
│   │   ├── 1070_Fix_Critical_Violations_DONE.md
│   │   ├── 1074_Migrate_JS_Guard_to_Rust_DONE.md
│   │   ├── 1075_Classify_Map_Entries_DONE.md
│   │   ├── 1076_Classify_Ambiguous_Files_DONE.md
│   │   ├── 1077_Structural_Refactor_BACKEND_DONE.md
│   │   ├── 1078_Fix_Violations_FRONTEND_DONE.md
│   │   ├── 1079_Fix_Violations_BACKEND_DONE.md
│   │   ├── 1080_Surgical_Refactor_CORE_FRONTEND_DONE.md
│   │   ├── 1081_Surgical_Refactor_SYSTEMS_FRONTEND_DONE.md
│   │   ├── 1082_Surgical_Refactor_COMPONENTS_FRONTEND_DONE.md
│   │   ├── 1083_Surgical_Refactor_UTILS_FRONTEND_DONE.md
│   │   ├── 1084_Surgical_Refactor_API_BACKEND_DONE.md
│   │   ├── 1085_Surgical_Refactor_MEDIA_BACKEND_DONE.md
│   │   ├── 1095_Classify_Ambiguous_Files_DONE.md
│   │   ├── 1097_Perfect_Dev_System_Analyzer.md
│   │   ├── 1104_refine_dev_system_analyzer_maintenance.md
│   │   ├── 1105_Surgical_Refactor_SYSTEMS_FRONTEND_DONE.md
│   │   ├── 1108_Surgical_Refactor_COMPONENTS_FRONTEND_DONE.md
│   │   ├── 1111_Surgical_Refactor_MEDIA_BACKEND_DONE.md
│   │   ├── 1112_Surgical_Refactor_SRC_BACKEND_DONE.md
│   │   ├── 1113_Merge_Folders_BACKEND_DONE.md
│   │   ├── 1114_Surgical_Refactor_SYSTEMS_FRONTEND_DONE.md
│   │   ├── 1116_Classify_Map_Entries_DONE.md
│   │   ├── 1117_Deep_Audit_and_Process_Enhancement.md
│   │   ├── 1118_Classify_Ambiguous_Files_DONE.md
│   │   ├── 1119_Surgical_Refactor_COMPONENTS_FRONTEND_DONE.md
│   │   ├── 1120_Surgical_Refactor_SYSTEMS_FRONTEND_DONE.md
│   │   ├── 1122_Classify_Map_Entries_DONE.md
│   │   ├── 1123_Comprehensive_DevSystem_Analyzer_Overhaul_DONE.md
│   │   ├── 1124_Complete_ReScript_JSX_Auto_Discovery_Implementation_DONE.md
│   │   ├── 1125_Fix_Violations_FRONTEND_DONE.md
│   │   ├── 1126_Upgrade_Dev_System_Semantic_Engine_DONE.md
│   │   ├── 1131_Surgical_Refactor_SRC_BACKEND_DONE.md
│   │   ├── 1132_Surgical_Refactor_MEDIA_BACKEND_DONE.md
│   │   ├── 1133_Surgical_Refactor_API_BACKEND_DONE.md
│   │   ├── 1135_Surgical_Refactor_SERVICES_BACKEND_DONE.md
│   │   ├── 1136_Surgical_Refactor_PATHFINDER_BACKEND_DONE.md
│   │   ├── 1138_Merge_Folders_FRONTEND_DONE.md
│   │   ├── 1139_Classify_Map_Entries_DONE.md
│   │   ├── 1140_Surgical_Refactor_MEDIA_BACKEND_DONE.md
│   │   ├── 1141_Surgical_Refactor_API_BACKEND_DONE.md
│   │   ├── 1142_Surgical_Refactor_SRC_BACKEND_DONE.md
│   │   ├── 1143_Surgical_Refactor_SERVICES_BACKEND_DONE.md
│   │   ├── 1144_Surgical_Refactor_PATHFINDER_BACKEND_DONE.md
│   │   ├── 795_Refactor_analysis_DONE.md
│   │   ├── 798_Refactor_Backend_Streaming_ZIP_DONE.md
│   │   ├── 799_Refactor_Backend_Asset_Sanitization_DONE.md
│   │   ├── 801_Test_Logger_System_Unified_TESTED.md
│   │   ├── 802_Test_ExifReport_Pipeline_Unified.md
│   │   ├── 803_Test_SceneLoader_Lifecycle_Unified.md
│   │   ├── 804_Test_Sidebar_Components_Unified.md
│   │   ├── 805_Test_VisualPipeline_System_Unified.md
│   │   ├── 806_Test_Bindings_Unified.md
│   │   ├── 807_Test_Simulation_Autopilot_Unified.md
│   │   ├── 808_Test_Navigation_Graph_Unified.md
│   │   ├── 809_Test_Teaser_System_Unified.md
│   │   ├── 810_Test_Tour_Templates_Unified.md
│   │   ├── 811_Test_Hotspots_Unified.md
│   │   ├── 812_Test_Viewer_Core_Unified.md
│   │   ├── 813_Test_Project_Persistence_Unified.md
│   │   ├── 814_Test_UI_Components_Unified.md
│   │   ├── 815_Test_Lucide_Icons_Unified.md
│   │   ├── 816_Test_Utilities_Unified.md
│   │   ├── 817_Test_App_Core_Infrastructure_Unified.md
│   │   ├── 818_Test_Media_Services_Unified.md
│   │   ├── 819_Test_Core_Reducers_Unified.md
│   │   ├── 820_Test_Visuals_Remaining_Unified.md
│   │   ├── 821_Aggregate_Completed_Tasks_DONE.md
│   │   ├── 856_Refactor_ViewerManager_DONE.md
│   │   ├── 894_Refactor_HotspotLine_DONE.md
│   │   ├── 901_migration_foundation_DONE.md
│   │   ├── 902_migration_security_DONE.md
│   │   ├── 903_migration_storage_DONE.md
│   │   ├── 904_migration_frontend_auth_DONE.md
│   │   ├── 929_Refactor_UploadProcessorLogic_DONE.md
│   │   ├── 965_Refactor_ViewerManagerLogic_DONE.md
│   │   ├── _CONCISE_SUMMARY.md
│   │   ├── analysis_1067_schema_fixes.md
│   │   ├── task_598_reduce_magic_REPORT.md
│   │   ├── task_599_backend_tests_REPORT.md
│   │   ├── task_602_feature_persistence_layer_DONE.md
│   │   └── tests
│   │       ├── 598_Test_SceneCache_New.md
│   │       ├── 599_Test_SceneHelpers_Update.md
│   │       └── 600_Test_ViewerSnapshot_Update.md
│   ├── pending
│   │   ├── 1127_Surgical_Refactor_CORE_FRONTEND.md
│   │   ├── 1128_Surgical_Refactor_UTILS_FRONTEND.md
│   │   ├── 1130_Surgical_Refactor_SRC_FRONTEND.md
│   │   ├── 1137_Surgical_Refactor_SYSTEMS_FRONTEND.md
│   │   ├── 1145_Surgical_Refactor_API_BACKEND.md
│   │   ├── 1146_Surgical_Refactor_PATHFINDER_BACKEND.md
│   │   ├── 1147_Surgical_Refactor_SERVICES_BACKEND.md
│   │   ├── 1148_Surgical_Refactor_SRC_BACKEND.md
│   │   ├── 1149_Surgical_Refactor_MEDIA_BACKEND.md
│   │   └── tests
│   └── postponed
│       ├── 900_COMMERCIAL_MIGRATION_MASTER.md
│       └── 905_migration_telemetry.md
├── test_output.txt
├── test_results.txt
├── test_results_2.txt
├── tests
│   ├── TestRunner.bs.js
│   ├── TestRunner.res
│   ├── jsx-loader.mjs
│   ├── node-setup.js
│   ├── rescript-schema-shim.js
│   └── unit
│       ├── ActionsTest.bs.js
│       ├── Actions_v.test.bs.js
│       ├── Actions_v.test.res
│       ├── ApiTypes_v.test.bs.js
│       ├── ApiTypes_v.test.res
│       ├── AppContext_v.test.bs.js
│       ├── AppContext_v.test.res
│       ├── AppErrorBoundary_v.test.bs.js
│       ├── AppErrorBoundary_v.test.res
│       ├── App_v.test.bs.js
│       ├── App_v.test.res
│       ├── AsyncDebug_v.test.bs.js
│       ├── AudioManager_v.test.bs.js
│       ├── AudioManager_v.test.res
│       ├── AuthenticatedClient_v.test.bs.js
│       ├── AuthenticatedClient_v.test.res
│       ├── BackendApi_v.test.bs.js
│       ├── BackendApi_v.test.res
│       ├── Bindings_Unified_v.test.bs.js
│       ├── Bindings_Unified_v.test.res
│       ├── ColorPalette_v.test.bs.js
│       ├── ColorPalette_v.test.res
│       ├── Components_v.test.setup.jsx
│       ├── Constants_v.test.bs.js
│       ├── Constants_v.test.res
│       ├── CursorPhysics_v.test.bs.js
│       ├── CursorPhysics_v.test.res
│       ├── DownloadSystem_v.test.bs.js
│       ├── DownloadSystem_v.test.res
│       ├── ErrorFallbackUI_v.test.bs.js
│       ├── ErrorFallbackUI_v.test.res
│       ├── EventBusTest.bs.js
│       ├── EventBus_v.test.bs.js
│       ├── EventBus_v.test.res
│       ├── ExifParser_v.test.bs.js
│       ├── ExifParser_v.test.res
│       ├── ExifReportGeneratorLogicExtraction_v.test.bs.js
│       ├── ExifReportGeneratorLogicExtraction_v.test.res
│       ├── ExifReportGeneratorLogicGroups_v.test.bs.js
│       ├── ExifReportGeneratorLogicGroups_v.test.res
│       ├── ExifReportGeneratorLogicLocation_v.test.bs.js
│       ├── ExifReportGeneratorLogicLocation_v.test.res
│       ├── ExifReportGeneratorUtils_v.test.bs.js
│       ├── ExifReportGeneratorUtils_v.test.res
│       ├── ExifReportGenerator_v.test.bs.js
│       ├── ExifReportGenerator_v.test.res
│       ├── Exporter_v.test.bs.js
│       ├── Exporter_v.test.res
│       ├── FinalAsyncCheck_v.test.bs.js
│       ├── FinalAsyncCheck_v.test.res
│       ├── FingerprintService_v.test.bs.js
│       ├── FingerprintService_v.test.res
│       ├── FloorNavigation_v.test.bs.js
│       ├── FloorNavigation_v.test.res
│       ├── GeoUtils_v.test.bs.js
│       ├── GeoUtils_v.test.res
│       ├── GlobalStateBridgeTest.bs.js
│       ├── GlobalStateBridge_v.test.bs.js
│       ├── GlobalStateBridge_v.test.res
│       ├── HotspotActionMenu_v.test.bs.js
│       ├── HotspotActionMenu_v.test.res
│       ├── HotspotLayer_v.test.bs.js
│       ├── HotspotLayer_v.test.res
│       ├── HotspotLineLogic_v.test.bs.js
│       ├── HotspotLineLogic_v.test.res
│       ├── HotspotLineTypes_v.test.bs.js
│       ├── HotspotLineTypes_v.test.res
│       ├── HotspotLine_v.test.bs.js
│       ├── HotspotLine_v.test.res
│       ├── HotspotLine_v.test.setup.js
│       ├── HotspotManager_v.test.bs.js
│       ├── HotspotManager_v.test.res
│       ├── HotspotMenuLayer_v.test.bs.js
│       ├── HotspotMenuLayer_v.test.res
│       ├── HotspotReducer_v.test.bs.js
│       ├── HotspotReducer_v.test.res
│       ├── ImageOptimizer_v.test.bs.js
│       ├── ImageOptimizer_v.test.res
│       ├── ImageValidator_v.test.bs.js
│       ├── ImageValidator_v.test.res
│       ├── InputSystem_v.test.bs.js
│       ├── InputSystem_v.test.res
│       ├── InteractionsRobustness_v.test.bs.js
│       ├── InteractionsRobustness_v.test.res
│       ├── LabelMenu_v.test.bs.js
│       ├── LabelMenu_v.test.res
│       ├── LabelMenu_v.test.setup.jsx
│       ├── LazyLoad_v.test.bs.js
│       ├── LazyLoad_v.test.res
│       ├── LinkEditorLogic_v.test.bs.js
│       ├── LinkEditorLogic_v.test.res
│       ├── LinkModal_v.test.bs.js
│       ├── LinkModal_v.test.res
│       ├── LoggerLogic_v.test.bs.js
│       ├── LoggerLogic_v.test.res
│       ├── LoggerTelemetry_v.test.bs.js
│       ├── LoggerTelemetry_v.test.res
│       ├── LoggerTypes_v.test.bs.js
│       ├── LoggerTypes_v.test.res
│       ├── Logger_v.test.bs.js
│       ├── Logger_v.test.res
│       ├── LucideIcons_v.test.bs.js
│       ├── LucideIcons_v.test.res
│       ├── Main_v.test.bs.js
│       ├── Main_v.test.res
│       ├── MediaApi_v.test.bs.js
│       ├── MediaApi_v.test.res
│       ├── Mod_v.test.bs.js
│       ├── Mod_v.test.res
│       ├── ModalContext_v.test.bs.js
│       ├── ModalContext_v.test.res
│       ├── NavigationFSM_v.test.bs.js
│       ├── NavigationFSM_v.test.res
│       ├── NavigationGraph_v.test.bs.js
│       ├── NavigationGraph_v.test.res
│       ├── NavigationReducer_v.test.bs.js
│       ├── NavigationReducer_v.test.res
│       ├── NotificationContext_v.test.bs.js
│       ├── NotificationContext_v.test.res
│       ├── NotificationLayer_v.test.bs.js
│       ├── NotificationLayer_v.test.res
│       ├── PannellumAdapter_v.test.bs.js
│       ├── PannellumAdapter_v.test.res
│       ├── PannellumLifecycle_v.test.bs.js
│       ├── PannellumLifecycle_v.test.res
│       ├── PanoramaClusterer_v.test.bs.js
│       ├── PanoramaClusterer_v.test.res
│       ├── PathInterpolation_v.test.bs.js
│       ├── PathInterpolation_v.test.res
│       ├── PersistentLabel_v.test.bs.js
│       ├── PersistentLabel_v.test.res
│       ├── PopOver_v.test.bs.js
│       ├── PopOver_v.test.res
│       ├── Portal_v.test.bs.js
│       ├── Portal_v.test.res
│       ├── PreviewArrow_v.test.bs.js
│       ├── PreviewArrow_v.test.res
│       ├── ProgressBar_v.test.bs.js
│       ├── ProgressBar_v.test.res
│       ├── ProjectApi_v.test.bs.js
│       ├── ProjectApi_v.test.res
│       ├── ProjectData_v.test.bs.js
│       ├── ProjectData_v.test.res
│       ├── ProjectManagerLogic_v.test.bs.js
│       ├── ProjectManagerLogic_v.test.res
│       ├── ProjectManager_v.test.bs.js
│       ├── ProjectManager_v.test.res
│       ├── ProjectReducer_v.test.bs.js
│       ├── ProjectReducer_v.test.res
│       ├── ProjectionMath_v.test.bs.js
│       ├── ProjectionMath_v.test.res
│       ├── QualityIndicator_v.test.bs.js
│       ├── QualityIndicator_v.test.res
│       ├── ReBindings_v.test.bs.js
│       ├── ReBindings_v.test.res
│       ├── Reducer_v.test.bs.js
│       ├── Reducer_v.test.res
│       ├── RequestQueue_v.test.bs.js
│       ├── RequestQueue_v.test.res
│       ├── Resizer_v.test.bs.js
│       ├── Resizer_v.test.res
│       ├── ReturnPrompt_v.test.bs.js
│       ├── ReturnPrompt_v.test.res
│       ├── RootReducer_v.test.bs.js
│       ├── RootReducer_v.test.res
│       ├── SceneCache_v.test.bs.js
│       ├── SceneCache_v.test.res
│       ├── SceneHelpers_v.test.bs.js
│       ├── SceneHelpers_v.test.res
│       ├── SceneList_v.test.bs.js
│       ├── SceneList_v.test.res
│       ├── SceneLoader_Lifecycle_Unified_v.test.bs.js
│       ├── SceneLoader_Lifecycle_Unified_v.test.res
│       ├── SceneLoader_v.test.bs.js
│       ├── SceneLoader_v.test.res
│       ├── SceneReducer_v.test.bs.js
│       ├── SceneReducer_v.test.res
│       ├── SceneSwitcher_v.test.bs.js
│       ├── SceneSwitcher_v.test.res
│       ├── SceneTransitionManager_v.test.bs.js
│       ├── SceneTransitionManager_v.test.res
│       ├── Schemas_v.test.bs.js
│       ├── Schemas_v.test.res
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
│       ├── SimHelpers_v.test.bs.js
│       ├── SimHelpers_v.test.res
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
│       ├── SnapshotOverlay_v.test.bs.js
│       ├── SnapshotOverlay_v.test.res
│       ├── StateInspectorTest.bs.js
│       ├── StateInspector_v.test.bs.js
│       ├── StateInspector_v.test.res
│       ├── State_v.test.bs.js
│       ├── State_v.test.res
│       ├── SvgManager_v.test.bs.js
│       ├── SvgManager_v.test.res
│       ├── SvgRenderer_v.test.bs.js
│       ├── SvgRenderer_v.test.res
│       ├── TeaserManager_v.test.bs.js
│       ├── TeaserManager_v.test.res
│       ├── TeaserPathfinder_v.test.bs.js
│       ├── TeaserPathfinder_v.test.res
│       ├── TeaserPlayback_v.test.bs.js
│       ├── TeaserPlayback_v.test.res
│       ├── TeaserRecorder_v.test.bs.js
│       ├── TeaserRecorder_v.test.res
│       ├── TeaserState_v.test.bs.js
│       ├── TeaserState_v.test.res
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
│       ├── UiHelpers_v.test.bs.js
│       ├── UiHelpers_v.test.res
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
│       ├── UtilityBar_v.test.bs.js
│       ├── UtilityBar_v.test.res
│       ├── Version_v.test.bs.js
│       ├── Version_v.test.res
│       ├── VideoEncoder_v.test.bs.js
│       ├── VideoEncoder_v.test.res
│       ├── ViewerFollow_v.test.bs.js
│       ├── ViewerFollow_v.test.res
│       ├── ViewerHUD_v.test.bs.js
│       ├── ViewerHUD_v.test.res
│       ├── ViewerLabelMenu_v.test.bs.js
│       ├── ViewerLabelMenu_v.test.res
│       ├── ViewerLoader_v.test.bs.js
│       ├── ViewerLoader_v.test.res
│       ├── ViewerManager_v.test.bs.js
│       ├── ViewerManager_v.test.res
│       ├── ViewerPool_v.test.bs.js
│       ├── ViewerPool_v.test.res
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
├── tmp
└── vitest.config.mjs

201 directories, 5081 files
