/**
 * Tour HTML Template Generator
 * Generates the HTML/CSS/JS for exported virtual tours
 * 
 * @module TourHTMLTemplate
 */

/**
 * Generate HTML content for an exported tour
 * @param {Array} scenes - Array of scene objects
 * @param {string} tourName - Name of the tour
 * @param {boolean} hasLogo - Whether logo is included
 * @param {string} exportType - Export type: 'hd', '2k', '4k'
 * @param {number} baseSize - Base size for hotspot arrows
 * @param {number} logoSize - Logo height in pixels
 * @param {string} version - Application version string
 * @returns {string} Complete HTML document string
 */
export function generateTourHTML(scenes, tourName, hasLogo, exportType, baseSize, logoSize, version) {
  const firstSceneName = scenes[0].name;
  const rawScenesData = {};
  scenes.forEach((s) => {
    rawScenesData[s.name] = {
      panorama: `assets/images/${s.name}`,
      autoLoad: true,
      floor: s.floor || "ground",
      category: s.category || "indoor",
      label: s.label || s.name,
      isAutoForward: s.isAutoForward || false,
      hotSpots: s.hotspots.map((h) => ({
        pitch: h.displayPitch !== undefined ? h.displayPitch : h.pitch,
        yaw: h.yaw,
        target: h.target,
        truePitch: h.pitch,
        viewFrame: h.viewFrame || null,
        returnViewFrame: h.returnViewFrame || null,
        isReturnLink: h.isReturnLink || false,
        targetYaw: h.targetYaw,
        targetPitch: h.targetPitch
      })),
    };
  });

  const isMobile = exportType === 'hd';

  const customCSS = generateCSS(firstSceneName, isMobile, exportType, baseSize, logoSize);
  const renderFunctionScript = generateRenderScript(baseSize);

  // Config: HFOV Settings - LOCKED at 90° for all tours
  const hfovDefault = 90;
  const hfovMin = 90;
  const hfovMax = 90;

  return `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="libs/pannellum.css"/><script src="libs/pannellum.js"></script><link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet"><link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"><style>${customCSS}</style></head><body><div id="stage"><div id="panorama"></div><div id="floor-nav" class="floor-navigator"></div>${hasLogo ? '<div class="watermark"><img src="assets/logo.png"></div>' : ""}</div>

  <script>
    const firstSceneId = "${scenes[0].name}";
    ${renderFunctionScript}
    
    let transitionFrom = null;
    let lastVisitedSceneId = null;
    let persistentFrom = null;
    let isFirstLoad = true;

    const config = {
      "default": {
        "firstScene": "${scenes[0].name}",
        "sceneFadeDuration": 1000,
        "autoRotate": 0,
        "hfov": ${hfovDefault},
        "minHfov": ${hfovMin},
        "maxHfov": ${hfovMax},
        "showControls": false,
        "showFullscreenCtrl": false,
        "showZoomCtrl": false
      },
      "scenes":{}
    }; 
    const scenesData = ${JSON.stringify(rawScenesData)}; 
    
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
    
    ${generateLoadEventScript()}
    ${generateFloorNavScript()}
  </script></body></html>`;
}

/**
 * Generate CSS for the exported tour
 */
