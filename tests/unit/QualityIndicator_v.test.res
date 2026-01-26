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

    let scenes = [{...defaultScene, quality: Some(Obj.magic(quality))}]

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
