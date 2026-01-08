/**
 * SimulationSystem.js
 * Auto-pilot orchestration for simulation mode
 * 
 * Handles automatic scene traversal following link connections,
 * providing a teaser-like preview experience.
 */

import { store } from "../store.js";
import { Debug } from "../utils/Debug.js";
import {
    setSimulationMode,
    getIsSimulationMode,
    navigateToScene,
    clearSimulationUI,
    resetAutoForwardChain,
    registerOnSceneArrival
} from "./NavigationSystem.js";

// ============================================================================
// State
// ============================================================================

let isAutoPilot = false;
let visitedScenes = [];
let autoPilotJourneyId = 0;
let pendingAdvance = null; // Timeout ID for delayed advance

// ============================================================================
// Public API
// ============================================================================

/**
 * Check if auto-pilot is currently active
 */
export function isAutoPilotActive() {
    return isAutoPilot;
}

/**
 * Start auto-pilot simulation
 * Jumps to scene 1 and begins automatic traversal
 */
export function startAutoPilot() {
    const state = store.state;

    if (state.scenes.length === 0) {
        window.notify?.("No scenes to simulate", "warning");
        return;
    }

    Debug.info('Simulation', 'Auto-pilot starting');

    // Reset state
    isAutoPilot = true;
    visitedScenes = [];
    autoPilotJourneyId++;

    // Enable simulation mode (this sets up the visual style)
    setSimulationMode(true);

    // Lock UI
    document.body.classList.add('auto-pilot-active');

    // Update toggle button appearance (stop = white square on red)
    const simToggle = document.getElementById('v-scene-sim-toggle');
    if (simToggle) {
        // Force red background with inline style + stop icon
        simToggle.innerHTML = '<span class="material-icons" style="font-size: 22px; color: white;">stop</span>';
        simToggle.style.removeProperty('background-color');
        simToggle.style.setProperty('background-color', '#dc3545', 'important');
        // simToggle.classList.add('active'); // REMOVED: Conflicts with CSS teal gradient
        simToggle.title = 'Click to Stop Simulation';

        // Force a reflow/repaint
        void simToggle.offsetHeight;
    }

    // Jump to scene 0 (first scene)
    if (state.activeIndex !== 0) {
        store.setActiveScene(0, 0, 0, { type: "auto-pilot-start" });
    }

    // Mark first scene as visited
    visitedScenes.push(0);

    // Begin traversal after brief delay for scene to load
    // This is a safety fallback; usually onSceneArrival or syncUI will trigger first move
    if (pendingAdvance) clearTimeout(pendingAdvance);
    pendingAdvance = setTimeout(() => {
        advanceToNextScene();
    }, 800);

    window.notify?.("Auto-pilot started", "success");
}

/**
 * Stop auto-pilot and clean up
 * @param {boolean} returnToStart - Whether to return to scene 1
 */
export function stopAutoPilot(returnToStart = true) {
    if (!isAutoPilot) return;

    Debug.info('Simulation', 'Auto-pilot stopping', {
        visitedCount: visitedScenes.length,
        returnToStart
    });

    // Clear pending operations
    if (pendingAdvance) {
        clearTimeout(pendingAdvance);
        pendingAdvance = null;
    }

    // Increment journey ID to cancel any in-progress navigation
    autoPilotJourneyId++;

    // Reset state
    isAutoPilot = false;
    visitedScenes = [];

    // Disable simulation mode
    setSimulationMode(false);
    clearSimulationUI();
    resetAutoForwardChain();

    // Unlock UI
    document.body.classList.remove('auto-pilot-active');

    // Reset toggle button appearance (play = green)
    const simToggle = document.getElementById('v-scene-sim-toggle');
    if (simToggle) {
        simToggle.innerHTML = '<span class="material-icons" style="font-size: 22px;">play_arrow</span>';
        simToggle.style.removeProperty('background-color');
        simToggle.style.setProperty('background-color', '#10b981', 'important');
        // simToggle.classList.remove('active'); // REMOVED: No longer using .active class
        simToggle.title = 'Start Auto-Pilot Simulation';
    }

    // Return to first scene
    if (returnToStart && store.state.scenes.length > 0) {
        store.setActiveScene(0, 0, 0, { type: "auto-pilot-end" });
    }

    window.notify?.("Simulation stopped", "info");
}

/**
 * Called by NavigationSystem when a scene transition completes
 * @param {number} sceneIndex - The index of the scene we just arrived at
 * @param {boolean} isChainEnd - True if this is being called because an auto-forward chain ended
 */
export function onSceneArrival(sceneIndex, isChainEnd = false) {
    if (!isAutoPilot) return;

    Debug.debug('Simulation', `Arrived at scene ${sceneIndex} (chainEnd: ${isChainEnd})`, {
        visitedCount: visitedScenes.length
    });

    // Clear any pending advance from previous scenes or startAutoPilot
    if (pendingAdvance) {
        clearTimeout(pendingAdvance);
        pendingAdvance = null;
    }

    // Mark as visited
    if (!visitedScenes.includes(sceneIndex)) {
        visitedScenes.push(sceneIndex);
    }

    // Check if current scene is auto-forward - NavigationSystem handles those
    // UNLESS we are specifically told that the chain has ended
    const currentScene = store.state.scenes[sceneIndex];
    if (currentScene?.isAutoForward && !isChainEnd) {
        return;
    }

    // Schedule next advance
    pendingAdvance = setTimeout(() => {
        advanceToNextScene();
    }, 500); // Balanced pacing
}

