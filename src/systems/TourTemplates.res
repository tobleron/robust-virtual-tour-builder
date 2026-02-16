/* src/systems/TourTemplates.res - Consolidated Tour Templates System */

open Types
@scope("JSON") @val external stringify: 'a => string = "stringify"

// --- ASSETS ---

module Assets = {
  let indexTemplate = `<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>__TOUR_NAME__ - Virtual Tour Hub</title><link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet"><script src="https://unpkg.com/lucide@latest"></script><style>
:root { --primary: #003da5; --primary-dark: #002a70; --slate-900: #020617; --slate-800: #0f172a; --slate-700: #1e293b; --glass: rgba(255, 255, 255, 0.03); --glass-border: rgba(255, 255, 255, 0.08); --warning: #f59e0b; --info: #3b82f6; --success: #10b981; --slate-600: #475569; --slate-400: #94a3b8; --slate-200: #e2e8f0; }
* { box-sizing: border-box; }
body { margin: 0; padding: 0; font-family: 'Outfit', sans-serif; background: var(--slate-900); color: white; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; overflow-x: hidden; }
.background-blob { position: fixed; width: 800px; height: 800px; background: radial-gradient(circle, rgba(0, 61, 165, 0.1) 0%, rgba(0, 0, 0, 0) 70%); z-index: -1; filter: blur(80px); pointer-events: none; }
.blob-1 { top: -200px; left: -200px; }
.blob-2 { bottom: -200px; right: -200px; background: radial-gradient(circle, rgba(15, 23, 42, 0.3) 0%, rgba(0, 0, 0, 0) 70%); }
.container { width: 90%; max-width: 1000px; text-align: center; padding: 60px 0; animation: fadeIn 1s cubic-bezier(0.22, 1, 0.36, 1); }
@keyframes fadeIn { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
.logo-container { display: inline-flex; align-items: center; justify-content: center; background: white; padding: 4px; border-radius: 12px; margin-bottom: 32px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); max-width: 120px; max-height: 60px; overflow: hidden; }
.logo-container img { width: 100%; height: auto; display: block; object-fit: contain; }
h1 { font-size: 42px; font-weight: 600; margin: 0 0 16px 0; }
.version-badge { display: inline-flex; align-items: center; gap: 8px; background: var(--glass); padding: 6px 16px; border-radius: 100px; font-size: 13px; font-weight: 600; color: var(--slate-400); }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 32px; margin-top: 20px; }
.card { background: var(--slate-800); border: 1px solid var(--glass-border); border-radius: 24px; padding: 40px 30px; text-decoration: none; color: white; display: flex; flex-direction: column; align-items: center; gap: 20px; position: relative; overflow: hidden; transition: all 0.4s; }
.card:hover { transform: translateY(-12px); background: var(--slate-700); }
.icon { width: 48px; height: 48px; }
.card-4k .icon { color: var(--warning); } .card-2k .icon { color: var(--info); } .card-hd .icon { color: var(--success); }
.res-label { font-size: 26px; font-weight: 600; }
.description { font-size: 15px; color: var(--slate-400); line-height: 1.6; }
.btn { margin-top: 10px; background: rgba(255, 255, 255, 0.05); color: var(--slate-200); padding: 12px 32px; border-radius: 100px; font-size: 14px; font-weight: 600; }
.card:hover .btn { background: white; color: #0f172a; }
.footer { margin-top: 80px; font-size: 13px; color: var(--slate-600); }
</style></head><body><div class="background-blob blob-1"></div><div class="background-blob blob-2"></div><div class="container"><div class="header">
__LOGO_BLOCK__
<h1>__TOUR_NAME_PRETTY__</h1><div class="version-badge">Virtual Tour v__VERSION__</div></div><div class="grid">
<a href="tour_4k/index.html" class="card card-4k"><i data-lucide="sparkles" class="icon"></i><span class="res-label">4K Ultra HD</span><span class="description">Best for high-end displays.</span><span class="btn">Launch Tour</span></a>
<a href="tour_2k/index.html" class="card card-2k"><i data-lucide="monitor" class="icon"></i><span class="res-label">2K Desktop</span><span class="description">Optimized for laptops.</span><span class="btn">Launch Tour</span></a>
<a href="tour_hd/index.html" class="card card-hd"><i data-lucide="smartphone" class="icon"></i><span class="res-label">HD Mobile</span><span class="description">Portrait layout for phones.</span><span class="btn">Launch Tour</span></a>
</div><div class="footer">&copy; __YEAR__ Virtual Tour Platform.</div></div><script>lucide.createIcons();</script></body></html>`

  let generateExportIndex = (tourName, version, logoFilename: option<string>) => {
    let prettyName = String.replaceRegExp(tourName, /_/g, " ")
    let year = Date.make()->Date.getFullYear->Belt.Int.toString
    let logoBlock = switch logoFilename {
    | Some(filename) =>
      `<div class="logo-container"><img src="tour_4k/assets/${filename}" onerror="this.parentElement.style.display='none'"></div>`
    | None => ""
    }
    indexTemplate
    ->String.replaceRegExp(/__TOUR_NAME__/g, tourName)
    ->String.replaceRegExp(/__TOUR_NAME_PRETTY__/g, prettyName)
    ->String.replaceRegExp(/__VERSION__/g, version)
    ->String.replaceRegExp(/__YEAR__/g, year)
    ->String.replaceRegExp(/__LOGO_BLOCK__/g, logoBlock)
  }

  let generateEmbedCodes = (tourName, version) => {
    `VIRTUAL TOUR - EMBED CODES\nVersion: ${version}\nProperty: ${tourName}\n\n1. 4K (Desktop):\n   <iframe src="tour_4k/index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n\n2. 2K (Desktop):\n   <iframe src="tour_2k/index.html" width="100%" height="400" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n\n3. HD (Mobile):\n   <iframe src="tour_hd/index.html" width="375" height="667" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`
  }
}

