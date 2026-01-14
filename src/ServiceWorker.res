/**
 * ServiceWorker.res
 * 
 * Type-safe bindings for Service Worker registration.
 * Enables offline capability and asset caching for faster repeat loads.
 */

// External bindings for Service Worker API
type serviceWorkerContainer
type serviceWorkerRegistration

@val @scope(("window", "navigator"))
external serviceWorker: option<serviceWorkerContainer> = "serviceWorker"

@send
external register: (serviceWorkerContainer, string) => Promise.t<serviceWorkerRegistration> =
  "register"

@send
external getRegistration: (serviceWorkerContainer, unit) => Promise.t<Nullable.t<serviceWorkerRegistration>> = "getRegistration"

@send
external unregister: (serviceWorkerRegistration, unit) => Promise.t<bool> = "unregister"

/**
 * Register the service worker.
 * Returns a promise that resolves when registration is complete.
 */
let registerServiceWorker = () => {
  switch serviceWorker {
  | Some(sw) =>
    sw
    ->register("/service-worker.js")
    ->Promise.then(registration => {
      Logger.info(
        ~module_="ServiceWorker",
        ~message="Service Worker registered successfully",
        ~data=Some({"scope": registration->Obj.magic}),
        ()
      )
      Promise.resolve()
    })
    ->Promise.catch(error => {
      Logger.error(
        ~module_="ServiceWorker",
        ~message="Service Worker registration failed",
        ~data=Some({"error": error->Obj.magic}),
        ()
      )
      Promise.resolve()
    })
    ->ignore
  | None =>
    Logger.warn(
      ~module_="ServiceWorker",
      ~message="Service Workers not supported in this browser",
      ()
    )
  }
}

/**
 * Unregister all service workers.
 * Useful for debugging or cleanup.
 */
let unregisterServiceWorker = () => {
  switch serviceWorker {
  | Some(sw) =>
    sw
    ->getRegistration()
    ->Promise.then(regOpt => {
      switch regOpt->Nullable.toOption {
      | Some(registration) =>
        registration
        ->unregister()
        ->Promise.then(success => {
          if success {
            Logger.info(
              ~module_="ServiceWorker",
              ~message="Service Worker unregistered successfully",
              ()
            )
          }
          Promise.resolve()
        })
      | None => Promise.resolve()
      }
    })
    ->ignore
  | None => ()
  }
}
