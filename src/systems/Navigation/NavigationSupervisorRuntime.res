let notifyListeners = (statusValue, listenersRef: ref<array<'status => unit>>) => {
  listenersRef.contents->Belt.Array.forEach(cb => {
    try {
      cb(statusValue)
    } catch {
    | exn =>
      let (msg, _) = Logger.getErrorDetails(exn)
      Logger.error(
        ~module_="NavigationSupervisor",
        ~message="LISTENER_ERROR",
        ~data=Some({"error": msg}),
        (),
      )
    }
  })
}

let addStatusListener = (listenersRef: ref<array<'status => unit>>, cb: 'status => unit) => {
  listenersRef := Belt.Array.concat(listenersRef.contents, [cb])
  () => {
    listenersRef := listenersRef.contents->Belt.Array.keep(x => x !== cb)
  }
}
