/* src/systems/NavigationUI.res */
open ReBindings
open Types

module WebApi = {
  @val external requestAnimationFrame: (unit => unit) => unit = "requestAnimationFrame"
}

module DomExt = {
  @set external setTextContent: (Dom.element, string) => unit = "textContent"
}

let updateReturnPrompt = (state: state, scene: scene) => {
  let promptOpt = Dom.getElementById("return-link-prompt")->Nullable.toOption

  switch promptOpt {
  | None => ()
  | Some(prompt) =>
    if state.isLinking {
      Dom.add(prompt, "hidden")
      Dom.remove(prompt, "flex")
    } else {
      switch state.incomingLink {
      | None =>
        Dom.add(prompt, "hidden")
        Dom.remove(prompt, "flex")
      | Some(incoming) =>
        let sourceSceneOpt = Belt.Array.get(state.scenes, incoming.sceneIndex)
        switch sourceSceneOpt {
        | None => ()
        | Some(sourceScene) =>
          // Check if return link exists
          let hasReturnLink = Js.Array.some(h => {
            h.target == sourceScene.name &&
              switch h.isReturnLink {
              | Some(true) => true
              | _ => false
              }
          }, scene.hotspots)

          if hasReturnLink {
            Dom.add(prompt, "hidden")
            Dom.remove(prompt, "flex")
          } else {
            let textElOpt = Dom.querySelector(prompt, ".return-link-text")->Nullable.toOption
            switch textElOpt {
            | Some(el) => DomExt.setTextContent(el, "Return to " ++ sourceScene.name)
            | None => ()
            }

            Dom.remove(prompt, "hidden")
            Dom.add(prompt, "flex")

            WebApi.requestAnimationFrame(() => {
              Dom.add(prompt, "visible")
            })
          }
        }
      }
    }
  }
}