// --- STYLES ---

module Styles = {
  let cssTemplate = `
    :root { --viewer-bg: #111; --stage-border: #333; --glow-color: #fff4d1; --font-family: 'Outfit', sans-serif; --gold-1: #ea580c; --gold-2: #f97316; --gold-3: #c2410c; --gold-text: #ffffff; --gold-border: #7c2d12; --arrow-white: rgba(255, 255, 255, 0.4); }
    body { margin: 0; padding: 0; width: 100%; min-height: 100vh; display: flex; align-items: center; justify-content: center; overflow: auto; background-color: var(--viewer-bg); font-family: var(--font-family); }
    body::before { content: ""; position: fixed; top: -20px; left: -20px; right: -20px; bottom: -20px; background: url('assets/images/__FIRST_SCENE_NAME__') no-repeat center center fixed; background-size: cover; filter: blur(25px) brightness(0.4); z-index: -1; }
    __MEDIA_QUERY_CSS__
    #panorama { width: 100%; height: 100%; border-radius: inherit; }
    .pnlm-controls-container, .pnlm-zoom-controls, .pnlm-fullscreen-toggle-button, .pnlm-zoom-in, .pnlm-zoom-out, .pnlm-controls { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }
    .watermark { position: absolute; bottom: 25px; right: 25px; z-index: 10; pointer-events: none; background: rgba(255, 255, 255, 0.1); backdrop-filter: blur(5px); -webkit-backdrop-filter: blur(5px); padding: 3px; border-radius: 8px; border: 1px solid rgba(249, 115, 22, 1); display: flex; align-items: center; justify-content: center; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
    .watermark img { height: __LOGO_SIZE__px; width: auto; display: block; object-fit: contain; border-radius: 5px; }
    #viewer-floor-nav-export { position: absolute; bottom: 24px; left: 20px; z-index: 5002; display: flex; flex-direction: column-reverse; gap: 8px; align-items: center; pointer-events: none; }
    #viewer-floor-nav-export .floor-nav-btn { width: 32px; height: 32px; min-width: 32px; min-height: 32px; border-radius: 9999px; font-size: 15px; font-weight: 500; line-height: 1; display: inline-flex; align-items: center; justify-content: center; transition: all 0.2s ease; box-sizing: border-box; user-select: none; }
    #viewer-floor-nav-export .floor-nav-btn.state-active { border: 2px solid #ea580c; background: #ea580c; color: #fff; }
    #viewer-floor-nav-export .floor-nav-btn.state-idle { border: 1px solid rgba(255, 255, 255, 0.2); background: rgba(14, 45, 82, 0.8); color: #fff; }
    #viewer-floor-nav-export .floor-nav-btn sup { font-size: 10px; margin-left: -1px; }
    .viewer-persistent-label-export { position: absolute; top: 24px; left: 50%; transform: translateX(-50%); z-index: 6005; background-color: rgba(0, 61, 165, 0.85); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); color: #fff; padding: 0 0.5rem; height: 27px; border-radius: 6px; font-family: var(--font-family); font-size: 11px; font-weight: 600; text-transform: uppercase; box-shadow: 0 10px 25px rgba(0, 0, 0, 0.35); display: flex; align-items: center; justify-content: center; transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1); pointer-events: none; border: 1px solid rgba(255, 255, 255, 0.1); letter-spacing: 0.1em; white-space: nowrap; }
    .viewer-persistent-label-export.state-visible { opacity: 1; transform: translateX(-50%) translateY(0) scale(1); visibility: visible; }
    .viewer-persistent-label-export.state-hidden { opacity: 0; transform: translateX(-50%) translateY(-1rem) scale(0.9); visibility: hidden; pointer-events: none; }
    @keyframes glow-sequence { 0%, 100% { fill-opacity: 0; filter: brightness(1); } 10%, 30% { fill-opacity: 0.8; filter: brightness(1.5); } 40% { fill-opacity: 0; filter: brightness(1); } }
    @keyframes diagonal-sweep { 0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); } 20%, 100% { transform: translateX(100%) translateY(100%) rotate(45deg); } }
    .pnlm-hotspot.flat-arrow { display: block !important; background: rgba(255, 255, 255, 0.01) !important; border: 1px solid transparent !important; padding: 0 !important; pointer-events: auto !important; width: __BASE_SIZE__px !important; height: __BASE_SIZE__px !important; margin-left: -__BASE_SIZE_HALF__px !important; margin-top: -__BASE_SIZE_HALF__px !important; overflow: visible !important; cursor: pointer; z-index: 2000 !important; }
    .pnlm-hotspot.flat-arrow.waypoint-pending { opacity: 0 !important; pointer-events: auto !important; cursor: pointer !important; transform: scale(0.82); }
    .pnlm-hotspot.flat-arrow.waypoint-ready { opacity: 1 !important; pointer-events: auto !important; transform: scale(1); transition: opacity 0.24s ease, transform 0.24s ease; }
    .custom-arrow-svg { width: 100% !important; height: 100% !important; display: block; pointer-events: none; transform: none; transform-origin: center center; transition: transform 0.2s ease; filter: drop-shadow(0 8px 4px rgba(0,0,0,0.35)); }
    .export-hotspot-root { position: relative; width: 32px; height: 32px; }
    .export-hotspot-btn { position: absolute; inset: 0; background: #ea580c; border-radius: 6px; box-shadow: 0 10px 16px rgba(0,0,0,0.35); display: flex; align-items: center; justify-content: center; overflow: hidden; transition: background-color 0.2s ease, transform 0.2s ease, filter 0.2s ease; pointer-events: auto; cursor: pointer; }
    .export-hotspot-btn:hover { background: #f97316; transform: scale(1.03); filter: brightness(1.04); }
    .export-hotspot-btn-sweep { position: absolute; inset: 0; background: linear-gradient(to bottom, transparent, rgba(255,255,255,0.25), transparent); pointer-events: none; transform: scale(2); animation: diagonal-sweep var(--sweep-duration, 4s) ease-in-out infinite; }
    .export-hotspot-root.auto-forward .export-hotspot-btn-sweep { --sweep-duration: 1.5s; }
    .export-hotspot-icon { position: relative; z-index: 2; width: 20px; height: 20px; overflow: visible; }
    .export-hotspot-icon path { stroke: white; stroke-width: 3.5; fill: none; stroke-linecap: round; stroke-linejoin: round; }
    .glow-unit { fill-opacity: 0; fill: var(--glow-color); }
    .glow-bottom { animation: glow-sequence 1.8s infinite; }
    .glow-top { animation: glow-sequence 1.8s infinite; animation-delay: 0.4s; }
    .pnlm-hotspot.flat-arrow:hover .custom-arrow-svg { animation: none; transform: scale(1.08); filter: drop-shadow(0 10px 10px rgba(0,0,0,0.35)); }
    .pnlm-load-box, .pnlm-lbox, .pnlm-lmsg, .pnlm-lbar, .pnlm-ltext, .pnlm-loading-container, [class^="pnlm-l"], [class*="loading"] { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }
    .pnlm-hotspot.flat-arrow[data-target-home] { perspective: none !important; transform-style: flat !important; }
    .pnlm-hotspot.flat-arrow[data-target-home] .custom-arrow-svg { transform: none !important; animation: home-pulse 2s infinite ease-in-out !important; }
    @keyframes home-pulse { 0% { transform: scale(1); } 50% { transform: scale(1.1); } 100% { transform: scale(1); } }
  `

