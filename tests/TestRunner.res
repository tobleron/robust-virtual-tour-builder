/* tests/TestRunner.res */
Console.log("Starting Frontend Unit Tests...")

let runAll = async () => {
  GeoUtilsTest.run()
  LoggerTest.run()

  InputSystemTest.run()
  TourLogicTest.run()
  PathInterpolationTest.run()
  ReducerTest.run()
  ReducerHelpersTest.run()
  JsonTypesTest.run()
  // SceneReducerTest.run() - Migrated to Vitest
  // HotspotReducerTest.run() - Migrated to Vitest
  // NavigationReducerTest.run() - Migrated to Vitest
  ExifParserTest.run()
  AudioManagerTest.run()
  ExifReportGeneratorTest.run()
  SharedTypesTest.run()
  ReBindingsTest.run()
  BackendApiTest.run()
  ProjectManagerTest.run()
  DownloadSystemTest.run()
  ProjectDataTest.run()
  ResizerTest.run()
  UploadProcessorTest.run()
  VideoEncoderTest.run()
  TeaserManagerTest.run()
  TeaserRecorderTest.run()
  TourTemplateAssetsTest.run()
  TourTemplateScriptsTest.run()
  TourTemplateStylesTest.run()
  TourTemplatesTest.run()
  ExporterTest.run()
  LazyLoadTest.run()
  ProgressBarTest.run()
  StateInspectorTest.run()
  ServiceWorkerTest.run()
  // NavigationTest.run() - Migrated to Vitest
  NavigationRendererTest.run()
  MainTest.run()
  ViewerLoaderTest.run()
  ActionsTest.run()
  GlobalStateBridgeTest.run()
  RootReducerTest.run()
  ProjectReducerTest.run()
  // NavigationReducerTest.run() - Migrated to Vitest
  EventBusTest.run()
  TimelineReducerTest.run()
  SimulationNavigationTest.run()
  SimulationChainSkipperTest.run()
  SimulationPathGeneratorTest.run()
  await TeaserPathfinderTest.run()
  ServerTeaserTest.run()
  ConstantsTest.run()
  VersionTest.run()
  await ImageOptimizerTest.run()
  UrlUtilsTest.run()
  VersionDataTest.run()
  ServiceWorkerMainTest.run()

  Console.log("All frontend tests passed successfully! 🎉")
  let _ = %raw(`process.exit(0)`)
}

runAll()->ignore
