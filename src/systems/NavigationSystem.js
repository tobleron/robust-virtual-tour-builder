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
    // 1. TRACK HISTORY: Always record where we just came from
    // This allows the NEW scene to know which hotspot brought us here
    // Useful for bidirectional view saving and "Return Link" suggestions
    incomingLink = {
        sceneIndex: sourceSceneIndex,
        hotspotIndex: sourceHotspotIndex
    };

    console.log(`Navigation Sequence: Scene ${sourceSceneIndex} → Scene ${targetIndex} via Hotspot ${sourceHotspotIndex}`);

    // 2. TRIGGER STATE CHANGE
    // 'transition: { type: "link" }' informs components this was an intentional navigation
    store.setActiveScene(targetIndex, {
        transition: { type: "link" },
        targetYaw: targetYaw,
        targetPitch: targetPitch
    });
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
        if (autoForwardChain.length === 0 && incomingLink) {
            autoForwardChain.push(incomingLink.sceneIndex);
        }

        if (autoForwardChain.includes(state.activeIndex)) {
            console.warn(`Auto-forward loop detected!`);
            autoForwardChain = [];
            if (window.notify) window.notify(`⚠️ Loop detected. Auto-navigation stopped.`, 'warning');
            return;
        }

        autoForwardChain.push(state.activeIndex);
        const visitedSceneNames = autoForwardChain.map(idx => state.scenes[idx]?.name).filter(Boolean);

        let bestHotspot = currentScene.hotspots.find(h => !visitedSceneNames.includes(h.target));
        if (!bestHotspot && currentScene.hotspots.length > 0) {
            bestHotspot = currentScene.hotspots[0];
        }

        if (bestHotspot) {
            const targetIndex = state.scenes.findIndex(s => s.name === bestHotspot.target);
            if (targetIndex !== -1) {
                setTimeout(() => {
                    const simToggle = document.getElementById('v-scene-sim-toggle');
                    const stillSimulating = simToggle && simToggle.classList.contains("active");

                    if (store.state.activeIndex === state.activeIndex && !store.state.isLinking && stillSimulating) {
                        const hsIndex = currentScene.hotspots.indexOf(bestHotspot);
                        navigateToScene(targetIndex, state.activeIndex, hsIndex !== -1 ? hsIndex : 0, bestHotspot.targetYaw || 0, bestHotspot.viewFrame ? bestHotspot.viewFrame.pitch : 0);
                    }
                }, 1000);
            }
        }
    } else {
        if (autoForwardChain.length > 0) {
            autoForwardChain = [];
        }
    }
}