  let generateCSS = (firstSceneName, isMobile, exportType, baseSize, logoSize) => {
    let mediaQuery = if isMobile {
      ` #stage { position: relative; width: 375px; height: 667px; background: #000; border-radius: 20px; border: 4px solid var(--stage-border); box-shadow: 0 0 50px rgba(0,0,0,0.6); overflow: hidden; } `
    } else {
      let maxWidth = exportType == "4k" ? "1024px" : "640px"
      let mediaWidth = exportType == "4k" ? "1100px" : "700px"
      ` #stage { position: relative; margin: 0 auto; width: 100%; max-width: ${maxWidth}; height: auto; aspect-ratio: 16/10; max-height: 90vh; background: #000; border-radius: 8px; box-shadow: 0 0 50px rgba(0,0,0,0.6); overflow: hidden; } @media (max-width: ${mediaWidth}) { #stage { max-width: 95vw; } } `
    }
    cssTemplate
    ->String.replaceRegExp(/__FIRST_SCENE_NAME__/g, firstSceneName)
    ->String.replaceRegExp(/__MEDIA_QUERY_CSS__/g, mediaQuery)
    ->String.replaceRegExp(/__LOGO_SIZE__/g, Belt.Int.toString(logoSize))
    ->String.replaceRegExp(/__BASE_SIZE__/g, Belt.Int.toString(baseSize))
    ->String.replaceRegExp(
      /__BASE_SIZE_HALF__/g,
      Belt.Float.toString(Belt.Int.toFloat(baseSize) /. 2.0),
    )
  }
}

// --- SCRIPTS ---

