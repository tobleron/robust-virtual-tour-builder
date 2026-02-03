/* src/hooks/useIsInteractionPermitted.res */

let useIsInteractionPermitted = () => {
  let isQueueProcessing = AppContext.useIsSystemLocked()
  let isModalOpen = ModalContext.useIsModalOpen()
  let navigationFsm = AppContext.useNavigationFsm()

  let isTransitioning = switch navigationFsm {
  | Idle | Error(_) => false
  | _ => true
  }

  !(isQueueProcessing || isModalOpen || isTransitioning)
}
