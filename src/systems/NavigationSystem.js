/**
 * NavigationSystem
 * Manages scene transitions, history, and auto-forward logic
 */

import { store } from "../store.js";

// Module State
let incomingLink = null; // { sceneIndex: int, hotspotIndex: int }
let isSimulationMode = false;
let autoForwardChain = []; // Track visited scenes to prevent infinite loops
let pendingReturnSceneName = null;

/**
 * Initialize Navigation System
 */
export function initNavigation() {
    // Simulation mode always starts OFF
    isSimulationMode = false;
}

/**
 * Getters / Setters
 */
export function getIsSimulationMode() { return isSimulationMode; }
export function setSimulationMode(val) {
    isSimulationMode = val;
    if (!val) autoForwardChain = [];
}

export function getIncomingLink() { return incomingLink; }
export function setIncomingLink(val) { incomingLink = val; }

export function getAutoForwardChain() { return autoForwardChain; }
export function resetAutoForwardChain() { autoForwardChain = []; }

export function getPendingReturnSceneName() { return pendingReturnSceneName; }
export function setPendingReturnSceneName(val) { pendingReturnSceneName = val; }

/**
 * Centralized navigation function
 */
export function navigateToScene(targetIndex, sourceSceneIndex, sourceHotspotIndex, targetYaw = 0, targetPitch = 0) {
    // 1. SANITIZE: Prevent NaN from entering the state
    const cleanYaw = Number.isFinite(targetYaw) ? targetYaw : 0;
    const cleanPitch = Number.isFinite(targetPitch) ? targetPitch : 0;

    // 2. TRACK HISTORY: Always record where we just came from
    incomingLink = {
        sceneIndex: sourceSceneIndex,
        hotspotIndex: sourceHotspotIndex
    };

    console.log(`Navigation Sequence: Scene ${sourceSceneIndex} → Scene ${targetIndex} via Hotspot ${sourceHotspotIndex} (Yaw: ${cleanYaw}, Pitch: ${cleanPitch})`);

    // 3. TRIGGER STATE CHANGE - Pass parameters correctly: index, yaw, pitch, transition
    store.setActiveScene(targetIndex, cleanYaw, cleanPitch, { type: "link" });
}

/**
 * Update the return link prompt visibility and text
 */
export function updateReturnPrompt(state, scene) {
    const prompt = document.getElementById("return-link-prompt");
    if (!prompt) return;

    // Default: Hide
    prompt.classList.remove("visible");

    // Requirements:
    if (!incomingLink) return;
    if (isSimulationMode) return;

    const prevSceneIndex = incomingLink.sceneIndex;
    const prevScene = state.scenes[prevSceneIndex];
    if (!prevScene) return;

    // Don't prompt in auto-forward scenes during simulation
    if (scene.isAutoForward && isSimulationMode) return;

    // Check if we already have a link pointing back
    const hasLinkBack = scene.hotspots.some(h => h.target === prevScene.name);

    if (!hasLinkBack) {
        const prevName = prevScene.label || prevScene.name;
        const txt = prompt.querySelector(".return-link-text");
        if (txt) txt.innerHTML = `Add Return Link to <strong>${prevName}</strong>`;
        prompt.classList.add("visible");
    }
}

/**
 * Execute Auto-Forward Logic
 */
export function handleAutoForward(currentScene, state, viewer) {
    if (currentScene.isAutoForward && !state.isLinking && isSimulationMode) {
        // Initialize chain if starting
        if (autoForwardChain.length === 0 && incomingLink) {
            autoForwardChain.push(incomingLink.sceneIndex);
        }

        // Loop detection
        if (autoForwardChain.includes(state.activeIndex)) {
            console.warn(`Auto-forward loop detected! Scene Index ${state.activeIndex} was already visited in this sequence.`);
            autoForwardChain = [];
            if (window.notify) window.notify(`⚠️ Navigation loop detected. Auto-forward paused.`, 'warning');
            return;
        }

        autoForwardChain.push(state.activeIndex);

        // Circuit breaker: Prevent chains longer than 15 hops
        if (autoForwardChain.length > 15) {
            console.error("Auto-forward safety cut-off: Chain too long.");
            autoForwardChain = [];
            return;
        }

        const visitedSceneNames = autoForwardChain.map(idx => state.scenes[idx]?.name).filter(Boolean);

        // Find next target that isn't where we just came from (if possible)
        let bestHotspot = currentScene.hotspots.find(h => !visitedSceneNames.includes(h.target));
        if (!bestHotspot && currentScene.hotspots.length > 0) {
            bestHotspot = currentScene.hotspots[0];
        }

        if (bestHotspot) {
            const targetIndex = state.scenes.findIndex(s => s.name === bestHotspot.target);
            if (targetIndex !== -1) {
                // Micro-delay to let the current scene settle before jumping
                setTimeout(() => {
                    const simToggle = document.getElementById('v-scene-sim-toggle');
                    const stillSimulating = simToggle && simToggle.classList.contains("active");

                    if (store.state.activeIndex === state.activeIndex && !store.state.isLinking && stillSimulating) {
                        const hsIndex = currentScene.hotspots.indexOf(bestHotspot);

                        // PRIORITY LOGIC:
                        let tYaw = 0;
                        let tPitch = 0;

                        if (bestHotspot.isReturnLink && bestHotspot.returnViewFrame) {
                            tYaw = bestHotspot.returnViewFrame.yaw !== undefined ? bestHotspot.returnViewFrame.yaw : 0;
                            tPitch = bestHotspot.returnViewFrame.pitch !== undefined ? bestHotspot.returnViewFrame.pitch : 0;
                        } else {
                            if (bestHotspot.targetYaw !== undefined) {
                                tYaw = bestHotspot.targetYaw;
                                tPitch = bestHotspot.targetPitch !== undefined ? bestHotspot.targetPitch : 0;
                            } else if (bestHotspot.viewFrame) {
                                tYaw = bestHotspot.viewFrame.yaw !== undefined ? bestHotspot.viewFrame.yaw : 0;
                                tPitch = bestHotspot.viewFrame.pitch !== undefined ? bestHotspot.viewFrame.pitch : 0;
                            }
                        }

                        navigateToScene(targetIndex, state.activeIndex, hsIndex !== -1 ? hsIndex : 0, tYaw, tPitch);
                    }
                }, 1200);
            }
        }
    } else {
        // Clear chain when manual navigation or toggle off
        if (autoForwardChain.length > 0) {
            autoForwardChain = [];
        }
    }
}