module Scripts = {
  let renderScriptTemplate = `
    const waypointRuntime = { animationId: null, readyTimeoutId: null, autoForwardTimeoutId: null, sceneId: null, arrivedSceneId: null };
    const EXPORT_FLOOR_LEVELS = [
      { id: "b2", label: "Basement 2", short: "B", suffix: "-2" },
      { id: "b1", label: "Basement 1", short: "B", suffix: "-1" },
      { id: "ground", label: "Ground Floor", short: "G", suffix: "" },
      { id: "first", label: "First Floor", short: "+1", suffix: "" },
      { id: "second", label: "Second Floor", short: "+2", suffix: "" },
      { id: "third", label: "Third Floor", short: "+3", suffix: "" },
      { id: "fourth", label: "Fourth Floor", short: "+4", suffix: "" },
      { id: "roof", label: "Roof Top", short: "R", suffix: "" }
    ];
    const PAN_VELOCITY = 25.0;
    const PAN_MIN_DURATION = 1000.0;
    const PAN_MAX_DURATION = 20000.0;
    const TRAPEZOID_FACTOR = 0.12;
    const WAYPOINT_SMOOTHING_FACTOR = 0.3;
    const SPLINE_SEGMENTS = 100;
    function clearWaypointRuntime() {
      if (waypointRuntime.animationId !== null) cancelAnimationFrame(waypointRuntime.animationId);
      if (waypointRuntime.readyTimeoutId !== null) clearTimeout(waypointRuntime.readyTimeoutId);
      if (waypointRuntime.autoForwardTimeoutId !== null) clearTimeout(waypointRuntime.autoForwardTimeoutId);
      waypointRuntime.animationId = null; waypointRuntime.readyTimeoutId = null; waypointRuntime.autoForwardTimeoutId = null; waypointRuntime.arrivedSceneId = null;
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
    function getSceneHotspots(sceneId) {
      return Array.from(document.querySelectorAll('.pnlm-hotspot.flat-arrow')).filter(el => el.dataset.ownerScene === sceneId);
    }
    function setSceneHotspotsPending(sceneId) {
      getSceneHotspots(sceneId).forEach(el => {
        el.classList.remove('waypoint-ready');
        el.classList.add('waypoint-pending');
        el.dataset.ready = 'false';
      });
    }
    function setSceneHotspotsReady(sceneId) {
      getSceneHotspots(sceneId).forEach(el => {
        el.classList.remove('waypoint-pending');
        el.classList.add('waypoint-ready');
        el.dataset.ready = 'true';
      });
    }
    function resolveDestinationView(args) {
      let y = 90, p = 0;
      if (args.isReturnLink && args.returnViewFrame) { y = args.returnViewFrame.yaw ?? 90; p = args.returnViewFrame.pitch ?? 0; }
      else { if (args.targetYaw !== undefined && args.targetYaw !== null) { y = args.targetYaw; p = args.targetPitch ?? 0; } else if (args.viewFrame) { y = args.viewFrame.yaw ?? 90; p = args.viewFrame.pitch ?? 0; } }
      return { yaw: y, pitch: p };
    }
    function normalizeSceneId(candidate) {
      if (typeof candidate !== "string") return null;
      let value = candidate.trim();
      if (!value) return null;
      try { value = decodeURIComponent(value); } catch (_) {}
      value = value.replaceAll("\\\\", "/");
      if (value.startsWith("./")) value = value.slice(2);
      if (value.startsWith("/")) value = value.slice(1);
      if (value.startsWith("assets/images/")) value = value.slice("assets/images/".length);
      value = value.trim();
      return value.length > 0 ? value : null;
    }
    function stripSceneExtension(sceneId) {
      const lower = sceneId.toLowerCase();
      const exts = [".jpeg", ".jpg", ".png", ".webp", ".avif"];
      for (const ext of exts) {
        if (lower.endsWith(ext)) return sceneId.slice(0, sceneId.length - ext.length);
      }
      return sceneId;
    }
    function getExportSceneIds() {
      if (scenesData && typeof scenesData === "object") {
        const sceneIds = Object.keys(scenesData);
        if (sceneIds.length > 0) return sceneIds;
      }
      if (config && config.scenes && typeof config.scenes === "object") {
        return Object.keys(config.scenes);
      }
      return [];
    }
    function resolveExistingSceneId(candidate) {
      const normalized = normalizeSceneId(candidate);
      if (!normalized) return null;
      const sceneIds = getExportSceneIds();
      if (sceneIds.length === 0) return normalized;
      if (sceneIds.includes(normalized)) return normalized;
      const normalizedNoExt = stripSceneExtension(normalized).toLowerCase();
      for (const sceneId of sceneIds) {
        if (sceneId.toLowerCase() === normalized.toLowerCase()) return sceneId;
      }
      for (const sceneId of sceneIds) {
        if (stripSceneExtension(sceneId).toLowerCase() === normalizedNoExt) return sceneId;
      }
      const normalizedBase = normalized.split("/").pop();
      const normalizedBaseNoExt = stripSceneExtension(normalizedBase ?? normalized).toLowerCase();
      if (normalizedBase && normalizedBase !== normalized) {
        for (const sceneId of sceneIds) {
          if (sceneId.toLowerCase() === normalizedBase.toLowerCase()) return sceneId;
          if (stripSceneExtension(sceneId).toLowerCase() === stripSceneExtension(normalizedBase).toLowerCase()) return sceneId;
        }
      }
      for (const sceneId of sceneIds) {
        const sceneNameRaw = scenesData?.[sceneId]?.name;
        const sceneName = normalizeSceneId(typeof sceneNameRaw === "string" ? sceneNameRaw : "");
        if (!sceneName) continue;
        const sceneNameNoExt = stripSceneExtension(sceneName).toLowerCase();
        const sceneNameBase = sceneName.split("/").pop() ?? sceneName;
        const sceneNameBaseNoExt = stripSceneExtension(sceneNameBase).toLowerCase();
        if (sceneName === normalized) return sceneId;
        if (sceneName.toLowerCase() === normalized.toLowerCase()) return sceneId;
        if (sceneNameNoExt === normalizedNoExt) return sceneId;
        if (sceneNameBase.toLowerCase() === (normalizedBase ?? normalized).toLowerCase()) return sceneId;
        if (sceneNameBaseNoExt === normalizedBaseNoExt) return sceneId;
      }
      return null;
    }
    function hasExportScene(sceneId) {
      return resolveExistingSceneId(sceneId) !== null;
    }
    function resolveTargetSceneId(args, forceTargetSceneId) {
      const ownerSceneId = resolveExistingSceneId(args?.sourceSceneId) ?? normalizeSceneId(args?.sourceSceneId);
      const hotspotIndex = Number.isInteger(args?.i) ? args.i : null;
      const ownerHotspot = ownerSceneId !== null && hotspotIndex !== null && hotspotIndex >= 0
        ? scenesData?.[ownerSceneId]?.hotSpots?.[hotspotIndex]
        : null;
      const ownerTarget = ownerSceneId !== null && hotspotIndex !== null && hotspotIndex >= 0
        ? ownerHotspot?.targetSceneId ?? ownerHotspot?.target
        : null;
      const candidates = [
        forceTargetSceneId,
        ownerTarget,
        args?.targetSceneId,
        args?.target,
        args?.targetName,
        args?.targetId
      ];
      for (const candidate of candidates) {
        const resolved = resolveExistingSceneId(candidate);
        if (resolved) return resolved;
      }
      return null;
    }
    function navigateToNextScene(args, forceTargetSceneId) {
      const destination = resolveDestinationView(args);
      const targetSceneId = resolveTargetSceneId(args, forceTargetSceneId);
      if (!targetSceneId) return;
      transitionFrom = window.viewer.getScene(); persistentFrom = transitionFrom;
      setTimeout(() => {
        const verifiedTarget = resolveExistingSceneId(targetSceneId);
        if (!verifiedTarget) return;
        const targetConfig = config?.scenes?.[verifiedTarget];
        if (!targetConfig || typeof targetConfig.panorama !== "string" || targetConfig.panorama.trim() === "") return;
        window.viewer.loadScene(verifiedTarget, destination.pitch, destination.yaw, 90);
      }, 450);
    }
    function setSceneHotspotsReadyWithRetry(sceneId, retries) {
      const hotspots = getSceneHotspots(sceneId);
      hotspots.forEach(el => {
        el.classList.remove('waypoint-pending');
        el.classList.add('waypoint-ready');
        el.dataset.ready = 'true';
      });
      if (window.viewer.getScene() !== sceneId) return;
      const needsRetry = hotspots.length === 0 || hotspots.some(el => el.dataset.ready !== 'true');
      if (!needsRetry || retries <= 0) return;
      waypointRuntime.readyTimeoutId = setTimeout(() => setSceneHotspotsReadyWithRetry(sceneId, retries - 1), 80);
    }
    function normalizeSceneFloor(sceneData) {
      const floor = typeof sceneData?.floor === "string" ? sceneData.floor.trim() : "";
      return floor === "" ? "ground" : floor;
    }
    function updateExportFloorNav(sceneId) {
      const nav = document.getElementById("viewer-floor-nav-export");
      if (!nav) return;
      const sceneData = scenesData[sceneId];
      const currentFloor = normalizeSceneFloor(sceneData);
      while (nav.firstChild) nav.removeChild(nav.firstChild);
      for (const level of EXPORT_FLOOR_LEVELS) {
        const btn = document.createElement("div");
        btn.className = "floor-nav-btn " + (level.id === currentFloor ? "state-active" : "state-idle");
        btn.setAttribute("title", level.label);
        btn.setAttribute("aria-label", level.label);
        btn.textContent = level.short;
        if (level.suffix) {
          const suffix = document.createElement("sup");
          suffix.textContent = level.suffix;
          btn.appendChild(suffix);
        }
        nav.appendChild(btn);
      }
    }
    function updateExportRoomLabel(sceneId) {
      const labelEl = document.getElementById("viewer-room-label-export");
      if (!labelEl) return;
      const rawLabel = typeof scenesData[sceneId]?.label === "string" ? scenesData[sceneId].label.trim() : "";
      if (rawLabel !== "") {
        labelEl.textContent = "# " + rawLabel;
        labelEl.classList.remove("state-hidden");
        labelEl.classList.add("state-visible");
        return;
      }
      labelEl.textContent = "";
      labelEl.classList.remove("state-visible");
      labelEl.classList.add("state-hidden");
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
      const endYaw = primary.yaw;
      const endPitch = Number.isFinite(primary.truePitch) ? primary.truePitch : primary.pitch;
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
    function animateSceneToPrimaryHotspot(sceneId, retries) {
      if (window.viewer.getScene() !== sceneId) return;
      const sd = scenesData[sceneId];
      if (!sd?.hotSpots?.length) return;
      const primary = sd.hotSpots[0];
      waypointRuntime.arrivedSceneId = null;
      setSceneHotspotsPending(sceneId);
      let durationMs = PAN_MIN_DURATION;
      const startPitch = typeof window.viewer.getPitch === 'function' ? window.viewer.getPitch() : 0;
      const startYaw = typeof window.viewer.getYaw === 'function' ? window.viewer.getYaw() : 0;
      const path = buildPath(primary, startPitch, startYaw);
      const pathInfo = buildSegments(path);
      if (!pathInfo.segments.length || pathInfo.total <= 0) {
        setSceneHotspotsReadyWithRetry(sceneId, retries);
        return;
      }
      durationMs = Math.min(Math.max((pathInfo.total / PAN_VELOCITY) * 1000.0, PAN_MIN_DURATION), PAN_MAX_DURATION);
      window.viewer.lookAt(path[0].pitch, path[0].yaw, 90, false);
      const startAt = performance.now();
      const tick = now => {
        if (window.viewer.getScene() !== sceneId) return;
        const linear = Math.min(1, (now - startAt) / durationMs);
        const progress = trapezoidal(linear, TRAPEZOID_FACTOR);
        const current = samplePath(pathInfo.segments, pathInfo.total, progress);
        window.viewer.lookAt(current.pitch, current.yaw, 90, false);
        if (linear < 1) {
          waypointRuntime.animationId = requestAnimationFrame(tick);
          return;
        }
        waypointRuntime.animationId = null;
        waypointRuntime.arrivedSceneId = sceneId;
        setSceneHotspotsReadyWithRetry(sceneId, retries);
        const autoForward = primary.targetIsAutoForward === true;
        if (autoForward) {
          waypointRuntime.autoForwardTimeoutId = setTimeout(() => {
            if (window.viewer.getScene() !== sceneId) return;
            const hotspotsNow = getSceneHotspots(sceneId);
            const primaryEl = hotspotsNow.find(el => el.dataset.hotspotIndex === '0') ?? hotspotsNow[0];
            if (primaryEl && typeof primaryEl.__navigateNext === 'function') primaryEl.__navigateNext();
            else navigateToNextScene(primary, null);
          }, 360);
        }
      };
      waypointRuntime.animationId = requestAnimationFrame(tick);
    }
    function renderOrangeHotspot(hotSpotDiv, args) {
      const currentSceneId = window.viewer.getScene();
      const currentSceneData = scenesData[currentSceneId];
      const isHome = currentSceneData && currentSceneData.hotSpots.length === 1 && persistentFrom && args.targetSceneId === persistentFrom;
      const ownerScene = args.sourceSceneId ?? currentSceneId;
      hotSpotDiv.style.width = "__BASE_SIZE__px"; hotSpotDiv.style.height = "__BASE_SIZE__px";
      hotSpotDiv.style.pointerEvents = "auto";
      hotSpotDiv.style.cursor = "pointer";
      hotSpotDiv.dataset.ownerScene = ownerScene;
      hotSpotDiv.dataset.targetSceneId = resolveTargetSceneId(args, null) ?? "";
      hotSpotDiv.dataset.hotspotIndex = String(args.i ?? 0);
      hotSpotDiv.dataset.ready = "false";
      hotSpotDiv.classList.remove("waypoint-ready");
      hotSpotDiv.classList.add("waypoint-pending");
      if (waypointRuntime.arrivedSceneId === ownerScene) {
        hotSpotDiv.dataset.ready = "true";
        hotSpotDiv.classList.remove("waypoint-pending");
        hotSpotDiv.classList.add("waypoint-ready");
      }
      const ns = "http://www.w3.org/2000/svg";
      const bindNavigateHandlers = function(trigger, root) {
        if (!trigger) return;
        trigger.style.pointerEvents = "auto";
        trigger.style.cursor = "pointer";
        if (trigger.__exportNavClickHandler) {
          trigger.removeEventListener("click", trigger.__exportNavClickHandler);
        }
        if (trigger.__exportNavPointerUpHandler) {
          trigger.removeEventListener("pointerup", trigger.__exportNavPointerUpHandler);
        }
        const handleNavigate = function(e) {
          if (e && typeof e.stopPropagation === "function") e.stopPropagation();
          if (e && typeof e.preventDefault === "function") e.preventDefault();
          if (typeof root.__navigateNext !== "function") return;
          if (root.__navInFlight === true) return;
          root.__navInFlight = true;
          setTimeout(function() { root.__navInFlight = false; }, 700);
          root.__navigateNext();
        };
        trigger.__exportNavClickHandler = handleNavigate;
        trigger.__exportNavPointerUpHandler = handleNavigate;
        trigger.addEventListener("click", trigger.__exportNavClickHandler);
        trigger.addEventListener("pointerup", trigger.__exportNavPointerUpHandler);
      };
      const svg = document.createElementNS(ns, "svg");
      svg.setAttribute("class", "custom-arrow-svg"); svg.setAttribute("viewBox", "0 0 100 100"); svg.style.overflow = "visible";
      
      if (isHome) {
        hotSpotDiv.setAttribute('data-target-home', 'true');
        const defs = document.createElementNS(ns, "defs");
        const grad = document.createElementNS(ns, "linearGradient");
        grad.setAttribute("id", "homeGradExport_" + args.i); grad.setAttribute("x1", "0%"); grad.setAttribute("y1", "0%"); grad.setAttribute("x2", "0%"); grad.setAttribute("y2", "100%");
        [{o:"0%",c:"var(--gold-1)"},{o:"50%",c:"var(--gold-2)"},{o:"100%",c:"var(--gold-3)"}].forEach(s=>{ const stop=document.createElementNS(ns,"stop"); stop.setAttribute("offset",s.o); stop.style.stopColor=s.c; grad.appendChild(stop); });
        defs.appendChild(grad); svg.appendChild(defs);
        const rect = document.createElementNS(ns, "rect"); rect.setAttribute("x", "5"); rect.setAttribute("y", "5"); rect.setAttribute("width", "90"); rect.setAttribute("height", "90"); rect.setAttribute("rx", "12"); rect.setAttribute("fill", "url(#homeGradExport_" + args.i + ")"); svg.appendChild(rect);
        const text = document.createElementNS(ns, "text"); text.setAttribute("x", "50"); text.setAttribute("y", "52"); text.setAttribute("text-anchor", "middle"); text.setAttribute("dominant-baseline", "middle"); text.style.fontFamily = "Outfit, sans-serif"; text.style.fontWeight = "700"; text.style.fontSize = "22px"; text.setAttribute("fill", "var(--gold-text)"); text.textContent = "HOME"; svg.appendChild(text);
      } else {
        const root = document.createElement("div");
        root.className = "export-hotspot-root" + (args.targetIsAutoForward ? " auto-forward" : "");
        const btn = document.createElement("div");
        btn.className = "export-hotspot-btn";
        const sweep = document.createElement("div");
        sweep.className = "export-hotspot-btn-sweep";
        const icon = document.createElementNS(ns, "svg");
        icon.setAttribute("class", "export-hotspot-icon");
        icon.setAttribute("viewBox", "0 0 24 24");
        if (args.targetIsAutoForward) {
          const p1 = document.createElementNS(ns, "path"); p1.setAttribute("d", "M6 15 L12 9 L18 15"); icon.appendChild(p1);
          const p2 = document.createElementNS(ns, "path"); p2.setAttribute("d", "M6 10 L12 4 L18 10"); icon.appendChild(p2);
        } else {
          const p = document.createElementNS(ns, "path"); p.setAttribute("d", "M6 14 L12 8 L18 14"); icon.appendChild(p);
        }
        btn.appendChild(sweep);
        btn.appendChild(icon);
        root.appendChild(btn);
        while (hotSpotDiv.firstChild) hotSpotDiv.removeChild(hotSpotDiv.firstChild);
        hotSpotDiv.appendChild(root);
        hotSpotDiv.__navInFlight = false;
        hotSpotDiv.__navigateNext = function() { navigateToNextScene(args, null); };
        bindNavigateHandlers(hotSpotDiv, hotSpotDiv);
        bindNavigateHandlers(root, hotSpotDiv);
        bindNavigateHandlers(btn, hotSpotDiv);
        return;
      }
      while (hotSpotDiv.firstChild) hotSpotDiv.removeChild(hotSpotDiv.firstChild);
      hotSpotDiv.appendChild(svg);
      hotSpotDiv.__navInFlight = false;
      hotSpotDiv.__navigateNext = function() { navigateToNextScene(args, hotSpotDiv.getAttribute('data-target-home') === 'true' ? firstSceneId : null); };
      bindNavigateHandlers(hotSpotDiv, hotSpotDiv);
      bindNavigateHandlers(svg, hotSpotDiv);
    }
  `

