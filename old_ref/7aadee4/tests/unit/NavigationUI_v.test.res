open Vitest
open ReBindings

describe("NavigationUI", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  // Helper to mock requestAnimationFrame
  beforeEach(() => {
    let _ = %raw(`
      window.requestAnimationFrame = (cb) => {
        cb();
        return 1;
      }
    `)
  })

  testAsync("should update return prompt when incoming link exists", async t => {
    let prompt = Dom.createElement("div")
    Dom.setId(prompt, "return-link-prompt")
    Dom.add(prompt, "hidden")

    let textEl = Dom.createElement("span")
    Dom.add(textEl, "return-link-text")
    Dom.appendChild(prompt, textEl)
    Dom.appendChild(Dom.documentBody, prompt)

    let scene1 = TestUtils.createMockScene(~id="1", ~name="Scene 1", ())
    let scene2 = TestUtils.createMockScene(~id="2", ~name="Scene 2", ~hotspots=[], ())

    let state: Types.state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      incomingLink: Some({sceneIndex: 0, hotspotIndex: 0}),
    }

    NavigationUI.updateReturnPrompt(state, scene2)

    await wait(50)

    t->expect(Dom.contains(prompt, "hidden"))->Expect.toBe(false)
    t->expect(Dom.contains(prompt, "flex"))->Expect.toBe(true)
    t->expect(Dom.contains(prompt, "visible"))->Expect.toBe(true)
    t->expect(Dom.getTextContent(textEl))->Expect.toBe("Return to Scene 1")

    Dom.removeElement(prompt)
  })

  testAsync("should hide return prompt when return link already exists in scene", async t => {
    let prompt = Dom.createElement("div")
    Dom.setId(prompt, "return-link-prompt")
    Dom.add(prompt, "flex")
    Dom.appendChild(Dom.documentBody, prompt)

    let scene1 = TestUtils.createMockScene(~id="1", ~name="Scene 1", ())
    let scene2 = TestUtils.createMockScene(
      ~id="2",
      ~name="Scene 2",
      ~hotspots=[
        {
          ...TestUtils.createMockHotspot(~id="h1", ~target="Scene 1", ()),
          isReturnLink: Some(true),
        },
      ],
      (),
    )

    let state: Types.state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      incomingLink: Some({sceneIndex: 0, hotspotIndex: 0}),
    }

    NavigationUI.updateReturnPrompt(state, scene2)

    await wait(50)

    t->expect(Dom.contains(prompt, "hidden"))->Expect.toBe(true)
    t->expect(Dom.contains(prompt, "flex"))->Expect.toBe(false)

    Dom.removeElement(prompt)
  })

  testAsync("should hide return prompt during linking mode", async t => {
    let prompt = Dom.createElement("div")
    Dom.setId(prompt, "return-link-prompt")
    Dom.add(prompt, "flex")
    Dom.appendChild(Dom.documentBody, prompt)

    let state: Types.state = {
      ...State.initialState,
      isLinking: true,
    }

    NavigationUI.updateReturnPrompt(state, TestUtils.createMockScene())

    await wait(50)

    t->expect(Dom.contains(prompt, "hidden"))->Expect.toBe(true)

    Dom.removeElement(prompt)
  })
})
