/* src/systems/SceneLoaderLogicReuse.res */

open ReBindings
open ViewerState
open SceneLoaderTypes

let checkShouldReuse = (targetSceneId, targetIndex, isAnticipatory) => {
  let inactiveViewer = getInactiveViewer()
  
  switch Nullable.toOption(inactiveViewer) {
  | Some(v) =>
    let vDyn = PannellumAdapter.asCustom(v)
    let vid = vDyn.sceneId
    if vid == targetSceneId {
      if vDyn.isLoaded {
        let storeState = GlobalStateBridge.getState()
        if storeState.activeIndex == targetIndex && !isAnticipatory {
          GlobalStateBridge.dispatch(
            DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: targetSceneId})),
          )
          true
        } else {
          true /* Loaded but waiting */
        }
      } else {
        true /* Already loading this scene */
      }
    } else {
      false
    }
  | None => false
  }
}
