/* src/systems/Navigation/NavigationUI.res */

open Types
open ReBindings

let updateReturnPrompt = (state: state, scene: scene) => {
  Dom.getElementById("return-link-prompt")
  ->Nullable.toOption
  ->Option.forEach(p => {
    if state.isLinking {
      Dom.add(p, "hidden")
      Dom.remove(p, "flex")
    } else {
      switch state.navigationState.incomingLink {
      | Some(inc) =>
        state.scenes[inc.sceneIndex]->Option.forEach(src => {
          let has = Array.some(
            scene.hotspots,
            h => h.target == src.name && h.isReturnLink == Some(true),
          )
          if has {
            Dom.add(p, "hidden")
            Dom.remove(p, "flex")
          } else {
            Dom.querySelector(p, ".return-link-text")
            ->Nullable.toOption
            ->Option.forEach(el => Dom.setTextContent(el, "Return to " ++ src.name))
            Dom.remove(p, "hidden")
            Dom.add(p, "flex")
            let _ = Window.requestAnimationFrame(() => Dom.add(p, "visible"))
          }
        })
      | None =>
        Dom.add(p, "hidden")
        Dom.remove(p, "flex")
      }
    }
  })
}
