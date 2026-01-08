/**
 * LinkModal Component
 * 
 * Displays an interactive modal for creating navigation links between panoramic scenes.
 * Includes smart auto-selection and bidirectional linking capabilities.
 * 
 * @module LinkModal
 */

import { store } from "../store.js";

import {
  HOTSPOT_VISUAL_OFFSET_DEGREES,

  RETURN_LINK_DEFAULT_PITCH,
} from "../constants.js";

/**
 * Display the link creation modal
 * 
 * This modal allows users to:
 * - Select a destination scene for navigation
 * - Save the current camera view as the link's target orientation
 * - Optionally create a bidirectional link (auto-return)
 * 
 * @param {number} pitch - Vertical angle where user clicked (degrees, -90 to 90)
 * @param {number} yaw - Horizontal angle where user clicked (degrees, 0 to 360)
 * @param {number} camPitch - Current camera pitch for view frame
 * @param {number} camYaw - Current camera yaw for view frame
 * @param {number} camHfov - Current camera field of view
 * 
 * @example
 * // Called when user clicks in linking mode
 * @example
 * // Called when user clicks in linking mode
 * showLinkModal(-10, 180, -5, 175, 90, "Living Room");
 */
export function showLinkModal(pitch, yaw, camPitch, camYaw, camHfov, pendingReturnSceneName = null, linkDraft = null) {
  const state = store.state;
  const container = document.getElementById("modal-container");

  // SMART SELECTION: 
  // 1. If we have a pending return scene (from Smart Prompt), prioritize it.
  // 2. Otherwise, pre-select the next sequential scene.
  const nextIndex = state.activeIndex + 1;

  // Build accessible modal with ARIA attributes - Premium Blue Theme
  container.innerHTML = `
        <div 
          class="modal-overlay" 
          role="dialog" 
          aria-labelledby="modal-title"
          aria-describedby="modal-description"
          style="background: rgba(0,0,0,0.7); backdrop-filter: blur(12px);"
        >
            <div class="modal-box-premium" style="max-width: 360px; text-align: left;">
                <div style="text-align: center; margin-bottom: 16px;">
                    <span class="material-icons" style="font-size: 40px; color: #fbbf24; filter: drop-shadow(0 0 12px rgba(251, 191, 36, 0.4));">add_link</span>
                </div>
                <h3 id="modal-title" style="margin: 0 0 4px 0; font-size: 20px; font-weight: 800; letter-spacing: -0.02em; text-align: center; color: white;">Link Destination</h3>
                <p 
                  id="modal-description" 
                  style="font-size: 13px; color: rgba(255,255,255,0.6); margin-bottom: 16px; text-align: center;"
                >
                    Saving current view as "Target"
                </p>
                <label for="link-target" class="sr-only">Select destination room</label>
                <select 
                  id="link-target" 
                  style="width: 100%; height: 44px; padding: 0 36px 0 12px; margin-bottom: 16px; background-color: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.15); border-radius: 10px; color: white; font-weight: 600; font-size: 13px; outline: none; cursor: pointer; appearance: none; background-image: url('data:image/svg+xml,%3Csvg fill%3D%22%23ffffff%22 height%3D%2224%22 viewBox%3D%220 0 24 24%22 width%3D%2224%22 xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Cpath d%3D%22M7 10l5 5 5-5z%22%2F%3E%3C%2Fsvg%3E'); background-repeat: no-repeat; background-position: right 10px center; background-size: 20px;"
                  aria-label="Select destination room for navigation link"
                >
                    <option value="" style="background: #1e293b;">-- Select Room --</option>
                    ${state.scenes
      .map((s, i) => {
        // AUTO-SELECT LOGIC: 
        // 1. Pending Return Scene (High Priority)
        if (pendingReturnSceneName && s.name === pendingReturnSceneName) return `<option value="${s.name}" selected style="background: #1e293b;">${s.name}</option>`;

        // 2. Next Sequential Scene (Low Priority)
        const isNext = (!pendingReturnSceneName && i === nextIndex) ? "selected" : "";

        // Don't allow linking to self (would create infinite loop)
        if (i === state.activeIndex) return "";
        return `<option value="${s.name}" ${isNext} style="background: #1e293b;">${s.name}</option>`;
      })
      .join("")}
                </select>
                
                <div style="margin-top: 8px; display: none; flex-direction: column; gap: 12px; padding: 16px; background: rgba(255,255,255,0.05); border-radius: 12px; border: 1px solid rgba(255,255,255,0.1);">
                    <!-- Checkboxes hidden: functionality moved to hover buttons -->
                </div>
                
                <div style="display: flex; flex-direction: column; gap: 8px; margin-top: 20px;">
                    <button 
                      class="modal-btn-premium btn-blue" 
                      id="save-link"
                      style="width: 100%;"
                      aria-label="Save navigation link"
                    >
                      <span class="material-icons" style="font-size: 18px;">check</span>
                      <span>Save Link</span>
                    </button>
                    <button 
                      class="modal-btn-premium btn-secondary" 
                      id="cancel-link" 
                      style="width: 100%;"
                      aria-label="Cancel link creation"
                    >
                      <span>Cancel</span>
                    </button>
                </div>
            </div>
        </div>
    `;


  /**
   * Helper: Update Auto-Forward initial logic (no longer visible in modal)
   */
  const targetSelect = document.getElementById("link-target");

  /**
   * Handle link save action
   * Creates forward link and optionally a return link
   */
  const saveButton = document.getElementById("save-link");
  saveButton.onclick = () => {
    const targetName = document.getElementById("link-target").value;

    // Default values for new links - can be changed via hover buttons
    const isReturnLink = !!pendingReturnSceneName;
    const targetIdx = state.scenes.findIndex(s => s.name === targetName);
    const targetScene = state.scenes[targetIdx];
    const isAutoForward = targetScene ? !!targetScene.isAutoForward : false;

    if (!targetName) {
      if (window.notify) window.notify("Please select a destination room", "warning");
      return;
    }

    // 1. Check for Duplicate Link in current scene
    const exists = state.scenes[state.activeIndex].hotspots.some(h => h.target === targetName);
    if (exists) {
      if (window.notify) window.notify("A link to this room already exists here!", "warning");
      return;
    }

    // 2. Calculate display pitch (visual offset for "floor-level" arrow appearance)
    const displayPitch = pitch - HOTSPOT_VISUAL_OFFSET_DEGREES;

    // 3. Save Forward Link with Metadata
    store.addHotspot(state.activeIndex, {
      pitch: pitch,
      displayPitch: displayPitch,
      yaw,
      startPitch: linkDraft ? linkDraft.camPitch : camPitch,
      startYaw: linkDraft ? linkDraft.camYaw : camYaw,
      startHfov: linkDraft ? linkDraft.camHfov : camHfov,
      target: targetName,
      viewFrame: {
        pitch: camPitch,
        yaw: camYaw,
        hfov: camHfov
      },
      returnViewFrame: isReturnLink ? {
        pitch: camPitch,
        yaw: camYaw,
        hfov: camHfov
      } : null,
      isReturnLink: isReturnLink
    }, true);

    // Close modal and update UI
    container.innerHTML = "";
    store.state.isLinking = false;
    store.setLinkDraft(null); // Triggers notify()
  };

  /**
   * Handle cancel action
   * Closes modal without saving
   */
  const cancelButton = document.getElementById("cancel-link");
  cancelButton.onclick = () => {
    container.innerHTML = "";
    store.state.isLinking = false;
    store.setLinkDraft(null); // Triggers notify()
  };

  // Keyboard accessibility: Escape key closes modal
  const handleKeyDown = (e) => {
    if (e.key === "Escape") {
      cancelButton.click();
      document.removeEventListener("keydown", handleKeyDown);
    }
  };
  document.addEventListener("keydown", handleKeyDown);

  // Focus the select dropdown for immediate keyboard navigation
  setTimeout(() => {
    document.getElementById("link-target")?.focus();
  }, 100);
}