  let loadEventScript = `
    window.viewer.on('load', function() {
      const sid = window.viewer.getScene(); const sd = scenesData[sid];
      if (!transitionFrom && !isFirstLoad) return;
      if (sd?.hotSpots?.length > 0) window.viewer.setHfov(90);
      persistentFrom = transitionFrom; transitionFrom = null; isFirstLoad = false;
      updateExportFloorNav(sid);
      updateExportRoomLabel(sid);
      clearWaypointRuntime();
      waypointRuntime.sceneId = sid;
      animateSceneToPrimaryHotspot(sid, 20);
    });
  `

  let generateRenderScript = baseSize =>
    renderScriptTemplate->String.replaceRegExp(/__BASE_SIZE__/g, Belt.Int.toString(baseSize))
}

// --- MAIN ---

external castToJSON: dict<'a> => JSON.t = "%identity"
external castToUnknown: 'a => unknown = "%identity"

type hotspotData = {
  "pitch": float,
  "yaw": float,
  "target": string,
  "targetSceneId": string,
  "targetIsAutoForward": bool,
  "startYaw": Nullable.t<float>,
  "startPitch": Nullable.t<float>,
  "waypoints": Nullable.t<array<viewFrame>>,
  "truePitch": float,
  "viewFrame": Nullable.t<viewFrame>,
  "returnViewFrame": Nullable.t<viewFrame>,
  "isReturnLink": bool,
  "targetYaw": Nullable.t<float>,
  "targetPitch": Nullable.t<float>,
}

