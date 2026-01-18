open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | SetPreloadingScene(index) => Some({...state, preloadingSceneIndex: index})
  | StartLinking(draft) => Some({...state, isLinking: true, linkDraft: Some(draft)})
  | StopLinking => Some({...state, isLinking: false, linkDraft: None})
  | UpdateLinkDraft(draft) => Some({...state, linkDraft: Some(draft)})
  | SetIsTeasing(val) => Some({...state, isTeasing: val})
  | _ => None
  }
}
