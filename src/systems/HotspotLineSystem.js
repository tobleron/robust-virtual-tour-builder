/**
 * HotspotLineSystem
 * 
 * Manages the visualization of connecting lines between the viewer center
 * and hotspots.
 */
import { getIsSimulationMode, calculateSmartArrivalTarget, getAutoForwardChain } from "./NavigationSystem.js";

export class HotspotLineSystem {
    /**
     * Update all lines on the SVG overlay
     * @param {Object} viewer - Pannellum viewer instance
     * @param {Object} state - Current application state
     * @param {MouseEvent|null} mouseEvent - Current mouse event (for in-progress link)
     */
    static updateLines(viewer, state, mouseEvent = null) {
        const svg = document.getElementById("viewer-hotspot-lines");
        if (!svg || !viewer) return;

        // Clear existing lines
        svg.innerHTML = '';

        const rect = svg.getBoundingClientRect();
        if (!rect || rect.width === 0) return;

        // GUARD: Ensure state and scenes exist
        if (!state || !state.scenes || state.activeIndex < 0 || !state.scenes[state.activeIndex]) {
            return;
        }

        const currentScene = state.scenes[state.activeIndex];
        if (!currentScene.hotspots) return;

        // Animation timing: Use high-res timestamp for smooth flow
        const time = Date.now() / 1000;
        const flowSpeed = 0.4; // Rounds per second
        const progressOffset = (time * flowSpeed) % 1.0;

        // 1. Draw persistent red dashed lines for existing hotspots
        currentScene.hotspots.forEach((h, i) => {
            // Persistent lines now represent the CAMERA transition:
            // From: Recorded Start View
            // To: Intended Arrival View (viewFrame - relative to current scene)
            if (h && h.startPitch !== undefined && h.startYaw !== undefined && h.viewFrame) {
                let startPitch = h.startPitch;
                let startYaw = h.startYaw;
                let endPitch = h.viewFrame.pitch;
                let endYaw = h.viewFrame.yaw;

                const isSim = getIsSimulationMode();

                // REMOVED MOMENTUM LOGIC: The visual line should always start exactly at the hotspot
                // to match the blinking arrow path and provide accurate feedback.
                /*
                if (isSim) {
                    const chain = getAutoForwardChain();
                    if (chain.length > 0) {
                        const momentum = 0.10;
                        let yawDiff = endYaw - startYaw;
                        while (yawDiff > 180) yawDiff -= 360;
                        while (yawDiff < -180) yawDiff += 360;

                        // If we have waypoints, momentum should apply to the first segment
                        if (!h.waypoints || h.waypoints.length === 0) {
                            startPitch = startPitch + (endPitch - startPitch) * momentum;
                            startYaw = startYaw + yawDiff * momentum;
                        }
                    }
                }
                */

                // DRAW MULTI-POINT PATH (Red Dashed)
                if (h.waypoints && h.waypoints.length > 0) {
                    let prevP = { pitch: startPitch, yaw: startYaw };

                    // Draw Start -> W1 -> W2 ... -> End
                    const allPoints = [...h.waypoints, { pitch: endPitch, yaw: endYaw }];

                    allPoints.forEach(p => {
                        const pStart = this.getScreenCoords(viewer, prevP.pitch, prevP.yaw, rect);
                        const pEnd = this.getScreenCoords(viewer, p.pitch, p.yaw, rect);

                        if (pStart && pEnd) {
                            this.drawLine(svg, pStart.x, pStart.y, pEnd.x, pEnd.y, "#ef4444", 3.0, 0.8, "4,4");
                        }
                        prevP = p;
                    });
                } else {
                    // Standard straight line
                    const startCoords = this.getScreenCoords(viewer, startPitch, startYaw, rect);
                    const endCoords = this.getScreenCoords(viewer, endPitch, endYaw, rect);

                    if (startCoords && endCoords) {
                        this.drawLine(svg, startCoords.x, startCoords.y, endCoords.x, endCoords.y, "#ef4444", 3.0, 0.8, "4,4");
                    }
                }
            }
        });

        // 2. DRAW IN-PROGRESS LINES if in linking mode
        if (state.isLinking && state.linkDraft) {
            const draft = state.linkDraft;

            // --- A. RED DASHED LINES (CAMERA PATH) ---
            // Connecting camera centers at each click
            let prevCam = { pitch: draft.camPitch, yaw: draft.camYaw };

            if (draft.intermediatePoints && draft.intermediatePoints.length > 0) {
                draft.intermediatePoints.forEach(p => {
                    const startCoords = this.getScreenCoords(viewer, prevCam.pitch, prevCam.yaw, rect);
                    const endCoords = this.getScreenCoords(viewer, p.camPitch, p.camYaw, rect);
                    if (startCoords && endCoords) {
                        this.drawLine(svg, startCoords.x, startCoords.y, endCoords.x, endCoords.y, "#ef4444", 3.0, 0.9, "5,5");
                    }
                    prevCam = { pitch: p.camPitch, yaw: p.camYaw };
                });
            }

            // Camera Path Rubber Band: from last waypoint camera center to CURRENT camera center
            const redStart = this.getScreenCoords(viewer, prevCam.pitch, prevCam.yaw, rect);
            const redEnd = this.getScreenCoords(viewer, viewer.getPitch(), viewer.getYaw(), rect);
            if (redStart && redEnd) {
                this.drawLine(svg, redStart.x, redStart.y, redEnd.x, redEnd.y, "#ef4444", 3.0, 0.8, "4,4");
            }

            // --- B. YELLOW DASHED LINES (FLOOR PATH / VISUAL INDICATOR) ---
            // Only visible during drafting to show where your clicks are
            let prevFloor = { pitch: draft.pitch, yaw: draft.yaw };

            if (draft.intermediatePoints && draft.intermediatePoints.length > 0) {
                draft.intermediatePoints.forEach(p => {
                    const startCoords = this.getScreenCoords(viewer, prevFloor.pitch, prevFloor.yaw, rect);
                    const endCoords = this.getScreenCoords(viewer, p.pitch, p.yaw, rect);
                    if (startCoords && endCoords) {
                        this.drawLine(svg, startCoords.x, startCoords.y, endCoords.x, endCoords.y, "#fbbf24", 3.0, 0.8, "3,3"); // Subtle path indicator
                    }
                    prevFloor = { pitch: p.pitch, yaw: p.yaw };
                });
            }

            // Floor Path Rubber Band (to Mouse)
            if (mouseEvent) {
                const mouseCoords = viewer.mouseEventToCoords(mouseEvent);
                const yellowStart = this.getScreenCoords(viewer, prevFloor.pitch, prevFloor.yaw, rect);
                const yellowEnd = this.getScreenCoords(viewer, mouseCoords[0], mouseCoords[1], rect);
                if (yellowStart && yellowEnd) {
                    this.drawLine(svg, yellowStart.x, yellowStart.y, yellowEnd.x, yellowEnd.y, "#fbbf24", 3.0, 0.8, "3,3");
                }
            }
        }
    }

