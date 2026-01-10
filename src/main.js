import { initSidebar } from "./components/Sidebar.js";
import { initViewer } from "./components/Viewer.js";
import { showLinkModal } from "./components/LinkModal.js";
import { store } from "./store.js";
import { setupGlobalClickSounds } from "./systems/AudioManager.js";
import { initSimulationKeyHandler } from "./systems/SimulationSystem.js";

// Utility modules (initialized first to ensure global availability)
import { initLogger } from "./utils/Logger.js";
import { initNotificationSystem } from "./utils/NotificationSystem.js";
import { initProgressBar } from "./utils/ProgressBar.js";

import { Debug } from "./utils/Debug.js";

console.log("Initializing Remax Builder...");

// Global Error Handler for Telemetry
window.onerror = (message, source, lineno, colno, error) => {
  Debug.error("Global", `Uncaught Error: ${message}`, {
    source,
    lineno,
    colno,
    stack: error?.stack,
    type: error?.name || 'Error'
  });
};

window.onunhandledrejection = (event) => {
  const reason = event.reason;
  Debug.error("Global", "Unhandled Promise Rejection", {
    reason: reason instanceof Error ? reason.message : reason,
    stack: reason instanceof Error ? reason.stack : null,
    promise: event.promise
  });

  // Prevent default browser console error in production to avoid noise
  // (Debug system already logs to backend)
  if (!window.location.hostname.includes('localhost')) {
    event.preventDefault();
  }
};

// Initialize utilities first (they attach to window object)
initLogger();
initNotificationSystem();
initProgressBar();

// Initialize components
initSidebar();
initViewer();
setupGlobalClickSounds();

// Initialize simulation ESC key handler
initSimulationKeyHandler();

// Global Event Listener
document.addEventListener("viewer-click", (e) => {
  if (store.state.isLinking) {
    // Extract All Data (Including Director Camera)
    const { pitch, yaw, camPitch, camYaw, camHfov } = e.detail;
    showLinkModal(pitch, yaw, camPitch, camYaw, camHfov);
  }
});
