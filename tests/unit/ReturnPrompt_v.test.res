// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

module WrappedReturnPrompt = {
  @react.component
  let make = (~incomingLink, ~scenes, ~mockDispatch) => {
    <AppContext.DispatchProvider value=mockDispatch>
      <ReturnPrompt incomingLink scenes />
    </AppContext.DispatchProvider>
  }
}

describe("ReturnPrompt", () => {
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

  testAsync("should handle click and dispatch action", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let incomingLink: Types.linkInfo = {
      sceneIndex: 0,
      hotspotIndex: 0,
    }
    let scenes = [defaultScene]

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    // Mock Viewer instance
    let _ = %raw(`
      (function() {
        window.pannellumViewer = {
          getYaw: () => 45.0,
          setPitch: function() {},
          setYaw: function() {},
          getPitch: () => 0.0,
          getHfov: () => 90.0
        };
      })()
    `)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedReturnPrompt incomingLink={Some(incomingLink)} scenes mockDispatch />,
    )

    await wait(50)

    let prompt = Dom.getElementById("return-link-prompt")
    t->expect(Nullable.toOption(prompt)->Belt.Option.isSome)->Expect.toBe(true)

    switch Nullable.toOption(prompt) {
    | Some(el) => Dom.click(el)
    | None => ()
    }

    t
    ->expect(lastAction.contents)
    ->Expect.toEqual(Some(Actions.SetPendingReturnSceneName(Some("Scene 1"))))

    Dom.removeElement(container)
  })
})
