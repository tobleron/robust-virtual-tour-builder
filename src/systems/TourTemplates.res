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
<div class="logo-container"><img src="tour_4k/assets/logo.png" onerror="this.parentElement.style.display='none'"></div>
<h1>__TOUR_NAME_PRETTY__</h1><div class="version-badge">Virtual Tour v__VERSION__</div></div><div class="grid">
<a href="tour_4k/index.html" class="card card-4k"><i data-lucide="sparkles" class="icon"></i><span class="res-label">4K Ultra HD</span><span class="description">Best for high-end displays.</span><span class="btn">Launch Tour</span></a>
<a href="tour_2k/index.html" class="card card-2k"><i data-lucide="monitor" class="icon"></i><span class="res-label">2K Desktop</span><span class="description">Optimized for laptops.</span><span class="btn">Launch Tour</span></a>
<a href="tour_hd/index.html" class="card card-hd"><i data-lucide="smartphone" class="icon"></i><span class="res-label">HD Mobile</span><span class="description">Portrait layout for phones.</span><span class="btn">Launch Tour</span></a>
</div><div class="footer">&copy; __YEAR__ Virtual Tour Platform.</div></div><script>lucide.createIcons();</script></body></html>`

  let generateExportIndex = (tourName, version) => {
    let prettyName = String.replaceRegExp(tourName, /_/g, " ")
    let year = Date.make()->Date.getFullYear->Belt.Int.toString
    indexTemplate
    ->String.replaceRegExp(/__TOUR_NAME__/g, tourName)
    ->String.replaceRegExp(/__TOUR_NAME_PRETTY__/g, prettyName)
    ->String.replaceRegExp(/__VERSION__/g, version)
    ->String.replaceRegExp(/__YEAR__/g, year)
  }

  let generateEmbedCodes = (tourName, version) => {
    `VIRTUAL TOUR - EMBED CODES\nVersion: ${version}\nProperty: ${tourName}\n\n1. 4K (Desktop):\n   <iframe src="tour_4k/index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n\n2. 2K (Desktop):\n   <iframe src="tour_2k/index.html" width="100%" height="400" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n\n3. HD (Mobile):\n   <iframe src="tour_hd/index.html" width="375" height="667" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`
  }
}

// --- STYLES ---

