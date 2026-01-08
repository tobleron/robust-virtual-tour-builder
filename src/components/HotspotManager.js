/**
 * HotspotManager Component
 * Handles hotspot configuration and synchronization for the panorama viewer
 * 
 * @module HotspotManager
 */

import { store } from "../store.js";
import { Debug } from "../utils/Debug.js";

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
    const isCurrentSceneAutoForward = scene.isAutoForward;
    // Check if the TARGET scene has auto-forward enabled (for visual indicator on arrow)
    const isTargetAutoForward = targetScene && targetScene.isAutoForward;

    // CSS Class Construction
    let cssClass = "flat-arrow";
    if (isTargetAutoForward) cssClass += " auto-forward";
    if (isReturnLink) cssClass += " return-link";
    if (isSimulationMode) cssClass += " in-simulation";
    if (isSimulationMode && isCurrentSceneAutoForward) cssClass += " hidden-in-sim";

    return {
        id: `hs_${i}`,
        pitch: h.displayPitch !== undefined ? h.displayPitch : h.pitch,
        yaw: h.yaw,
        type: "info",
        cssClass: cssClass,
        createTooltipFunc: (div) => {
            const isAutoForward = isTargetAutoForward;
            const isReturn = !!h.isReturnLink;

            div.innerHTML = `
        <div class="hotspot-delete-btn" title="Delete Link">✕</div>
        <svg class="custom-arrow-svg" viewBox="0 0 100 100">
          <defs>
            <linearGradient id="hsG_${i}" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#FFD700"/><stop offset="100%" style="stop-color:#FDB931"/></linearGradient>
            <linearGradient id="autoForwardGradient" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#0d9488"/><stop offset="100%" style="stop-color:#0f766e"/></linearGradient>
          </defs>
          <path d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" fill="${isTargetAutoForward ? 'url(#autoForwardGradient)' : `url(#hsG_${i})`}" />
          <path class="glow-unit glow-top" d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z" />
          <path class="glow-unit glow-bottom" d="M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" />
        </svg>
        <div class="hotspot-controls">
          <div class="hotspot-forward-btn ${isAutoForward ? 'active' : ''}" title="Toggle Auto-Forward">A</div>
          <div class="hotspot-return-btn ${isReturn ? 'active' : ''}" title="Toggle Return Link">R</div>
        </div>
      `;

            // Ensure tooltip content is interactive
            div.style.pointerEvents = 'auto';
            div.style.cursor = 'default';

            // Direct click on the tooltip div for navigation
            div.onclick = (e) => {
                Debug.debug('Hotspot', `Click received on hotspot ${i}`, {
                    isSimulationMode,
                    targetScene: h.target,
                    eventTimestamp: Date.now()
                });

                const deleteBtn = e.target.closest('.hotspot-delete-btn');
                const forwardBtn = e.target.closest('.hotspot-forward-btn');
                const returnBtn = e.target.closest('.hotspot-return-btn');

                // 1. Delete Link
                if (deleteBtn) {
                    e.stopPropagation(); e.preventDefault();
                    store.removeHotspot(state.activeIndex, i);
                    if (window.notify) window.notify("Link deleted", "info");
                    return;
                }

                // 2. Toggle Auto-Forward (on target scene)
                if (forwardBtn) {
                    e.stopPropagation(); e.preventDefault();
                    if (targetScene) {
                        const targetIndex = state.scenes.findIndex(s => s.name === h.target);
                        const currentVal = !!targetScene.isAutoForward;
                        store.updateSceneMetadata(targetIndex, { isAutoForward: !currentVal });
                        if (window.notify) window.notify(!currentVal ? "Auto-forward: ENABLED" : "Auto-forward: DISABLED", "success");
                    }
                    return;
                }

                // 3. Toggle Return Link
                if (returnBtn) {
                    e.stopPropagation(); e.preventDefault();
                    h.isReturnLink = !h.isReturnLink;
                    // Ensure return view frame exists if enabled
                    if (h.isReturnLink && !h.returnViewFrame) {
                        h.returnViewFrame = {
                            pitch: h.viewFrame?.pitch !== undefined ? h.viewFrame.pitch : 0,
                            yaw: h.viewFrame?.yaw !== undefined ? h.viewFrame.yaw : 0,
                            hfov: h.viewFrame?.hfov !== undefined ? h.viewFrame.hfov : 90
                        };
                    }
                    store.notify(); // Re-sync UI
                    if (window.notify) window.notify(h.isReturnLink ? "Return Link: ENABLED" : "Return Link: DISABLED", "success");
                    return;
                }

                // 4. Navigation
                if (targetScene) {
                    const targetIndex = state.scenes.findIndex(s => s.name === h.target);
                    if (targetIndex !== -1) {
                        // USE CENTRALIZED NAVIGATION: Ensures consistent tracking
                        // PRIORITY LOGIC:
                        // 1. Live Saved View (h.targetYaw / h.targetPitch) - last place user looked in target
                        // 2. Director's View (h.viewFrame) - captured at link creation
                        // 3. Fallback (0, 0)

                        let navYaw = 0;
                        let navPitch = 0;
                        let navHfov = state.hfov || 90;

                        if (h.isReturnLink && h.returnViewFrame) {
                            // Return links prioritize their specific return frame
                            navYaw = h.returnViewFrame.yaw !== undefined ? h.returnViewFrame.yaw : 0;
                            navPitch = h.returnViewFrame.pitch !== undefined ? h.returnViewFrame.pitch : 0;
                            navHfov = h.returnViewFrame.hfov !== undefined ? h.returnViewFrame.hfov : 90;
                        } else {
                            // Normal links check for live-saved target view first
                            if (h.targetYaw !== undefined) {
                                navYaw = h.targetYaw;
                                navPitch = h.targetPitch !== undefined ? h.targetPitch : 0;
                                navHfov = h.targetHfov !== undefined ? h.targetHfov : 90;
                            } else if (h.viewFrame) {
                                // Fallback to original Director's View
                                navYaw = h.viewFrame.yaw !== undefined ? h.viewFrame.yaw : 0;
                                navPitch = h.viewFrame.pitch !== undefined ? h.viewFrame.pitch : 0;
                                navHfov = h.viewFrame.hfov !== undefined ? h.viewFrame.hfov : 90;
                            }
                        }

                        Debug.info('Hotspot', `Calling navigateToScene for hotspot ${i} -> ${h.target}`);
                        navigateToScene(targetIndex, state.activeIndex, i, navYaw, navPitch, navHfov);
                    } else {
                        Debug.warn('Hotspot', `Target scene ${h.target} not found`);
                    }
                } else {
                    Debug.warn('Hotspot', `No target scene defined for hotspot ${i}`);
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
