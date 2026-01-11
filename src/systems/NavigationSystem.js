import { notify } from "../utils/NotificationSystem.js";
import { store } from "../store.js";
import { Debug } from "../utils/Debug.js";
import { getCatmullRomSpline } from "../utils/PathInterpolation.js";
import { PubSub, EVENTS } from "../utils/PubSub.js";
import {
    PANNING_VELOCITY,
    PANNING_MIN_DURATION,
    PANNING_MAX_DURATION,
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
let previewingLink = null; // { sceneIndex, hotspotIndex } used to hide static arrow during preview

export function getPreviewingLink() { return previewingLink; }

/**
 * Initialize Navigation System
 */
export function initNavigation() {
    isSimulationMode = false;
    currentJourneyId = 0;
    isNavigating = false;
    incomingLink = null;
    autoForwardChain = [];

    // Subscribe to completion events from the renderer
    PubSub.subscribe(EVENTS.NAV_COMPLETED, (data) => {
        if (data.journeyId === currentJourneyId) {
            handleJourneyFinalize(data);
        }
    });

    PubSub.subscribe(EVENTS.NAV_CANCELLED, (data) => {
        if (data.journeyId === currentJourneyId) {
            isNavigating = false;
        }
    });

    Debug.info('Navigation', 'Navigation system initialized');
}

/**
 * Clear all simulation UI artifacts
 */
export function clearSimulationUI() {
    PubSub.publish('CLEAR_SIM_UI');
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
            if (currentScene) {
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

        // PRIORITY: Use creation sequence (Oldest first)
        let nextHotspot = null;

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
 * Handle the final step of a navigation journey (store update, etc.)
 */
function handleJourneyFinalize(data) {
    const { journeyId, targetIndex, arrivalYaw, arrivalPitch, arrivalHfov, previewOnly, sourceIndex, hotspotIndex } = data;

    if (journeyId !== currentJourneyId) return;

    Debug.info('Navigation', `Journey ${journeyId} reached handleJourneyFinalize`);

    // PREVIEW MODE EXIT
    if (previewOnly) {
        Debug.info('Navigation', `Preview Journey ${journeyId} complete. Staying in current scene.`);
        isNavigating = false;
        previewingLink = null;
        notify("Preview complete", "success");
        return;
    }

    const state = store.state;
    const sourceScene = state.scenes[sourceIndex];
    const hotspot = sourceScene?.hotspots[hotspotIndex];

    incomingLink = { sceneIndex: sourceIndex, hotspotIndex: hotspotIndex };
    Debug.info('Navigation', `Finalizing journey ${journeyId} to Scene ${targetIndex}`);

    store.setPreloadingScene(-1);

    // SYNC VISUAL PIPELINE
    if (hotspot && hotspot.linkId) {
        const timelineItem = state.timeline.find(item =>
            item.sceneId === sourceScene.id && item.linkId === hotspot.linkId
        );
        if (timelineItem) {
            store.setActiveTimelineStep(timelineItem.id);
        } else {
            store.setActiveTimelineStep(null);
        }
    }

    isNavigating = false; // Release guard
    store.setActiveScene(targetIndex, arrivalYaw, arrivalPitch, { type: "link", hfov: arrivalHfov });
    clearSimulationUI();

    // Notify SimulationSystem
    if (isSimulationMode && onSceneArrivalCallback) {
        onSceneArrivalCallback(targetIndex);
    }
}

/**
 * Force stop any ongoing navigation journey
 */
export function cancelNavigation() {
    isNavigating = false;
    currentJourneyId++;
    PubSub.publish(EVENTS.NAV_CANCELLED, { journeyId: currentJourneyId });
    Debug.info('Navigation', 'Navigation manually cancelled');
}

/**
 * Calculate the full path parameters for a navigation journey
 */
function calculateJourneyPath(targetIndex, sourceSceneIndex, sourceHotspotIndex, targetYaw, targetPitch, targetHfov, currentView) {
    const state = store.state;
    const sourceScene = state.scenes[sourceSceneIndex];
    const hotspot = sourceScene?.hotspots[sourceHotspotIndex];

    const cleanYaw = Number.isFinite(targetYaw) ? targetYaw : 0;
    const cleanPitch = Number.isFinite(targetPitch) ? targetPitch : 0;
    const cleanHfov = Number.isFinite(targetHfov) ? targetHfov : 90;

    let { arrivalYaw, arrivalPitch, arrivalHfov } = (isSimulationMode)
        ? calculateSmartArrivalTarget(state, targetIndex)
        : { arrivalYaw: cleanYaw, arrivalPitch: cleanPitch, arrivalHfov: cleanHfov };

    const usePathLogic = (isSimulationMode) && hotspot && hotspot.viewFrame;
    const targetPitchForPan = usePathLogic ? hotspot.viewFrame.pitch : cleanPitch;
    const targetYawForPan = usePathLogic ? hotspot.viewFrame.yaw : cleanYaw;
    const targetHfovForPan = usePathLogic ? (hotspot.viewFrame.hfov || cleanHfov) : cleanHfov;

    const actualStartPitch = (hotspot?.startPitch !== undefined) ? hotspot.startPitch : currentView.pitch;
    const actualStartYaw = (hotspot?.startYaw !== undefined) ? hotspot.startYaw : currentView.yaw;
    const actualStartHfov = (hotspot?.startHfov !== undefined) ? hotspot.startHfov : currentView.hfov;

    let initialYawDiff = targetYawForPan - actualStartYaw;
    while (initialYawDiff > 180) initialYawDiff -= 360;
    while (initialYawDiff < -180) initialYawDiff += 360;

    const startPitch = actualStartPitch;
    const startYaw = actualStartYaw;
    const startHfov = actualStartHfov;

    const waypointsRaw = hotspot?.waypoints || [];
    const waypoints = Array.isArray(waypointsRaw) ? waypointsRaw.filter(wp =>
        wp && typeof wp === 'object' &&
        (typeof wp.pitch === 'number' || typeof wp.camPitch === 'number')
    ) : [];

    const controlPoints = [{ pitch: startPitch, yaw: startYaw }];
    waypoints.forEach(wp => {
        const wpPitch = wp.pitch !== undefined ? wp.pitch : (wp.camPitch !== undefined ? wp.camPitch : 0);
        const wpYaw = wp.yaw !== undefined ? wp.yaw : (wp.camYaw !== undefined ? wp.camYaw : 0);
        controlPoints.push({ pitch: wpPitch, yaw: wpYaw });
    });
    controlPoints.push({ pitch: targetPitchForPan, yaw: targetYawForPan });

    let cameraPath = (controlPoints.length > 2) ? getCatmullRomSpline(controlPoints, 100) : controlPoints;

    let totalPathDistance = 0;
    const segments = [];
    for (let i = 0; i < cameraPath.length - 1; i++) {
        const p1 = cameraPath[i];
        const p2 = cameraPath[i + 1];
        let segYawDiff = p2.yaw - p1.yaw;
        while (segYawDiff > 180) segYawDiff -= 360;
        while (segYawDiff < -180) segYawDiff += 360;
        const segPitchDiff = p2.pitch - p1.pitch;
        const segDist = Math.sqrt(segYawDiff * segYawDiff + segPitchDiff * segPitchDiff);
        segments.push({ dist: segDist, yawDiff: segYawDiff, pitchDiff: segPitchDiff, p1, p2 });
        totalPathDistance += segDist;
    }

    const rawDuration = (totalPathDistance / PANNING_VELOCITY) * 1000;
    const panDuration = Math.min(Math.max(rawDuration, PANNING_MIN_DURATION), PANNING_MAX_DURATION);

    return {
        startPitch, startYaw, startHfov,
        targetPitchForPan, targetYawForPan, targetHfovForPan,
        arrivalYaw, arrivalPitch, arrivalHfov,
        segments, totalPathDistance, panDuration, waypoints
    };
}

/**
 * Centralized navigation function (Decoupled version)
 */
export function navigateToScene(targetIndex, sourceSceneIndex, sourceHotspotIndex, targetYaw = 0, targetPitch = 0, targetHfov = 90, overrideViewer = null, previewOnly = false) {
    if (isNavigating) {
        Debug.warn('Navigation', 'BLOCKED: Navigation already in progress');
        return;
    }

    const journeyId = ++currentJourneyId;
    isNavigating = true;

    const state = store.state;
    const sourceScene = state.scenes[sourceSceneIndex];
    const hotspot = sourceScene?.hotspots[sourceHotspotIndex];

    // We need current view. If viewer is provided, use it. Otherwise assume window.
    const viewer = overrideViewer || window.pannellumViewer;
    const currentView = viewer ? {
        pitch: viewer.getPitch(),
        yaw: viewer.getYaw(),
        hfov: viewer.getHfov()
    } : { pitch: 0, yaw: 0, hfov: 90 };

    if (previewOnly) {
        previewingLink = { sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex };
    }

    // Determine if we should animate
    const shouldAnimate = (isSimulationMode || previewOnly) && hotspot;

    if (shouldAnimate) {
        const pathData = calculateJourneyPath(targetIndex, sourceSceneIndex, sourceHotspotIndex, targetYaw, targetPitch, targetHfov, currentView);

        PubSub.publish(EVENTS.NAV_START, {
            journeyId,
            sourceIndex: sourceSceneIndex,
            targetIndex,
            hotspotIndex: sourceHotspotIndex,
            previewOnly,
            pathData
        });
    } else {
        // Manual jump
        const { arrivalYaw, arrivalPitch, arrivalHfov } = calculateSmartArrivalTarget(state, targetIndex);
        handleJourneyFinalize({
            journeyId,
            targetIndex,
            sourceIndex: sourceSceneIndex,
            hotspotIndex: sourceHotspotIndex,
            arrivalYaw,
            arrivalPitch,
            arrivalHfov,
            previewOnly: false
        });
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
            notify(`⚠️ Navigation loop detected. Auto-forward paused.`, 'warning');
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

        // PRIORITY: Use creation sequence (Oldest first)
        let bestHotspot = null;

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