module Styles = {
  let cssTemplate = `
    :root { --viewer-bg: #111; --stage-border: #333; --glow-color: #fff4d1; --font-family: 'Outfit', sans-serif; --gold-1: #FFD700; --gold-2: #FDB931; --gold-3: #B8860B; --gold-text: #4B3300; --gold-border: #8B6508; --arrow-white: rgba(255, 255, 255, 0.5); }
    body { margin: 0; padding: 0; width: 100%; min-height: 100vh; display: flex; align-items: center; justify-content: center; overflow: auto; background-color: var(--viewer-bg); font-family: var(--font-family); }
    body::before { content: ""; position: fixed; top: -20px; left: -20px; right: -20px; bottom: -20px; background: url('assets/images/__FIRST_SCENE_NAME__') no-repeat center center fixed; background-size: cover; filter: blur(25px) brightness(0.4); z-index: -1; }
    __MEDIA_QUERY_CSS__
    #panorama { width: 100%; height: 100%; border-radius: inherit; }
    .pnlm-controls-container, .pnlm-zoom-controls, .pnlm-fullscreen-toggle-button, .pnlm-zoom-in, .pnlm-zoom-out, .pnlm-controls { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }
    .watermark { position: absolute; bottom: 25px; right: 25px; z-index: 10; pointer-events: none; background: white; border-radius: 12px; padding: 2px; display: flex; align-items: center; justify-content: center; box-shadow: 0 10px 30px rgba(0,0,0,0.3); border: 1px solid rgba(0,0,0,0.1); overflow: hidden; -webkit-mask-image: -webkit-radial-gradient(white, black); }
    .watermark img { height: __LOGO_SIZE__px; width: auto; display: block; object-fit: contain; }
    @keyframes glow-sequence { 0%, 100% { fill-opacity: 0; filter: brightness(1); } 10%, 30% { fill-opacity: 0.8; filter: brightness(1.5); } 40% { fill-opacity: 0; filter: brightness(1); } }
    .pnlm-hotspot.flat-arrow { display: block !important; background: rgba(255, 255, 255, 0.01) !important; border: 1px solid transparent !important; padding: 0 !important; pointer-events: auto !important; width: __BASE_SIZE__px !important; height: __BASE_SIZE__px !important; margin-left: -__BASE_SIZE_HALF__px !important; margin-top: -__BASE_SIZE_HALF__px !important; overflow: visible !important; cursor: pointer; perspective: 1500px; z-index: 2000 !important; transform-style: preserve-3d; }
    .custom-arrow-svg { width: 100% !important; height: 100% !important; display: block; pointer-events: none; transform: rotateX(65deg); transform-origin: center center; transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275); filter: drop-shadow(0 8px 4px rgba(0,0,0,0.4)); }
    .glow-unit { fill-opacity: 0; fill: var(--glow-color); }
    .glow-bottom { animation: glow-sequence 1.8s infinite; }
    .glow-top { animation: glow-sequence 1.8s infinite; animation-delay: 0.4s; }
    .pnlm-hotspot.flat-arrow:hover .custom-arrow-svg { animation: none; transform: rotateX(65deg) translateY(-20px) scale(1.15); filter: drop-shadow(0 25px 15px rgba(0,0,0,0.25)); }
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
    function renderGoldArrow(hotSpotDiv, args) {
      const currentSceneId = window.viewer.getScene();
      const currentSceneData = scenesData[currentSceneId];
      const isHome = currentSceneData && currentSceneData.hotSpots.length === 1 && persistentFrom && args.targetSceneId === persistentFrom;
      hotSpotDiv.style.width = "__BASE_SIZE__px"; hotSpotDiv.style.height = "__BASE_SIZE__px";
      const ns = "http://www.w3.org/2000/svg";
      const svg = document.createElementNS(ns, "svg");
      svg.setAttribute("class", "custom-arrow-svg"); svg.setAttribute("viewBox", "0 0 100 100"); svg.style.overflow = "visible";
      
      if (isHome) {
        hotSpotDiv.setAttribute('data-target-home', 'true');
        const defs = document.createElementNS(ns, "defs");
        const grad = document.createElementNS(ns, "linearGradient");
        grad.setAttribute("id", "homeGradExport_" + args.i); grad.setAttribute("x1", "0%"); grad.setAttribute("y1", "0%"); grad.setAttribute("x2", "0%"); grad.setAttribute("y2", "100%");
        [{o:"0%",c:"var(--gold-1)"},{o:"50%",c:"var(--gold-2)"},{o:"100%",c:"var(--gold-3)"}].forEach(s=>{ const stop=document.createElementNS(ns,"stop"); stop.setAttribute("offset",s.o); stop.style.stopColor=s.c; grad.appendChild(stop); });
        defs.appendChild(grad); svg.appendChild(defs);
        const rect = document.createElementNS(ns, "rect"); rect.setAttribute("x", "5"); rect.setAttribute("y", "5"); rect.setAttribute("width", "90"); rect.setAttribute("height", "90"); rect.setAttribute("rx", "8"); rect.setAttribute("fill", "url(#homeGradExport_" + args.i + ")"); svg.appendChild(rect);
        const text = document.createElementNS(ns, "text"); text.setAttribute("x", "50"); text.setAttribute("y", "52"); text.setAttribute("text-anchor", "middle"); text.setAttribute("dominant-baseline", "middle"); text.style.fontFamily = "Outfit, sans-serif"; text.style.fontWeight = "700"; text.style.fontSize = "24px"; text.setAttribute("fill", "var(--gold-text)"); text.textContent = "HOME"; svg.appendChild(text);
      } else {
        const defs = document.createElementNS(ns, "defs");
        const grad = document.createElementNS(ns, "linearGradient");
        grad.setAttribute("id", "arrowGradExport_" + args.i); grad.setAttribute("x1", "0%"); grad.setAttribute("y1", "0%"); grad.setAttribute("x2", "0%"); grad.setAttribute("y2", "100%");
        [{o:"0%",c:"var(--gold-1)"},{o:"50%",c:"var(--gold-2)"},{o:"100%",c:"var(--gold-3)"}].forEach(s=>{ const stop=document.createElementNS(ns,"stop"); stop.setAttribute("offset",s.o); stop.style.stopColor=s.c; grad.appendChild(stop); });
        defs.appendChild(grad); svg.appendChild(defs);
        const p1 = document.createElementNS(ns, "path"); p1.setAttribute("d", "M10 43 L50 13 L90 43 L90 53 L50 23 L10 53 Z M10 73 L50 43 L90 73 L90 83 L50 53 L10 83 Z"); p1.setAttribute("fill", "var(--gold-border)"); svg.appendChild(p1);
        const p2 = document.createElementNS(ns, "path"); p2.setAttribute("d", "M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z"); p2.setAttribute("fill", "url(#arrowGradExport_" + args.i + ")"); svg.appendChild(p2);
        const g1 = document.createElementNS(ns, "path"); g1.setAttribute("class", "glow-unit glow-top"); g1.setAttribute("d", "M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z"); svg.appendChild(g1);
        const g2 = document.createElementNS(ns, "path"); g2.setAttribute("class", "glow-unit glow-bottom"); g2.setAttribute("d", "M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z"); svg.appendChild(g2);
        const p3 = document.createElementNS(ns, "path"); p3.setAttribute("d", "M10 40 L50 10 L90 40 L50 11 Z"); p3.setAttribute("fill", "var(--arrow-white)"); svg.appendChild(p3);
      }
      while (hotSpotDiv.firstChild) hotSpotDiv.removeChild(hotSpotDiv.firstChild);
      hotSpotDiv.appendChild(svg);
      hotSpotDiv.onclick = function() {
        let y = 90, p = 0;
        if (args.isReturnLink && args.returnViewFrame) { y = args.returnViewFrame.yaw ?? 90; p = args.returnViewFrame.pitch ?? 0; }
        else { if (args.targetYaw !== undefined) { y = args.targetYaw; p = args.targetPitch ?? 0; } else if (args.viewFrame) { y = args.viewFrame.yaw ?? 90; p = args.viewFrame.pitch ?? 0; } }
        transitionFrom = window.viewer.getScene(); persistentFrom = transitionFrom;
        setTimeout(() => { window.viewer.loadScene(hotSpotDiv.getAttribute('data-target-home') === 'true' ? firstSceneId : args.targetSceneId, p, y, 90); }, 450);
      };
    }
  `

