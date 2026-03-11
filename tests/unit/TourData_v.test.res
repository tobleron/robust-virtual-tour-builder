open Vitest
open Types

let makeScene = (~id: string, ~name: string, ~label: string): scene => {
  id,
  name,
  file: Url(""),
  tinyFile: None,
  originalFile: None,
  hotspots: [],
  category: "General",
  floor: "1",
  label,
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: true,
  labelSet: true,
  isAutoForward: false,
  sequenceId: 0,
}

let sampleViewFrame: viewFrame = {
  yaw: 10.0,
  pitch: 2.5,
  hfov: 80.0,
}

describe("TourData", () => {
  test("normalizeSceneRefForExport strips prefixes and leading separators", t => {
    t
    ->expect(TourData.normalizeSceneRefForExport("/assets/images/2k/014_Master_Bedroom.webp"))
    ->Expect.toBe("2k/014_Master_Bedroom.webp")
    t
    ->expect(TourData.normalizeSceneRefForExport("./assets/images/014_Master_Bedroom.webp"))
    ->Expect.toBe("014_Master_Bedroom.webp")
    t
    ->expect(TourData.normalizeSceneRefForExport("/014_Master_Bedroom.webp"))
    ->Expect.toBe("014_Master_Bedroom.webp")
  })

  test("resolveSceneIdFromTargetRef matches explicit ids, names, and numeric prefixes", t => {
    let scenes = [
      makeScene(~id="scene-1", ~name="001_Zoom_Out_View.webp", ~label="Zoom Out View"),
      makeScene(~id="scene-14", ~name="014_Master_Bedroom.webp", ~label="Master Bedroom"),
    ]

    t
    ->expect(TourData.resolveSceneIdFromTargetRef("scene-14", scenes))
    ->Expect.toEqual(Some("scene-14"))
    t
    ->expect(TourData.resolveSceneIdFromTargetRef("assets/images/014_Master_Bedroom.webp", scenes))
    ->Expect.toEqual(Some("scene-14"))
    t
    ->expect(TourData.resolveSceneIdFromTargetRef("014_Master_Bedroom", scenes))
    ->Expect.toEqual(Some("scene-14"))
    t->expect(TourData.resolveSceneIdFromTargetRef("014", scenes))->Expect.toEqual(Some("scene-14"))
  })

  test("encodeSceneData and encodeAutoTourManifest preserve stable scene-number metadata", t => {
    let hotspot: TourData.hotspotData = {
      "pitch": 5.0,
      "yaw": 25.0,
      "target": "014_Master_Bedroom.webp",
      "targetSceneId": "scene-14",
      "targetSceneNumber": Nullable.fromOption(Some(14)),
      "targetIsAutoForward": false,
      "isReturnLink": false,
      "sequenceNumber": Nullable.fromOption(Some(10)),
      "startYaw": Nullable.fromOption(Some(5.0)),
      "startPitch": Nullable.fromOption(Some(-2.0)),
      "waypoints": Nullable.fromOption(Some([sampleViewFrame])),
      "truePitch": 5.0,
      "viewFrame": Nullable.fromOption(Some(sampleViewFrame)),
      "targetYaw": Nullable.fromOption(Some(35.0)),
      "targetPitch": Nullable.fromOption(Some(0.0)),
    }
    let sceneData: TourData.sceneData = {
      "name": "010_Corridor_Hub_1.webp",
      "panorama": "assets/images/2k/010_Corridor_Hub_1.webp",
      "autoLoad": true,
      "sceneNumber": 10,
      "floor": "2",
      "category": "Corridor",
      "label": "Corridor Hub Left",
      "isAutoForward": false,
      "autoForwardHotspotIndex": -1,
      "autoForwardTargetSceneId": "",
      "hotSpots": [hotspot],
      "sequenceEdges": [
        {
          "linkId": "A14",
          "target": "014_Master_Bedroom.webp",
          "targetSceneId": "scene-14",
          "targetIsAutoForward": false,
          "sequenceNumber": 10,
          "visibleHotspotIndex": 0,
        },
      ],
      "isHubScene": false,
    }
    let manifest: TourData.autoTourManifestData = {
      "steps": [
        {
          "sourceSceneId": "scene-10",
          "targetSceneId": "scene-14",
          "linkId": "A14",
          "hotspotIndex": 0,
          "visibleHotspotIndex": 0,
          "sequenceCursor": 10,
          "isReturnLink": false,
          "targetIsAutoForward": false,
          "hotspot": hotspot,
        },
      ],
      "finalSceneId": "scene-14",
    }

    let sceneJson = JsonCombinators.Json.stringify(TourData.encodeSceneData(sceneData))
    let manifestJson = JsonCombinators.Json.stringify(TourData.encodeAutoTourManifest(manifest))

    t->expect(String.includes(sceneJson, "\"sceneNumber\":10"))->Expect.toBe(true)
    t->expect(String.includes(sceneJson, "\"targetSceneNumber\":14"))->Expect.toBe(true)
    t->expect(String.includes(sceneJson, "\"sequenceEdges\""))->Expect.toBe(true)
    t->expect(String.includes(manifestJson, "\"sequenceCursor\":10"))->Expect.toBe(true)
    t->expect(String.includes(manifestJson, "\"finalSceneId\":\"scene-14\""))->Expect.toBe(true)
  })
})
