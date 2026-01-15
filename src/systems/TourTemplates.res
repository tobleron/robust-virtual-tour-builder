/* src/systems/TourTemplates.res */

open Types

/* Main tour template composition using extracted modules */

let generateTourHTML = (
  scenes: array<scene>,
  tourName,
  hasLogo,
  exportType,
  baseSize,
  logoSize,
  _version,
) => {
  let firstSceneName = switch Belt.Array.get(scenes, 0) {
  | Some(s) => s.name
  | None => "unknown"
  }

  let rawScenesData = Dict.make()

  Belt.Array.forEach(scenes, s => {
    let rawHotspots = Belt.Array.mapWithIndex(s.hotspots, (_idx, h) => {
      let pitch = Option.getOr(h.displayPitch, h.pitch)
      let viewFrame = Option.getOr(h.viewFrame, Nullable.null->Obj.magic)
      let rvf = Option.getOr(h.returnViewFrame, Nullable.null->Obj.magic)
      let isRet = Option.getOr(h.isReturnLink, false)
      let ty = Option.getOr(h.targetYaw, Nullable.undefined->Obj.magic)
      let tp = Option.getOr(h.targetPitch, Nullable.undefined->Obj.magic)

      {
        "pitch": pitch,
        "yaw": h.yaw,
        "target": h.target,
        "truePitch": h.pitch,
        "viewFrame": viewFrame,
        "returnViewFrame": rvf,
        "isReturnLink": isRet,
        "targetYaw": ty,
        "targetPitch": tp,
      }
    })

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
  let customCSS = TourTemplateStyles.generateCSS(
    firstSceneName,
    isMobile,
    exportType,
    baseSize,
    logoSize,
  )
  let renderScript = TourTemplateScripts.generateRenderScript(baseSize)
  let logoDiv = hasLogo ? `<div class="watermark"><img src="assets/logo.png"></div>` : ""

  /* Get defaults from first scene */
  let (defPitch, defYaw) = switch Belt.Array.get(scenes, 0) {
  | Some(s) =>
    switch Belt.Array.get(s.hotspots, 0) {
    | Some(h) =>
      switch h.viewFrame {
      | Some(vf) => (vf.pitch, vf.yaw)
      | None => (0.0, 0.0)
      }
    | None => (0.0, 0.0)
    }
  | None => (0.0, 0.0)
  }

  /* Construct HTML */
  `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="libs/pannellum.css"/><script src="libs/pannellum.js"></script><link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet"><link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"><style>${customCSS}</style></head><body><div id="stage"><div id="panorama"></div>${logoDiv}</div>

  <script>
    const firstSceneId = "${firstSceneName}";
    ${renderScript}
    
    let transitionFrom = null;
    let lastVisitedSceneId = null;
    let persistentFrom = null;
    let isFirstLoad = true;

    const config = {
      "default": {
        "firstScene": "${firstSceneName}",
        "sceneFadeDuration": 1000,
        "autoRotate": 0,
        "pitch": ${Belt.Float.toString(defPitch)},
        "yaw": ${Belt.Float.toString(defYaw)},
        "hfov": 90,
        "minHfov": 90,
        "maxHfov": 90,
        "showControls": false,
        "showFullscreenCtrl": false,
        "showZoomCtrl": false
      },
      "scenes":{}
    }; 
    const scenesData = ${JSON.stringify(JSON.Encode.object(Obj.magic(rawScenesData)))}; 
    
    for (const [name, data] of Object.entries(scenesData)) { 
      config.scenes[name] = { 
        panorama: data.panorama, 
        autoLoad: true, 
        hotSpots: data.hotSpots.map((h, idx) => ({ 
          pitch: h.pitch, 
          yaw: h.yaw, 
          type: "info", 
          cssClass: "flat-arrow", 
          createTooltipFunc: renderGoldArrow, 
          createTooltipArgs: { 
            i: idx, 
            targetSceneId: h.target, 
            pitch: h.pitch, 
            yaw: h.yaw, 
            truePitch: h.truePitch, 
            viewFrame: h.viewFrame,
            targetYaw: h.targetYaw,
            targetPitch: h.targetPitch,
            isReturnLink: h.isReturnLink,
            returnViewFrame: h.returnViewFrame
          } 
        })) 
      }; 
    } 
    
    window.viewer = pannellum.viewer('panorama', config);
    window.viewer.resize();
    
    window.addEventListener('resize', function() {
      if (window.viewer) {
        window.viewer.resize();
      }
    });
    
    ${TourTemplateScripts.loadEventScript}
  </script></body></html>`
}

let generateEmbedCodes = TourTemplateAssets.generateEmbedCodes
let generateExportIndex = TourTemplateAssets.generateExportIndex
