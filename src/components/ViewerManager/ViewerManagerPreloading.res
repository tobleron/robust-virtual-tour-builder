// @efficiency-role: ui-component

open ReBindings
open ViewerState
open Types
open Actions

// Hook 3: Preloading
let usePreloading = (
  ~preloadingSceneIndex: int,
  ~scenes: array<scene>,
  ~activeIndex: int,
  ~dispatch: action => unit,
) => {
  React.useEffect1(() => {
    if (
      preloadingSceneIndex != -1 &&
      preloadingSceneIndex != ViewerState.state.contents.lastPreloadingIndex &&
      preloadingSceneIndex != activeIndex
    ) {
      ViewerState.state := {
          ...ViewerState.state.contents,
          lastPreloadingIndex: preloadingSceneIndex,
        }
      switch Belt.Array.get(scenes, preloadingSceneIndex) {
      | Some(s) =>
        dispatch(DispatchNavigationFsmEvent(StartAnticipatoryLoad({targetSceneId: s.id})))
      | None => ()
      }
    }
    None
  }, [preloadingSceneIndex])
}
