open Vitest
open Types

describe("HotspotLineTypes", () => {
  test("should define screenCoords correctly", t => {
    let coords: screenCoords = {x: 100.0, y: 200.0}
    t->expect(coords.x)->Expect.toBe(100.0)
    t->expect(coords.y)->Expect.toBe(200.0)
  })

  test("should define customViewerProps correctly", t => {
    let props: HotspotLine.customViewerProps = {sceneId: "scene-1"}
    t->expect(props.sceneId)->Expect.toBe("scene-1")

    // Verify @as("_sceneId") via raw JS if possible, but standard ReScript access is enough for structural test
    let asJson = %raw(`function(p) { return JSON.stringify(p); }`)(props)
    t->expect(String.includes(asJson, "_sceneId"))->Expect.toBe(true)
  })
})