function generateCSS(firstSceneName, isMobile, exportType, baseSize, logoSize) {
  return `
    /* BASE RESET */
    body { 
      margin: 0; padding: 0; 
      width: 100%; 
      min-height: 100vh;
      display: flex; 
      align-items: center;
      justify-content: center;
      overflow: auto;
      background-color: #111;
      font-family: 'Outfit', sans-serif;
    }
    
    body::before {
      content: ""; position: fixed;
      top: -20px; left: -20px; right: -20px; bottom: -20px;
      background: url('assets/images/${firstSceneName}') no-repeat center center fixed;
      background-size: cover; filter: blur(25px) brightness(0.4);
      z-index: -1;
    }

    ${isMobile ? `
    /* HD EXPORT: MOBILE ONLY */
    #stage {
      position: relative; 
      width: 375px; 
      height: 667px;
      background: #000;
      border-radius: 20px;
      border: 4px solid #333;
      box-shadow: 0 0 50px rgba(0,0,0,0.6);
      overflow: hidden;
    }
    ` : `
    /* 2K/4K EXPORT: DESKTOP */
    #stage {
      position: relative; 
      margin: 0 auto;
      width: 100%;
      max-width: ${exportType === '4k' ? '1024px' : '640px'};
      height: auto;
      aspect-ratio: 16/10;
      max-height: 90vh;
      background: #000;
      border-radius: 8px;
      box-shadow: 0 0 50px rgba(0,0,0,0.6);
      overflow: hidden;
    }
    
    @media (max-width: ${exportType === '4k' ? '1100px' : '700px'}) {
      #stage {
        max-width: 95vw;
      }
    }
    `}
    
    #panorama { width: 100%; height: 100%; border-radius: inherit; }

    /* HIDE PANNELLUM DEFAULT CONTROLS */
    .pnlm-controls-container,
    .pnlm-zoom-controls,
    .pnlm-fullscreen-toggle-button,
    .pnlm-zoom-in,
    .pnlm-zoom-out,
    .pnlm-controls {
      display: none !important;
      opacity: 0 !important;
      visibility: hidden !important;
      pointer-events: none !important;
    }

    /* WATERMARK */
    .watermark { 
      position: absolute; 
      bottom: 25px; 
      right: 25px; 
      z-index: 10; 
      pointer-events: none; 
      opacity: 0.95;
    }
    .watermark img { 
      height: ${logoSize}px;
      width: auto; 
      filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5)); 
      display: block;
      border-radius: 8px;
    }

    /* Sequential Glow Animation */
    @keyframes glow-sequence {
      0%, 100% { fill-opacity: 0; filter: brightness(1); }
      10%, 30% { fill-opacity: 0.8; filter: brightness(1.5); }
      40% { fill-opacity: 0; filter: brightness(1); }
    }

    /* HOTSPOT CONTAINER */
    .pnlm-hotspot.flat-arrow {
      display: block !important;
      background: rgba(255, 255, 255, 0.01) !important;
      border: 1px solid transparent !important;
      padding: 0 !important;
      pointer-events: auto !important;
      width: ${baseSize}px !important;
      height: ${baseSize}px !important;
      margin-left: -${baseSize / 2}px !important;
      margin-top: -${baseSize / 2}px !important;
      overflow: visible !important;
      cursor: pointer;
      perspective: 1500px; 
      z-index: 2000 !important;
      transform-style: preserve-3d;
    }

    .custom-arrow-svg {
      width: 100% !important;
      height: 100% !important;
      display: block;
      pointer-events: none;
      transform: rotateX(65deg); 
      transform-origin: center center;
      transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
      filter: drop-shadow(0 8px 4px rgba(0,0,0,0.4));
    }

    .glow-unit { fill-opacity: 0; fill: #fff4d1; }
    .glow-bottom { animation: glow-sequence 1.8s infinite; }
    .glow-top { animation: glow-sequence 1.8s infinite; animation-delay: 0.4s; }

    .pnlm-hotspot.flat-arrow:hover .custom-arrow-svg {
      animation: none;
      transform: rotateX(65deg) translateY(-20px) scale(1.15);
      filter: drop-shadow(0 25px 15px rgba(0,0,0,0.25));
    }

    /* HIDE LOADING UI */
    .pnlm-load-box, .pnlm-lbox, .pnlm-lmsg, .pnlm-lbar, .pnlm-ltext,
    .pnlm-loading-container, [class^="pnlm-l"], [class*="loading"] { 
      display: none !important; 
      opacity: 0 !important;
      visibility: hidden !important;
      pointer-events: none !important;
    }

    /* HOME PLAQUE */
    .pnlm-hotspot.flat-arrow[data-target-home] {
      perspective: none !important;
      transform-style: flat !important;
    }
    .pnlm-hotspot.flat-arrow[data-target-home] .custom-arrow-svg {
      transform: none !important;
      animation: home-pulse 2s infinite ease-in-out !important;
    }

    @keyframes home-pulse {
      0% { transform: scale(1); }
      50% { transform: scale(1.1); }
      100% { transform: scale(1); }
    }

    /* FLOOR NAVIGATOR */
    .floor-navigator {
      position: absolute;
      top: 20px;
      left: 20px;
      z-index: 1000;
      background: rgba(0, 26, 77, 0.95);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 0;
      min-width: 160px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
      font-family: 'Outfit', sans-serif;
      overflow: hidden;
      max-height: calc(100% - 40px);
      overflow-y: auto;
    }
    .floor-nav-header {
      background: #003da5;
      color: #ffffff;
      font-weight: 700;
      font-size: 12px;
      padding: 10px 14px;
      text-transform: uppercase;
      letter-spacing: 1px;
      border-bottom: 2px solid #002570;
    }
    .floor-nav-section {
      border-bottom: 1px solid rgba(255,255,255,0.05);
    }
    .floor-nav-btn {
      display: flex;
      align-items: center;
      gap: 10px;
      width: 100%;
      padding: 12px 14px;
      background: transparent;
      border: none;
      color: #94a3b8;
      font-size: 13px;
      font-weight: 500;
      cursor: pointer;
      text-align: left;
      transition: all 0.2s ease;
      border-left: 3px solid transparent;
    }
    .floor-nav-btn:hover {
      background: rgba(255,255,255,0.05);
      color: #fff;
    }
    .floor-nav-btn.active {
      background: rgba(0, 61, 165, 0.4);
      color: #ffcc00;
      border-left-color: #ffcc00;
    }
    .floor-nav-btn .floor-indicator {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: transparent;
      border: 1px solid #64748b;
      flex-shrink: 0;
    }
    .floor-nav-btn.active .floor-indicator {
      background: #ffcc00;
      border-color: #ffcc00;
      box-shadow: 0 0 8px rgba(255, 204, 0, 0.4);
    }
    .floor-rooms {
      display: none;
      padding: 5px 0 10px 0;
      background: rgba(0, 0, 0, 0.2);
    }
    .floor-nav-section.expanded .floor-rooms {
      display: block;
    }
    .room-btn {
      display: block;
      width: 100%;
      padding: 8px 14px 8px 34px;
      background: transparent;
      border: none;
      color: #cbd5e1;
      font-size: 12px;
      cursor: pointer;
      text-align: left;
      transition: all 0.2s ease;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .room-btn:hover {
      color: #fff;
      padding-left: 38px;
    }
    .room-btn.current {
      color: #ffcc00;
      font-weight: 600;
      background: linear-gradient(90deg, rgba(255,204,0,0.1), transparent);
    }
    .room-btn.current::before {
      content: "• ";
      color: #ffcc00;
      margin-right: 4px;
    }
  `;
}

