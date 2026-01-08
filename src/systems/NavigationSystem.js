import { store } from "../store.js";
import { HotspotLineSystem } from "./HotspotLineSystem.js";
import { Debug } from "../utils/Debug.js";
import {
    PANNING_VELOCITY,
    PANNING_MIN_DURATION,
    PANNING_MAX_DURATION
} from "../constants.js";

// Callback for scene arrival (set by SimulationSystem to avoid circular import)
let onSceneArrivalCallback = null;

// Module State
let incomingLink = null; // { sceneIndex: int, hotspotIndex: int }
let isSimulationMode = false;
let autoForwardChain = []; // Track visited scenes to prevent infinite loops
let pendingReturnSceneName = null;
let currentJourneyId = 0;
let isNavigating = false; // Guard to prevent concurrent navigations

/**
 * Initialize Navigation System
 */
export function initNavigation() {
    isSimulationMode = false;
    currentJourneyId = 0;
    isNavigating = false;
    incomingLink = null;
    autoForwardChain = [];
    Debug.info('Navigation', 'Navigation system initialized');
}

/**
 * Clear all simulation UI artifacts
 */
export function clearSimulationUI() {
    const svg = document.getElementById("viewer-hotspot-lines");
    if (svg) svg.innerHTML = '';
}

/**
 * Getters / Setters
 */
export function getIsSimulationMode() { return isSimulationMode; }

/**
 * Register callback for scene arrival (used by SimulationSystem to avoid circular import)
 */
export function registerOnSceneArrival(callback) {
    onSceneArrivalCallback = callback;
}

export function setSimulationMode(val) {
    isSimulationMode = val;
    Debug.info('Navigation', `Simulation mode: ${val ? 'ON' : 'OFF'}`);

    // reset cross-session state
    autoForwardChain = [];
    incomingLink = null;
    currentJourneyId++; // Invalidate ongoing animation loops
    clearSimulationUI();
    isNavigating = false; // Reset navigation guard

    if (!val) {
        // Exit cleanup
    } else {
        // Entry: Initial check to see if current scene should auto-forward immediately
        const state = store.state;
        if (state.activeIndex >= 0) {
            const currentScene = state.scenes[state.activeIndex];
            // We need the viewer instance. Since NavigationSystem is a utility, 
            // the viewer is usually passed in or accessed via window.
            if (window.pannellumViewer && currentScene) {
                // Delay slightly to ensure UI has updated styles
                setTimeout(() => {
                    handleAutoForward(currentScene, state, window.pannellumViewer);
                }, 100);
            }
        }
    }
}

export function getIncomingLink() { return incomingLink; }
export function setIncomingLink(val) { incomingLink = val; }

export function getAutoForwardChain() { return autoForwardChain; }
export function resetAutoForwardChain() { autoForwardChain = []; }

export function getPendingReturnSceneName() { return pendingReturnSceneName; }
export function setPendingReturnSceneName(val) { pendingReturnSceneName = val; }

/**
 * Force stop any ongoing navigation journey
 */
export function cancelNavigation() {
    isNavigating = false;
    currentJourneyId++; // Invalidate ongoing animation loops

    // Force stop Pannellum movement if it's currently animating a lookAt
    if (window.pannellumViewer) {
        try {
            const v = window.pannellumViewer;
            v.setPitch(v.getPitch(), false);
            v.setYaw(v.getYaw(), false);
            v.setHfov(v.getHfov(), false);
        } catch (e) {
            console.warn("[Navigation] Failed to stop viewer animation during cancel", e);
        }
    }
    Debug.info('Navigation', 'Navigation manually cancelled');
}

/**
 * Calculate the intended arrival orientation for a scene
 * @param {Object} state - Application state
 * @param {number} targetIndex - Target scene index
 * @returns {Object} { arrivalYaw, arrivalPitch, arrivalHfov }
 */
