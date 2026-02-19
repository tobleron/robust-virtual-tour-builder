// @efficiency-role: ui-component

open ReBindings
open ViewerState
open Types
open Actions

// Hook 6: Ratchet State
let useRatchetState = (~isLinking: bool) => {
  React.useEffect1(() => {
    if isLinking {
      ViewerState.state := {
          ...ViewerState.state.contents,
          ratchetState: {
            yawOffset: 0.0,
            pitchOffset: 0.0,
            maxYawOffset: 0.0,
            minYawOffset: 0.0,
            maxPitchOffset: 0.0,
            minPitchOffset: 0.0,
          },
        }

      if !ViewerState.state.contents.followLoopActive {
        ViewerState.state := {...ViewerState.state.contents, followLoopActive: true}
        ViewerSystem.Follow.updateFollowLoop(~getState=AppContext.getBridgeState)
      }
    }
    None
  }, [isLinking])
}
