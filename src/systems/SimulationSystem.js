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

/**
 * CIRCULAR DEPENDENCY NOTES:
 * SimulationSystem depends on NavigationSystem for movement commands.
 * NavigationSystem depends on SimulationSystem for onSceneArrival callbacks.
 * 
 * To resolve this, NavigationSystem exposes `registerOnSceneArrival` which 
 * SimulationSystem calls at initialization. This avoids direct cyclic imports 
 * at the top level while maintaining tight integration.
 */

// ============================================================================
// State
// ============================================================================

let isAutoPilot = false;
let visitedScenes = [];
let autoPilotJourneyId = 0;
let pendingAdvance = null; // Timeout ID for delayed advance
let lastAdvanceTime = 0; // Debounce protection against rapid calls
let stoppingOnArrival = false; // Flag to stop simulation upon next arrival
let skipAutoForwardGlobal = false; // Flag to skip bridge scenes during simulation

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
 * @param {boolean} skipAutoForward - Whether to skip bridge/auto-forward scenes
 */
export function startAutoPilot(skipAutoForward = false) {
    const state = store.state;

    if (state.scenes.length === 0) {
        window.notify?.("No scenes to simulate", "warning");
        return;
    }

    Debug.info('Simulation', 'Auto-pilot starting');

    // Reset state
    isAutoPilot = true;
    visitedScenes = [];
    stoppingOnArrival = false;
    skipAutoForwardGlobal = skipAutoForward;
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
    stoppingOnArrival = false;
    skipAutoForwardGlobal = false;

    // Disable simulation mode
    setSimulationMode(false);
    clearSimulationUI();
    resetAutoForwardChain();

    // Unlock UI
    document.body.classList.remove('auto-pilot-active');

    // Reset toggle button appearance (play = green)
    const simToggle = document.getElementById('v-scene-sim-toggle');
    if (simToggle) {
        simToggle.innerHTML = '<span class="material-icons" style="font-size: 22px; color: white;">play_arrow</span>';
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

    if (stoppingOnArrival) {
        stoppingOnArrival = false;
        completeAutoPilot();
        return;
    }

    // Clear any pending advance from previous scenes or startAutoPilot
    if (pendingAdvance) {
        clearTimeout(pendingAdvance);
        pendingAdvance = null;
    }

    // DEBOUNCE: Prevent rapid successive calls from creating race conditions
    const now = Date.now();
    if (now - lastAdvanceTime < 300) {
        Debug.warn('Simulation', 'onSceneArrival called too quickly, debouncing');
        return;
    }
    lastAdvanceTime = now;

    // Mark as visited
    if (!visitedScenes.includes(sceneIndex)) {
        visitedScenes.push(sceneIndex);
    }

    // Check if current scene is auto-forward - NavigationSystem handles those
    // UNLESS we are specifically told that the chain has ended
    // Check if current scene is auto-forward - NavigationSystem handles those
    // UNLESS we are specifically told that the chain has ended
    const currentScene = store.state.scenes[sceneIndex];

    // MODIFIED: SimulationSystem now handles EVERYTHING ensuring smart unvisited priority.
    // We no longer yield to NavigationSystem for auto-forward scenes.
    /*
    if (currentScene?.isAutoForward && !isChainEnd) {
        return;
    }
    */

    // Schedule next advance with robustness check
    pendingAdvance = setTimeout(async () => {
        try {
            // Wait for viewer to be truly ready for this scene
            // This prevents advancing before the Viewer.js swap has completed
            await waitForViewerScene(sceneIndex);

            // Re-check auto-pilot state as it might have been stopped during the wait
            if (!isAutoPilot || stoppingOnArrival) return;

            advanceToNextScene();
        } catch (e) {
            // If simulation was intentionally stopped, ignore errors
            if (!isAutoPilot) return;

            Debug.error('Simulation', 'Failed to arrive at scene properly, stopping', e);
            completeAutoPilot();
        }
    }, 500); // Balanced pacing
}

/**
 * Robustly wait for the global viewer to be ready for a specific scene index.
 * This ensures that when we advance, we are looking at the correct viewer instance.
 */
async function waitForViewerScene(sceneIndex) {
    const expectedScene = store.state.scenes[sceneIndex];
    if (!expectedScene) return;

    const timeout = 8000;
    const start = Date.now();

    while (Date.now() - start < timeout) {
        // Stop waiting if simulation was cancelled
        if (!isAutoPilot) return;

        const v = window.pannellumViewer;
        if (v && v._sceneId === expectedScene.id && typeof v.isLoaded === 'function' && v.isLoaded()) {
            return;
        }
        await new Promise(r => setTimeout(r, 100));
    }
    throw new Error(`Timeout waiting for viewer to load scene ${expectedScene.name}`);
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
    let nextLink = findBestNextLink(currentScene, state);

    // SKIP AUTO-FORWARD LOGIC
    if (skipAutoForwardGlobal && nextLink) {
        let chainCounter = 0;
        let tempNextLink = nextLink;
        const originalHotspotIndex = nextLink.hotspotIndex; // Store original hotspot index

        while (chainCounter < 10) {
            const targetScene = state.scenes[tempNextLink.targetIndex];
            if (!targetScene || !targetScene.isAutoForward) break;

            // It's a bridge, we want to skip it.
            // Mark it as visited so we don't return to it unnecessarily
            if (!visitedScenes.includes(tempNextLink.targetIndex)) {
                visitedScenes.push(tempNextLink.targetIndex);
            }

            // Find the next link from this bridge
            const jumpLink = findBestNextLink(targetScene, state);
            if (jumpLink) {
                tempNextLink = jumpLink;
                chainCounter++;
            } else {
                // Dead end in bridge chain, just stop here (render this bridge)
                break;
            }
        }
        // Reassign nextLink, but preserve the original hotspotIndex from the starting scene
        nextLink = { ...tempNextLink, hotspotIndex: originalHotspotIndex };
    }

    if (!nextLink) {
        Debug.info('Simulation', 'Auto-pilot complete: No unvisited scenes reachable');
        completeAutoPilot();
        return;
    }

    const { hotspot, hotspotIndex, targetIndex } = nextLink;

    // Stop simulation if returning to the start scene (Scene 0) and there are no direct unvisited paths from it.
    // This prevents infinite loops where the simulation endlessly cycles through visited scenes.
    if (targetIndex === 0) {
        const startScene = state.scenes[0];
        const hasNewPaths = startScene?.hotspots?.some(h => {
            const tIdx = state.scenes.findIndex(s => s.name === h.target);
            return tIdx !== -1 && !visitedScenes.includes(tIdx);
        });

        if (!hasNewPaths) {
            Debug.info('Simulation', 'Simulation ending: Final leg to start scene (stopping on arrival)', {
                visitedCount: visitedScenes.length
            });
            stoppingOnArrival = true;
            // Fall through to navigateToScene to play the final transition
        }
    }

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
 * @param {Object} currentScene - Current scene object
 * @param {Object} state - Application state
 * @param {Array} explicitVisitedScenes - Optional: Use this instead of module-level visitedScenes
 */
function findBestNextLink(currentScene, state, explicitVisitedScenes = null) {
    const visited = explicitVisitedScenes || visitedScenes;
    const hotspots = currentScene.hotspots;
    if (!hotspots || hotspots.length === 0) return null;

    // Build enriched link list
    const allLinks = hotspots.map((h, i) => {
        const targetIndex = state.scenes.findIndex(s => s.name === h.target);
        if (targetIndex === -1) return null;
        const targetScene = state.scenes[targetIndex];
        return {
            hotspot: h,
            hotspotIndex: i,
            targetIndex,
            isVisited: visited.includes(targetIndex),
            isReturn: !!h.isReturnLink,
            isBridge: !!targetScene?.isAutoForward
        };
    }).filter(Boolean);

    // PRIORITY 1: UNVISITED Forward Room (Creation Sequence)
    const unvisitedForwardRoom = allLinks.find(l => !l.isVisited && !l.isReturn && !l.isBridge);
    if (unvisitedForwardRoom) {
        Debug.debug('Simulation', 'Target: Unvisited Forward Room (Oldest)');
        return unvisitedForwardRoom;
    }

    // PRIORITY 2: UNVISITED Forward Bridge (Creation Sequence)
    // Bridge scenes are hallways/stairs - we visit them if no local rooms are left
    const unvisitedForwardBridge = allLinks.find(l => !l.isVisited && !l.isReturn && l.isBridge);
    if (unvisitedForwardBridge) {
        Debug.debug('Simulation', 'Target: Unvisited Forward Bridge (Oldest)');
        return unvisitedForwardBridge;
    }

    // PRIORITY 3: UNVISITED Return Room (Creation Sequence)
    const unvisitedReturnRoom = allLinks.find(l => !l.isVisited && l.isReturn && !l.isBridge);
    if (unvisitedReturnRoom) {
        Debug.debug('Simulation', 'Target: Unvisited Return Room (Oldest)');
        return unvisitedReturnRoom;
    }

    // PRIORITY 4: UNVISITED Return Bridge (Creation Sequence)
    const unvisitedReturnBridge = allLinks.find(l => !l.isVisited && l.isReturn && l.isBridge);
    if (unvisitedReturnBridge) {
        Debug.debug('Simulation', 'Target: Unvisited Return Bridge (Oldest)');
        return unvisitedReturnBridge;
    }

    // --- FALLBACK (ALL REACHABLE ALREADY VISITED) ---
    // Instead of stopping, we follow visited links to find new branches elsewhere.

    // PRIORITY 5: OLDest Forward (visited)
    const visitedForward = allLinks.find(l => !l.isReturn);
    if (visitedForward) {
        Debug.debug('Simulation', 'Target: Visited Forward (Loop/Breadth Search)');
        return visitedForward;
    }

    // PRIORITY 6: OLDest Return (visited)
    const visitedReturn = allLinks.find(l => l.isReturn);
    if (visitedReturn) {
        Debug.debug('Simulation', 'Target: Visited Return (Backtrack Search)');
        return visitedReturn;
    }

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

// ============================================================================
// Path Generation for Teaser
// ============================================================================

/**
 * Generates the full path that the simulation would take.
 * Used by TeaserSystem to create "Cinematic Scenes" mode.
 * Returns an array of steps compatible with TeaserSystem.
 * @param {boolean} skipAutoForward - Whether to skip bridge/auto-forward scenes
 */
export function getSimulationPath(skipAutoForward = false) {
    const state = store.state;
    if (state.scenes.length === 0) return [];

    let path = [];
    let visited = new Set();
    let currentIdx = 0; // Start at scene 0
    let loopCount = 0;
    const MAX_STEPS = 50; // Safety limit

    // Initial Scene (Scene 0)
    // For the start, we use the default initial view or the first scene's data
    // Teaser System logic for first scene:
    /*
      let firstArrivalYaw = 0;
      if (firstScene.hotspots && firstScene.hotspots.length > 0) {
        if (firstHotspot.viewFrame) { ... }
      }
    */
    // We will let TeaserSystem handle the initial arrival view logic for the *first* frame
    // taking the pointer from logical start.
    // For the simulation path, we just need to track the sequence of [CurrentScene -> Link -> NextScene]

    // Initialize with scene 0
    visited.add(0);

    // We add the first scene as the starting point.
    // Teaser expects the path to includes the current scene and where it's going.

    // BUT: findBestNextLink needs `visitedScenes` array which is local to the module usually.
    // We will make a local visited array for this calculation.
    let localVisited = [0];

    // To construct the path consistent with TeaserSystem:
    // We need to iterate: Find link from Current -> Next. 
    // Add Current to path with transitionTarget = Link.

    // Step 0: We are at Scene 0.
    // We can't fully fill Scene 0's object until we know the link.

    let currentPathObj = {
        idx: 0,
        transitionTarget: null,
        arrivalView: { yaw: 0, pitch: 0 } // Default for start, TeaserSystem might refine this
    };

    // Try to refine arrivalView of start (matches TeaserSystem logic roughly)
    const firstScene = state.scenes[0];
    if (firstScene.hotspots && firstScene.hotspots.length > 0) {
        // Try to find a logical "start view" - typically viewFrame of first hotspot
        // This creates a nice "Director's View" start
        const startHotspot = firstScene.hotspots[0];
        if (startHotspot.viewFrame) {
            currentPathObj.arrivalView.yaw = startHotspot.viewFrame.yaw ?? 0;
            currentPathObj.arrivalView.pitch = startHotspot.viewFrame.pitch ?? 0;
        }
    }

    const pathSet = new Set(); // To detect actual path cycles
    path.push(currentPathObj);

    // Track state (current -> link -> target) to prevent infinite loops
    // Some tours might be naturally cyclic (circles), so we detection specific repeating transitions
    const visitedStateSet = new Set();

    let terminationReason = 'complete';
    while (loopCount < MAX_STEPS) {
        const currentScene = state.scenes[currentIdx];
        if (!currentScene) {
            terminationReason = 'invalid_scene';
            break;
        }

        let nextLink = findBestNextLink(currentScene, state, localVisited);

        // SKIP AUTO-FORWARD LOGIC FOR PATH GENERATION
        if (skipAutoForward && nextLink) {
            let chainCounter = 0;
            let tempNextLink = nextLink;
            while (chainCounter < 10) {
                const targetScene = state.scenes[tempNextLink.targetIndex];
                if (!targetScene || !targetScene.isAutoForward) break;

                // Note: We DO NOT mark bridges as visited here, or do we?
                // For path generation, we just want to jump through them.
                if (!localVisited.includes(tempNextLink.targetIndex)) {
                    localVisited.push(tempNextLink.targetIndex);
                }

                const jumpLink = findBestNextLink(targetScene, state, localVisited);
                if (jumpLink) {
                    tempNextLink = jumpLink;
                    chainCounter++;
                } else {
                    break;
                }
            }
            nextLink = tempNextLink;
        }

        if (!nextLink) {
            terminationReason = 'no_more_links';
            break;
        }

        const { hotspot, targetIndex } = nextLink;

        // CYCLE DETECTION: If we have traversed this EXACT link before, we are in a loop.
        const stateKey = `${currentIdx}->${targetIndex}`;

        if (visitedStateSet.has(stateKey)) {
            Debug.warn('Simulation', 'Detected infinite loop in path generation, terminating safely.');
            terminationReason = 'infinite_loop_detected';
            break;
        }
        visitedStateSet.add(stateKey);

        if (pathSet.has(stateKey)) {
            Debug.warn('Simulation', 'Detected cycle in path generation (pathSet), terminating');
            terminationReason = 'cycle_detected';
            break;
        }
        pathSet.add(stateKey);

        // 1. Update current path object with transition info (WE ARE LEAVING CURRENT SCENE VIA THIS LINK)
        let transYaw = hotspot.yaw;
        let transPitch = hotspot.pitch || 0;
        if (hotspot.viewFrame) {
            transYaw = hotspot.viewFrame.yaw;
            transPitch = hotspot.viewFrame.pitch;
        }

        // Get start position for waypoint animation
        let startYaw = hotspot.startYaw ?? 0;
        let startPitch = hotspot.startPitch ?? 0;

        currentPathObj.transitionTarget = {
            yaw: transYaw,
            pitch: transPitch,
            targetName: hotspot.target,
            startYaw: startYaw,
            startPitch: startPitch,
            waypoints: hotspot.waypoints || []
        };

        // 2. Prepare Next Path Object (WE ARE ARRIVING AT TARGET SCENE)
        let arrivalYaw = 0;
        let arrivalPitch = 0;

        // Logic from SimulationSystem.js advanceToNextScene for arrival
        if (hotspot.isReturnLink && hotspot.returnViewFrame) {
            arrivalYaw = hotspot.returnViewFrame.yaw ?? 0;
            arrivalPitch = hotspot.returnViewFrame.pitch ?? 0;
        } else if (hotspot.viewFrame) {
            arrivalYaw = hotspot.viewFrame.yaw ?? 0;
            arrivalPitch = hotspot.viewFrame.pitch ?? 0;
        } else if (hotspot.targetYaw !== undefined) {
            arrivalYaw = hotspot.targetYaw;
            arrivalPitch = hotspot.targetPitch ?? 0;
        }

        const nextPathObj = {
            idx: targetIndex,
            transitionTarget: null,
            arrivalView: { yaw: arrivalYaw, pitch: arrivalPitch }
        };

        path.push(nextPathObj); // Add to path
        currentPathObj = nextPathObj; // Update pointer

        // Update loop state
        localVisited.push(targetIndex);
        currentIdx = targetIndex;
        loopCount++;

        // Stop if we returned to start (optional, but standard for teasers)
        if (targetIndex === 0 && localVisited.length > 2) {
            terminationReason = 'returned_to_start';
            break;
        }
    }

    if (loopCount >= MAX_STEPS) terminationReason = 'max_steps_reached';

    // TELEMETRY
    Debug.info('Simulation', 'PATH_GENERATED', {
        steps: path.length,
        visitedCount: localVisited.length,
        uniqueVisited: new Set(localVisited).size,
        totalScenes: state.scenes.length,
        terminationReason,
        skipAutoForward
    });

    return path;
}
