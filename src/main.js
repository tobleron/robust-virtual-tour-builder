// ... (Canvas Fix code remains) ...

import { initSidebar } from "./components/Sidebar.js";
import { initViewer } from "./components/Viewer.js";
import { showLinkModal } from "./components/LinkModal.js";
import { store } from "./store.js";

console.log("Initializing Remax Builder...");

initSidebar();
initViewer();

// Global Event Listener
document.addEventListener("viewer-click", (e) => {
  if (store.state.isLinking) {
    // Extract All Data (Including Director Camera)
    const { pitch, yaw, camPitch, camYaw, camHfov } = e.detail;
    showLinkModal(pitch, yaw, camPitch, camYaw, camHfov);
  }
});