// ============================================================================
// Internal Logic
// ============================================================================

/**
 * Find and navigate to the next unvisited scene
 */
function advanceToNextScene() {
    if (!isAutoPilot) return;

    const state = store.state;
    const currentScene = state.scenes[state.activeIndex];

    if (!currentScene || !currentScene.hotspots || currentScene.hotspots.length === 0) {
        Debug.info('Simulation', 'Auto-pilot complete: No hotspots in current scene');
        completeAutoPilot();
        return;
    }

    // Find best next link
    const nextLink = findBestNextLink(currentScene, state);

    if (!nextLink) {
        Debug.info('Simulation', 'Auto-pilot complete: No unvisited scenes reachable');
        completeAutoPilot();
        return;
    }

    const { hotspot, hotspotIndex, targetIndex } = nextLink;

    Debug.info('Simulation', `Advancing to ${hotspot.target}`, {
        isReturn: hotspot.isReturnLink,
        visited: visitedScenes.length
    });

    // Calculate target orientation
    let tYaw = 0, tPitch = 0, tHfov = 90;

    if (hotspot.isReturnLink && hotspot.returnViewFrame) {
        tYaw = hotspot.returnViewFrame.yaw ?? 0;
        tPitch = hotspot.returnViewFrame.pitch ?? 0;
        tHfov = hotspot.returnViewFrame.hfov ?? 90;
    } else if (hotspot.viewFrame) {
        tYaw = hotspot.viewFrame.yaw ?? 0;
        tPitch = hotspot.viewFrame.pitch ?? 0;
        tHfov = hotspot.viewFrame.hfov ?? 90;
    } else if (hotspot.targetYaw !== undefined) {
        tYaw = hotspot.targetYaw;
        tPitch = hotspot.targetPitch ?? 0;
        tHfov = hotspot.targetHfov ?? 90;
    }

    // Navigate
    navigateToScene(
        targetIndex,
        state.activeIndex,
        hotspotIndex,
        tYaw,
        tPitch,
        tHfov
    );
}

/**
 * Find the best next link to follow
 * Priority:
 * 1. Forward links to unvisited scenes
 * 2. Return links to unvisited scenes (only if no forward links exist)
 * 3. null - tour complete when all reachable scenes visited
 */
function findBestNextLink(currentScene, state) {
    const hotspots = currentScene.hotspots;

    // Separate forward and return links
    const forwardLinks = [];
    const returnLinks = [];

    for (let i = 0; i < hotspots.length; i++) {
        const h = hotspots[i];
        const targetIndex = state.scenes.findIndex(s => s.name === h.target);

        if (targetIndex === -1) continue; // Invalid target

        const linkInfo = { hotspot: h, hotspotIndex: i, targetIndex };

        if (h.isReturnLink) {
            returnLinks.push(linkInfo);
        } else {
            forwardLinks.push(linkInfo);
        }
    }

    // Priority 1: Forward link to unvisited scene
    const unvisitedForward = forwardLinks.find(l => !visitedScenes.includes(l.targetIndex));
    if (unvisitedForward) {
        Debug.debug('Simulation', 'Chose unvisited forward link');
        return unvisitedForward;
    }

    // Priority 2: Return link to unvisited scene
    const unvisitedReturn = returnLinks.find(l => !visitedScenes.includes(l.targetIndex));
    if (unvisitedReturn) {
        Debug.debug('Simulation', 'Chose unvisited return link');
        return unvisitedReturn;
    }

    // Priority 3: Fallback to ANY forward link (circular route)
    // We prefer the one we haven't visited in the longest time? For now just the first one.
    if (forwardLinks.length > 0) {
        Debug.debug('Simulation', 'Chose visited forward link (looping)');
        return forwardLinks[0];
    }

    // Priority 4: Fallback to ANY return link (backtracking)
    if (returnLinks.length > 0) {
        Debug.debug('Simulation', 'Chose visited return link (backtracking)');
        return returnLinks[0];
    }

    // All directly reachable scenes have been visited AND no links exist - tour complete
    return null;
}

/**
 * Complete auto-pilot and return to start
 */
function completeAutoPilot() {
    Debug.info('Simulation', 'Auto-pilot journey complete', {
        scenesVisited: visitedScenes.length,
        totalScenes: store.state.scenes.length
    });

    window.notify?.(`Simulation complete! Visited ${visitedScenes.length} scenes.`, "success");

    // Small delay before returning to start for user to see final scene
    setTimeout(() => {
        stopAutoPilot(true);
    }, 800);
}

// ============================================================================
// Keyboard Handler
// ============================================================================

/**
 * Initialize simulation system:
 * - ESC key handler for stopping auto-pilot
 * - Register callback with NavigationSystem (avoids circular import)
 */
export function initSimulationKeyHandler() {
    // Register our callback with NavigationSystem
    registerOnSceneArrival(onSceneArrival);

    // ESC key to stop auto-pilot
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && isAutoPilot) {
            e.preventDefault();
            stopAutoPilot(true);
        }
    });
}
