/* src/utils/LazyLoad.res */

open ReBindings

let pannellumLoaded: ref<bool> = ref(false)
let jszipLoaded: ref<bool> = ref(false)
let fileSaverLoaded: ref<bool> = ref(false)

let checkGlobal = (_name: string): bool => {
  %raw(`typeof window[_name] !== 'undefined'`)
}

let loadScript = (src: string, globalName: option<string>) => {
  Promise.make((resolve, _reject) => {
    switch globalName {
    | Some(name) if checkGlobal(name) => resolve()
    | _ =>
      /* Check if script is already in document */
      let scripts = Dom.querySelectorAllDoc("script[src=\"" ++ src ++ "\"]")
      let scriptsCount = Dom.nodeListLength(scripts)

      if scriptsCount > 0 {
        /* Script exists but global might not be ready. Poll for it. */
        let attempts = ref(0)
        let rec check = () => {
          switch globalName {
          | Some(name) =>
            if checkGlobal(name) {
              resolve()
            } else if attempts.contents > 50 {
              /* 5 seconds timeout */
              Logger.error(~module_="LazyLoad", ~message="SCRIPT_TIMEOUT", ~data={"src": src}, ())
              resolve()
            } else {
              attempts := attempts.contents + 1
              let _ = setTimeout(check, 100)
            }
          | None => resolve() /* Cannot verify, assume loaded */
          }
        }
        check()
      } else {
        let script = Dom.createElement("script")
        Dom.setAttribute(script, "src", src)

        Dom.addEventListenerNoEv(script, "load", () => {
          resolve()
        })

        Dom.addEventListenerNoEv(script, "error", () => {
          Logger.error(
            ~module_="LazyLoad",
            ~message="FAILED_TO_LOAD_SCRIPT",
            ~data={"src": src},
            (),
          )
          resolve()
        })

        Dom.appendChild(Dom.documentBody, script)
      }
    }
  })
}

let loadPannellum = () => {
  if pannellumLoaded.contents {
    Promise.resolve()
  } else {
    loadScript("/libs/pannellum.js", Some("pannellum"))->Promise.then(() => {
      pannellumLoaded := true
      Promise.resolve()
    })
  }
}

let loadJSZip = () => {
  if jszipLoaded.contents {
    Promise.resolve()
  } else {
    loadScript("/libs/jszip.min.js", Some("JSZip"))->Promise.then(() => {
      jszipLoaded := true
      Promise.resolve()
    })
  }
}

let loadFileSaver = () => {
  if fileSaverLoaded.contents {
    Promise.resolve()
  } else {
    /* FileSaver doesn't always expose a predictable global, sometimes `saveAs` */
    loadScript("/libs/FileSaver.min.js", None)->Promise.then(() => {
      fileSaverLoaded := true
      Promise.resolve()
    })
  }
}
