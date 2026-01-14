/* src/systems/TourTemplateStyles.res */

/* CSS template for exported tours */

let cssTemplate = `
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
      background: url('assets/images/__FIRST_SCENE_NAME__') no-repeat center center fixed;
      background-size: cover; filter: blur(25px) brightness(0.4);
      z-index: -1;
    }

    __MEDIA_QUERY_CSS__
    
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
      height: __LOGO_SIZE__px;
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
      width: __BASE_SIZE__px !important;
      height: __BASE_SIZE__px !important;
      margin-left: -__BASE_SIZE_HALF__px !important;
      margin-top: -__BASE_SIZE_HALF__px !important;
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
`

let generateCSS = (firstSceneName, isMobile, exportType, baseSize, logoSize) => {
  let mediaQuery = if isMobile {
    `
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
    `
  } else {
    let maxWidth = exportType == "4k" ? "1024px" : "640px"
    let mediaWidth = exportType == "4k" ? "1100px" : "700px"
    `
    /* 2K/4K EXPORT: DESKTOP */
    #stage {
      position: relative; 
      margin: 0 auto;
      width: 100%;
      max-width: ${maxWidth};
      height: auto;
      aspect-ratio: 16/10;
      max-height: 90vh;
      background: #000;
      border-radius: 8px;
      box-shadow: 0 0 50px rgba(0,0,0,0.6);
      overflow: hidden;
    }
    
    @media (max-width: ${mediaWidth}) {
      #stage {
        max-width: 95vw;
      }
    }
    `
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
