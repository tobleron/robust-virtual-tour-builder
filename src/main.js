import { initSidebar } from "./components/Sidebar.js";
import { initViewer } from "./components/Viewer.js";
import { showLinkModal } from "./components/LinkModal.js";
import { store } from "./store.js";
import { setupGlobalClickSounds } from "./systems/AudioManager.js";

// Utility modules (initialized first to ensure global availability)
import { initLogger } from "./utils/Logger.js";
import { initNotificationSystem } from "./utils/NotificationSystem.js";
import { initProgressBar } from "./utils/ProgressBar.js";

console.log("Initializing Remax Builder...");

// Initialize utilities first (they attach to window object)
initLogger();
initNotificationSystem();
initProgressBar();

// Initialize components
initSidebar();
initViewer();
setupGlobalClickSounds();

// Global Event Listener
document.addEventListener("viewer-click", (e) => {
  if (store.state.isLinking) {
    // Extract All Data (Including Director Camera)
    const { pitch, yaw, camPitch, camYaw, camHfov } = e.detail;
    showLinkModal(pitch, yaw, camPitch, camYaw, camHfov);
  }
});
