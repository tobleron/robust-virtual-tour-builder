/**
 * NavigationRenderer.js
 * 
 * Handles the actual execution of navigation animations (panning, waypoints, blinking).
 * Decoupled from the NavigationSystem via PubSub.
 */

import { PubSub, EVENTS } from "../utils/PubSub.js";
import { HotspotLineSystem } from "./HotspotLineSystem.js";
import { store } from "../store.js";
import { Debug } from "../utils/Debug.js";
import {
    BLINK_DURATION_PREVIEW,
    BLINK_DURATION_SIMULATION,
    BLINK_RATE_PREVIEW,
    BLINK_RATE_SIMULATION
} from "../constants.js";

let activeJourneyId = null;
let currentViewerGetter = null;

export const NavigationRenderer = {
    /**
     * Initialize the renderer
     * @param {function} viewerGetter - Function that returns the currently active Pannellum viewer
     */
    init(viewerGetter) {
        currentViewerGetter = viewerGetter;

        // Listen for navigation start
        PubSub.subscribe(EVENTS.NAV_START, (data) => {
            this.startJourney(data);
        });

        // Listen for cancellation
        PubSub.subscribe(EVENTS.NAV_CANCELLED, (data) => {
            if (data.journeyId === activeJourneyId) {
                activeJourneyId = null;
            }
        });

        // Listen for global clear UI signal
        PubSub.subscribe('CLEAR_SIM_UI', () => {
            const svg = document.getElementById("viewer-hotspot-lines");
            if (svg) svg.innerHTML = '';
        });
    },

    /**
     * Start the animation journey
     */
    startJourney(data) {
        const { journeyId, pathData, previewOnly, targetIndex, sourceIndex, hotspotIndex } = data;
        const viewer = currentViewerGetter();

        if (!viewer) {
            Debug.error('NavRenderer', 'Cannot start journey: Viewer not ready');
            PubSub.publish(EVENTS.NAV_CANCELLED, { journeyId });
            return;
        }

        activeJourneyId = journeyId;
        const startTime = Date.now();
        let blinkStartTime = null;
        let crossfadeTriggered = false;

        const {
            startPitch, startYaw, startHfov,
            targetPitchForPan, targetYawForPan, targetHfovForPan,
            segments, totalPathDistance, panDuration, waypoints
        } = pathData;

        // CRITICAL: Ensure starting position
        viewer.setPitch(startPitch, false);
        viewer.setYaw(startYaw, false);
        viewer.setHfov(startHfov, false);

        const arrowStartPitch = startPitch;
        const arrowStartYaw = startYaw;

        const animLoop = () => {
            if (journeyId !== activeJourneyId) {
                Debug.warn('NavRenderer', `JOURNEY_CANCELLED`, { journeyId });
                return;
            }

            if (crossfadeTriggered) {
                const svg = document.getElementById("viewer-hotspot-lines");
                if (svg) svg.innerHTML = '';
                return;
            }

            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / panDuration, 1.0);

            // BLINK FINISH SEQUENCE
            if (progress >= 1.0) {
                if (!blinkStartTime) {
                    blinkStartTime = Date.now();
                }

                const blinkElapsed = Date.now() - blinkStartTime;
                const isPreview = previewOnly;
                const blinkDuration = isPreview ? BLINK_DURATION_PREVIEW : BLINK_DURATION_SIMULATION;
                const blinkRate = isPreview ? BLINK_RATE_PREVIEW : BLINK_RATE_SIMULATION;

                viewer.setPitch(targetPitchForPan, false);
                viewer.setYaw(targetYawForPan, false);
                viewer.setHfov(targetHfovForPan, false);

                if (blinkElapsed < blinkDuration) {
                    const blinkState = Math.floor(blinkElapsed / blinkRate) % 2;
                    const opacity = blinkState === 0 ? 1.0 : 0.0;
                    const colorOverride = isPreview ? 'red' : null;

                    HotspotLineSystem.updateLines(viewer, store.state);
                    HotspotLineSystem.drawSimulationArrow(
                        viewer,
                        arrowStartPitch,
                        arrowStartYaw,
                        targetPitchForPan,
                        targetYawForPan,
                        1.0,
                        opacity,
                        waypoints,
                        colorOverride
                    );
                    requestAnimationFrame(animLoop);
                    return;
                }

                // COMPLETE
                crossfadeTriggered = true;
                PubSub.publish(EVENTS.NAV_COMPLETED, {
                    journeyId,
                    targetIndex,
                    sourceIndex,
                    hotspotIndex,
                    arrivalYaw: pathData.arrivalYaw,
                    arrivalPitch: pathData.arrivalPitch,
                    arrivalHfov: pathData.arrivalHfov,
                    previewOnly
                });
                return;
            }

            // INTERPOLATE
            const targetDist = progress * totalPathDistance;
            let camPitch = startPitch;
            let camYaw = startYaw;

            if (totalPathDistance > 0 && segments.length > 0) {
                let covered = 0;
                for (const seg of segments) {
                    if (targetDist <= covered + seg.dist) {
                        const segProgress = seg.dist > 0 ? (targetDist - covered) / seg.dist : 0;
                        camPitch = seg.p1.pitch + seg.pitchDiff * segProgress;
                        camYaw = seg.p1.yaw + seg.yawDiff * segProgress;
                        break;
                    }
                    covered += seg.dist;
                    camPitch = seg.p2.pitch;
                    camYaw = seg.p2.yaw;
                }
            }

            viewer.setPitch(camPitch, false);
            viewer.setYaw(camYaw, false);
            const hfovProgress = startHfov + (targetHfovForPan - startHfov) * progress;
            viewer.setHfov(hfovProgress, false);

            // Update UI
            HotspotLineSystem.updateLines(viewer, store.state);
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

        requestAnimationFrame(animLoop);
    }
};
