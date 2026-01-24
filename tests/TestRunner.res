/* tests/TestRunner.res */
Console.log("Starting Frontend Unit Tests...")

let runAll = async () => {
  GeoUtilsTest.run()
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

  AudioManagerTest.run()
  // ExifReportGeneratorTest.run() - Migrated to Vitest
  SharedTypesTest.run()
  // ReBindingsTest.run() - Migrated to Vitest
  // BackendApiTest.run() - Migrated to Vitest
  // ProjectManagerTest.run() - Migrated to Vitest
  // DownloadSystemTest.run() - Migrated to Vitest
  ProjectDataTest.run()
  // ResizerTest.run() - Migrated to Vitest
  // UploadProcessorTest.run() - Migrated to Vitest
  VideoEncoderTest.run()

  // TourTemplateAssetsTest.run() - Migrated to Vitest
  // TourTemplateScriptsTest.run() - Migrated to Vitest
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
  // RootReducerTest.run() - Migrated to Vitest
  EventBusTest.run()
  // TimelineReducerTest.run() - Migrated to Vitest
  // SimulationNavigationTest.run() - Migrated to Vitest
  // SimulationChainSkipperTest.run() - Migrated to Vitest
  // SimulationPathGeneratorTest.run() - Migrated to Vitest

  ServerTeaserTest.run()
  // ConstantsTest.run() - Migrated to Vitest
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
