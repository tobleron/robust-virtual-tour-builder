open Vitest
open SimHelpers
open Types

describe("SimHelpers", () => {
  test("Parse timeline item", t => {
    let timelineJson = JSON.parseOrThrow(`{
      "id": "t1",
      "linkId": "l1",
      "sceneId": "s1",
      "targetScene": "s2",
      "transition": "fade",
      "duration": 1000
    }`)

    let item = parseTimelineItem(timelineJson)
    t->expect(item.id)->Expect.toEqual("t1")
    t->expect(item.duration)->Expect.toEqual(1000)
  })

  test("handleUpdateTimelineStep logic", t => {
    let stateWithTimeline = {
      ...State.initialState,
      timeline: [
        {
          id: "step1",
          linkId: "l1",
          sceneId: "s1",
          targetScene: "s2",
          transition: "fade",
          duration: 1000,
        },
      ],
    }
    let stepUpdateJson = JSON.parseOrThrow(`{
      "transition": "zoom",
      "duration": 2000
    }`)
    let stateAfterStepUpdate = handleUpdateTimelineStep(stateWithTimeline, "step1", stepUpdateJson)
    let updatedStep = Belt.Array.getExn(stateAfterStepUpdate.timeline, 0)
    t->expect(updatedStep.transition)->Expect.toEqual("zoom")
    t->expect(updatedStep.duration)->Expect.toEqual(2000)
  })
})
