/* @efficiency-role: state-hook */

let useIsInteractionPermitted = () => {
  let isQueueProcessing = Capability.useIsSystemLocked()
  let isModalOpen = ModalContext.useIsModalOpen()

  !(isQueueProcessing || isModalOpen)
}
