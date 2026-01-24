/* tests/unit/TimelineReducer_v.test.res */
open Vitest
open Actions

describe("TimelineReducer", () => {
  let initialState = State.initialState

  test("AddToTimeline", t => {
    let itemJson = JSON.parseOrThrow(`{
      "id": "step1",
      "linkId": "link1",
      "sceneId": "scene1",
      "targetScene": "scene2",
      "transition": "fade",
      "duration": 1000
    }`)

    let actionAdd = AddToTimeline(itemJson)
    let resultAdd = TimelineReducer.reduce(initialState, actionAdd)

    switch resultAdd {
    | Some(ns) =>
      t->expect(Array.length(ns.timeline))->Expect.toEqual(1)
      let item = Array.getUnsafe(ns.timeline, 0)
      t->expect(item.id)->Expect.toEqual("step1")
      t->expect(item.transition)->Expect.toEqual("fade")
    | None => failwith("Expected Some(state)")
    }
  })

  test("SetActiveTimelineStep", t => {
    let stateWithItem: Types.state = {
      ...initialState,
      timeline: [
        {
          id: "step1",
          linkId: "link1",
          sceneId: "scene1",
          targetScene: "scene2",
          transition: "fade",
          duration: 1000,
        },
      ],
    }

    let actionSetActive = SetActiveTimelineStep(Some("step1"))
    let resultSetActive = TimelineReducer.reduce(stateWithItem, actionSetActive)

    switch resultSetActive {
    | Some(ns) => t->expect(ns.activeTimelineStepId)->Expect.toEqual(Some("step1"))
    | None => failwith("Expected Some(state)")
    }
  })

  test("UpdateTimelineStep", t => {
    let stateWithItem: Types.state = {
      ...initialState,
      timeline: [
        {
          id: "step1",
          linkId: "link1",
          sceneId: "scene1",
          targetScene: "scene2",
          transition: "fade",
          duration: 1000,
        },
      ],
    }

    let updateJson = JSON.parseOrThrow(`{
      "transition": "crossfade",
      "duration": 2000
    }`)

    let actionUpdate = UpdateTimelineStep("step1", updateJson)
    let resultUpdate = TimelineReducer.reduce(stateWithItem, actionUpdate)

    switch resultUpdate {
    | Some(ns) =>
      let item = Array.getUnsafe(ns.timeline, 0)
      t->expect(item.transition)->Expect.toEqual("crossfade")
      t->expect(item.duration)->Expect.toEqual(2000)
    | None => failwith("Expected Some(state)")
    }
  })

  test("ReorderTimeline", t => {
    let stateWithTwoItems: Types.state = {
      ...initialState,
      timeline: [
        {
          id: "step1",
          linkId: "link1",
          sceneId: "scene1",
          targetScene: "scene2",
          transition: "fade",
          duration: 1000,
        },
        {
          id: "step2",
          linkId: "link2",
          sceneId: "scene2",
          targetScene: "scene3",
          transition: "fade",
          duration: 1000,
        },
      ],
    }

    let actionReorder = ReorderTimeline(0, 1) // Move first to second
    let resultReorder = TimelineReducer.reduce(stateWithTwoItems, actionReorder)

    switch resultReorder {
    | Some(ns) =>
      t->expect(Array.getUnsafe(ns.timeline, 0).id)->Expect.toEqual("step2")
      t->expect(Array.getUnsafe(ns.timeline, 1).id)->Expect.toEqual("step1")
    | None => failwith("Expected Some(state)")
    }
  })

  test("RemoveFromTimeline", t => {
    let stateWithTwoItems: Types.state = {
      ...initialState,
      timeline: [
        {
          id: "step1",
          linkId: "link1",
          sceneId: "scene1",
          targetScene: "scene2",
          transition: "fade",
          duration: 1000,
        },
        {
          id: "step2",
          linkId: "link2",
          sceneId: "scene2",
          targetScene: "scene3",
          transition: "fade",
          duration: 1000,
        },
      ],
    }

    let actionRemove = RemoveFromTimeline("step1")
    let resultRemove = TimelineReducer.reduce(stateWithTwoItems, actionRemove)

    switch resultRemove {
    | Some(ns) =>
      t->expect(Array.length(ns.timeline))->Expect.toEqual(1)
      t->expect(Array.getUnsafe(ns.timeline, 0).id)->Expect.toEqual("step2")
    | None => failwith("Expected Some(state)")
    }
  })

  test("Fallthrough", t => {
    let actionUnknown = Obj.magic("UnknownAction")
    let resultUnknown = TimelineReducer.reduce(initialState, actionUnknown)
    t->expect(resultUnknown)->Expect.toEqual(None)
  })
})
