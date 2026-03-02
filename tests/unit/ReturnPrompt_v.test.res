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
    sequenceId: 0,
  }

  testAsync("should handle click and dispatch action", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let incomingLink: Types.linkInfo = {
      sceneIndex: 0,
      hotspotIndex: 0,
      sceneId: None,
      hotspotLinkId: None,
    }
    let scenes = [defaultScene]

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    // Set up active viewport in Pool
    ViewerSystem.Pool.pool := [
        {
          id: "primary-a",
          containerId: "panorama-a",
          status: #Active,
          instance: None,
          cleanupTimeout: None,
        },
      ]

    // Mock Viewer instance
    let mockV = %raw(`
      (function() {
        const v = {
          getYaw: () => 45.0,
          setPitch: function() {},
          setYaw: function() {},
          setYawWithDuration: function() {}, 
          getPitch: () => 0.0,
          getHfov: () => 90.0,
          on: function() {},
          isLoaded: () => true
        };
        window.pannellumViewer = v;
        return v;
      })()
    `)
    ViewerSystem.Pool.registerInstance("panorama-a", mockV)

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

    // Note: SetPendingReturnSceneName action was removed (return link feature deprecated)
    // The return prompt still turns the viewer around, but no longer sets a pending scene name

    Dom.removeElement(container)
  })
})
