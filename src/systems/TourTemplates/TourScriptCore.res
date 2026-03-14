let script = `
    const waypointRuntime = { animationId: null, readyTimeoutId: null, autoForwardTimeoutId: null, postArrivalAnimationId: null, sceneId: null, arrivedSceneId: null };
    const DEFAULT_HFOV = __DEFAULT_HFOV__;
    const MIN_HFOV = __MIN_HFOV__;
    const MAX_HFOV = __MAX_HFOV__;
    const STAGE_MIN_WIDTH = __STAGE_MIN_WIDTH__;
    const STAGE_MAX_WIDTH = __STAGE_MAX_WIDTH__;
    const DYNAMIC_HFOV_ENABLED = __DYNAMIC_HFOV_ENABLED__;
    const IS_HD_EXPORT = __IS_HD_EXPORT__;
    const EXPORT_TRAVERSAL_MODE = "__EXPORT_TRAVERSAL_MODE__";
    // Set to "always" to force full manual exported-tour waypoint playback regardless of mode.
    const EXPORT_WAYPOINT_ANIMATION_POLICY = "auto-tour-only";
    const EXPORT_NAVIGATION_MODE_MANUAL = "manual";
    const EXPORT_NAVIGATION_MODE_SEMI_AUTO = "semi-auto";
    const EXPORT_NAVIGATION_MODE_AUTO = "auto";
    const EXPORT_DEFAULT_NAVIGATION_MODE = EXPORT_NAVIGATION_MODE_SEMI_AUTO;
    const IS_4K_EXPORT = STAGE_MAX_WIDTH >= 1000;
    const PAN_VELOCITY = 25.0;
    const PAN_MIN_DURATION = 1000.0;
    const PAN_MAX_DURATION = 20000.0;
    const ANIMATED_NAVIGATION_BASE_SPEED_MULTIPLIER = 1.44;
    const AUTO_TOUR_BASE_SPEED_MULTIPLIER = ANIMATED_NAVIGATION_BASE_SPEED_MULTIPLIER;
    const AUTO_TOUR_BOOSTED_SPEED_MULTIPLIER = 2.24;
    const AUTO_TOUR_FORWARD_DELAY_MS = 360;
    const AUTO_TOUR_MIN_ANIMATION_MS = 180.0;
    const AUTO_TOUR_MIN_FORWARD_DELAY_MS = 80;
    const MANUAL_POST_ARRIVAL_FOCUS_MS = 320.0;
    const PORTRAIT_MODE_SELECTOR_COLLAPSE_MS = 420;
    const TRAPEZOID_FACTOR = 0.12;
    const WAYPOINT_SMOOTHING_FACTOR = 0.3;
    const SPLINE_SEGMENTS = 100;

    function clearWaypointRuntime() {
      if (waypointRuntime.animationId !== null) cancelAnimationFrame(waypointRuntime.animationId);
      if (waypointRuntime.readyTimeoutId !== null) clearTimeout(waypointRuntime.readyTimeoutId);
      if (waypointRuntime.autoForwardTimeoutId !== null) clearTimeout(waypointRuntime.autoForwardTimeoutId);
      if (waypointRuntime.postArrivalAnimationId !== null) cancelAnimationFrame(waypointRuntime.postArrivalAnimationId);
      waypointRuntime.animationId = null; waypointRuntime.readyTimeoutId = null; waypointRuntime.autoForwardTimeoutId = null; waypointRuntime.postArrivalAnimationId = null; waypointRuntime.arrivedSceneId = null;
    }
    function normalizeYawDelta(fromYaw, toYaw) {
      let delta = toYaw - fromYaw;
      while (delta > 180) delta -= 360;
      while (delta < -180) delta += 360;
      return delta;
    }
    function normalizeYaw(yaw) {
      let y = yaw % 360;
      if (y > 180) y -= 360;
      if (y < -180) y += 360;
      return y;
    }
    function trapezoidal(t, factor) {
      const vmax = 1.0 / (1.0 - factor);
      if (t < factor) return 0.5 * (vmax / factor) * t * t;
      if (t > 1.0 - factor) return 1.0 - 0.5 * (vmax / factor) * (1.0 - t) * (1.0 - t);
      return vmax * (t - 0.5 * factor);
    }
    function toPoint(yaw, pitch) {
      return { yaw, pitch };
    }
    function interpolateBSpline(p0, p1, p2, p3, t) {
      const t2 = t * t;
      const t3 = t2 * t;
      const b0 = ((1.0 - t) * (1.0 - t) * (1.0 - t)) / 6.0;
      const b1 = (3.0 * t3 - 6.0 * t2 + 4.0) / 6.0;
      const b2 = (-3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0) / 6.0;
      const b3 = t3 / 6.0;
      return {
        yaw: p0.yaw * b0 + p1.yaw * b1 + p2.yaw * b2 + p3.yaw * b3,
        pitch: p0.pitch * b0 + p1.pitch * b1 + p2.pitch * b2 + p3.pitch * b3,
      };
    }
    function getBSplinePath(points, totalSegments) {
      if (!Array.isArray(points) || points.length < 2) return points || [];
      const first = points[0];
      const last = points[points.length - 1];
      let smoothed = points.slice();
      if (WAYPOINT_SMOOTHING_FACTOR > 0.0 && smoothed.length > 3) {
        const s = WAYPOINT_SMOOTHING_FACTOR * 0.5;
        for (let pass = 0; pass < 2; pass += 1) {
          for (let i = 1; i < smoothed.length - 1; i += 1) {
            const prev = smoothed[i - 1];
            const curr = smoothed[i];
            const next = smoothed[i + 1];
            const weighting = (i === 1 || i === smoothed.length - 2) ? s * 0.5 : s;
            let dy1 = next.yaw - curr.yaw;
            while (dy1 > 180) dy1 -= 360;
            while (dy1 < -180) dy1 += 360;
            let dy2 = prev.yaw - curr.yaw;
            while (dy2 > 180) dy2 -= 360;
            while (dy2 < -180) dy2 += 360;
            smoothed[i] = {
              yaw: curr.yaw + (dy1 + dy2) * weighting,
              pitch: curr.pitch + (next.pitch + prev.pitch - 2.0 * curr.pitch) * weighting,
            };
          }
        }
      }
      const rawPoints = [first, first, ...smoothed, last, last];
      const unrolled = [];
      let prevYaw = first.yaw;
      for (const p of rawPoints) {
        let diff = p.yaw - prevYaw;
        while (diff > 180) diff -= 360;
        while (diff < -180) diff += 360;
        const absYaw = prevYaw + diff;
        unrolled.push({ yaw: absYaw, pitch: p.pitch });
        prevYaw = absYaw;
      }
      const sections = unrolled.length - 3;
      if (sections < 1) return points;
      const segmentsPerSection = Math.ceil(totalSegments / sections);
      const spline = [];
      for (let i = 0; i < sections; i += 1) {
        const p0 = unrolled[i];
        const p1 = unrolled[i + 1];
        const p2 = unrolled[i + 2];
        const p3 = unrolled[i + 3];
        for (let j = 0; j < segmentsPerSection; j += 1) {
          const t = j / segmentsPerSection;
          spline.push(interpolateBSpline(p0, p1, p2, p3, t));
        }
      }
      spline.push({ yaw: last.yaw, pitch: last.pitch });
      return spline.map(p => ({ yaw: normalizeYaw(p.yaw), pitch: p.pitch }));
    }
    function getFloorProjectedPath(start, end, segments) {
      const toRad = deg => deg * Math.PI / 180.0;
      const toDeg = rad => rad * 180.0 / Math.PI;
      const project = p => {
        const yRad = toRad(p.yaw);
        const pRad = toRad(p.pitch);
        if (pRad >= -0.001) return null;
        const r = -1.0 / Math.tan(pRad);
        return { x: r * Math.sin(yRad), z: r * Math.cos(yRad) };
      };
      const unproject = (x, z) => {
        const r = Math.sqrt(x * x + z * z);
        return { yaw: toDeg(Math.atan2(x, z)), pitch: toDeg(Math.atan(-1.0 / r)) };
      };
      const p1 = project(start);
      const p2 = project(end);
      if (!p1 || !p2) return [start, end];
      const path = [];
      for (let i = 0; i <= segments; i += 1) {
        const t = i / segments;
        const x = p1.x + (p2.x - p1.x) * t;
        const z = p1.z + (p2.z - p1.z) * t;
        path.push(unproject(x, z));
      }
      return path;
    }
    function buildPath(primary, currentPitch, currentYaw) {
      const startYaw = Number.isFinite(primary.startYaw) ? primary.startYaw : currentYaw;
      const startPitch = Number.isFinite(primary.startPitch) ? primary.startPitch : currentPitch;
      const endYaw = Number.isFinite(primary?.viewFrame?.yaw)
        ? primary.viewFrame.yaw
        : (Number.isFinite(primary.targetYaw) ? primary.targetYaw : primary.yaw);
      const endPitch = Number.isFinite(primary?.viewFrame?.pitch)
        ? primary.viewFrame.pitch
        : (Number.isFinite(primary.targetPitch)
            ? primary.targetPitch
            : (Number.isFinite(primary.truePitch) ? primary.truePitch : primary.pitch));
      const waypoints = Array.isArray(primary.waypoints) ? primary.waypoints : [];
      const controls = [toPoint(startYaw, startPitch)];
      for (const w of waypoints) {
        if (w && Number.isFinite(w.yaw) && Number.isFinite(w.pitch)) {
          controls.push(toPoint(w.yaw, w.pitch));
        }
      }
      controls.push(toPoint(endYaw, endPitch));
      if (waypoints.length > 0) {
        return getBSplinePath(controls, SPLINE_SEGMENTS);
      }
      return getFloorProjectedPath(controls[0], controls[controls.length - 1], SPLINE_SEGMENTS);
    }
    function buildSegments(path) {
      const segments = [];
      let total = 0;
      for (let i = 0; i < path.length - 1; i += 1) {
        const a = path[i]; const b = path[i + 1];
        const dy = normalizeYawDelta(a.yaw, b.yaw);
        const dp = b.pitch - a.pitch;
        const dist = Math.max(0.0001, Math.sqrt(dy * dy + dp * dp));
        segments.push({ a, dy, dp, dist });
        total += dist;
      }
      return { segments, total };
    }
    function samplePath(segments, total, t) {
      const target = total * t;
      let traversed = 0;
      for (const seg of segments) {
        if (traversed + seg.dist >= target) {
          const local = (target - traversed) / seg.dist;
          return {
            yaw: seg.a.yaw + seg.dy * local,
            pitch: seg.a.pitch + seg.dp * local,
          };
        }
        traversed += seg.dist;
      }
      const last = segments[segments.length - 1];
      return {
        yaw: last.a.yaw + last.dy,
        pitch: last.a.pitch + last.dp,
      };
    }
`
