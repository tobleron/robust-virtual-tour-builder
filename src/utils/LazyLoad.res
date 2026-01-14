/* src/utils/LazyLoad.res */

open ReBindings

let pannellumLoaded: ref<bool> = ref(false)
let jszipLoaded: ref<bool> = ref(false)
let fileSaverLoaded: ref<bool> = ref(false)

let loadScript = (src: string) => {
  Promise.make((resolve, _reject) => {
    /* Check if script is already in document to be safe */
    let scripts = (Obj.magic(Dom.document)["querySelectorAll"]("script[src=\"" ++ src ++ "\"]"))
    let scriptsCount: int = Obj.magic(scripts)["length"]
    if scriptsCount > 0 {

       resolve()
    } else {
      let script = Dom.createElement("script")
      Dom.setAttribute(script, "src", src)
      
      Dom.addEventListenerNoEv(script, "load", () => {
        resolve()
      })
      
      Dom.addEventListenerNoEv(script, "error", () => {
        Logger.error(~module_="LazyLoad", ~message="FAILED_TO_LOAD_SCRIPT", ~data={"src": src}, ())
        resolve() /* Resolve anyway to not block app, but functionality will fail */
      })
      
      Dom.appendChild(Dom.documentBody, script)
    }
  })
}

let loadPannellum = () => {
  if pannellumLoaded.contents {
    Promise.resolve()
  } else {
    loadScript("src/libs/pannellum.js")
    ->Promise.then(() => {
      pannellumLoaded := true
      Promise.resolve()
    })
  }
}

let loadJSZip = () => {
  if jszipLoaded.contents {
    Promise.resolve()
  } else {
    loadScript("src/libs/jszip.min.js")
    ->Promise.then(() => {
      jszipLoaded := true
      Promise.resolve()
    })
  }
}

let loadFileSaver = () => {
  if fileSaverLoaded.contents {
    Promise.resolve()
  } else {
    loadScript("src/libs/FileSaver.min.js")
    ->Promise.then(() => {
      fileSaverLoaded := true
      Promise.resolve()
    })
  }
}
