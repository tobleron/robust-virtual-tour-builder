/**
 * ViewerHealthCheck - Validates viewer instance is functional
 * 
 * Provides periodic health monitoring for the Pannellum viewer instance.
 * Detects stuck states, invalid coordinates, and other issues.
 * 
 * @module ViewerHealthCheck
 */

import { DebugTelemetry } from './debugTelemetry.js';

/**
 * Check the health status of the viewer
 * @returns {Object} Health status with healthy boolean and reason if unhealthy
 */
export function checkViewerHealth() {
    const viewer = window.pannellumViewer;

    if (!viewer) {
        return { healthy: false, reason: 'no_instance' };
    }

    try {
        const yaw = viewer.getYaw();
        const pitch = viewer.getPitch();
        const hfov = viewer.getHfov();

        // Validate values are finite numbers
        if (!Number.isFinite(yaw) || !Number.isFinite(pitch)) {
            DebugTelemetry.log('ViewerHealth', 'Invalid coordinates detected', { yaw, pitch });
            return { healthy: false, reason: 'invalid_coords', yaw, pitch };
        }

        // Check for unreasonable values (sanity check)
        if (Math.abs(pitch) > 90) {
            DebugTelemetry.log('ViewerHealth', 'Pitch out of range', { pitch });
            return { healthy: false, reason: 'pitch_out_of_range', pitch };
        }

        // Check if viewer is loaded (has a panorama)
        const config = viewer.getConfig();
        if (!config || !config.panorama) {
            return { healthy: false, reason: 'no_panorama_loaded' };
        }

        return {
            healthy: true,
            stats: { yaw, pitch, hfov }
        };

    } catch (err) {
        DebugTelemetry.error('ViewerHealth', 'Health check failed', err);
        return { healthy: false, reason: err.message };
    }
}

/**
 * Start periodic health monitoring
 * @param {number} intervalMs - Check interval in milliseconds (default: 30000)
 * @returns {number} Interval ID (use clearInterval to stop)
 */
export function startHealthMonitor(intervalMs = 30000) {
    return setInterval(() => {
        const health = checkViewerHealth();
        if (!health.healthy) {
            console.warn('[ViewerHealthMonitor] Unhealthy state detected:', health.reason);
            DebugTelemetry.log('ViewerHealth', 'Periodic check failed', health);
        }
    }, intervalMs);
}

/**
 * Attempt to recover from unhealthy state
 * @returns {boolean} True if recovery attempted
 */
export function attemptRecovery() {
    const viewer = window.pannellumViewer;

    if (!viewer) {
        console.warn('[ViewerHealth] No viewer to recover');
        return false;
    }

    try {
        // Try resetting to safe values
        viewer.setPitch(0, false);
        viewer.setYaw(0, false);
        DebugTelemetry.log('ViewerHealth', 'Recovery attempted - reset to origin');
        return true;
    } catch (err) {
        DebugTelemetry.error('ViewerHealth', 'Recovery failed', err);
        return false;
    }
}

// Expose globally for debugging
if (typeof window !== 'undefined') {
    window.ViewerHealthCheck = {
        check: checkViewerHealth,
        startMonitor: startHealthMonitor,
        recover: attemptRecovery
    };
}
