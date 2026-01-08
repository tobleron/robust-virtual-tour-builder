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

  return `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="libs/pannellum.css"/><script src="libs/pannellum.js"></script><link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet"><link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"><style>${customCSS}</style></head><body><div id="stage"><div id="panorama"></div>${hasLogo ? '<div class="watermark"><img src="assets/logo.png"></div>' : ""}</div>

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
        "pitch": ${scenes[0].hotspots && scenes[0].hotspots[0] && scenes[0].hotspots[0].viewFrame && scenes[0].hotspots[0].viewFrame.pitch ? scenes[0].hotspots[0].viewFrame.pitch : 0},
        "yaw": ${scenes[0].hotspots && scenes[0].hotspots[0] && scenes[0].hotspots[0].viewFrame && scenes[0].hotspots[0].viewFrame.yaw ? scenes[0].hotspots[0].viewFrame.yaw : 0},
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
      background: white;
      border-radius: 12px;
      padding: 2px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
      border: 1px solid rgba(0,0,0,0.1);
      overflow: hidden;
      -webkit-mask-image: -webkit-radial-gradient(white, black);
    }
    .watermark img { 
      height: ${logoSize}px;
      width: auto; 
      display: block;
      object-fit: contain;
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
        // DISABLED: Automatic pan to hotspot before transition (for manual control)
        // v.lookAt(args.truePitch, args.yaw, 85, 400);
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
          // DISABLED: Automatic pan to forward direction after scene load (for manual control)
          // const delay = isFirstLoad ? 500 : 500;
          // setTimeout(() => {
          //   window.viewer.lookAt(targetHotspot.truePitch, targetHotspot.yaw, 120, 1500);
          // }, delay);
        } else {
          window.viewer.setHfov(120);
        }
      }
      
      persistentFrom = transitionFrom;
      lastVisitedSceneId = transitionFrom;
      transitionFrom = null;
      isFirstLoad = false;
    });
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

/**
 * Generate a landing page for the export root
 * @param {string} tourName - Name of the tour
 * @param {string} version - Application version
 * @returns {string} Complete HTML document for the hub index
 */
export function generateExportIndex(tourName, version) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${tourName} - Virtual Tour Hub</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        :root {
            --primary: #003da5;
            --primary-dark: #002a70;
            --accent: #ffcc00;
            --danger: #dc3545;
            --slate-900: #020617;
            --slate-800: #0f172a;
            --slate-700: #1e293b;
            --glass: rgba(255, 255, 255, 0.03);
            --glass-border: rgba(255, 255, 255, 0.08);
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            padding: 0;
            font-family: 'Outfit', sans-serif;
            background: var(--slate-900);
            color: white;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            overflow-x: hidden;
        }

        .background-blob {
            position: fixed;
            width: 800px;
            height: 800px;
            background: radial-gradient(circle, rgba(0, 61, 165, 0.1) 0%, rgba(0, 0, 0, 0) 70%);
            z-index: -1;
            filter: blur(80px);
            pointer-events: none;
        }

        .blob-1 { top: -200px; left: -200px; }
        .blob-2 { bottom: -200px; right: -200px; background: radial-gradient(circle, rgba(15, 23, 42, 0.3) 0%, rgba(0, 0, 0, 0) 70%); }

        .container {
            width: 90%;
            max-width: 1000px;
            text-align: center;
            padding: 60px 0;
            animation: fadeIn 1s cubic-bezier(0.22, 1, 0.36, 1);
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .header {
            margin-bottom: 60px;
            position: relative;
        }

        .header::after {
            content: "";
            position: absolute;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            width: 200px; height: 100px;
            background: var(--primary);
            filter: blur(100px);
            opacity: 0.2;
            z-index: -1;
        }

        .logo-container {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            background: white;
            padding: 4px;
            border-radius: 12px;
            margin-bottom: 32px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            border: 1px solid rgba(0,0,0,0.05);
            position: relative;
            max-width: 120px;
            max-height: 60px;
            overflow: hidden;
            -webkit-mask-image: -webkit-radial-gradient(white, black);
        }

        .logo-container img {
            width: 100%;
            height: auto;
            display: block;
            object-fit: contain;
        }

        h1 {
            font-size: 42px;
            font-weight: 700;
            margin: 0 0 16px 0;
            letter-spacing: -1px;
            background: linear-gradient(to bottom, #ffffff, #94a3b8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }

        .version-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: var(--glass);
            padding: 6px 16px;
            border-radius: 100px;
            font-size: 13px;
            font-weight: 600;
            color: #94a3b8;
            border: 1px solid var(--glass-border);
            letter-spacing: 0.5px;
        }

        .version-dot {
            width: 6px;
            height: 6px;
            background: #10b981;
            border-radius: 50%;
            box-shadow: 0 0 10px #10b981;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.5; transform: scale(1.2); }
            100% { opacity: 1; transform: scale(1); }
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 32px;
            margin-top: 20px;
        }

        .card {
            background: var(--slate-800);
            border: 1px solid var(--glass-border);
            border-radius: 24px;
            padding: 40px 30px;
            text-decoration: none;
            color: white;
            transition: all 0.4s cubic-bezier(0.25, 1, 0.5, 1);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 20px;
            position: relative;
            overflow: hidden;
        }

        .card-glow {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: radial-gradient(circle at center, var(--primary), transparent 70%);
            opacity: 0;
            transition: opacity 0.4s;
            pointer-events: none;
        }

        .card:hover {
            transform: translateY(-12px);
            border-color: rgba(255, 255, 255, 0.15);
            box-shadow: 0 30px 60px rgba(0,0,0,0.5), inset 0 0 0 1px rgba(255,255,255,0.05);
            background: var(--slate-700);
        }

        .card:hover .card-glow {
            opacity: 0.05;
        }

        .card-4k .icon { color: #f59e0b; }
        .card-2k .icon { color: #3b82f6; }
        .card-hd .icon { color: #10b981; }

        .card .icon {
            font-size: 48px;
            filter: drop-shadow(0 0 20px rgba(0,0,0,0.3));
        }

        .card .res-label {
            font-size: 26px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }

        .card .description {
            font-size: 15px;
            color: #94a3b8;
            line-height: 1.6;
        }

        .card .btn {
            margin-top: 10px;
            background: rgba(255, 255, 255, 0.05);
            color: #e2e8f0;
            padding: 12px 32px;
            border-radius: 100px;
            font-size: 14px;
            font-weight: 600;
            border: 1px solid rgba(255, 255, 255, 0.1);
            transition: all 0.3s;
        }

        .card:hover .btn {
            background: white;
            color: #0f172a;
            transform: scale(1.05);
            box-shadow: 0 10px 20px rgba(0,0,0,0.2);
        }

        .footer {
            margin-top: 80px;
            font-size: 13px;
            color: #475569;
            letter-spacing: 0.5px;
        }
    </style>
</head>
<body>
    <div class="background-blob blob-1"></div>
    <div class="background-blob blob-2"></div>

    <div class="container">
        <div class="header">
            <div class="logo-container">
                <img src="tour_4k/assets/logo.png" onerror="this.parentElement.style.display='none'">
            </div>
            <h1>${tourName.replace(/_/g, ' ')}</h1>
            <div class="version-badge">
                <span class="version-dot"></span>
                Virtual Tour v${version}
            </div>
        </div>

        <div class="grid">
            <a href="tour_4k/index.html" class="card card-4k">
                <div class="card-glow"></div>
                <span class="material-icons icon">high_quality</span>
                <span class="res-label">4K Ultra HD</span>
                <span class="description">Best for high-end displays and big screens. Maximum detail.</span>
                <span class="btn">Launch Tour</span>
            </a>

            <a href="tour_2k/index.html" class="card card-2k">
                <div class="card-glow"></div>
                <span class="material-icons icon">monitor</span>
                <span class="res-label">2K Desktop</span>
                <span class="description">Optimized for standard laptops and monitors. Fast loading.</span>
                <span class="btn">Launch Tour</span>
            </a>

            <a href="tour_hd/index.html" class="card card-hd">
                <div class="card-glow"></div>
                <span class="material-icons icon">smartphone</span>
                <span class="res-label">HD Mobile</span>
                <span class="description">Portrait layout designed specifically for phones and tablets.</span>
                <span class="btn">Launch Tour</span>
            </a>
        </div>

        <div class="footer">
            &copy; ${new Date().getFullYear()} RE/MAX Virtual Tour Platform. Built with Antigravity.
        </div>
    </div>
</body>
</html>`;
}
