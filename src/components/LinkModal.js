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
export function showLinkModal(pitch, yaw, camPitch, camYaw, camHfov, pendingReturnSceneName = null) {
  const state = store.state;
  const container = document.getElementById("modal-container");

  // SMART SELECTION: 
  // 1. If we have a pending return scene (from Smart Prompt), prioritize it.
  // 2. Otherwise, pre-select the next sequential scene.
  const nextIndex = state.activeIndex + 1;

  // Build accessible modal with ARIA attributes
  container.innerHTML = `
        <div 
          class="modal-overlay" 
          role="dialog" 
          aria-labelledby="modal-title"
          aria-describedby="modal-description"
        >
            <div class="modal-box">
                <h3 id="modal-title">Link Destination</h3>
                <p 
                  id="modal-description" 
                  style="font-size:12px; color:#666; margin-bottom:10px;"
                >
                    Saving current view as "Target"
                </p>
                <label for="link-target" class="sr-only">Select destination room</label>
                <select 
                  id="link-target" 
                  style="width: 100%; padding: 8px; margin-bottom: 10px;"
                  aria-label="Select destination room for navigation link"
                >
                    <option value="">-- Select Room --</option>
                    ${state.scenes
      .map((s, i) => {
        // AUTO-SELECT LOGIC: 
        // 1. Pending Return Scene (High Priority)
        if (pendingReturnSceneName && s.name === pendingReturnSceneName) return `<option value="${s.name}" selected>${s.name}</option>`;

        // 2. Next Sequential Scene (Low Priority)
        const isNext = (!pendingReturnSceneName && i === nextIndex) ? "selected" : "";

        // Don't allow linking to self (would create infinite loop)
        if (i === state.activeIndex) return "";
        return `<option value="${s.name}" ${isNext}>${s.name}</option>`;
      })
      .join("")}
                </select>
                
                <div style="margin-top: 15px; display: flex; flex-direction: column; gap: 8px;">
                    <!-- Return Link Checkbox -->
                    <div style="display: flex; align-items: flex-start;">
                        <input 
                          type="checkbox" 
                          id="is-return-link" 
                          style="margin-top: 4px;"
                        >
                        <div style="margin-left: 8px;">
                            <label for="is-return-link" style="font-weight: 600; font-size: 14px; display: block;">
                                Return Link
                            </label>
                            <span style="font-size: 11px; color: #666; display: block; line-height: 1.4; margin-top: 2px;">
                              ↩ Check this if you're creating a link back/exit. Camera will look straight ahead (horizon) when arriving.
                            </span>
                        </div>
                    </div>

                    <!-- Auto-Forward Scene Checkbox -->
                    <div style="display: flex; align-items: flex-start;">
                        <input 
                          type="checkbox" 
                          id="is-auto-forward" 
                           style="margin-top: 4px;"
                        >
                        <div style="margin-left: 8px;">
                            <label for="is-auto-forward" style="font-weight: 600; font-size: 14px; display: block;">
                                Auto-Forward Scene (Bridge)
                            </label>
                            <span style="font-size: 11px; color: #666; display: block; line-height: 1.4; margin-top: 2px;">
                              ⚡ Target scene will automatically forward to next link in Simulation Mode (useful for hallways, staircases).
                            </span>
                        </div>
                    </div>
                </div>
                <hr style="margin: 15px 0; border: 0; border-top: 1px solid #eee;" aria-hidden="true">
                
                <button 
                  class="btn btn-primary" 
                  id="save-link"
                  aria-label="Save navigation link"
                >
                  Save Link
                </button>
                <button 
                  class="btn" 
                  id="cancel-link" 
                  style="background:#ccc; color:#333"
                  aria-label="Cancel link creation"
                >
                  Cancel
                </button>
            </div>
        </div>
    `;

  /**
   * Helper: Update Auto-Forward checkbox based on selected scene
   */
  const targetSelect = document.getElementById("link-target");
  const autoForwardCheck = document.getElementById("is-auto-forward");
  const returnCheck = document.getElementById("is-return-link");

  // Initial State Logic
  const updateAutoForwardCheck = () => {
    const name = targetSelect.value;
    const scene = state.scenes.find(s => s.name === name);
    if (scene) {
      autoForwardCheck.checked = !!scene.isAutoForward;
    } else {
      autoForwardCheck.checked = false;
    }
  };

  // 1. Set Return Link Default: Checked ONLY if we are in "Assist Mode" (pending return scene exists)
  // Otherwise false (standard manual link)
  if (pendingReturnSceneName) {
    returnCheck.checked = true;
  } else {
    returnCheck.checked = false;
  }

  // 2. Set Auto-Forward initial state
  updateAutoForwardCheck();

  // 3. Listen for changes
  targetSelect.addEventListener("change", updateAutoForwardCheck);

  /**
   * Handle link save action
   * Creates forward link and optionally a return link
   */
  const saveButton = document.getElementById("save-link");
  saveButton.onclick = () => {
    const targetName = document.getElementById("link-target").value;
    const isReturnLink = document.getElementById("is-return-link").checked;
    const isAutoForward = document.getElementById("is-auto-forward").checked;

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
      pitch: pitch,        // Original eye-level click point (used for zoom targeting)
      displayPitch: displayPitch, // Visual arrow location (appears at floor level)
      yaw,
      target: targetName,
      // Prioritize Horizon (0) if it's a return link, else preserve camPitch as fallback
      viewFrame: {
        pitch: isReturnLink ? 0 : camPitch,
        yaw: camYaw,
        hfov: camHfov
      },
      isReturnLink: isReturnLink // Tag for future logic
    }, true); // Skip immediate notify for batch update

    // 4. Update Target Scene Metadata (Auto-Forward Status)
    const targetIndex = state.scenes.findIndex(s => s.name === targetName);
    if (targetIndex !== -1) {
      // Only update if changed to prevent unnecessary writes, though updateSceneMetadata handles diffs
      store.updateSceneMetadata(targetIndex, { isAutoForward: isAutoForward });
    }

    // Close modal and update UI
    container.innerHTML = "";
    store.state.isLinking = false;
    store.notify();
  };

  /**
   * Handle cancel action
   * Closes modal without saving
   */
  const cancelButton = document.getElementById("cancel-link");
  cancelButton.onclick = () => {
    container.innerHTML = "";
    store.state.isLinking = false;
    store.notify(); // Update UI (removes linking cursor)
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
