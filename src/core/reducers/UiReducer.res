open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | SetPreloadingScene(idx) => Some({...state, preloadingSceneIndex: idx})
  | StartLinking(draft) => Some({...state, isLinking: true, linkDraft: draft})
  | StartAutoPilot(_) => Some({...state, isLinking: false, linkDraft: None})
  | StopLinking => Some({...state, isLinking: false, linkDraft: None})
  | UpdateLinkDraft(draft) => Some({...state, linkDraft: Some(draft)})
  | SetIsTeasing(val) => Some({...state, isTeasing: val})
  | _ => None
  }
}
