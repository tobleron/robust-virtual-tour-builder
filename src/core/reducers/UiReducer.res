open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | SetPreloadingScene(index) => Some({...state, preloadingSceneIndex: index})
  | SetLinkDraft(draft) => Some({...state, linkDraft: draft})
  | SetIsLinking(val) => Some({...state, isLinking: val})
  | SetIsTeasing(val) => Some({...state, isTeasing: val})
  | _ => None
  }
}
