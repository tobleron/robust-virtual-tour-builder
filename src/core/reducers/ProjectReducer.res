open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | SetTourName(name) => Some({...state, tourName: TourLogic.sanitizeName(name)})

  | LoadProject(projectDataJson) =>
    Some({...ReducerHelpers.parseProject(projectDataJson), sessionId: state.sessionId})

  | Reset => Some(State.initialState)

  | SetExifReport(report) => Some({...state, exifReport: Some(report)})

  | RemoveDeletedSceneId(id) =>
    Some({
      ...state,
      deletedSceneIds: Belt.Array.keep(state.deletedSceneIds, i => i != id),
    })

  | SetSessionId(id) => Some({...state, sessionId: Some(id)})
  | _ => None
  }
}
