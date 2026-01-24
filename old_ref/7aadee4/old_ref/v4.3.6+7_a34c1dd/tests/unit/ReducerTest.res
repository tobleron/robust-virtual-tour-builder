/* tests/unit/ReducerTest.res */
open Types
open Actions

let run = () => {
  Console.log("Running Reducer tests...")

  let initialState = State.initialState

  // Test SetActiveScene
  let stateWithScenes = {
    ...initialState,
    scenes: [
      {
        id: "1",
        name: "scene1.webp",
        file: Obj.magic("scene1.webp"),
        tinyFile: None,
        originalFile: None,
        hotspots: [],
        category: "indoor",
        floor: "ground",
        label: "",
        quality: None,
        colorGroup: None,
        _metadataSource: "user",
        categorySet: false,
        labelSet: false,
        isAutoForward: false,
        preCalculatedSnapshot: None,
      },
    ],
  }

  // 1. SetActiveScene within bounds
  let action1 = SetActiveScene(0, 45.0, 10.0, None)
  let state1 = Reducer.reducer(stateWithScenes, action1)
  assert(state1.activeIndex == 0)
  assert(state1.activeYaw == 45.0)
  assert(state1.activePitch == 10.0)
  Console.log("✓ SetActiveScene within bounds")

  // 2. SetActiveScene out of bounds
  let action2 = SetActiveScene(1, 0.0, 0.0, None)
  let state2 = Reducer.reducer(stateWithScenes, action2)
  assert(state2.activeIndex == initialState.activeIndex)
  Console.log("✓ SetActiveScene out of bounds")

  // 3. SetTourName
  let action3 = SetTourName("My awesome tour")
  let state3 = Reducer.reducer(initialState, action3)
  assert(state3.tourName == "My_awesome_tour") // SanitizeName is called
  Console.log("✓ SetTourName")

  // 4. AddHotspot
  let hotspot = {
    linkId: "A01",
    yaw: 100.0,
    pitch: 0.0,
    target: "scene2.webp",
    targetYaw: None,
    targetPitch: None,
    targetHfov: None,
    startYaw: None,
    startPitch: None,
    startHfov: None,
    isReturnLink: None,
    viewFrame: None,
    returnViewFrame: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
  }
  let action4 = AddHotspot(0, hotspot)
  let state4 = Reducer.reducer(stateWithScenes, action4)
  let firstScene = Array.getUnsafe(state4.scenes, 0)
  assert(Array.length(firstScene.hotspots) == 1)
  assert(Array.getUnsafe(firstScene.hotspots, 0).linkId == "A01")
  Console.log("✓ AddHotspot")

  // 6. DeleteScene
  let stateBeforeDelete = {
    ...stateWithScenes,
    scenes: [
      {...Array.getUnsafe(stateWithScenes.scenes, 0), id: "1", name: "scene1.webp"},
      {...Array.getUnsafe(stateWithScenes.scenes, 0), id: "2", name: "scene2.webp"},
    ],
    activeIndex: 1,
  }
  let action6 = DeleteScene(1)
  let state6 = Reducer.reducer(stateBeforeDelete, action6)
  assert(Array.length(state6.scenes) == 1)
  assert(state6.activeIndex == 0)
  assert(Array.getUnsafe(state6.deletedSceneIds, 0) == "2")
  Console.log("✓ DeleteScene")

  // 7. LoadProject
  let projectJson = JSON.parseOrThrow(`{
    "tourName": "New Project",
    "scenes": [
      {
        "id": "p1",
        "name": "living.webp",
        "file": "living.webp",
        "hotspots": []
      }
    ]
  }`)
  let action7 = LoadProject(projectJson)
  let state7 = Reducer.reducer(initialState, action7)
  assert(state7.tourName == "New Project") // parseProject doesn't sanitize currently
  assert(Array.length(state7.scenes) == 1)
  assert(Array.getUnsafe(state7.scenes, 0).id == "p1")
  Console.log("✓ LoadProject valid JSON")

  // 8. SyncSceneNames
  let stateWithLabel = {
    ...stateWithScenes,
    scenes: [
      {
        ...Array.getUnsafe(stateWithScenes.scenes, 0),
        label: "Living Room",
      },
    ],
  }
  let action8 = SyncSceneNames
  let state8 = Reducer.reducer(stateWithLabel, action8)
  let updatedScene = Array.getUnsafe(state8.scenes, 0)
  assert(updatedScene.name == "01_living_room.webp")
  Console.log("✓ SyncSceneNames (Label to filename)")

  Console.log("Reducer tests passed!")
}