type sceneData = {
  "name": string,
  "panorama": string,
  "autoLoad": bool,
  "floor": string,
  "category": string,
  "label": string,
  "isAutoForward": bool,
  "hotSpots": array<hotspotData>,
}

let encodeHotspot = (h: hotspotData) => {
  JsonCombinators.Json.Encode.object([
    ("pitch", JsonCombinators.Json.Encode.float(h["pitch"])),
    ("yaw", JsonCombinators.Json.Encode.float(h["yaw"])),
    ("target", JsonCombinators.Json.Encode.string(h["target"])),
    ("targetSceneId", JsonCombinators.Json.Encode.string(h["targetSceneId"])),
    ("targetIsAutoForward", JsonCombinators.Json.Encode.bool(h["targetIsAutoForward"])),
    (
      "startYaw",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["startYaw"]),
      ),
    ),
    (
      "startPitch",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["startPitch"]),
      ),
    ),
    (
      "waypoints",
      JsonCombinators.Json.Encode.option(
        JsonCombinators.Json.Encode.array(JsonParsers.Encoders.viewFrame),
      )(Nullable.toOption(h["waypoints"])),
    ),
    ("truePitch", JsonCombinators.Json.Encode.float(h["truePitch"])),
    (
      "viewFrame",
      JsonCombinators.Json.Encode.option(JsonParsers.Encoders.viewFrame)(
        Nullable.toOption(h["viewFrame"]),
      ),
    ),
    (
      "returnViewFrame",
      JsonCombinators.Json.Encode.option(JsonParsers.Encoders.viewFrame)(
        Nullable.toOption(h["returnViewFrame"]),
      ),
    ),
    ("isReturnLink", JsonCombinators.Json.Encode.bool(h["isReturnLink"])),
    (
      "targetYaw",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["targetYaw"]),
      ),
    ),
    (
      "targetPitch",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["targetPitch"]),
      ),
    ),
  ])
}

