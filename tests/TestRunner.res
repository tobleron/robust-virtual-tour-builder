// @efficiency: infra-adapter
/* tests/TestRunner.res */
Console.log("Starting Frontend Unit Tests...")

let runAll = async () => {
  // GeoUtilsTest.run() - Migrated to Vitest
  // LoggerTest.run() - Migrated to Vitest

  // InputSystemTest.run() - Migrated to Vitest
  // TourLogicTest.run() - Migrated to Vitest
  // PathInterpolationTest.run() - Migrated to Vitest
  // ReducerTest.run() - Migrated to Vitest
  // ReducerHelpersTest.run() - Migrated to Vitest
  // ProjectReducerTest.run() - Migrated to Vitest
  // JsonTypesTest.run() - Migrated to Vitest
  // SceneReducerTest.run() - Migrated to Vitest
  // HotspotReducerTest.run() - Migrated to Vitest
  // NavigationReducerTest.run() - Migrated to Vitest

  // AudioManagerTest.run() - Migrated to Vitest
  // ExifReportGeneratorTest.run() - Migrated to Vitest
  // SharedTypesTest.run() - Migrated to Vitest
  // ReBindingsTest.run() - Migrated to Vitest
  // BackendApiTest.run() - Migrated to Vitest
  // ProjectManagerTest.run() - Migrated to Vitest
  // DownloadSystemTest.run() - Migrated to Vitest
  // ProjectDataTest.run() - Migrated to Vitest
  // ResizerTest.run() - Migrated to Vitest
  // UploadProcessorTest.run() - Migrated to Vitest
  // VideoEncoderTest.run() - Migrated to Vitest

  // TourTemplateAssetsTest.run() - Migrated to Vitest
  // TourTemplateScriptsTest.run() - Migrated to Vitest
  // TourTemplateStylesTest.run() - Migrated to Vitest
  // TourTemplatesTest.run() - Migrated to Vitest
  // ExporterTest.run() - Migrated to Vitest
  // LazyLoadTest.run() - Migrated to Vitest
  // ProgressBarTest.run() - Migrated to Vitest
  // StateInspectorTest.run() - Migrated to Vitest
  // ServiceWorkerTest.run() - Migrated to Vitest
  // NavigationTest.run() - Migrated to Vitest
  // NavigationRendererTest.run() - Migrated to Vitest
  // MainTest.run() - Migrated to Vitest
  // ViewerLoaderTest.run() - Migrated to Vitest
  // ActionsTest.run() - Migrated to Vitest
  // GlobalStateBridgeTest.run() - Migrated to Vitest
  // RootReducerTest.run() - Migrated to Vitest
  // EventBusTest.run() - Migrated to Vitest
  // TimelineReducerTest.run() - Migrated to Vitest
  // SimulationNavigationTest.run() - Migrated to Vitest
  // SimulationChainSkipperTest.run() - Migrated to Vitest
  // SimulationPathGeneratorTest.run() - Migrated to Vitest

  // ServerTeaserTest.run() - Migrated to Vitest
  // ConstantsTest.run() - Migrated to Vitest
  // VersionTest.run() - Migrated to Vitest
  // await ImageOptimizerTest.run() - Migrated to Vitest
  // UrlUtilsTest.run() - Migrated to Vitest
  // VersionDataTest.run() - Migrated to Vitest
  // ServiceWorkerMainTest.run() - Migrated to Vitest

  Console.log("All frontend tests passed successfully! 🎉")
  let _ = %raw(`process.exit(0)`)
}

runAll()
->Promise.catch(err => {
  Console.error("Test Runner FAILED:")
  Console.error(err)
  let _ = %raw(`process.exit(1)`)
  Promise.resolve()
})
->ignore