/**
 * Generate the render function script for hotspot arrows
 */
function generateRenderScript(baseSize) {
  return `
    function renderGoldArrow(hotSpotDiv, args) {
      const currentSceneId = window.viewer.getScene();
      const currentSceneData = scenesData[currentSceneId];
      
      const isHome = currentSceneData && 
                     currentSceneData.hotSpots.length === 1 && 
                     persistentFrom && 
                     args.targetSceneId === persistentFrom;

      hotSpotDiv.style.width = "${baseSize}px";
      hotSpotDiv.style.height = "${baseSize}px";
      
      if (isHome) {
        hotSpotDiv.setAttribute('data-target-home', 'true');
        hotSpotDiv.innerHTML = \`
          <svg class="custom-arrow-svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet" style="overflow:visible;">
            <defs>
              <linearGradient id="homeGradExport_\${args.i}" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" style="stop-color:#FFD700;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#FDB931;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#B8860B;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect x="5" y="5" width="90" height="90" rx="8" fill="url(#homeGradExport_\${args.i})" />
            <text x="50" y="52" text-anchor="middle" dominant-baseline="middle" font-family="Outfit, sans-serif" font-weight="700" font-size="24" fill="#4B3300" style="letter-spacing: 0px;">HOME</text>
          </svg>\`;
      } else {
        hotSpotDiv.innerHTML = \`
          <svg class="custom-arrow-svg" viewBox="0 0 100 100" style="overflow:visible;">
            <defs>
              <linearGradient id="arrowGradExport_\${args.i}" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" style="stop-color:#FFD700;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#FDB931;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#B8860B;stop-opacity:1" />
              </linearGradient>
            </defs>
            <path d="M10 43 L50 13 L90 43 L90 53 L50 23 L10 53 Z M10 73 L50 43 L90 73 L90 83 L50 53 L10 83 Z" fill="#8B6508" />
            <path d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" fill="url(#arrowGradExport_\${args.i})" />
            <path class="glow-unit glow-top" d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z" />
            <path class="glow-unit glow-bottom" d="M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" />
            <path d="M10 40 L50 10 L90 40 L50 11 Z" fill="#ffffff" fill-opacity="0.5" />
          </svg>\`;
      }
      
      hotSpotDiv.onclick = function() {
        // PRIORITY LOGIC:
        let navYaw = 90; // Fallback
        let navPitch = 0;

        if (args.isReturnLink && args.returnViewFrame) {
          navYaw = args.returnViewFrame.yaw !== undefined ? args.returnViewFrame.yaw : 90;
          navPitch = args.returnViewFrame.pitch !== undefined ? args.returnViewFrame.pitch : 0;
        } else {
          if (args.targetYaw !== undefined) {
             navYaw = args.targetYaw;
             navPitch = args.targetPitch !== undefined ? args.targetPitch : 0;
          } else if (args.viewFrame) {
             navYaw = args.viewFrame.yaw !== undefined ? args.viewFrame.yaw : 90;
             navPitch = args.viewFrame.pitch !== undefined ? args.viewFrame.pitch : 0;
          }
        }

        const v = window.viewer;
        v.lookAt(args.truePitch, args.yaw, 85, 400);
        const currentScene = v.getScene();
        transitionFrom = currentScene;
        persistentFrom = currentScene;

        setTimeout(() => { 
          const finalTarget = hotSpotDiv.getAttribute('data-target-home') === 'true' 
                              ? firstSceneId : args.targetSceneId;
          v.loadScene(finalTarget, navPitch, navYaw, 90);
        }, 450);
      };
    }
  `;
}