    /**
     * Draw a single alternating arrow for simulation transitions
     */
    static drawSimulationArrow(viewer, startPitch, startYaw, endPitch, endYaw, progress, opacity = 1.0, waypoints = []) {
        const svg = document.getElementById("viewer-hotspot-lines");
        if (!svg || !viewer) return;

        const rect = svg.getBoundingClientRect();

        // 1. CONSTRUCT POINTS LIST (Start -> Waypoints -> End)
        const path = [{ pitch: startPitch, yaw: startYaw }];
        if (waypoints && waypoints.length > 0) {
            path.push(...waypoints);
        }
        path.push({ pitch: endPitch, yaw: endYaw });

        // 2. CALCULATE SEGMENT DISTANCES
        let totalDistance = 0;
        const segments = [];

        for (let i = 0; i < path.length - 1; i++) {
            const p1 = path[i];
            const p2 = path[i + 1];

            // Calculate shortest yaw diff
            let yawDiff = p2.yaw - p1.yaw;
            while (yawDiff > 180) yawDiff -= 360;
            while (yawDiff < -180) yawDiff += 360;

            const pitchDiff = p2.pitch - p1.pitch;
            // Euclidean distance in degree-space (approximation)
            const dist = Math.sqrt(yawDiff * yawDiff + pitchDiff * pitchDiff);

            segments.push({
                dist,
                yawDiff,
                pitchDiff,
                p1,
                p2
            });
            totalDistance += dist;
        }

        // 3. FIND CURRENT POSITION
        const targetDist = progress * totalDistance;
        let pCurrentPitch = startPitch;
        let pCurrentYaw = startYaw;
        let pNextYaw = endYaw;

        // Default Rotation in case of 0 distance
        // Use the first segment direction if available
        let yawForRotation = (segments.length > 0) ? segments[0].yawDiff : (endYaw - startYaw);
        let pitchForRotation = (segments.length > 0) ? segments[0].pitchDiff : (endPitch - startPitch);

        if (totalDistance > 0 && segments.length > 0) {
            let covered = 0;
            let currentSegment = segments[0];

            for (let seg of segments) {
                if (targetDist <= covered + seg.dist) {
                    currentSegment = seg;
                    const segmentProgress = (seg.dist > 0) ? (targetDist - covered) / seg.dist : 0;
                    pCurrentPitch = seg.p1.pitch + seg.pitchDiff * segmentProgress;
                    pCurrentYaw = seg.p1.yaw + seg.yawDiff * segmentProgress;

                    yawForRotation = seg.yawDiff;
                    pitchForRotation = seg.pitchDiff;
                    break;
                }
                covered += seg.dist;
                // If we overshoot (floating point), stick to last segment
                currentSegment = seg;
                pCurrentPitch = seg.p2.pitch;
                pCurrentYaw = seg.p2.yaw;
                yawForRotation = seg.yawDiff;
                pitchForRotation = seg.pitchDiff;
            }
        }

        // 4. PROJECT TO SCREEN
        const start = this.getScreenCoords(viewer, pCurrentPitch, pCurrentYaw, rect);

        // For rotation: Project a point slightly ahead along the CURRENT SEGMENT vector
        // This is smoother than looking at the next waypoint
        const lookAheadRatio = 0.01;
        const pLookAheadPitch = pCurrentPitch + pitchForRotation * lookAheadRatio;
        const pLookAheadYaw = pCurrentYaw + yawForRotation * lookAheadRatio;

        const end = this.getScreenCoords(viewer, pLookAheadPitch, pLookAheadYaw, rect);

        if (!start || !end) return;

        const x = start.x;
        const y = start.y;

        // Rotation angle
        const angle = Math.atan2(end.y - start.y, end.x - start.x) * (180 / Math.PI);

        // Alternating Color (Yellow/Green)
        const color = (Math.floor(Date.now() / 200) % 2 === 0) ? "#fbbf24" : "#10b981";

        const arrow = document.createElementNS("http://www.w3.org/2000/svg", "path");
        arrow.setAttribute("d", "M -10,-7 L 6,0 L -10,7 Z");
        arrow.setAttribute("fill", color);
        arrow.setAttribute("stroke", "#000");
        arrow.setAttribute("stroke-width", "1");
        arrow.setAttribute("transform", `translate(${x}, ${y}) rotate(${angle})`);

        // Apply Opacity
        if (opacity < 1.0) {
            arrow.setAttribute("opacity", opacity.toFixed(2));
        }

        svg.appendChild(arrow);
    }

