/* tests/TestRunner.res */
Console.log("Starting Frontend Unit Tests...")

let runAll = async () => {
  GeoUtilsTest.run()
  // LoggerTest.run() - Migrated to Vitest

  InputSystemTest.run()
  // TourLogicTest.run() - Migrated to Vitest
  PathInterpolationTest.run()
  ReducerTest.run()
  ReducerHelpersTest.run()
  ProjectReducerTest.run()
  JsonTypesTest.run()
  // SceneReducerTest.run() - Migrated to Vitest
  // HotspotReducerTest.run() - Migrated to Vitest
  // NavigationReducerTest.run() - Migrated to Vitest
  ExifParserTest.run()
  AudioManagerTest.run()
  // ExifReportGeneratorTest.run() - Migrated to Vitest
  SharedTypesTest.run()
  // ReBindingsTest.run() - Migrated to Vitest
  // BackendApiTest.run() - Migrated to Vitest
  ProjectManagerTest.run()
  // DownloadSystemTest.run() - Migrated to Vitest
  ProjectDataTest.run()
  // ResizerTest.run() - Migrated to Vitest
  UploadProcessorTest.run()
  VideoEncoderTest.run()
  TeaserManagerTest.run()
  TeaserRecorderTest.run()
  // TourTemplateAssetsTest.run() - Migrated to Vitest
  TourTemplateScriptsTest.run()
  TourTemplateStylesTest.run()
  TourTemplatesTest.run()
  ExporterTest.run()
  // LazyLoadTest.run() - Migrated to Vitest
  ProgressBarTest.run()
  StateInspectorTest.run()
  ServiceWorkerTest.run()
  // NavigationTest.run() - Migrated to Vitest
  // NavigationRendererTest.run() - Migrated to Vitest
  // MainTest.run() - Migrated to Vitest
  ViewerLoaderTest.run()
  ActionsTest.run()
  GlobalStateBridgeTest.run()
  RootReducerTest.run()
  EventBusTest.run()
  TimelineReducerTest.run()
  SimulationNavigationTest.run()
  SimulationChainSkipperTest.run()
  // SimulationPathGeneratorTest.run() - Migrated to Vitest
  await TeaserPathfinderTest.run()
  ServerTeaserTest.run()
  ConstantsTest.run()
  VersionTest.run()
  await ImageOptimizerTest.run()
  UrlUtilsTest.run()
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
