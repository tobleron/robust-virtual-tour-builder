open ReBindings

type status = [#Free | #Active | #Background]
type viewport = {
  id: string,
  containerId: string,
  instance: option<ViewerAdapter.t>,
  status: status,
  cleanupTimeout: option<int>,
}
let pool = ref([
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
])
let getViewport = id => pool.contents->Belt.Array.getBy(v => v.id == id)
let getViewportByContainer = cId => pool.contents->Belt.Array.getBy(v => v.containerId == cId)
let getActive = () => pool.contents->Belt.Array.getBy(v => v.status == #Active)
let getActiveViewer = () => getActive()->Option.flatMap(v => v.instance)
let getInactive = () => pool.contents->Belt.Array.getBy(v => v.status == #Background)
let getInactiveViewer = () => getInactive()->Option.flatMap(v => v.instance)
let swapActive = () =>
  pool :=
    pool.contents->Belt.Array.map(v => {
      ...v,
      status: switch v.status {
      | #Active => #Background
      | #Background => #Active
      | #Free => #Free
      },
    })
let registerInstance = (cId, inst) =>
  pool :=
    pool.contents->Belt.Array.map(v =>
      if v.containerId == cId {
        {...v, instance: Some(inst)}
      } else {
        v
      }
    )
let clearInstance = cId =>
  pool :=
    pool.contents->Belt.Array.map(v =>
      if v.containerId == cId {
        {...v, instance: None}
      } else {
        v
      }
    )
let setCleanupTimeout = (id, t) =>
  pool :=
    pool.contents->Belt.Array.map(v =>
      if v.id == id {
        v.cleanupTimeout->Option.forEach(Window.clearTimeout)
        {...v, cleanupTimeout: t}
      } else {
        v
      }
    )
let clearCleanupTimeout = id =>
  pool :=
    pool.contents->Belt.Array.map(v =>
      if v.id == id {
        v.cleanupTimeout->Option.forEach(Window.clearTimeout)
        {...v, cleanupTimeout: None}
      } else {
        v
      }
    )

let reset = () => {
  pool :=
    pool.contents->Belt.Array.map(v => {
      switch v.instance {
      | Some(i) => i->ViewerAdapter.destroy
      | None => ()
      }
      {
        ...v,
        instance: None,
        status: if v.id == "primary-a" {
          #Active
        } else if v.id == "primary-b" {
          #Background
        } else {
          #Free
        },
      }
    })
}
