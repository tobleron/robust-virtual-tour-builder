/* tests/TestRunner.res */
Console.log("Starting Frontend Unit Tests...")

GeoUtilsTest.run()
SimulationSystemTest.run()
TourLogicTest.run()
PathInterpolationTest.run()
ReducerTest.run()
ReducerJsonTest.run()
SceneReducerTest.run()
HotspotReducerTest.run()
ExifParserTest.run()
SharedTypesTest.run()
BackendApiTest.run()
ProjectManagerTest.run()
ResizerTest.run()
UploadProcessorTest.run()

Console.log("All frontend tests passed successfully! 🎉")
