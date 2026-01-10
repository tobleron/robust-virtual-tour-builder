/**
 * HotspotLineSystem
 * 
 * Manages the visualization of connecting lines between the viewer center
 * and hotspots.
 */
import { getIsSimulationMode, calculateSmartArrivalTarget, getAutoForwardChain, getPreviewingLink } from "./NavigationSystem.js";
import { getCatmullRomSpline } from "../utils/PathInterpolation.js";

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

                // DRAW MULTI-POINT PATH (Red Dashed)
                // Use Spline if waypoints exist
                if (h.waypoints && h.waypoints.length > 0) {
                    const controlPoints = [{ yaw: startYaw, pitch: startPitch }, ...h.waypoints, { yaw: endYaw, pitch: endPitch }];
                    const splinePath = getCatmullRomSpline(controlPoints, 60); // 60 segments for smooth curve

                    this.drawPolyLine(svg, viewer, splinePath, rect, "#ef4444", 3.0, 0.8, "4,4");

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
            // Draw spline from Start -> Waypoints -> Current Camera
            const camStart = { yaw: draft.camYaw, pitch: draft.camPitch };
            const currentCam = { yaw: viewer.getYaw(), pitch: viewer.getPitch() };

            // Build control points
            const camControlPoints = [camStart];
            if (draft.intermediatePoints) {
                draft.intermediatePoints.forEach(p => camControlPoints.push({ yaw: p.camYaw, pitch: p.camPitch }));
            }
            camControlPoints.push(currentCam);

            if (camControlPoints.length > 2) {
                const splinePath = getCatmullRomSpline(camControlPoints, 60);
                this.drawPolyLine(svg, viewer, splinePath, rect, "#ef4444", 3.0, 0.9, "5,5");
            } else {
                // Straight line fallback
                const startCoords = this.getScreenCoords(viewer, camStart.pitch, camStart.yaw, rect);
                const endCoords = this.getScreenCoords(viewer, currentCam.pitch, currentCam.yaw, rect);
                if (startCoords && endCoords) {
                    this.drawLine(svg, startCoords.x, startCoords.y, endCoords.x, endCoords.y, "#ef4444", 3.0, 0.9, "5,5"); // Fixed: removed opacity from color args
                }
            }


            // --- B. YELLOW DASHED LINES (FLOOR PATH / VISUAL INDICATOR) ---
            // Only visible during drafting to show where your clicks are
            const floorStart = { yaw: draft.yaw, pitch: draft.pitch };

            const floorControlPoints = [floorStart];
            if (draft.intermediatePoints) {
                draft.intermediatePoints.forEach(p => floorControlPoints.push({ yaw: p.yaw, pitch: p.pitch }));
            }

            // Add mouse position if valid
            if (mouseEvent) {
                const mouseCoords = viewer.mouseEventToCoords(mouseEvent);
                floorControlPoints.push({ yaw: mouseCoords[1], pitch: mouseCoords[0] });
            }

            if (floorControlPoints.length > 2) {
                // Floor path is also curved now for consistency
                const floorSpline = getCatmullRomSpline(floorControlPoints, 60);
                this.drawPolyLine(svg, viewer, floorSpline, rect, "#fbbf24", 3.0, 0.8, "3,3");
            } else if (floorControlPoints.length === 2) {
                const p1 = floorControlPoints[0];
                const p2 = floorControlPoints[1];
                const startCoords = this.getScreenCoords(viewer, p1.pitch, p1.yaw, rect);
                const endCoords = this.getScreenCoords(viewer, p2.pitch, p2.yaw, rect);
                if (startCoords && endCoords) {
                    this.drawLine(svg, startCoords.x, startCoords.y, endCoords.x, endCoords.y, "#fbbf24", 3.0, 0.8, "3,3");
                }
            }
        } else if (!getIsSimulationMode()) {
            // 3. DRAW PREVIEW ARROWS (Normal Mode Only)
            // Persistent green arrow at the START of the path, clickable for preview

            // Get currently previewing link to hide its static arrow
            const previewingLink = getPreviewingLink();

            currentScene.hotspots.forEach((h, i) => {
                // Skip drawing the static arrow if this hotspot is currently being previewed
                if (previewingLink && previewingLink.sceneIndex === state.activeIndex && previewingLink.hotspotIndex === i) {
                    return; // Don't draw static arrow - the animated one is running
                }

                // Only if we have camera path data
                if (h && h.startPitch !== undefined && h.startYaw !== undefined && h.viewFrame) {
                    let startPitch = h.startPitch;
                    let startYaw = h.startYaw;

                    // Determine rotation angle (Tangent at start)
                    let angle = 0;

                    // Use Waypoints or straight line to End for tangent
                    let nextPoint = null;
                    if (h.waypoints && h.waypoints.length > 0) {
                        nextPoint = h.waypoints[0];
                    } else {
                        nextPoint = { yaw: h.viewFrame.yaw, pitch: h.viewFrame.pitch };
                    }

                    if (nextPoint) {
                        const p1 = { pitch: startPitch, yaw: startYaw };

                        // FIX: Use spline interpolation for smooth tangent if possible, or just p1->p2
                        // To fix the "gap", we ensure we draw at the exact projected pixel of startPitch/startYaw
                        const s1 = this.getScreenCoords(viewer, p1.pitch, p1.yaw, rect);
                        const s2 = this.getScreenCoords(viewer, nextPoint.pitch, nextPoint.yaw, rect);

                        if (s1 && s2) {
                            angle = Math.atan2(s2.y - s1.y, s2.x - s1.x) * (180 / Math.PI);

                            // Draw the Arrow
                            const arrow = document.createElementNS("http://www.w3.org/2000/svg", "path");
                            // Shape: Same as sim arrow
                            // FIX ALIGNMENT: The 'd' path defines the shape relative to (0,0).
                            // M -10,-7 L 6,0 L -10,7 Z
                            // (0,0) is 6px behind the tip.
                            // If the red line starts at (0,0), the arrow centers on it.
                            // If we want the arrow TIP to be near the start of the defined curve? 
                            // No, usually the arrow body sits ON the path start.
                            // We will leave the shape, but ensure the red line starts properly.
                            arrow.setAttribute("d", "M -10,-7 L 6,0 L -10,7 Z");
                            arrow.setAttribute("fill", "#10b981"); // Green
                            arrow.setAttribute("stroke", "#000");
                            arrow.setAttribute("stroke-width", "1");
                            arrow.setAttribute("transform", `translate(${s1.x}, ${s1.y}) rotate(${angle})`);
                            arrow.setAttribute("class", "preview-arrow");
                            arrow.setAttribute("data-hs-index", i);
                            arrow.style.cursor = "pointer";
                            arrow.style.pointerEvents = "all"; // Enable clicking

                            // Hover effect
                            arrow.onmouseover = () => arrow.setAttribute("fill", "#34d399");
                            arrow.onmouseout = () => arrow.setAttribute("fill", "#10b981");

                            svg.appendChild(arrow);
                        }
                    }
                }
            });
        }
    }

    /**
     * Draw a single alternating arrow for simulation transitions
     * @param {Object} viewer - Pannellum viewer instance
     * @param {number} startPitch - Starting pitch
     * @param {number} startYaw - Starting yaw
     * @param {number} endPitch - Ending pitch
     * @param {number} endYaw - Ending yaw
     * @param {number} progress - Animation progress (0-1)
     * @param {number} opacity - Arrow opacity (0-1)
     * @param {Array} waypoints - Optional intermediate waypoints
     * @param {string|null} colorOverride - Optional color override (e.g., 'red' for preview blink)
     */
    static drawSimulationArrow(viewer, startPitch, startYaw, endPitch, endYaw, progress, opacity = 1.0, waypoints = [], colorOverride = null) {
        const svg = document.getElementById("viewer-hotspot-lines");
        if (!svg || !viewer) return;

        const rect = svg.getBoundingClientRect();

        // 1. GENERATE SPLINE PATH
        // If waypoints exist, we use the spline. If not, straight line (2 points acts as straight in Catmull-Rom usually if handled, or we just fallback)
        let path = [];
        if (waypoints && waypoints.length > 0) {
            const controlPoints = [{ yaw: startYaw, pitch: startPitch }, ...waypoints, { yaw: endYaw, pitch: endPitch }];
            path = getCatmullRomSpline(controlPoints, 100);
        } else {
            path = [{ pitch: startPitch, yaw: startYaw }, { pitch: endPitch, yaw: endYaw }];
        }

        // 2. CALCULATE SEGMENT DISTANCES from the dense path
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
        let pCurrentPitch, pCurrentYaw;
        let yawForRotation, pitchForRotation;

        // FIX: When progress is 1.0 (or greater), place arrow EXACTLY at endpoint
        if (progress >= 1.0) {
            pCurrentPitch = endPitch;
            pCurrentYaw = endYaw;

            // Use the last segment's direction for rotation at endpoint
            if (segments.length > 0) {
                // Search backwards for a stable segment for rotation
                let stableSeg = segments[segments.length - 1];
                for (let k = segments.length - 1; k >= 0; k--) {
                    if (segments[k].dist >= 0.5) {
                        stableSeg = segments[k];
                        break;
                    }
                }
                yawForRotation = stableSeg.yawDiff;
                pitchForRotation = stableSeg.pitchDiff;
            } else {
                yawForRotation = endYaw - startYaw;
                pitchForRotation = endPitch - startPitch;
            }
        } else {
            const targetDist = progress * totalDistance;
            pCurrentPitch = startPitch;
            pCurrentYaw = startYaw;

            yawForRotation = (segments.length > 0) ? segments[0].yawDiff : (endYaw - startYaw);
            pitchForRotation = (segments.length > 0) ? segments[0].pitchDiff : (endPitch - startPitch);

            if (totalDistance > 0 && segments.length > 0) {
                let covered = 0;

                for (let i = 0; i < segments.length; i++) {
                    const seg = segments[i];
                    // Check if this segment contains the target distance
                    if (targetDist <= covered + seg.dist) {
                        const segmentProgress = (seg.dist > 0) ? (targetDist - covered) / seg.dist : 0;
                        pCurrentPitch = seg.p1.pitch + seg.pitchDiff * segmentProgress;
                        pCurrentYaw = seg.p1.yaw + seg.yawDiff * segmentProgress;

                        // ROBUST ROTATION (Fix for end-of-path jitter)
                        // Search backwards for a segment with significant length to use as rotation vector
                        let stableSeg = seg;
                        let foundStable = false;

                        if (seg.dist < 0.5) { // Threshold: 0.5 degrees
                            // Look backwards first
                            for (let k = i; k >= 0; k--) {
                                if (segments[k].dist >= 0.5) {
                                    stableSeg = segments[k];
                                    foundStable = true;
                                    break;
                                }
                            }
                            // If no backward stable, look forward (start of path case)
                            if (!foundStable) {
                                for (let k = i + 1; k < segments.length; k++) {
                                    if (segments[k].dist >= 0.5) {
                                        stableSeg = segments[k];
                                        foundStable = true;
                                        break;
                                    }
                                }
                            }
                        }

                        yawForRotation = stableSeg.yawDiff;
                        pitchForRotation = stableSeg.pitchDiff;
                        break;
                    }
                    covered += seg.dist;

                    // Handle Overshoot (End of path)
                    if (i === segments.length - 1) {
                        pCurrentPitch = seg.p2.pitch;
                        pCurrentYaw = seg.p2.yaw;

                        // Same robust search for the very end
                        let stableSeg = seg;
                        // Look strictly backwards from end
                        for (let k = segments.length - 1; k >= 0; k--) {
                            if (segments[k].dist >= 0.5) {
                                stableSeg = segments[k];
                                break;
                            }
                        }
                        yawForRotation = stableSeg.yawDiff;
                        pitchForRotation = stableSeg.pitchDiff;
                    }
                }
            }
        }

        // 4. PROJECT TO SCREEN
        const start = this.getScreenCoords(viewer, pCurrentPitch, pCurrentYaw, rect);

        // For rotation: Calculate the direction the arrow should point
        let end;

        if (progress >= 1.0) {
            // AT ENDPOINT: Look backward along the path to determine arrow direction
            // This prevents the arrow from appearing to "recoil" at the end
            const lookBackRatio = 0.5; // Look back along the path
            const pLookBackPitch = pCurrentPitch - pitchForRotation * lookBackRatio;
            const pLookBackYaw = pCurrentYaw - yawForRotation * lookBackRatio;

            // Calculate angle from lookback point TO current position (forward direction)
            const backPoint = this.getScreenCoords(viewer, pLookBackPitch, pLookBackYaw, rect);

            if (backPoint && start) {
                // Use the vector FROM backPoint TO start for rotation
                end = start; // We'll calculate angle differently below
                const angle = Math.atan2(start.y - backPoint.y, start.x - backPoint.x) * (180 / Math.PI);

                // Move arrow forward by 10px so the tip reaches the endpoint
                const forwardOffset = 10;
                const angleRad = angle * Math.PI / 180;
                const x = start.x + forwardOffset * Math.cos(angleRad);
                const y = start.y + forwardOffset * Math.sin(angleRad);

                // Color selection: Use override if provided, otherwise alternating Yellow/Green
                let color;
                if (colorOverride) {
                    // Map color names to hex values
                    const colorMap = {
                        'red': '#ef4444',
                        'green': '#10b981',
                        'yellow': '#fbbf24'
                    };
                    color = colorMap[colorOverride] || colorOverride;
                } else {
                    // Alternating Color (Yellow/Green)
                    color = (Math.floor(Date.now() / 200) % 2 === 0) ? "#fbbf24" : "#10b981";
                }

                const arrow = document.createElementNS("http://www.w3.org/2000/svg", "path");
                arrow.setAttribute("d", "M -10,-7 L 6,0 L -10,7 Z");
                arrow.setAttribute("fill", color);
                arrow.setAttribute("stroke", "#000");
                arrow.setAttribute("stroke-width", "1");
                arrow.setAttribute("transform", `translate(${x}, ${y}) rotate(${angle})`);

                if (opacity < 1.0) {
                    arrow.setAttribute("opacity", opacity.toFixed(2));
                }

                svg.appendChild(arrow);
                return; // Early return for endpoint case
            }
        }

        // NORMAL CASE: Project a point slightly ahead for rotation
        const lookAheadRatio = 0.5; // Larger lookahead for smoother rotation on spline segments
        const pLookAheadPitch = pCurrentPitch + pitchForRotation * lookAheadRatio;
        const pLookAheadYaw = pCurrentYaw + yawForRotation * lookAheadRatio;

        end = this.getScreenCoords(viewer, pLookAheadPitch, pLookAheadYaw, rect);

        if (!start || !end) return;

        const x = start.x;
        const y = start.y;

        // Rotation angle
        const angle = Math.atan2(end.y - start.y, end.x - start.x) * (180 / Math.PI);

        // Color selection: Use override if provided, otherwise alternating Yellow/Green
        let color;
        if (colorOverride) {
            // Map color names to hex values
            const colorMap = {
                'red': '#ef4444',
                'green': '#10b981',
                'yellow': '#fbbf24'
            };
            color = colorMap[colorOverride] || colorOverride;
            console.log(`[HotspotLineSystem] Color override: ${colorOverride} -> ${color}, opacity: ${opacity}`);
        } else {
            // Alternating Color (Yellow/Green)
            color = (Math.floor(Date.now() / 200) % 2 === 0) ? "#fbbf24" : "#10b981";
        }

        const arrow = document.createElementNS("http://www.w3.org/2000/svg", "path");
        arrow.setAttribute("d", "M -10,-7 L 6,0 L -10,7 Z");
        arrow.setAttribute("fill", color);
        arrow.setAttribute("stroke", "#000");
        arrow.setAttribute("stroke-width", "1");
        arrow.setAttribute("transform", `translate(${x}, ${y}) rotate(${angle})`);

        if (opacity < 1.0) {
            arrow.setAttribute("opacity", opacity.toFixed(2));
        }

        svg.appendChild(arrow);
    }

    /**
     * Helper to draw a polyline from a path array
     */
    static drawPolyLine(svg, viewer, path, rect, color, width, opacity, dashArray) {
        if (!path || path.length < 2) return;

        // Convert all points to screen coords first
        // Optimization: We could use <polyline> but for wrapping/clipping individual lines might be safer
        // Actually since we check 'getScreenCoords' return for each point, segments are better.

        let prevPoint = path[0];

        for (let i = 1; i < path.length; i++) {
            const currPoint = path[i];
            const startCoords = this.getScreenCoords(viewer, prevPoint.pitch, prevPoint.yaw, rect);
            const endCoords = this.getScreenCoords(viewer, currPoint.pitch, currPoint.yaw, rect);

            // Only draw segment if BOTH points are visible (or handle clipping?)
            // Simple visibility check
            if (startCoords && endCoords) {
                // Optimization: Skip very short segments
                if (Math.abs(startCoords.x - endCoords.x) < 1 && Math.abs(startCoords.y - endCoords.y) < 1) {
                    prevPoint = currPoint;
                    continue;
                }
                this.drawLine(svg, startCoords.x, startCoords.y, endCoords.x, endCoords.y, color, width, opacity, dashArray);
            }

            prevPoint = currPoint;
        }
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

            // Check if behind camera
            if (Math.cos(yawRad) < 0) return null;

            // Bounds check (optional, but good)
            // if (Math.abs(x) > 2 || Math.abs(y) > 2) return null;

            return {
                x: (rect.width / 2) * (1 + x),
                y: (rect.height / 2) * (1 - y)
            };
        } catch (e) {
            return null;
        }
    }
}


