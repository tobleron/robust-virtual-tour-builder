/**
 * PathInterpolation.js
 * Utilities for generating smooth curved paths for navigation
 */

/**
 * Generate a smooth spline path through a set of control points
 * Uses Centripetal Catmull-Rom Spline algorithm
 * 
 * @param {Array<{yaw: number, pitch: number}>} points - Control points (must include start and end)
 * @param {number} totalSegments - Approximate number of segments to generate for the whole path
 * @returns {Array<{yaw: number, pitch: number}>} - Dense array of points forming the curve
 */
export function getCatmullRomSpline(points, totalSegments = 100) {
    if (!points || points.length < 2) return points;

    // 1. Prepare Points: Duplicate start and end for Catmull-Rom constraint
    // and UNROLL YAW to prevent wrapping issues (e.g. 170 -> -170 should be continuous)
    const rawPoints = [points[0], ...points, points[points.length - 1]];
    const unrolledPoints = [];

    let previousYaw = rawPoints[0].yaw;
    let rotationAccumulator = 0;

    rawPoints.forEach(p => {
        let currentYaw = p.yaw;

        // Calculate shortest difference
        let diff = currentYaw - previousYaw;
        while (diff > 180) diff -= 360;
        while (diff < -180) diff += 360;

        const absoluteYaw = previousYaw + diff;
        unrolledPoints.push({
            yaw: absoluteYaw,
            pitch: p.pitch
        });

        previousYaw = absoluteYaw;
    });

    // 2. Generate Spline Points
    const splinePoints = [];
    const numSections = unrolledPoints.length - 3; // Catmull-Rom uses 4 points sliding window
    if (numSections < 1) return points;

    const segmentsPerSection = Math.ceil(totalSegments / numSections);

    for (let i = 0; i < numSections; i++) {
        const p0 = unrolledPoints[i];
        const p1 = unrolledPoints[i + 1];
        const p2 = unrolledPoints[i + 2];
        const p3 = unrolledPoints[i + 3];

        // Loop for this section (P1 -> P2)
        // For the last section, we include t=1.0 to ensure we hit end point exactly?
        // Actually, usually 0 to <1, and we explicitly add the very last point at the end.
        for (let j = 0; j < segmentsPerSection; j++) {
            const t = j / segmentsPerSection;
            const pt = interpolateCatmullRom(p0, p1, p2, p3, t);
            splinePoints.push(pt);
        }
    }

    // Add the very last point explicitly to ensure closure
    splinePoints.push(unrolledPoints[unrolledPoints.length - 2]);

    // 3. Normalize Yaws back to -180..180
    return splinePoints.map(p => ({
        yaw: normalizeYaw(p.yaw),
        pitch: p.pitch
    }));
}

/**
 * Standard Catmull-Rom Interpolation
 * Alpha = 0.5 (Centripetal) is often best to avoid loops, 
 * but for simplicity and "camera-like" motion, the uniform variant (alpha=0) 
 * or standard hermite basis usually works well if points are somewhat evenly spaced.
 * 
 * We'll use the standard uniform basis fn here for performance, 
 * effectively t goes 0->1 between p1 and p2.
 */
function interpolateCatmullRom(p0, p1, p2, p3, t) {
    const t2 = t * t;
    const t3 = t2 * t;

    const f0 = -0.5 * t3 + t2 - 0.5 * t;
    const f1 = 1.5 * t3 - 2.5 * t2 + 1.0;
    const f2 = -1.5 * t3 + 2.0 * t2 + 0.5 * t;
    const f3 = 0.5 * t3 - 0.5 * t2;

    const yaw = p0.yaw * f0 + p1.yaw * f1 + p2.yaw * f2 + p3.yaw * f3;
    const pitch = p0.pitch * f0 + p1.pitch * f1 + p2.pitch * f2 + p3.pitch * f3;

    return { yaw, pitch };
}

function normalizeYaw(yaw) {
    let y = yaw % 360;
    if (y > 180) y -= 360;
    if (y < -180) y += 360;
    return y;
}