    /**
     * Helper to draw a line on SVG
     */
    static drawLine(svg, x1, y1, x2, y2, color, width, opacity, dashArray = "") {
        const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
        line.setAttribute("x1", x1);
        line.setAttribute("y1", y1);
        line.setAttribute("x2", x2);
        line.setAttribute("y2", y2);
        line.setAttribute("stroke", color);
        line.setAttribute("stroke-width", width);
        line.setAttribute("stroke-opacity", opacity);
        if (dashArray) line.setAttribute("stroke-dasharray", dashArray);
        svg.appendChild(line);
    }

    /**
     * Project panorama coordinates to screen coordinates
     */
    static getScreenCoords(viewer, pitch, yaw, rect) {
        try {
            const camYaw = viewer.getYaw();
            const hfov = viewer.getHfov();

            let diff = yaw - camYaw;
            while (diff > 180) diff -= 360;
            while (diff < -180) diff += 360;

            const toRad = (deg) => deg * Math.PI / 180;
            const hfovRad = toRad(hfov);
            const camPitch = viewer.getPitch();
            const aspectRatio = rect.width / rect.height;
            const vfovRad = 2 * Math.atan(Math.tan(hfovRad / 2) / aspectRatio);

            const yawRad = toRad(diff);
            const pitchRad = toRad(pitch - camPitch);

            const x = Math.tan(yawRad) / Math.tan(hfovRad / 2);
            const y = Math.tan(pitchRad) / (Math.tan(vfovRad / 2) * Math.cos(yawRad));

            if (Math.cos(yawRad) < 0) return null;

            return {
                x: (rect.width / 2) * (1 + x),
                y: (rect.height / 2) * (1 - y)
            };
        } catch (e) {
            return null;
        }
    }
}
