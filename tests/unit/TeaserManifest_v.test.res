/* tests/unit/TeaserManifest_v.test.res */
open Vitest

describe("TeaserManifest", () => {
  test("generateManifest produces valid motion-spec-v1 JSON logic", t => {
    let scenes: array<Types.scene> = [
      {
        id: "scene-1",
        name: "Scene 1",
        file: Types.Url("s1.webp"),
        tinyFile: None,
        originalFile: None,
        hotspots: [],
        category: "outdoor",
        floor: "ground",
        label: "",
        quality: None,
        colorGroup: None,
        _metadataSource: "user",
        categorySet: true,
        labelSet: true,
        isAutoForward: false,
      },
    ]

    let steps: array<Types.step> = [
      {
        idx: 0,
        arrivalView: {yaw: 0.0, pitch: 0.0},
        transitionTarget: Some({
          yaw: 10.0,
          pitch: 0.0,
          targetName: "Target",
          timelineItemId: None,
        }),
      },
    ]

    let config: TeaserStyleConfig.teaserConfig = {
      clipDuration: 2000.0,
      transitionDuration: 1000.0,
      cameraPanOffset: 5.0,
    }

    let manifest = TeaserManifest.generateManifest(scenes, steps, "slow", config)

    t->expect(manifest.version)->Expect.toEqual("motion-spec-v1")
    t->expect(Belt.Array.length(manifest.shots))->Expect.toEqual(1)

    let shot = manifest.shots[0]->Option.getOrThrow
    t->expect(shot.sceneId)->Expect.toEqual("scene-1")
    t->expect(Belt.Array.length(shot.animationSegments))->Expect.toEqual(1)

    let segment = shot.animationSegments[0]->Option.getOrThrow
    // startYaw = targetYaw (10.0) - cameraPanOffset (5.0) = 5.0
    t->expect(segment.startYaw)->Expect.toEqual(5.0)
    t->expect(segment.endYaw)->Expect.toEqual(10.0)
    t->expect(segment.durationMs)->Expect.toEqual(2000)
  })

  test("JsonParsers decodes valid manifest", t => {
    let json = JsonCombinators.Json.parse(`{
      "version": "motion-spec-v1",
      "fps": 60,
      "canvasWidth": 1920,
      "canvasHeight": 1080,
      "includeIntroPan": false,
      "shots": [
        {
          "sceneId": "s1",
          "arrivalPose": {"yaw": 0, "pitch": 0, "hfov": 90},
          "animationSegments": [
            {
              "startYaw": 0, "endYaw": 10,
              "startPitch": 0, "endPitch": 0,
              "startHfov": 90, "endHfov": 90,
              "easing": "linear",
              "durationMs": 1000
            }
          ],
          "transitionOut": {"type": "crossfade", "durationMs": 500}
        }
      ]
    }`)->Result.getOrThrow

    let result = JsonCombinators.Json.decode(json, JsonParsers.Domain.motionManifest)
    t->expect(result->Result.isOk)->Expect.toEqual(true)
    let manifest = result->Result.getOrThrow
    t->expect(manifest.version)->Expect.toEqual("motion-spec-v1")
    t->expect(manifest.fps)->Expect.toEqual(60)
  })

  test("JsonParsers encodes valid manifest", t => {
    let manifest: Types.motionManifest = {
      version: "motion-spec-v1",
      fps: 30,
      canvasWidth: 1280,
      canvasHeight: 720,
      includeIntroPan: true,
      shots: [
        {
          sceneId: "s2",
          arrivalPose: {yaw: 45.0, pitch: -10.0, hfov: 70.0},
          animationSegments: [
            {
              startYaw: 45.0,
              endYaw: 90.0,
              startPitch: -10.0,
              endPitch: 0.0,
              startHfov: 70.0,
              endHfov: 90.0,
              easing: "cubic-bezier",
              durationMs: 2000,
            },
          ],
          transitionOut: Some({
            type_: "crossfade",
            durationMs: 1000,
          }),
          pathData: None,
          waitBeforePanMs: 0,
          blinkAfterPanMs: 0,
        },
      ],
    }

    let encoded = JsonParsers.Encoders.motionManifest(manifest)
    let result = JsonCombinators.Json.decode(encoded, JsonParsers.Domain.motionManifest)

    t->expect(result->Result.isOk)->Expect.toEqual(true)
    let decoded = result->Result.getOrThrow
    t->expect(decoded.version)->Expect.toEqual("motion-spec-v1")
    t->expect(decoded.fps)->Expect.toEqual(30)
    t->expect(decoded.canvasWidth)->Expect.toEqual(1280)
    t->expect(decoded.includeIntroPan)->Expect.toEqual(true)
    t->expect(Belt.Array.length(decoded.shots))->Expect.toEqual(1)
  })
})
