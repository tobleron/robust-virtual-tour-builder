// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

describe("QualityIndicator", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let defaultScene: scene = {
    id: "s1",
    name: "Scene 1",
    label: "Living Room",
    file: Url("test.webp"),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "indoor",
    floor: "ground",
    quality: None,
    colorGroup: None,
    categorySet: false,
    labelSet: false,
    _metadataSource: "user",
    isAutoForward: false,
    sequenceId: 0,
  }

  testAsync("should render quality badges based on analysis", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let quality: SharedTypes.qualityAnalysis = {
      score: 5.0,
      isBlurry: true,
      isSoft: false,
      isSeverelyDark: true,
      isSeverelyBright: false,
      isDim: false,
      hasBlackClipping: true,
      hasWhiteClipping: false,
      stats: {
        avgLuminance: 20,
        blackClipping: 15.0,
        whiteClipping: 0.0,
        sharpnessVariance: 10,
      },
      histogram: [],
      colorHist: {r: [], g: [], b: []},
      issues: 2,
      warnings: 1,
      analysis: Nullable.null,
    }

    // Use proper JSON encoding for the quality field
    let qualityJson = JsonCombinators.Json.Encode.object([
      ("score", JsonCombinators.Json.Encode.float(quality.score)),
      ("isBlurry", JsonCombinators.Json.Encode.bool(quality.isBlurry)),
      ("isSoft", JsonCombinators.Json.Encode.bool(quality.isSoft)),
      ("isSeverelyDark", JsonCombinators.Json.Encode.bool(quality.isSeverelyDark)),
      ("isSeverelyBright", JsonCombinators.Json.Encode.bool(quality.isSeverelyBright)),
      ("isDim", JsonCombinators.Json.Encode.bool(quality.isDim)),
      ("hasBlackClipping", JsonCombinators.Json.Encode.bool(quality.hasBlackClipping)),
      ("hasWhiteClipping", JsonCombinators.Json.Encode.bool(quality.hasWhiteClipping)),
      (
        "stats",
        JsonCombinators.Json.Encode.object([
          ("avgLuminance", JsonCombinators.Json.Encode.int(quality.stats.avgLuminance)),
          ("blackClipping", JsonCombinators.Json.Encode.float(quality.stats.blackClipping)),
          ("whiteClipping", JsonCombinators.Json.Encode.float(quality.stats.whiteClipping)),
          ("sharpnessVariance", JsonCombinators.Json.Encode.int(quality.stats.sharpnessVariance)),
        ]),
      ),
      (
        "histogram",
        JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.histogram),
      ),
      (
        "colorHist",
        JsonCombinators.Json.Encode.object([
          (
            "r",
            JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.colorHist.r),
          ),
          (
            "g",
            JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.colorHist.g),
          ),
          (
            "b",
            JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.colorHist.b),
          ),
        ]),
      ),
      ("issues", JsonCombinators.Json.Encode.int(quality.issues)),
      ("warnings", JsonCombinators.Json.Encode.int(quality.warnings)),
      // analysis omitted
    ])

    let scenes = [{...defaultScene, quality: Some(qualityJson)}]

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <QualityIndicator activeIndex=0 scenes />)

    await wait(50)

    let indicator = Dom.getElementById("v-scene-quality-indicator")
    switch Nullable.toOption(indicator) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(String.includes(text, "BLURRY"))->Expect.toBe(true)
      t->expect(String.includes(text, "DARK"))->Expect.toBe(true)
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })
})
