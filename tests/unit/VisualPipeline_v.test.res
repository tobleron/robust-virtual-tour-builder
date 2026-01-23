open Vitest
open ReBindings
open Types

describe("VisualPipeline", () => {
  let setupDOM = () => {
    let container = Dom.createElement("div")
    Dom.setId(container, "pipeline-container")
    Dom.appendChild(Dom.documentBody, container)
    container
  }

  let cleanupDOM = container => {
    Dom.removeElement(container)
    let style = Dom.getElementById("visual-pipeline-styles")
    switch Nullable.toOption(style) {
    | Some(s) => Dom.removeElement(s)
    | None => ()
    }
  }

  let createTimelineItem = (id, target): timelineItem => {
    {
      id,
      linkId: "link_" ++ id,
      sceneId: "scene_" ++ id,
      targetScene: target,
      transition: "fade",
      duration: 1000,
    }
  }

  test("init should return Some(pipeline) and setup DOM", t => {
    let container = setupDOM()
    let pipeline = VisualPipeline.init("pipeline-container")

    t->expect(Belt.Option.isSome(pipeline))->Expect.toBe(true)

    let wrapper = Dom.querySelector(container, ".visual-pipeline-wrapper")
    t->expect(Belt.Option.isSome(Nullable.toOption(wrapper)))->Expect.toBe(true)

    cleanupDOM(container)
  })

  test("render should show/hide wrapper based on timeline length", t => {
    let container = setupDOM()
    let _ = VisualPipeline.init("pipeline-container")

    // Empty state
    let emptyState = {
      ...State.initialState,
      timeline: [],
    }
    GlobalStateBridge.setState(emptyState)

    let wrapper =
      Dom.querySelector(container, ".visual-pipeline-wrapper")
      ->Nullable.toOption
      ->Belt.Option.getExn
    // Use raw access for style.display since computed style might be tricky in JSDOM without real CSS
    let display = %raw(`(w) => w.style.display`)(wrapper)
    t->expect(display)->Expect.toBe("none")

    // State with items
    let item1 = createTimelineItem("1", "Living Room")
    let stateWithItems = {
      ...emptyState,
      timeline: [item1],
    }
    GlobalStateBridge.setState(stateWithItems)

    let displayAfter = %raw(`(w) => w.style.display`)(wrapper)
    t->expect(displayAfter)->Expect.toBe("flex")

    cleanupDOM(container)
  })

  test("render should create nodes for timeline items", t => {
    let container = setupDOM()
    let _ = VisualPipeline.init("pipeline-container")

    let item1 = createTimelineItem("1", "Living Room")
    let item2 = createTimelineItem("2", "Kitchen")
    let state = {
      ...State.initialState,
      timeline: [item1, item2],
    }
    GlobalStateBridge.setState(state)

    let nodes = Dom.querySelectorAll(container, ".pipeline-node")
    t->expect(Dom.nodeListLength(nodes))->Expect.toBe(2)

    let zones = Dom.querySelectorAll(container, ".drop-zone")
    // For N items, there should be N+1 drop zones
    t->expect(Dom.nodeListLength(zones))->Expect.toBe(3)

    cleanupDOM(container)
  })
})