export function calculateSmartArrivalTarget(state, targetIndex) {
    let arrivalYaw = 0;
    let arrivalPitch = 0;
    let arrivalHfov = 90;

    if (state.scenes[targetIndex]) {
        const nextScene = state.scenes[targetIndex];

        // ALIGNED LOGIC: Find the target hotspot that handleAutoForward will likely pick.
        // We prioritize the next sequential scene in the project list.
        const nextTargetIndex = targetIndex + 1;
        const sequentialTargetName = (nextTargetIndex < state.scenes.length) ? state.scenes[nextTargetIndex].name : null;

        let nextHotspot = null;
        if (sequentialTargetName) {
            nextHotspot = nextScene.hotspots.find(h => h.target === sequentialTargetName);
        }

        // Fallback: Use the same logic as handleAutoForward (first unvisited or first existing)
        if (!nextHotspot && nextScene.hotspots?.length > 0) {
            nextHotspot = nextScene.hotspots.find(h => !h.isReturnLink) || nextScene.hotspots[0];
        }

        if (nextHotspot) {
            if (nextHotspot.startYaw !== undefined && nextHotspot.startPitch !== undefined) {
                arrivalYaw = nextHotspot.startYaw;
                arrivalPitch = nextHotspot.startPitch;
                if (nextHotspot.startHfov !== undefined) arrivalHfov = nextHotspot.startHfov;
            } else {
                arrivalYaw = nextHotspot.yaw - 35;
                arrivalPitch = 0;
            }
        }
    }

    return { arrivalYaw, arrivalPitch, arrivalHfov };
}

/**
 * Centralized navigation function
 * SIMPLIFIED VERSION - Uses Pannellum's built-in lookAt for reliability
 * @param {number} targetIndex - Target scene index
 * @param {number} sourceSceneIndex - Source scene index
 * @param {number} sourceHotspotIndex - Source hotspot index
 * @param {number} targetYaw - Target yaw orientation
 * @param {number} targetPitch - Target pitch orientation
 * @param {object} overrideViewer - Optional: Use this viewer instead of window.pannellumViewer
 */
