/**
 * HotspotManager Component
 * Handles hotspot configuration and synchronization for the panorama viewer
 * 
 * @module HotspotManager
 */

import { store } from "../store.js";

/**
 * Create hotspot configuration for Pannellum
 * @param {Object} h - Hotspot data object
 * @param {number} i - Hotspot index
 * @param {Object} state - Current application state
 * @param {Object} scene - Current scene object
 * @param {Object|null} incomingLink - Link navigation history { sceneIndex, hotspotIndex }
 * @param {boolean} isSimulationMode - Whether simulation mode is active
 * @param {Function} navigateToScene - Navigation callback function
 * @returns {Object} Pannellum hotspot configuration
 */
export function createHotspotConfig(h, i, state, scene, incomingLink, isSimulationMode, navigateToScene) {
    const targetScene = state.scenes.find(s => s.name === h.target);
    // NAVIGATION LOGIC: Identify if this is the link we just came from
    const isReturnLink = incomingLink && state.scenes[incomingLink.sceneIndex]?.name === h.target;
    const isAutoForwardScene = scene.isAutoForward;

    // CSS Class Construction
    let cssClass = "flat-arrow";
    if (isReturnLink) cssClass += " return-link";
    if (isSimulationMode) cssClass += " in-simulation";
    if (isSimulationMode && isAutoForwardScene) cssClass += " hidden-in-sim";

    return {
        id: `hs_${i}`,
        pitch: h.displayPitch !== undefined ? h.displayPitch : h.pitch,
        yaw: h.yaw,
        type: "info",
        cssClass: cssClass,
        createTooltipFunc: (div) => {
            // Visual Feedback in Tooltip
            const isAutoForwardTarget = targetScene && targetScene.isAutoForward;
            div.innerHTML = `
        <div class="hotspot-delete-btn" title="Delete Link">✕</div>
        <svg class="custom-arrow-svg" viewBox="0 0 100 100">
          <defs><linearGradient id="hsG_${i}" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#FFD700"/><stop offset="100%" style="stop-color:#FDB931"/></linearGradient></defs>
          <path d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" fill="url(#hsG_${i})" />
          <path class="glow-unit glow-top" d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z" />
          <path class="glow-unit glow-bottom" d="M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" />
        </svg>
      `;

            // Ensure tooltip content is interactive
            div.style.pointerEvents = 'auto';
            div.style.cursor = 'default';

            // Direct click on the tooltip div for navigation
            div.onclick = (e) => {
                const deleteBtn = e.target.closest('.hotspot-delete-btn');

                // 1. Delete Link
                if (deleteBtn) {
                    e.stopPropagation(); e.preventDefault();
                    store.removeHotspot(state.activeIndex, i);
                    if (window.notify) window.notify("Link deleted", "info");
                    return;
                }

                // 2. Navigation
                if (targetScene) {
                    const targetIndex = state.scenes.findIndex(s => s.name === h.target);
                    if (targetIndex !== -1) {
                        // USE CENTRALIZED NAVIGATION: Ensures consistent tracking
                        navigateToScene(targetIndex, state.activeIndex, i, h.targetYaw || 0, h.viewFrame ? h.viewFrame.pitch : 0);
                    }
                }
            };
        }
    };
}

/**
 * Synchronize hotspots with the viewer
 * @param {Object} v - Pannellum viewer instance
 * @param {Object} state - Current application state
 * @param {Object} scene - Current scene object
 * @param {Object|null} incomingLink - Link navigation history
 * @param {boolean} isSimulationMode - Whether simulation mode is active  
 * @param {Function} navigateToScene - Navigation callback function
 */
export function syncHotspots(v, state, scene, incomingLink, isSimulationMode, navigateToScene) {
    if (!v) return;
    // GUARD: Validate scene and hotspots array exist
    if (!scene || !Array.isArray(scene.hotspots)) {
        console.warn('[HotspotManager] Invalid scene or missing hotspots array');
        return;
    }
    const hs = v.getConfig().hotSpots || [];
    hs.forEach(h => { if (h.id) v.removeHotSpot(h.id); });
    scene.hotspots.forEach((h, i) => v.addHotSpot(
        createHotspotConfig(h, i, state, scene, incomingLink, isSimulationMode, navigateToScene)
    ));
}
