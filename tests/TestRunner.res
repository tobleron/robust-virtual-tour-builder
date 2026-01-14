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

Console.log("All frontend tests passed successfully! 🎉")
