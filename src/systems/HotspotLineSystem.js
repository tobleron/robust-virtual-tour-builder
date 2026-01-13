/**
 * HotspotLineSystem
 * 
 * Bridge to ReScript HotspotLine implementation.
 */
import * as HotspotLine from "./HotspotLine.bs.js";

export class HotspotLineSystem {
    /**
     * Update all lines on the SVG overlay
     * @param {Object} viewer - Pannellum viewer instance
     * @param {Object} state - Current application state
     * @param {MouseEvent|null} mouseEvent - Current mouse event (for in-progress link)
     */
    static updateLines(viewer, state, mouseEvent = null) {
        return HotspotLine.updateLines(viewer, state, mouseEvent || undefined, undefined);
    }

    /**
     * Draw a single alternating arrow for simulation transitions
     */
    static drawSimulationArrow(viewer, startPitch, startYaw, endPitch, endYaw, progress, opacity = 1.0, waypoints = [], colorOverride = null) {
        return HotspotLine.drawSimulationArrow(
            viewer,
            startPitch,
            startYaw,
            endPitch,
            endYaw,
            progress,
            opacity,
            waypoints,
            colorOverride || undefined,
            undefined
        );
    }
}
