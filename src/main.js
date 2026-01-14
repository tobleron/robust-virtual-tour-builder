import { updateProgressBar } from "./utils/ProgressBar.bs.js";
import { notify } from "./utils/NotificationSystem.js";
import React from "react";
import { createRoot } from "react-dom/client";


import { showLinkModal } from "./components/LinkModal.bs.js";
import { getState } from "./core/GlobalStateBridge.bs.js";
window.store = {
  get state() { return getState(); }
};
import { setupGlobalClickSounds } from "./systems/AudioManager.bs.js";
import { initSimulationKeyHandler } from "./systems/SimulationSystem.bs.js";

// Utility modules (initialized first to ensure global availability)
import { initLogger } from "./utils/Logger.js";

import { Debug } from "./utils/Debug.js";
import { initInputSystem } from "./systems/InputSystem.bs.js";

Debug.info('System', "Initializing Remax Builder...");

// --- SYSTEM TELEMETRY ---
(async () => {
  try {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    const debugInfo = gl ? gl.getExtension('WEBGL_debug_renderer_info') : null;
    const renderer = debugInfo ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) : 'unknown';
    const vendor = debugInfo ? gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL) : 'unknown';

    Debug.info('System', 'Application Startup', {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      cores: navigator.hardwareConcurrency,
      memory: navigator.deviceMemory ? `${navigator.deviceMemory}GB` : 'unknown',
      screen: `${window.screen.width}x${window.screen.height} (${window.devicePixelRatio}x)`,
      gpu: { renderer, vendor },
      url: window.location.href,
      version: typeof window.APP_VERSION !== 'undefined' ? window.APP_VERSION : 'unknown'
    });
  } catch (e) {
    console.warn("Failed to collect system telemetry", e);
  }
})();

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

// Initialize components
// Initialize components
const sidebarContainer = document.getElementById("sidebar"); // Ensure this exists

// Mount ViewerUI Container (for Portal target)
const viewerStage = document.getElementById("viewer-stage");
const uiLayer = document.createElement("div");
uiLayer.id = "viewer-ui-layer";
uiLayer.className = "absolute inset-0 w-full h-full pointer-events-none";
viewerStage.appendChild(uiLayer);

// Create Headless Root for App (since it portals everything)
const appRootContainer = document.createElement("div");
appRootContainer.id = "react-app-controller";
document.body.appendChild(appRootContainer);

import { make as App } from "./App.bs.js";
const root = createRoot(appRootContainer);
root.render(React.createElement(App, {}));


setupGlobalClickSounds();

// Initialize Visual Pipeline
import { init as initVisualPipeline } from "./components/VisualPipeline.bs.js";
initVisualPipeline("visual-pipeline-container");

// Initialize simulation ESC key handler
initSimulationKeyHandler();
initInputSystem();

// Global Event Listener
document.addEventListener("viewer-click", (e) => {
  if (getState().isLinking) {
    // Extract All Data (Including Director Camera)
    const { pitch, yaw, camPitch, camYaw, camHfov } = e.detail;
    showLinkModal(pitch, yaw, camPitch, camYaw, camHfov);
  }
});
