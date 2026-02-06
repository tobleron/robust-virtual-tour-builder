/* @efficiency-role: state-hook */

let useIsInteractionPermitted = () => {
  let isQueueProcessing = AppContext.useIsSystemLocked()
  let isModalOpen = ModalContext.useIsModalOpen()

  !(isQueueProcessing || isModalOpen)
}