/**
 * Generate the load event script for auto-navigation
 */
function generateLoadEventScript() {
  return `
    window.viewer.on('load', function() {
      const currentSceneId = window.viewer.getScene();
      const currentSceneData = scenesData[currentSceneId];
      
      // AUTO-FORWARD
      if (currentSceneData && currentSceneData.isAutoForward && 
          currentSceneData.hotSpots && currentSceneData.hotSpots.length > 0) {
        const firstHotspot = currentSceneData.hotSpots[0];
        const targetSceneId = firstHotspot.target;
        
        setTimeout(() => {
          transitionFrom = currentSceneId;
          persistentFrom = currentSceneId;
          window.viewer.loadScene(targetSceneId, "same", "same", 90);
        }, 1000);
        return;
      }
      
      if (!transitionFrom && !isFirstLoad) return; 
      
      let targetHotspot = null;
      
      if (currentSceneData && currentSceneData.hotSpots && currentSceneData.hotSpots.length > 0) {
        if (isFirstLoad) {
          targetHotspot = currentSceneData.hotSpots[0];
        } else {
          targetHotspot = currentSceneData.hotSpots.find(h => h.target !== transitionFrom) 
                       || currentSceneData.hotSpots[0];
        }

        if (targetHotspot) {
          const delay = isFirstLoad ? 500 : 500;
          setTimeout(() => {
            window.viewer.lookAt(targetHotspot.truePitch, targetHotspot.yaw, 120, 1500);
          }, delay);
        } else {
          window.viewer.setHfov(120);
        }
      }
      
      persistentFrom = transitionFrom;
      lastVisitedSceneId = transitionFrom;
      transitionFrom = null;
      isFirstLoad = false;

      updateFloorNav(currentSceneId);
    });
  `;
}

/**
 * Generate the floor navigator script
 */
