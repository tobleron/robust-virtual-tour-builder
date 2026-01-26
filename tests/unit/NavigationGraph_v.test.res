open Vitest
open Types

describe("NavigationGraph", () => {
  let createScene = (name, hotspots) => {
    let sc: scene = {
      id: name,
      name,
      file: Url(name),
      tinyFile: None,
      originalFile: None,
      hotspots,
      category: "indoor",
      floor: "ground",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "user",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
    sc
  }

  test("findSceneByName finds existing scene", t => {
    let s1 = createScene("s1", [])
    let s2 = createScene("s2", [])
    let scenes = [s1, s2]

    let found = NavigationGraph.findSceneByName(scenes, "s2")
    switch found {
    | Some(s) => t->expect(s.name)->Expect.toBe("s2")
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("calculateSmartArrivalTarget returns default if no hotspots", t => {
    let s1 = createScene("s1", [])
    let (yaw, pitch, hfov) = NavigationGraph.calculateSmartArrivalTarget([s1], 0)
    t->expect(yaw)->Expect.toBe(0.0)
    t->expect(pitch)->Expect.toBe(0.0)
    t->expect(hfov)->Expect.toBe(90.0)
  })

  test("calculateSmartArrivalTarget uses start parameters from first forward hotspot", t => {
    let h1: hotspot = {
      linkId: "h1",
      yaw: 100.0,
      pitch: 0.0,
      target: "target",
      targetYaw: None,
      targetPitch: None,
      targetHfov: None,
      startYaw: Some(45.0),
      startPitch: Some(10.0),
      startHfov: Some(80.0),
      isReturnLink: Some(false),
      viewFrame: None,
      returnViewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
    }
    let s1 = createScene("s1", [h1])
    let (yaw, pitch, hfov) = NavigationGraph.calculateSmartArrivalTarget([s1], 0)
    t->expect(yaw)->Expect.toBe(45.0)
    t->expect(pitch)->Expect.toBe(10.0)
    t->expect(hfov)->Expect.toBe(80.0)
  })
})