export function navigateToScene(targetIndex, sourceSceneIndex, sourceHotspotIndex, targetYaw = 0, targetPitch = 0, targetHfov = 90, overrideViewer = null) {
    console.log(`[Navigation] attempt: target=${targetIndex}, source=${sourceSceneIndex}, isNavigating=${isNavigating}`);
    // GUARD: Prevent concurrent navigations
    if (isNavigating) {
        Debug.warn('Navigation', 'BLOCKED: Navigation already in progress');
        return;
    }

    const state = store.state;
    const sourceScene = state.scenes[sourceSceneIndex];
    const hotspot = sourceScene?.hotspots[sourceHotspotIndex];
    // Use override viewer if provided (for pre-swap invisible viewer panning)
    const viewer = overrideViewer || window.pannellumViewer;

    const cleanYaw = Number.isFinite(targetYaw) ? targetYaw : 0;
    const cleanPitch = Number.isFinite(targetPitch) ? targetPitch : 0;
    const cleanHfov = Number.isFinite(targetHfov) ? targetHfov : 90;

    // PRE-CALCULATE SMART ARRIVAL (for the TARGET scene): 
    // We determine the final landing perspective in Scene B's coordinate system.
    let { arrivalYaw, arrivalPitch, arrivalHfov } = isSimulationMode
        ? calculateSmartArrivalTarget(state, targetIndex)
        : { arrivalYaw: cleanYaw, arrivalPitch: cleanPitch, arrivalHfov: cleanHfov };

    // PAN TARGET (for the SOURCE scene):
    // The pan occurs in the current scene's coordinate system.
    // We must target the original viewFrame recorded for this link in Scene A.
    const targetPitchForPan = (isSimulationMode && hotspot.viewFrame) ? hotspot.viewFrame.pitch : cleanPitch;
    const targetYawForPan = (isSimulationMode && hotspot.viewFrame) ? hotspot.viewFrame.yaw : cleanYaw;
    const targetHfovForPan = (isSimulationMode && hotspot.viewFrame) ? (hotspot.viewFrame.hfov || cleanHfov) : cleanHfov;

    const journeyId = ++currentJourneyId;
    isNavigating = true; // Set guard

    Debug.info('Navigation', `Journey ${journeyId}: Scene ${sourceSceneIndex} -> ${targetIndex} (HFOV: ${arrivalHfov})`);

    const finalize = () => {
        if (journeyId !== currentJourneyId) {
            Debug.debug('Navigation', `Journey ${journeyId} cancelled (current: ${currentJourneyId})`);
            isNavigating = false; // Release guard
            return;
        }

        console.log(`[Navigation] Journey ${journeyId} reaching finalize()`);
        incomingLink = { sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex };
        Debug.info('Navigation', `Finalizing journey ${journeyId} to Scene ${targetIndex}`);

        store.setPreloadingScene(-1);

        // CRITICAL: Release navigation guard BEFORE store update.
        // store.notify() is synchronous, so Viewer.js will call handleAutoForward -> navigateToScene
        // immediately. If we set isNavigating = false AFTER, the next navigation gets blocked.
        isNavigating = false;

        store.setActiveScene(targetIndex, arrivalYaw, arrivalPitch, { type: "link", hfov: arrivalHfov });
        clearSimulationUI();

        // Notify SimulationSystem of arrival for auto-pilot orchestration
        if (isSimulationMode && onSceneArrivalCallback) {
            onSceneArrivalCallback(targetIndex);
        }
    };

    // SIMULATION MODE: Sequential panning (no crossfade overlap)
    if (isSimulationMode && hotspot && viewer) {
        console.log(`[Navigation] Simulation Mode Active - Journey ${journeyId}`);

        // Get current viewer position as fallback
        const currentViewerPitch = viewer.getPitch();
        const currentViewerYaw = viewer.getYaw();

        // Determine actual start position (use hotspot data or current camera position)
        // Fix: Use camOrientation instead of click-point if available to avoid "ground jump"
        const actualStartPitch = (hotspot.startPitch !== undefined) ? hotspot.startPitch : currentViewerPitch;
        const actualStartYaw = (hotspot.startYaw !== undefined) ? hotspot.startYaw : currentViewerYaw;
        const actualStartHfov = (hotspot.startHfov !== undefined) ? hotspot.startHfov : viewer.getHfov();

        // PAN TARGET: 
        // Use the source scene's viewFrame orientation.

        try {
            // Calculate interpolation start position (accounting for momentum)
            let yawDiff = targetYawForPan - actualStartYaw;
            while (yawDiff > 180) yawDiff -= 360;
            while (yawDiff < -180) yawDiff += 360;

            // MOMENTUM LOGIC:
            // 1. First Link (Manual Click): Start exactly at Point A (0% offset) to match the user's defined "Start View".
            // 2. Continuous Chain (Auto-Forward) OR Simulation Mode: Start at 10% offset ("Moving Handover") to preserve motion flow.
            const momentum = (autoForwardChain.length > 0 || isSimulationMode) ? 0.10 : 0.0;

            const startPitch = actualStartPitch + (targetPitchForPan - actualStartPitch) * momentum;
            const startYaw = actualStartYaw + yawDiff * momentum;
            const startHfov = actualStartHfov + (targetHfovForPan - actualStartHfov) * momentum;

            Debug.debug('Navigation', `Moving Handover: Starting at ${(momentum * 100).toFixed(0)}% (Yaw: ${startYaw.toFixed(1)}°, Pitch: ${startPitch.toFixed(1)}°, HFOV: ${startHfov.toFixed(1)})`);

            // CRITICAL: Always set camera position before lookAt to ensure consistent starting point
            viewer.setPitch(startPitch, false);
            viewer.setYaw(startYaw, false);
            viewer.setHfov(startHfov, false);

            // Animation tracking
            // DYNAMIC VELOCITY CALCULATION:
            // Calculate total angular distance to determine duration
            const pitchDiff = Math.abs(targetPitchForPan - startPitch);
            const totalDistance = Math.sqrt(Math.pow(yawDiff * (1.0 - momentum), 2) + Math.pow(pitchDiff, 2));

            // Formula: (Distance / Velocity) * 1000ms
            const rawDuration = (totalDistance / PANNING_VELOCITY) * 1000;
            const panDuration = Math.min(Math.max(rawDuration, PANNING_MIN_DURATION), PANNING_MAX_DURATION);

            const startTime = Date.now();
            let crossfadeTriggered = false;

            // TELEMETRY
            Debug.info('Navigation', `JOURNEY_START`, {
                journeyId,
                from: sourceScene?.name,
                to: state.scenes[targetIndex]?.name,
                panDuration: Math.round(panDuration),
                distance: totalDistance.toFixed(1)
            });

            // Arrow reference points:
            // SYNC FIX: The arrow MUST start where the camera starts (incorporating momentum)
            const arrowStartPitch = startPitch;
            const arrowStartYaw = startYaw;

            // ANIMATION LOOP
            const animLoop = () => {
                if (journeyId !== currentJourneyId) {
                    Debug.warn('Navigation', `JOURNEY_CANCELLED`, { journeyId });
                    return;
                }

                if (crossfadeTriggered) {
                    clearSimulationUI();
                    return;
                }

                const elapsed = Date.now() - startTime;
                const progress = Math.min(elapsed / panDuration, 1.0);

                if (progress >= 1.0) {
                    crossfadeTriggered = true;
                    finalize();
                    clearSimulationUI();
                    return;
                }

                // Update UI: Draw arrow following the actual camera pan path
                HotspotLineSystem.updateLines(viewer, state);
                HotspotLineSystem.drawSimulationArrow(viewer, arrowStartPitch, arrowStartYaw, targetPitchForPan, targetYawForPan, progress, 1.0);

                requestAnimationFrame(animLoop);
            };

            // START
            requestAnimationFrame(animLoop);
            viewer.lookAt(targetPitchForPan, targetYawForPan, targetHfovForPan, panDuration);

        } catch (e) {
            console.error("[Navigation] Critical error in simulation animation loop:", e);
            finalize();
        }
    } else {
        // MANUAL MODE: No animation, just swap
        if (isSimulationMode) {
            Debug.warn('Navigation', 'Simulation skipped - missing hotspot data');
        }
        finalize();
        isNavigating = false; // Release guard
    }
}

