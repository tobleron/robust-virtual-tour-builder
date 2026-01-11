import { notify } from "../utils/NotificationSystem.js";
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
 * Escape HTML special characters to prevent XSS attacks
 * @param {string} unsafe - Potentially unsafe user input
 * @returns {string} Sanitized string safe for HTML injection
 */
function escapeHtml(unsafe) {
  if (!unsafe) return '';
  return String(unsafe)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

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
import { ModalManager } from "../utils/ModalManager.js";

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

  // SMART SELECTION: 
  // 1. If we have a pending return scene (from Smart Prompt), prioritize it.
  // 2. Otherwise, pre-select the next sequential scene.
  const nextIndex = state.activeIndex + 1;

  ModalManager.show({
    title: "Link Destination",
    description: "Saving current view as \"Target\"",
    icon: "add_link",
    onClose: () => {
      store.state.isLinking = false;
      store.setLinkDraft(null);
    },
    contentHtml: `
        <label for="link-target" class="sr-only">Select destination room</label>
        <select 
          id="link-target" 
          style="width: 100%; height: 44px; padding: 0 36px 0 12px; margin-bottom: 16px; background-color: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.15); border-radius: 10px; color: white; font-weight: 600; font-size: 13px; outline: none; cursor: pointer; appearance: none; background-image: url('data:image/svg+xml,%3Csvg fill%3D%22%23ffffff%22 height%3D%2224%22 viewBox%3D%220 0 24 24%22 width%3D%2224%22 xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Cpath d%3D%22M7 10l5 5 5-5z%22%2F%3E%3C%2Fsvg%3E'); background-repeat: no-repeat; background-position: right 10px center; background-size: 20px;"
          aria-label="Select destination room for navigation link"
        >
            <option value="" style="background: #1e293b;">-- Select Room --</option>
            ${state.scenes
        .map((s, i) => {
          // Sanitize scene name to prevent XSS
          const safeName = escapeHtml(s.name);

          // AUTO-SELECT LOGIC: 
          // 1. Pending Return Scene (High Priority)
          if (pendingReturnSceneName && s.name === pendingReturnSceneName) {
            return `<option value="${safeName}" selected style="background: #1e293b;">${safeName}</option>`;
          }

          // 2. Exact Link Draft Match
          if (linkDraft && linkDraft.target === s.name) {
            return `<option value="${safeName}" selected style="background: #1e293b;">${safeName}</option>`;
          }

          // 3. Fallback: Next Sequential Scene (Low Priority)
          const isNext = (i === nextIndex && !pendingReturnSceneName && !linkDraft);
          // Don't allow linking to self (would create infinite loop)
          if (i === state.activeIndex) return "";
          return `<option value="${safeName}" ${isNext ? 'selected' : ''} style="background: #1e293b;">${safeName}</option>`;
        })
        .join("")}
        </select>
    `,
    buttons: [
      {
        label: "Save Link",
        class: "btn-blue",
        onClick: () => {
          const targetName = document.getElementById("link-target").value;
          const isReturnLink = !!pendingReturnSceneName;
          const targetIdx = state.scenes.findIndex(s => s.name === targetName);
          const targetScene = state.scenes[targetIdx];

          if (!targetName) {
            notify("Please select a destination room", "warning");
            return false; // Prevent auto-close
          }

          const exists = state.scenes[state.activeIndex].hotspots.some(h => h.target === targetName);
          if (exists) {
            notify("A link to this room already exists here!", "warning");
            return false; // Prevent auto-close
          }

          const displayPitch = pitch - HOTSPOT_VISUAL_OFFSET_DEGREES;

          store.addHotspot(state.activeIndex, {
            pitch: pitch,
            displayPitch: displayPitch,
            yaw,
            startPitch: linkDraft ? linkDraft.camPitch : camPitch,
            startYaw: linkDraft ? linkDraft.camYaw : camYaw,
            startHfov: linkDraft ? linkDraft.camHfov : camHfov,
            target: targetName,
            waypoints: (linkDraft && linkDraft.intermediatePoints)
              ? linkDraft.intermediatePoints.map(p => ({ pitch: p.camPitch, yaw: p.camYaw }))
              : [],
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

          ModalManager.close();
        },
        autoClose: false // We handle it manually
      },
      {
        label: "Cancel",
        class: "btn-secondary",
        onClick: () => {
          ModalManager.close();
        },
        autoClose: false
      }
    ]
  });

  // Focus the select dropdown
  setTimeout(() => {
    document.getElementById("link-target")?.focus();
  }, 300);
}
