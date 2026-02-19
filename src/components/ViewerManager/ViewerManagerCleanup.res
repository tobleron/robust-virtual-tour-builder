// @efficiency-role: ui-component

open ReBindings
open Types

// Hook 2: Scene Cleanup
let useSceneCleanup = (~scenes: array<scene>) => {
  React.useEffect1(() => {
    if Belt.Array.length(scenes) == 0 {
      ViewerSystem.Pool.pool.contents->Belt.Array.forEach(vVp => {
        switch vVp.instance {
        | Some(instance) => ViewerSystem.Adapter.destroy(instance)
        | None => ()
        }
      })
      ViewerSystem.Pool.reset()

      ViewerSystem.resetState()

      let pA = Dom.getElementById("panorama-a")
      let pB = Dom.getElementById("panorama-b")
      switch Nullable.toOption(pA) {
      | Some(el) => Dom.add(el, "active")
      | None => ()
      }
      switch Nullable.toOption(pB) {
      | Some(el) => Dom.remove(el, "active")
      | None => ()
      }
    }
    None
  }, [Belt.Array.length(scenes)])
}