  let loadEventScript = `
    window.viewer.on('load', function() {
      const sid = window.viewer.getScene(); const sd = scenesData[sid];
      if (sd?.isAutoForward && sd.hotSpots?.length > 0) {
        setTimeout(() => { transitionFrom = sid; persistentFrom = sid; window.viewer.loadScene(sd.hotSpots[0].target, "same", "same", 90); }, 1000);
        return;
      }
      if (!transitionFrom && !isFirstLoad) return;
      if (sd?.hotSpots?.length > 0) window.viewer.setHfov(120);
      persistentFrom = transitionFrom; transitionFrom = null; isFirstLoad = false;
    });
  `

  let generateRenderScript = baseSize =>
    renderScriptTemplate->String.replaceRegExp(/__BASE_SIZE__/g, Belt.Int.toString(baseSize))
}

// --- MAIN ---

external castToJSON: dict<'a> => JSON.t = "%identity"
external castToUnknown: 'a => unknown = "%identity"

let generateTourHTML = (
  scenes: array<scene>,
  tourName,
  hasLogo,
  exportType,
  baseSize,
  logoSize,
  _version,
) => {
  let firstSceneName = scenes[0]->Option.map(s => s.name)->Option.getOr("unknown")
  let rawScenesData = Dict.make()

  scenes->Belt.Array.forEach(s => {
    let rawHotspots = s.hotspots->Belt.Array.mapWithIndex((_, h) =>
      {
        "pitch": h.displayPitch->Option.getOr(h.pitch),
        "yaw": h.yaw,
        "target": h.target,
        "truePitch": h.pitch,
        "viewFrame": h.viewFrame->Nullable.fromOption,
        "returnViewFrame": h.returnViewFrame->Nullable.fromOption,
        "isReturnLink": h.isReturnLink->Option.getOr(false),
        "targetYaw": h.targetYaw->Nullable.fromOption,
        "targetPitch": h.targetPitch->Nullable.fromOption,
      }
    )
    Dict.set(
      rawScenesData,
      s.name,
      {
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
  let logoDiv = hasLogo ? `<div class="watermark"><img src="assets/logo.png"></div>` : ""

  let (defPitch, defYaw) =
    scenes[0]
    ->Option.flatMap(s => s.hotspots[0])
    ->Option.flatMap(h => h.viewFrame)
    ->Option.map(vf => (vf.pitch, vf.yaw))
    ->Option.getOr((0.0, 0.0))

  let html = `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="libs/pannellum.css"/><script src="libs/pannellum.js"></script><link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet"><style>${css}</style></head><body><div id="stage"><div id="panorama"></div>${logoDiv}</div><script>
    const firstSceneId = "${firstSceneName}"; ${renderScript}
    let transitionFrom = null; let persistentFrom = null; let isFirstLoad = true;
    const config = { "default": { "firstScene": "${firstSceneName}", "sceneFadeDuration": 1000, "pitch": ${Belt.Float.toString(
      defPitch,
    )}, "yaw": ${Belt.Float.toString(
      defYaw,
    )}, "hfov": 90, "minHfov": 90, "maxHfov": 90, "showControls": false }, "scenes":{} };
    const scenesData = ${switch JSON.stringifyAny(rawScenesData) {
    | Some(s) => s
    | None => "{}"
    }};
    for (const [name, data] of Object.entries(scenesData)) {
      config.scenes[name] = { panorama: data.panorama, autoLoad: true, hotSpots: data.hotSpots.map((h, idx) => ({ pitch: h.pitch, yaw: h.yaw, type: "info", cssClass: "flat-arrow", createTooltipFunc: renderGoldArrow, createTooltipArgs: { i: idx, targetSceneId: h.target, viewFrame: h.viewFrame, targetYaw: h.targetYaw, targetPitch: h.targetPitch, isReturnLink: h.isReturnLink, returnViewFrame: h.returnViewFrame } })) };
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
