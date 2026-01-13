/**
 * PathInterpolation.js
 * Utilities for generating smooth curved paths for navigation
 * 
 * REFACTORED: Logic moved to ReScript (PathInterpolation.bs.js)
 */

import { getCatmullRomSpline as resGetCatmullRomSpline } from "./PathInterpolation.bs.js";

/**
 * Generate a smooth spline path through a set of control points
 * Uses Centripetal Catmull-Rom Spline algorithm
 * 
 * @param {Array<{yaw: number, pitch: number}>} points - Control points (must include start and end)
 * @param {number} totalSegments - Approximate number of segments to generate for the whole path
 * @returns {Array<{yaw: number, pitch: number}>} - Dense array of points forming the curve
 */
export function getCatmullRomSpline(points, totalSegments = 100) {
    // Delegate to ReScript implementation
    return resGetCatmullRomSpline(points, totalSegments);
}
