// @efficiency: infra-adapter
open Vitest
open TeaserPathfinder

/* Types */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"

/* Mocks */
%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/BackendApi.bs.js', () => {
    return {
      calculatePath: vi.fn(),
    };
  });
`)

@module("../../src/systems/BackendApi.bs.js") external mockCalculatePath: mockFn = "calculatePath"

describe("TeaserPathfinder", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
    mockCalculatePath->mockResolvedValue(Ok([]))
  })

  testAsync("getWalkPath calls BackendApi with correct arguments", async t => {
    let scenes: array<Types.scene> = []
    let skipAutoForward = false

    let _ = await getWalkPath(scenes, skipAutoForward)

    expectCall(mockCalculatePath)->toHaveBeenCalledWith({
      "type": "walk",
      "scenes": scenes,
      "skipAutoForward": skipAutoForward,
      "timeline": undefined,
    })
    t->expect(true)->Expect.toBe(true)
  })

  testAsync("getTimelinePath calls BackendApi with correct arguments", async t => {
    let timeline: array<Types.timelineItem> = []
    let scenes: array<Types.scene> = []
    let skipAutoForward = true

    let _ = await getTimelinePath(timeline, scenes, skipAutoForward)

    expectCall(mockCalculatePath)->toHaveBeenCalledWith({
      "type": "timeline",
      "timeline": timeline,
      "scenes": scenes,
      "skipAutoForward": skipAutoForward,
    })
    t->expect(true)->Expect.toBe(true)
  })

  testAsync("getWalkPath forwards BackendApi result", async t => {
    let mockResult: array<TeaserPathfinder.step> = [
      {
        idx: 1,
        transitionTarget: Some({
          yaw: 0.0,
          pitch: 0.0,
          targetName: "pano1",
          timelineItemId: Some("1"),
        }),
        arrivalView: {
          yaw: 0.0,
          pitch: 0.0,
        },
      },
    ]
    mockCalculatePath->mockResolvedValue(Ok(mockResult))

    let result = await getWalkPath([], false)

    switch result {
    | Ok(steps) => t->expect(steps)->Expect.toBe(mockResult)
    | Error(_) => t->expect(true)->Expect.toBe(false)
    }
  })
})