/**
 * Update the return link prompt visibility and text
 */
export function updateReturnPrompt(state, scene) {
    const prompt = document.getElementById("return-link-prompt");
    if (!prompt) return;

    prompt.classList.remove("visible");

    if (!incomingLink) return;
    if (isSimulationMode) return;

    const prevSceneIndex = incomingLink.sceneIndex;
    const prevScene = state.scenes[prevSceneIndex];
    if (!prevScene) return;

    if (scene.isAutoForward && isSimulationMode) return;

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
    Debug.debug('Navigation', `AutoForward Check: ${currentScene.name}`, {
        isAutoForward: currentScene.isAutoForward,
        isLinking: state.isLinking,
        isSimulationMode: isSimulationMode,
        hasIncomingLink: !!incomingLink
    });

    // SIMULATION MODE OVERRIDE: 
    // In Simulation Mode, we disable the "dumb" NavigationSystem auto-forward logic
    // and let the "smart" SimulationSystem handle decision making (unvisited priority).
    if (isSimulationMode) {
        Debug.debug('Navigation', 'AutoForward logic skipped: Simulation Mode active');
        return;
    }

    if (currentScene.isAutoForward && !state.isLinking) {
        Debug.info('Navigation', `AutoForward Processing: ${currentScene.name}`);

        // Initialize chain if starting
        if (autoForwardChain.length === 0 && incomingLink) {
            autoForwardChain.push(incomingLink.sceneIndex);
        }

        // Loop detection
        if (autoForwardChain.includes(state.activeIndex)) {
            Debug.warn('Navigation', `AutoForward Loop detected at index ${state.activeIndex}`, { chain: autoForwardChain });
            autoForwardChain = [];
            if (window.notify) window.notify(`⚠️ Navigation loop detected. Auto-forward paused.`, 'warning');
            return;
        }

        autoForwardChain.push(state.activeIndex);

        // Circuit breaker
        if (autoForwardChain.length > 15) {
            Debug.error('Navigation', 'AutoForward Safety cut-off: Chain too long', { chainLength: autoForwardChain.length });
            autoForwardChain = [];
            return;
        }

        const visitedSceneNames = autoForwardChain.map(idx => state.scenes[idx]?.name).filter(Boolean);

        // SEQUENTIAL ACCURACY: 
        // 1. Try to find a hotspot targeting the NEXT scene in the project sequence (e.g. 01 -> 02)
        const nextInSequenceIndex = state.activeIndex + 1;
        const nextInSequenceName = (nextInSequenceIndex < state.scenes.length) ? state.scenes[nextInSequenceIndex].name : null;

        let bestHotspot = null;
        if (nextInSequenceName) {
            bestHotspot = currentScene.hotspots.find(h => h.target === nextInSequenceName);
        }

        // 2. Fallback: Find any hotspot that hasn't been visited yet
        if (!bestHotspot) {
            bestHotspot = currentScene.hotspots.find(h => !visitedSceneNames.includes(h.target));
        }

        // 3. Last Resort: Use first available hotspot
        if (!bestHotspot && currentScene.hotspots.length > 0) {
            Debug.debug('Navigation', 'AutoForward: No sequential or unvisited target, using first hotspot');
            bestHotspot = currentScene.hotspots[0];
        }

        if (bestHotspot) {
            const targetIndex = state.scenes.findIndex(s => s.name === bestHotspot.target);
            if (targetIndex !== -1) {
                if (!store.state.isLinking && isSimulationMode) {
                    const hsIndex = currentScene.hotspots.indexOf(bestHotspot);

                    // Determine target orientation
                    let tYaw = 0;
                    let tPitch = 0;
                    let tHfov = 90;

                    if (bestHotspot.isReturnLink && bestHotspot.returnViewFrame) {
                        tYaw = bestHotspot.returnViewFrame.yaw !== undefined ? bestHotspot.returnViewFrame.yaw : 0;
                        tPitch = bestHotspot.returnViewFrame.pitch !== undefined ? bestHotspot.returnViewFrame.pitch : 0;
                        tHfov = bestHotspot.returnViewFrame.hfov !== undefined ? bestHotspot.returnViewFrame.hfov : 90;
                    } else {
                        if (bestHotspot.targetYaw !== undefined) {
                            tYaw = bestHotspot.targetYaw;
                            tPitch = bestHotspot.targetPitch !== undefined ? bestHotspot.targetPitch : 0;
                            tHfov = bestHotspot.targetHfov !== undefined ? bestHotspot.targetHfov : 90;
                        } else if (bestHotspot.viewFrame) {
                            tYaw = bestHotspot.viewFrame.yaw !== undefined ? bestHotspot.viewFrame.yaw : 0;
                            tPitch = bestHotspot.viewFrame.pitch !== undefined ? bestHotspot.viewFrame.pitch : 0;
                            tHfov = bestHotspot.viewFrame.hfov !== undefined ? bestHotspot.viewFrame.hfov : 90;
                        }
                    }

                    Debug.info('Navigation', `AutoForward Starting journey to ${bestHotspot.target}`);

                    // TELEMETRY: Chain tracking
                    Debug.info('Navigation', 'AUTOFORWARD_CHAIN', {
                        current: currentScene.name,
                        target: bestHotspot.target,
                        length: autoForwardChain.length
                    });

                    // Pass the viewer to ensure we use the correct (potentially invisible) viewer instance
                    navigateToScene(targetIndex, state.activeIndex, hsIndex !== -1 ? hsIndex : 0, tYaw, tPitch, tHfov, viewer);
                } else {
                    Debug.warn('Navigation', 'AutoForward Aborted: Not in valid state');
                }
            } else {
                Debug.warn('Navigation', `AutoForward: Target scene '${bestHotspot.target}' not found`);
            }
        } else {
            Debug.warn('Navigation', 'AutoForward: No valid hotspots found');
            // If we're in simulation mode and the auto-forward chain ends,
            // we must notify the SimulationSystem so it can handle completion or next steps.
            if (isSimulationMode && onSceneArrivalCallback) {
                // Pass true to indicate this is the END of an auto-forward chain
                onSceneArrivalCallback(state.activeIndex, true);
            }
        }
    }
}
