/**
 * NavigationSystem.js
 * 
 * REFACTORED: Logic moved to ReScript (Navigation.bs.js)
 * This file now serves as a bridge/adapter for the existing codebase.
 */

import * as Navigation from "./Navigation.bs.js";

/**
 * Navigate to a new scene with animation if in simulation mode.
 * Wraps ReScript's navigateToScene to handle JS optional arguments and null values safely.
 */
export function navigateToScene(
    targetIndex,
    sourceIndex,
    hotspotIndex,
    targetYaw = 0.0,
    targetPitch = 0.0,
    targetHfov = 90.0,
    overrideViewer = undefined,
    previewOnly = false
) {
    return Navigation.navigateToScene(
        targetIndex,
        sourceIndex || 0,
        hotspotIndex || 0,
        targetYaw,
        targetPitch,
        targetHfov,
        overrideViewer || undefined, // Convert null to undefined
        previewOnly,
        undefined // Final 'param' unit ()
    );
}

// Explicit function exports to ensure static observability and prevent binding issues
export function setSimulationMode(val) { return Navigation.setSimulationMode(val); }
export function initNavigation() { return Navigation.initNavigation(); }
export function getIsSimulationMode() { return Navigation.getIsSimulationMode(); }
export function registerOnSceneArrival(cb) { return Navigation.registerOnSceneArrival(cb); }
export function clearSimulationUI() { return Navigation.clearSimulationUI(); }
export function resetAutoForwardChain() { return Navigation.resetAutoForwardChain(); }
export function cancelNavigation() { return Navigation.cancelNavigation(); }
export function getPendingReturnSceneName() { return Navigation.getPendingReturnSceneName(); }
export function setPendingReturnSceneName(val) { return Navigation.setPendingReturnSceneName(val); }
export function getPreviewingLink() { return Navigation.getPreviewingLink(); }
export function getAutoForwardChain() { return Navigation.getAutoForwardChain(); }

// Helper getters that might be used elsewhere
export function getIncomingLink() { return Navigation.getIncomingLink(); }
/**
 * Set the incoming link data.
 * Wraps ReScript to handle null as undefined (None).
 */
export function setIncomingLink(val) {
    return Navigation.setIncomingLink(val || undefined);
}

/**
 * Handle auto-forward logic for scenes.
 * Wraps ReScript logic to handle null/undefined viewer correctly.
 */
export function handleAutoForward(currentScene, state, viewer = undefined) {
    return Navigation.handleAutoForward(currentScene, state, viewer || undefined);
}

// If the original file had other exports, add them here.
// Based on previous reads, these were the main ones.

/**
 * Update the visibility of the "Add Return Link" prompt based on the current scene 
 * and whether we arrived here via a link that doesn't have a return path yet.
 */
export function updateReturnPrompt(state, scene) {
    const prompt = document.getElementById("return-link-prompt");
    if (!prompt) return;

    if (state.isLinking) {
        prompt.classList.add("hidden");
        prompt.classList.remove("flex");
        return;
    }

    const incoming = getIncomingLink();
    if (!incoming) {
        prompt.classList.add("hidden");
        prompt.classList.remove("flex");
        return;
    }

    // Check if a return link already exists to the source scene
    const sourceScene = state.scenes[incoming.sceneIndex];
    if (!sourceScene) return;

    const hasReturnLink = scene.hotspots.some(h => h.target === sourceScene.name && h.isReturnLink);

    if (hasReturnLink) {
        prompt.classList.add("hidden");
        prompt.classList.remove("flex");
    } else {
        const textEl = prompt.querySelector(".return-link-text");
        if (textEl) textEl.textContent = `Return to ${sourceScene.name}`;
        prompt.classList.remove("hidden");
        prompt.classList.add("flex");

        // Trigger animation
        requestAnimationFrame(() => {
            prompt.classList.add("visible");
        });
    }
}
