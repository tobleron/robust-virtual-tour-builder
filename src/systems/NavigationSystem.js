import { store } from "../store.js";
import { HotspotLineSystem } from "./HotspotLineSystem.js";
import { Debug } from "../utils/Debug.js";
import { getCatmullRomSpline } from "../utils/PathInterpolation.js";
import {
    PANNING_VELOCITY,
    PANNING_MIN_DURATION,
    PANNING_MAX_DURATION,
    BLINK_DURATION_PREVIEW,
    BLINK_DURATION_SIMULATION,
    BLINK_RATE_PREVIEW,
    BLINK_RATE_SIMULATION
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
 * Centralized navigation function
 * SIMPLIFIED VERSION - Uses Pannellum's built-in lookAt for reliability
 * @param {number} targetIndex - Target scene index
 * @param {number} sourceSceneIndex - Source scene index
 * @param {number} sourceHotspotIndex - Source hotspot index
 * @param {number} targetYaw - Target yaw orientation
 * @param {number} targetPitch - Target pitch orientation
 * @param {object} overrideViewer - Optional: Use this viewer instead of window.pannellumViewer
 */
export function navigateToScene(targetIndex, sourceSceneIndex, sourceHotspotIndex, targetYaw = 0, targetPitch = 0, targetHfov = 90, overrideViewer = null, previewOnly = false) {
    console.log(`[Navigation] attempt: target=${targetIndex}, source=${sourceSceneIndex}, isNavigating=${isNavigating}, previewOnly=${previewOnly}`);
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
    let { arrivalYaw, arrivalPitch, arrivalHfov } = (isSimulationMode || previewOnly)
        ? calculateSmartArrivalTarget(state, targetIndex)
        : { arrivalYaw: cleanYaw, arrivalPitch: cleanPitch, arrivalHfov: cleanHfov };

    // PAN TARGET (for the SOURCE scene):
    // The pan occurs in the current scene's coordinate system.
    // We must target the original viewFrame recorded for this link in Scene A.
    // NOTE: In previewOnly mode, we definitely use the viewFrame to show the intended path.
    const usePathLogic = (isSimulationMode || previewOnly) && hotspot && hotspot.viewFrame;

    const targetPitchForPan = usePathLogic ? hotspot.viewFrame.pitch : cleanPitch;
    const targetYawForPan = usePathLogic ? hotspot.viewFrame.yaw : cleanYaw;
    const targetHfovForPan = usePathLogic ? (hotspot.viewFrame.hfov || cleanHfov) : cleanHfov;

    const journeyId = ++currentJourneyId;
    isNavigating = true; // Set guard

    if (previewOnly) {
        previewingLink = { sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex };
    }

    Debug.info('Navigation', `NAV_START`, {
        journeyId,
        source: sourceSceneIndex,
        target: targetIndex,
        hotspot: sourceHotspotIndex,
        previewOnly,
        isSimulationMode,
        targetView: { yaw: cleanYaw, pitch: cleanPitch, hfov: cleanHfov }
    });

    const finalize = () => {
        if (journeyId !== currentJourneyId) {
            Debug.debug('Navigation', `Journey ${journeyId} cancelled (current: ${currentJourneyId})`);
            isNavigating = false; // Release guard
            if (previewOnly && previewingLink && previewingLink.hotspotIndex === sourceHotspotIndex) {
                previewingLink = null;
            }
            return;
        }

        console.log(`[Navigation] Journey ${journeyId} reaching finalize()`);

        // PREVIEW MODE EXIT
        if (previewOnly) {
            Debug.info('Navigation', `Preview Journey ${journeyId} complete. Staying in current scene.`);
            isNavigating = false;
            previewingLink = null; // Clear state so static arrow can be drawn again

            // Re-draw lines immediately to show the static arrow again
            // This will clear the SVG and redraw all static elements (red lines + green arrows)
            if (viewer) HotspotLineSystem.updateLines(viewer, store.state);

            if (window.notify) window.notify("Preview complete", "success");
            return;
        }

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

    // SIMULATION / PREVIEW MODE: Sequential panning (no crossfade overlap)
    // We enable the animation loop if we are in Sim Mode OR Preview Mode, and have hotspot/viewer.
    if ((isSimulationMode || previewOnly) && hotspot && viewer) {
        console.log(`[Navigation] Animation Active (Sim: ${isSimulationMode}, Preview: ${previewOnly}) - Journey ${journeyId}`);

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
            let initialYawDiff = targetYawForPan - actualStartYaw;
            while (initialYawDiff > 180) initialYawDiff -= 360;
            while (initialYawDiff < -180) initialYawDiff += 360;

            // MOMENTUM LOGIC:
            // REMOVED to force exact alignment with the visual path lines (red dashed lines).
            // The arrow must start exactly where the line starts.
            const momentum = 0.0;

            const startPitch = actualStartPitch + (targetPitchForPan - actualStartPitch) * momentum;
            const startYaw = actualStartYaw + initialYawDiff * momentum;
            const startHfov = actualStartHfov + (targetHfovForPan - actualStartHfov) * momentum;

            Debug.debug('Navigation', `Start Position: Yaw: ${startYaw.toFixed(1)}°, Pitch: ${startPitch.toFixed(1)}°, HFOV: ${startHfov.toFixed(1)}`);

            // CRITICAL: Always set camera position before animation to ensure consistent starting point
            viewer.setPitch(startPitch, false);
            viewer.setYaw(startYaw, false);
            viewer.setHfov(startHfov, false);

            // BUILD WAYPOINT PATH for camera interpolation
            // Path: Start -> Waypoints -> End
            const waypointsRaw = hotspot.waypoints || [];

            // SECURITY: Validate waypoint structure
            const waypoints = Array.isArray(waypointsRaw) ? waypointsRaw.filter(wp =>
                wp && typeof wp === 'object' &&
                (typeof wp.pitch === 'number' || typeof wp.camPitch === 'number')
            ) : [];

            // 1. Define Control Points
            const controlPoints = [{ pitch: startPitch, yaw: startYaw }];

            waypoints.forEach(wp => {
                const wpPitch = wp.pitch !== undefined ? wp.pitch : (wp.camPitch !== undefined ? wp.camPitch : 0);
                const wpYaw = wp.yaw !== undefined ? wp.yaw : (wp.camYaw !== undefined ? wp.camYaw : 0);
                controlPoints.push({ pitch: wpPitch, yaw: wpYaw });
            });

            controlPoints.push({ pitch: targetPitchForPan, yaw: targetYawForPan });

            // 2. Generate Spline Path (Dense points)
            // Use same resolution (approx) as lines to match visual
            let cameraPath = [];
            if (controlPoints.length > 2) {
                cameraPath = getCatmullRomSpline(controlPoints, 100);
            } else {
                // Fallback for straight lines (only 2 points)
                cameraPath = controlPoints;
            }

            // CALCULATE SEGMENT DISTANCES for proper interpolation
            // The logic below now iterates over the DENSE path segments (linear interp between spline points)
            let totalPathDistance = 0;
            const segments = [];

            for (let i = 0; i < cameraPath.length - 1; i++) {
                const p1 = cameraPath[i];
                const p2 = cameraPath[i + 1];

                // Calculate shortest yaw difference
                let segYawDiff = p2.yaw - p1.yaw;
                while (segYawDiff > 180) segYawDiff -= 360;
                while (segYawDiff < -180) segYawDiff += 360;

                const segPitchDiff = p2.pitch - p1.pitch;
                const segDist = Math.sqrt(segYawDiff * segYawDiff + segPitchDiff * segPitchDiff);

                segments.push({
                    dist: segDist,
                    yawDiff: segYawDiff,
                    pitchDiff: segPitchDiff,
                    p1,
                    p2
                });
                totalPathDistance += segDist;
            }

            // DYNAMIC VELOCITY CALCULATION using total path distance
            const rawDuration = (totalPathDistance / PANNING_VELOCITY) * 1000;
            const panDuration = Math.min(Math.max(rawDuration, PANNING_MIN_DURATION), PANNING_MAX_DURATION);

            const startTime = Date.now();
            let crossfadeTriggered = false;
            let blinkStartTime = null; // Track when blink sequence starts

            // TELEMETRY
            Debug.info('Navigation', `JOURNEY_START`, {
                journeyId,
                from: sourceScene?.name,
                to: state.scenes[targetIndex]?.name,
                panDuration: Math.round(panDuration),
                distance: totalPathDistance.toFixed(1),
                waypointCount: waypoints.length,
                previewOnly
            });

            // Arrow reference points:
            // SYNC FIX: The arrow MUST start where the camera starts (incorporating momentum)
            const arrowStartPitch = startPitch;
            const arrowStartYaw = startYaw;

            // ANIMATION LOOP - Now manually interpolates through waypoints
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

                // BLINK FINISH SEQUENCE
                // Instead of immediately finishing at 1.0, we pause and blink
                if (progress >= 1.0) {
                    // Start Blink Sequence if not already started
                    if (!blinkStartTime) {
                        blinkStartTime = Date.now();
                    }

                    const blinkElapsed = Date.now() - blinkStartTime;

                    // PREVIEW MODE: Blink red twice (slower, more visible)
                    // SIMULATION MODE: 600ms blink with opacity toggle (yellow/green)
                    const isPreview = previewOnly;

                    // Use centralized constants
                    const blinkDuration = isPreview ? BLINK_DURATION_PREVIEW : BLINK_DURATION_SIMULATION;
                    const blinkRate = isPreview ? BLINK_RATE_PREVIEW : BLINK_RATE_SIMULATION;

                    // Set final position exactly at the END of the waypoint path
                    viewer.setPitch(targetPitchForPan, false);
                    viewer.setYaw(targetYawForPan, false);
                    viewer.setHfov(targetHfovForPan, false);

                    if (blinkElapsed < blinkDuration) {
                        // Calculate blink state (for 2 blinks: on-off-on-off pattern)
                        const blinkState = Math.floor(blinkElapsed / blinkRate) % 2;
                        const opacity = blinkState === 0 ? 1.0 : 0.0;
                        const colorOverride = isPreview ? 'red' : null;

                        HotspotLineSystem.updateLines(viewer, state);
                        // For preview mode, pass special flag to draw RED blink
                        HotspotLineSystem.drawSimulationArrow(
                            viewer,
                            arrowStartPitch,
                            arrowStartYaw,
                            targetPitchForPan,
                            targetYawForPan,
                            1.0, // Force progress to exact end
                            opacity, // Blink opacity
                            waypoints,
                            colorOverride // Color override for preview mode
                        );
                        requestAnimationFrame(animLoop);
                        return;
                    }

                    // COMPLETE: Cleanup and finalize
                    crossfadeTriggered = true;
                    blinkStartTime = null; // Reset for next time
                    finalize();
                    return;
                }

                // CALCULATE CAMERA POSITION along the multi-segment path
                const targetDist = progress * totalPathDistance;
                let camPitch = startPitch;
                let camYaw = startYaw;

                if (totalPathDistance > 0 && segments.length > 0) {
                    let covered = 0;

                    for (const seg of segments) {
                        if (targetDist <= covered + seg.dist) {
                            // We're within this segment
                            const segProgress = seg.dist > 0 ? (targetDist - covered) / seg.dist : 0;
                            camPitch = seg.p1.pitch + seg.pitchDiff * segProgress;
                            camYaw = seg.p1.yaw + seg.yawDiff * segProgress;
                            break;
                        }
                        covered += seg.dist;
                        // Move to end of this segment
                        camPitch = seg.p2.pitch;
                        camYaw = seg.p2.yaw;
                    }
                }

                // MANUALLY SET CAMERA POSITION (not using lookAt which goes direct)
                viewer.setPitch(camPitch, false);
                viewer.setYaw(camYaw, false);

                // Interpolate HFOV linearly
                const hfovProgress = startHfov + (targetHfovForPan - startHfov) * progress;
                viewer.setHfov(hfovProgress, false);

                // Update UI: Draw arrow following the actual camera pan path
                HotspotLineSystem.updateLines(viewer, state);
                HotspotLineSystem.drawSimulationArrow(
                    viewer,
                    arrowStartPitch,
                    arrowStartYaw,
                    targetPitchForPan,
                    targetYawForPan,
                    progress,
                    1.0,
                    waypoints
                );

                requestAnimationFrame(animLoop);
            };

            // START - No longer using lookAt, animation loop handles everything
            requestAnimationFrame(animLoop);

        } catch (e) {
            console.error("[Navigation] Critical error in simulation animation loop:", e);
            finalize();
        }
    } else {
        // MANUAL MODE: No animation, just swap
        if (isSimulationMode && !previewOnly) {
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