function generateFloorNavScript() {
  return `
    const floorOrder = ['roof', 'fourth', 'third', 'second', 'first', 'ground', 'b1', 'b2'];
    const floorLabels = {
      'b2': 'B<sup>-2</sup>',
      'b1': 'B<sup>-1</sup>',
      'ground': 'G',
      'first': '+1',
      'second': '+2',
      'third': '+3',
      'fourth': '+4',
      'roof': 'R'
    };
    
    function buildFloorNav() {
      const nav = document.getElementById('floor-nav');
      if (!nav) return;
      
      const indoorFloors = {};
      const outdoorScenes = [];
      
      for (const [name, data] of Object.entries(scenesData)) {
        if (data.category === 'outdoor') {
          outdoorScenes.push({ name, label: data.label });
        } else {
          const floor = data.floor || 'ground';
          if (!indoorFloors[floor]) indoorFloors[floor] = [];
          indoorFloors[floor].push({ name, label: data.label });
        }
      }
      
      let html = '<div class="floor-nav-header">🏠 Navigate</div>';
      
      for (const floorId of floorOrder) {
        if (!indoorFloors[floorId] || indoorFloors[floorId].length === 0) continue;
        
        html += '<div class="floor-nav-section" data-floor="' + floorId + '">';
        html += '<button class="floor-nav-btn" onclick="toggleFloor(\\'' + floorId + '\\')">';
        html += '<span class="floor-indicator"></span>' + floorLabels[floorId];
        html += '</button>';
        html += '<div class="floor-rooms">';
        for (const scene of indoorFloors[floorId]) {
          html += '<button class="room-btn" data-scene="' + scene.name + '" onclick="goToScene(\\'' + scene.name + '\\')">' + scene.label + '</button>';
        }
        html += '</div></div>';
      }
      
      if (outdoorScenes.length > 0) {
        html += '<div class="floor-nav-section" data-floor="outdoor">';
        html += '<button class="floor-nav-btn" onclick="toggleFloor(\\'outdoor\\')">';
        html += '<span class="floor-indicator"></span>🌳 Outdoor';
        html += '</button>';
        html += '<div class="floor-rooms">';
        for (const scene of outdoorScenes) {
          html += '<button class="room-btn" data-scene="' + scene.name + '" onclick="goToScene(\\'' + scene.name + '\\')">' + scene.label + '</button>';
        }
        html += '</div></div>';
      }
      
      nav.innerHTML = html;
    }
    
    function toggleFloor(floorId) {
      const sections = document.querySelectorAll('.floor-nav-section');
      sections.forEach(s => {
        if (s.dataset.floor === floorId) {
          s.classList.toggle('expanded');
        }
      });
    }
    
    function goToScene(sceneName) {
      if (window.viewer) {
        transitionFrom = window.viewer.getScene();
        persistentFrom = transitionFrom;
        window.viewer.loadScene(sceneName, 'same', 'same', 90);
      }
    }
    
    function updateFloorNav(currentSceneName) {
      document.querySelectorAll('.room-btn.current').forEach(b => b.classList.remove('current'));
      document.querySelectorAll('.floor-nav-btn.active').forEach(b => b.classList.remove('active'));
      
      const currentBtn = document.querySelector('.room-btn[data-scene="' + currentSceneName + '"]');
      if (currentBtn) {
        currentBtn.classList.add('current');
        
        const section = currentBtn.closest('.floor-nav-section');
        if (section) {
          section.classList.add('expanded');
          const floorBtn = section.querySelector('.floor-nav-btn');
          if (floorBtn) floorBtn.classList.add('active');
        }
      }
    }
    
    buildFloorNav();
    updateFloorNav(firstSceneId);
  `;
}

/**
 * Generate embed codes text file content
 * @param {string} tourName - Tour name
 * @param {string} version - Application version
 * @returns {string} Embed codes content
 */
export function generateEmbedCodes(tourName, version) {
  return `REMAX VIRTUAL TOUR - EMBED CODES
Version: ${version}
Property: ${tourName}

1. 4K (Desktop):
   <iframe src="tour_4k/index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>

2. 2K (Desktop):
   <iframe src="tour_2k/index.html" width="100%" height="400" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>

3. HD (Mobile):
   <iframe src="tour_hd/index.html" width="375" height="667" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>
`;
}
