/* tests/unit/VisualPipeline_v.test.res */
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

  let createScene = (id: string, name: string): scene => {
    {
      id,
      name,
      file: Url("placeholder.jpg"),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "default",
      floor: "1",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "test",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  }

  test("init should return Some(pipeline) and setup DOM", t => {
    let container = setupDOM()
    let pipeline = VisualPipeline.init("pipeline-container")

    t->expect(Belt.Option.isSome(pipeline))->Expect.toBe(true)

    let wrapper = Dom.querySelector(container, ".visual-pipeline-wrapper")
    t->expect(Nullable.toOption(wrapper)->Belt.Option.isSome)->Expect.toBe(true)

    cleanupDOM(container)
  })

  test("injectStyles should add style element to head", t => {
    let container = setupDOM()
    let _ = VisualPipeline.init("pipeline-container")

    let style = Dom.getElementById("visual-pipeline-styles")
    t->expect(Nullable.toOption(style)->Belt.Option.isSome)->Expect.toBe(true)

    cleanupDOM(container)
  })

  test("render should apply color group colors to nodes", t => {
    let container = setupDOM()
    let _ = VisualPipeline.init("pipeline-container")

    let item1 = createTimelineItem("1", "Living Room")
    let scene1 = {
      ...createScene("scene_1", "Living Room"),
      colorGroup: Some("1"), // Should be Blue 500 #3b82f6 (based on logic 1-1=0 -> idx 0)
    }

    let state = {
      ...State.initialState,
      timeline: [item1],
      scenes: [scene1],
    }
    GlobalStateBridge.setState(state)

    let node = Dom.querySelector(container, ".pipeline-node")
    switch Nullable.toOption(node) {
    | Some(n) =>
      let style = Dom.getStyle(n)
      let color = Dom.getPropertyValue(style, "--node-color")
      // ColorPalette logic: id 1 -> idx 0 -> #3b82f6
      t->expect(color)->Expect.toBe("#3b82f6")
    | None => t->expect(false)->Expect.toBe(true)
    }

    cleanupDOM(container)
  })

  test("render should create tooltip with correct info", t => {
    let container = setupDOM()
    let _ = VisualPipeline.init("pipeline-container")

    let item1 = createTimelineItem("1", "Kitchen")
    let scene1 = {
      ...createScene("scene_1", "Kitchen"),
      file: Url("thumb.jpg"),
    }

    let state = {
      ...State.initialState,
      timeline: [item1],
      scenes: [scene1],
    }
    GlobalStateBridge.setState(state)

    let tooltip = Dom.querySelector(container, ".node-tooltip")
    let exists = Nullable.toOption(tooltip)->Belt.Option.isSome
    t->expect(exists)->Expect.toBe(true)

    if exists {
      let el = Nullable.toOption(tooltip)->Belt.Option.getExn
      let text = Dom.querySelector(el, ".tooltip-text")
      t
      ->expect(Dom.getTextContent(Nullable.toOption(text)->Belt.Option.getExn))
      ->Expect.toBe("Kitchen")

      let linkId = Dom.querySelector(el, ".tooltip-link-id")
      t
      ->expect(Dom.getTextContent(Nullable.toOption(linkId)->Belt.Option.getExn))
      ->Expect.toBe("Link: link_1")
    }

    cleanupDOM(container)
  })

  test("node active state should track activeTimelineStepId", t => {
    let container = setupDOM()
    let _ = VisualPipeline.init("pipeline-container")

    let item1 = createTimelineItem("1", "Living Room")
    let state = {
      ...State.initialState,
      timeline: [item1],
      activeTimelineStepId: Some("1"),
    }
    GlobalStateBridge.setState(state)

    let node = Dom.querySelector(container, ".pipeline-node")
    let cl = Dom.classList(Nullable.toOption(node)->Belt.Option.getExn)
    t->expect(Dom.ClassList.contains(cl, "active"))->Expect.toBe(true)

    let stateInactive = {...state, activeTimelineStepId: Some("other")}
    GlobalStateBridge.setState(stateInactive)
    // Node is re-rendered, so we need to query it again
    let nodeInactive = Dom.querySelector(container, ".pipeline-node")
    let cl2 = Dom.classList(Nullable.toOption(nodeInactive)->Belt.Option.getExn)
    t->expect(Dom.ClassList.contains(cl2, "active"))->Expect.toBe(false)

    cleanupDOM(container)
  })

  test("drag interaction should update state and dispatch reorder", t => {
    let container = setupDOM()
    let _ = VisualPipeline.init("pipeline-container")

    let item1 = createTimelineItem("1", "A")
    let item2 = createTimelineItem("2", "B")
    let scene1 = createScene("scene_1", "Scene 1")
    let scene2 = createScene("scene_2", "Scene 2")

    let state = {
      ...State.initialState,
      timeline: [item1, item2],
      scenes: [scene1, scene2],
    }
    GlobalStateBridge.setState(state)

    let lastAction = ref(None)
    GlobalStateBridge.setDispatch(action => lastAction := Some(action))

    let nodes = Dom.querySelectorAll(container, ".pipeline-node")
    t->expect(Dom.nodeListLength(nodes))->Expect.toBe(2)
    let sourceNode = %raw(`(list) => list[0]`)(nodes)

    let mockDataTransfer = %raw(`{
      setData: () => {},
      effectAllowed: '',
      dropEffect: ''
    }`)

    let dragStartEvent = %raw(`new Event('dragstart', {bubbles: true})`)
    let _ = %raw(`(ev, dt) => Object.defineProperty(ev, 'dataTransfer', { value: dt })`)(
      dragStartEvent,
      mockDataTransfer,
    )

    let _ = %raw(`(node, ev) => node.dispatchEvent(ev)`)(sourceNode, dragStartEvent)

    // Verify is-dragging class
    let clSource = Dom.classList(sourceNode)
    t->expect(Dom.ClassList.contains(clSource, "is-dragging"))->Expect.toBe(true)

    // Verify wrapper dragging-active
    let wrapper = Dom.querySelector(container, ".visual-pipeline-wrapper")
    let clWrapper = Dom.classList(Nullable.toOption(wrapper)->Belt.Option.getExn)
    t->expect(Dom.ClassList.contains(clWrapper, "dragging-active"))->Expect.toBe(true)

    let zones = Dom.querySelectorAll(container, ".drop-zone")
    let targetZone = %raw(`(list) => list[2]`)(zones)

    let dragOverEvent = %raw(`new Event('dragover', {bubbles: true})`)
    let _ = %raw(`(ev, dt) => Object.defineProperty(ev, 'dataTransfer', { value: dt })`)(
      dragOverEvent,
      mockDataTransfer,
    )
    let _ = %raw(`(node, ev) => node.dispatchEvent(ev)`)(targetZone, dragOverEvent)

    // Verify drag-over class
    let clZone = Dom.classList(targetZone)
    t->expect(Dom.ClassList.contains(clZone, "drag-over"))->Expect.toBe(true)

    // Drop
    let dropEvent = %raw(`new Event('drop', {bubbles: true})`)
    let _ = %raw(`(node, ev) => node.dispatchEvent(ev)`)(targetZone, dropEvent)

    // Verify ReorderTimeline(0, 1)
    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.ReorderTimeline(0, 1)))

    // Simulate Drag End on source node
    let dragEndEvent = %raw(`new Event('dragend', {bubbles: true})`)
    let _ = %raw(`(node, ev) => node.dispatchEvent(ev)`)(sourceNode, dragEndEvent)

    // Drag End
    t->expect(Dom.ClassList.contains(clSource, "is-dragging"))->Expect.toBe(false)
    t->expect(Dom.ClassList.contains(clZone, "drag-over"))->Expect.toBe(false)
    t->expect(Dom.ClassList.contains(clWrapper, "dragging-active"))->Expect.toBe(false)

    cleanupDOM(container)
  })
})
