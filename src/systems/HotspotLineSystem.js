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

                // SYNC FIX: If we are in a continuous chain, the camera (and arrow)
                // actually starts at a 10% offset from the literal start point.
                if (isSim) {
                    const chain = getAutoForwardChain();
                    if (chain.length > 0) {
                        const momentum = 0.10;
                        let yawDiff = endYaw - startYaw;
                        while (yawDiff > 180) yawDiff -= 360;
                        while (yawDiff < -180) yawDiff += 360;

                        startPitch = startPitch + (endPitch - startPitch) * momentum;
                        startYaw = startYaw + yawDiff * momentum;
                    }
                }

                const startCoords = this.getScreenCoords(viewer, startPitch, startYaw, rect);
                const endCoords = this.getScreenCoords(viewer, endPitch, endYaw, rect);

                if (startCoords && endCoords) {
                    this.drawLine(svg, startCoords.x, startCoords.y, endCoords.x, endCoords.y, "#ef4444", 1.5, 0.6, "4,4");
                }
            }
        });

        // 2. DRAW IN-PROGRESS LINES if in linking mode
        if (state.isLinking && state.linkDraft && mouseEvent) {
            const draft = state.linkDraft;
            const mouseCoords = viewer.mouseEventToCoords(mouseEvent);
            const click2Pitch = mouseCoords[0];
            const click2Yaw = mouseCoords[1];

            // A. Red Dashed Line (CAMERA PATH)
            // Connects Phase 1 center to CURRENT center
            const redStart = this.getScreenCoords(viewer, draft.camPitch, draft.camYaw, rect);
            const redEnd = this.getScreenCoords(viewer, viewer.getPitch(), viewer.getYaw(), rect);

            if (redStart && redEnd) {
                this.drawLine(svg, redStart.x, redStart.y, redEnd.x, redEnd.y, "#ef4444", 2, 0.8, "5,5");
            }

            // B. Yellow Dashed Line (PHYSICAL ATTACHMENT)
            // Connects Phase 1 click point to Phase 2 click point (mouse)
            const yellowStart = this.getScreenCoords(viewer, draft.pitch, draft.yaw, rect);
            const yellowEnd = this.getScreenCoords(viewer, click2Pitch, click2Yaw, rect);

            if (yellowStart && yellowEnd) {
                this.drawLine(svg, yellowStart.x, yellowStart.y, yellowEnd.x, yellowEnd.y, "#fbbf24", 1.5, 0.7, "3,3");
            }
        }
    }

    /**
     * Draw a single alternating arrow for simulation transitions
     */
    static drawSimulationArrow(viewer, startPitch, startYaw, endPitch, endYaw, progress, opacity = 1.0) {
        const svg = document.getElementById("viewer-hotspot-lines");
        if (!svg || !viewer) return;

        const rect = svg.getBoundingClientRect();
        const start = this.getScreenCoords(viewer, startPitch, startYaw, rect);
        const end = this.getScreenCoords(viewer, endPitch, endYaw, rect);

        if (!start || !end) return;

        // Current position based on progress (0.0 to 1.0)
        const x = start.x + (end.x - start.x) * progress;
        const y = start.y + (end.y - start.y) * progress;

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