let encodeSceneData = (s: sceneData) => {
  JsonCombinators.Json.Encode.object([
    ("name", JsonCombinators.Json.Encode.string(s["name"])),
    ("panorama", JsonCombinators.Json.Encode.string(s["panorama"])),
    ("autoLoad", JsonCombinators.Json.Encode.bool(s["autoLoad"])),
    ("floor", JsonCombinators.Json.Encode.string(s["floor"])),
    ("category", JsonCombinators.Json.Encode.string(s["category"])),
    ("label", JsonCombinators.Json.Encode.string(s["label"])),
    ("isAutoForward", JsonCombinators.Json.Encode.bool(s["isAutoForward"])),
    ("hotSpots", JsonCombinators.Json.Encode.array(encodeHotspot)(s["hotSpots"])),
  ])
}

let normalizeSceneRefForExport = (value: string): string =>
  value
  ->String.trim
  ->String.replaceRegExp(/\\/g, "/")
  ->String.replaceRegExp(/^\.\//, "")
  ->String.replaceRegExp(/^\//, "")
  ->String.replaceRegExp(/^assets\/images\//, "")

let extractScenePrefix = (value: string): option<string> => {
  if String.length(value) >= 3 {
    let prefix = String.substring(value, ~start=0, ~end=3)
    if RegExp.test(/^\d{3}$/, prefix) {
      Some(prefix)
    } else {
      None
    }
  } else {
    None
  }
}

let resolveSceneIdFromTargetRef = (targetRef: string, scenes: array<scene>): option<string> => {
  let normalizedTarget = normalizeSceneRefForExport(targetRef)
  if normalizedTarget == "" {
    None
  } else {
    let targetNoExt = UrlUtils.stripExtension(normalizedTarget)
    let byId =
      scenes
      ->Belt.Array.getBy(s => normalizeSceneRefForExport(s.id) == normalizedTarget)
      ->Option.map(s => s.id)
    switch byId {
    | Some(id) => Some(id)
    | None =>
      let byName =
        scenes
        ->Belt.Array.getBy(s => {
          let sceneName = normalizeSceneRefForExport(s.name)
          let sceneNameNoExt = UrlUtils.stripExtension(sceneName)
          sceneName == normalizedTarget || sceneNameNoExt == targetNoExt
        })
        ->Option.map(s => s.id)
      switch byName {
      | Some(id) => Some(id)
      | None =>
        switch extractScenePrefix(targetNoExt) {
        | Some(prefix) =>
          scenes
          ->Belt.Array.getBy(s => {
            let sceneNoExt = normalizeSceneRefForExport(s.name)->UrlUtils.stripExtension
            sceneNoExt == prefix || String.startsWith(sceneNoExt, prefix ++ "_")
          })
          ->Option.map(s => s.id)
        | None => None
        }
      }
    }
  }
}

let generateTourHTML = (
  scenes: array<scene>,
  tourName,
  logoFilename: option<string>,
  exportType,
  baseSize,
  logoSize,
  _version,
) => {
  let firstSceneName = scenes[0]->Option.map(s => s.name)->Option.getOr("unknown")
  let firstSceneId = scenes[0]->Option.map(s => s.id)->Option.getOr(firstSceneName)
  let rawScenesData = Dict.make()

  scenes->Belt.Array.forEach(s => {
    let rawHotspots = s.hotspots->Belt.Array.mapWithIndex((_, h) => {
      let resolvedTargetId = switch h.targetSceneId {
      | Some(targetSceneId) => targetSceneId
      | None => resolveSceneIdFromTargetRef(h.target, scenes)->Option.getOr(h.target)
      }
      let targetIsAutoForward = switch scenes->Belt.Array.getBy(ts => ts.id == resolvedTargetId) {
      | Some(ts) => ts.isAutoForward
      | None =>
        scenes
        ->Belt.Array.getBy(
          ts => normalizeSceneRefForExport(ts.name) == normalizeSceneRefForExport(h.target),
        )
        ->Option.map(ts => ts.isAutoForward)
        ->Option.getOr(false)
      }
      {
        "pitch": h.displayPitch->Option.getOr(h.pitch),
        "yaw": h.yaw,
        "target": h.target,
        "targetSceneId": resolvedTargetId,
        "targetIsAutoForward": targetIsAutoForward,
        "startYaw": h.startYaw->Nullable.fromOption,
        "startPitch": h.startPitch->Nullable.fromOption,
        "waypoints": h.waypoints->Nullable.fromOption,
        "truePitch": h.pitch,
        "viewFrame": h.viewFrame->Nullable.fromOption,
        "returnViewFrame": h.returnViewFrame->Nullable.fromOption,
        "isReturnLink": h.isReturnLink->Option.getOr(false),
        "targetYaw": h.targetYaw->Nullable.fromOption,
        "targetPitch": h.targetPitch->Nullable.fromOption,
      }
    })
    Dict.set(
      rawScenesData,
      s.id,
      {
        "name": s.name,
        "panorama": `assets/images/${s.name}`,
        "autoLoad": true,
        "floor": s.floor,
        "category": s.category,
        "label": s.label,
        "isAutoForward": s.isAutoForward,
        "hotSpots": rawHotspots,
      },
    )
  })

  let isMobile = exportType == "hd"
  let css = Styles.generateCSS(firstSceneName, isMobile, exportType, baseSize, logoSize)
  let renderScript = Scripts.generateRenderScript(baseSize)
  let logoDiv = switch logoFilename {
  | Some(filename) => `<div class="watermark"><img src="assets/${filename}"></div>`
  | None => ""
  }

  let (defPitch, defYaw) =
    scenes[0]
    ->Option.flatMap(s => s.hotspots[0])
    ->Option.flatMap(h => h.viewFrame)
    ->Option.map(vf => (vf.pitch, vf.yaw))
    ->Option.getOr((0.0, 0.0))

  // CSP SAFE: Using strict encoder
  let scenesDataJson = JsonCombinators.Json.stringify(
    JsonCombinators.Json.Encode.dict(encodeSceneData)(rawScenesData),
  )

  let html = `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="libs/pannellum.css"/><script src="libs/pannellum.js"></script><link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet"><style>${css}</style></head><body><div id="stage"><div id="panorama"></div><div id="viewer-room-label-export" class="viewer-persistent-label-export state-hidden"></div><div id="viewer-floor-nav-export" aria-hidden="true"></div>${logoDiv}</div><script>
    const firstSceneId = "${firstSceneId}"; ${renderScript}
    let transitionFrom = null; let persistentFrom = null; let isFirstLoad = true;
    const config = { "default": { "firstScene": "${firstSceneId}", "sceneFadeDuration": 1000, "pitch": ${Belt.Float.toString(
      defPitch,
    )}, "yaw": ${Belt.Float.toString(
      defYaw,
    )}, "hfov": 90, "minHfov": 90, "maxHfov": 90, "showControls": false }, "scenes":{} };
    const scenesData = ${scenesDataJson};
    for (const [sceneId, data] of Object.entries(scenesData)) {
      config.scenes[sceneId] = { panorama: data.panorama, autoLoad: true, hotSpots: data.hotSpots.map((h, idx) => ({ pitch: h.pitch, yaw: h.yaw, type: "info", cssClass: "flat-arrow", createTooltipFunc: renderOrangeHotspot, createTooltipArgs: { i: idx, sourceSceneId: sceneId, targetSceneId: h.targetSceneId, target: h.target, targetName: h.target, targetIsAutoForward: h.targetIsAutoForward, viewFrame: h.viewFrame, targetYaw: h.targetYaw, targetPitch: h.targetPitch, isReturnLink: h.isReturnLink, returnViewFrame: h.returnViewFrame } })) };
    }
    window.viewer = pannellum.viewer('panorama', config); window.viewer.resize();
    window.addEventListener('resize', () => window.viewer?.resize());
    ${Scripts.loadEventScript}
  </script></body></html>`
  html
}

// --- COMPATIBILITY ALIASES ---
module TourTemplateAssets = Assets
module TourTemplateStyles = Styles
module TourTemplateScripts = Scripts

let generateEmbedCodes = Assets.generateEmbedCodes
let generateExportIndex = Assets.generateExportIndex
