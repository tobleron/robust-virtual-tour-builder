open Vitest
open Types
open LinkEditorLogic

%%raw(`
  vi.mock('../../src/components/LinkModal.bs.js', () => {
    const mock = { showLinkModal: vi.fn() };
    globalThis.LinkModalMock = mock;
    return mock;
  });
`)

describe("LinkEditorLogic", () => {
  beforeEach(() => {
    GlobalStateBridge.setState({...State.initialState, isLinking: true})
    GlobalStateBridge.setDispatch(
      a => {
        let newState = RootReducer.reducer(GlobalStateBridge.getState(), a)
        GlobalStateBridge.setState(newState)
      },
    )

    let _ = %raw(`
      (function() {
        globalThis.setMockViewer({
          getPitch: () => 0.0,
          getYaw: () => 0.0,
          getHfov: () => 90.0,
          mouseEventToCoords: () => [10.0, 20.0]
        });
        if (globalThis.LinkModalMock) {
          globalThis.LinkModalMock.showLinkModal.mockClear();
        }
      })()
    `)
  })

  test("handleStageClick initializes draft on first click", t => {
    let mockEv = {"clientX": 100, "clientY": 100}->Obj.magic
    let _ = handleStageClick(mockEv)

    let state = GlobalStateBridge.getState()
    switch state.linkDraft {
    | Some(d) =>
      t->expect(d.pitch)->Expect.toBe(10.0)
      t->expect(d.yaw)->Expect.toBe(20.0)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("handleEnter calls showLinkModal with final points", t => {
    // Set up a draft with intermediate points
    let draft: Types.linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 90.0,
      intermediatePoints: Some([
        {pitch: 5.0, yaw: 5.0, camPitch: 0.0, camYaw: 0.0, camHfov: 90.0, intermediatePoints: None},
      ]),
    }
    GlobalStateBridge.setState({...State.initialState, isLinking: true, linkDraft: Some(draft)})

    handleEnter()

    // Check if LinkModal.showLinkModal was called with pitch=5.0
    // Arguments are positional in the generated JS for this function
    let pitchCalled = %raw(`globalThis.LinkModalMock.showLinkModal.mock.calls[0][0]`)
    t->expect(pitchCalled)->Expect.toBe(5.0)
  })
})
