/* src/systems/ViewerPool.res */

type viewportStatus = [#Free | #Active | #Background]

type viewport = {
  id: string,
  containerId: string,
  mutable instance: option<PannellumAdapter.t>,
  mutable status: viewportStatus,
  mutable cleanupTimeout: option<int>,
}

let pool: array<viewport> = [
  {
    id: "primary-a",
    containerId: "panorama-a",
    instance: None,
    status: #Active,
    cleanupTimeout: None,
  },
  {
    id: "primary-b",
    containerId: "panorama-b",
    instance: None,
    status: #Background,
    cleanupTimeout: None,
  },
]

let getViewport = (id: string) => {
  pool->Belt.Array.getBy(v => v.id == id)
}

let getViewportByContainer = (containerId: string) => {
  pool->Belt.Array.getBy(v => v.containerId == containerId)
}

let getActive = () => {
  pool->Belt.Array.getBy(v => v.status == #Active)
}

let getActiveViewer = () => {
  switch getActive() {
  | Some(v) => v.instance
  | None => None
  }
}

let getInactive = () => {
  pool->Belt.Array.getBy(v => v.status == #Background)
}

let getInactiveViewer = () => {
  switch getInactive() {
  | Some(v) => v.instance
  | None => None
  }
}

let swapActive = () => {
  pool->Belt.Array.forEach(v => {
    v.status = switch v.status {
    | #Active => #Background
    | #Background => #Active
    | #Free => #Free
    }
  })
}

let registerInstance = (containerId: string, instance: PannellumAdapter.t) => {
  pool->Belt.Array.forEach(v => {
    if v.containerId == containerId {
      v.instance = Some(instance)
    }
  })
}

let clearInstance = (containerId: string) => {
  pool->Belt.Array.forEach(v => {
    if v.containerId == containerId {
      v.instance = None
    }
  })
}

let setCleanupTimeout = (id: string, timeout: option<int>) => {
  pool->Belt.Array.forEach(v => {
    if v.id == id {
      // Clear existing if any
      switch (v.cleanupTimeout, timeout) {
      | (Some(old), Some(_)) => ReBindings.Window.clearTimeout(old)
      | _ => ()
      }
      v.cleanupTimeout = timeout
    }
  })
}

let clearCleanupTimeout = (id: string) => {
  pool->Belt.Array.forEach(v => {
    if v.id == id {
      switch v.cleanupTimeout {
      | Some(t) => ReBindings.Window.clearTimeout(t)
      | None => ()
      }
      v.cleanupTimeout = None
    }
  })
}
