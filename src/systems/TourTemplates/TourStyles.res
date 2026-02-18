let cssTemplate = `
    :root { --viewer-bg: #1e1e1e; --stage-border: #333; --glow-color: #fff4d1; --font-family: 'Outfit', sans-serif; --gold-1: #ea580c; --gold-2: #f97316; --gold-3: #c2410c; --gold-text: #ffffff; --gold-border: #7c2d12; --arrow-white: rgba(255, 255, 255, 0.4); --texture-noise: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E"); --export-fallback-padding: 5px; }
    body { margin: 0; padding: 0; width: 100%; min-height: 100vh; display: flex; align-items: center; justify-content: center; overflow: auto; background-color: var(--viewer-bg); font-family: var(--font-family); }
    body::after { content: ""; position: fixed; inset: 0; background-image: var(--texture-noise); opacity: 0.04; pointer-events: none; z-index: 0; filter: contrast(120%) brightness(100%); }
    #stage { z-index: 1; }
    __MEDIA_QUERY_CSS__
    #panorama { width: 100%; height: 100%; border-radius: inherit; }
    .pnlm-controls-container, .pnlm-zoom-controls, .pnlm-fullscreen-toggle-button, .pnlm-zoom-in, .pnlm-zoom-out, .pnlm-controls { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }
    .watermark { position: absolute; bottom: 25px; right: 25px; z-index: 10; pointer-events: none; background: rgba(255, 255, 255, 0.1); backdrop-filter: blur(5px); -webkit-backdrop-filter: blur(5px); padding: 6px; border-radius: 8px; display: flex; align-items: center; justify-content: center; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
    .watermark img { height: __LOGO_SIZE__px; width: auto; display: block; object-fit: contain; border-radius: 5px; }
    #viewer-floor-nav-export { position: absolute; bottom: 24px; left: 20px; z-index: 5002; display: flex; flex-direction: column-reverse; gap: 8px; align-items: center; pointer-events: none; }
    #viewer-floor-nav-export .floor-nav-btn { width: 32px; height: 32px; min-width: 32px; min-height: 32px; border-radius: 9999px; font-size: 15px; font-weight: 500; line-height: 1; display: inline-flex; align-items: center; justify-content: center; transition: all 0.2s ease; box-sizing: border-box; user-select: none; }
    #viewer-floor-nav-export .floor-nav-btn.state-active { border: 2px solid #ea580c; background: #ea580c; color: #fff; }
    #viewer-floor-nav-export .floor-nav-btn.state-idle { border: 1px solid rgba(255, 255, 255, 0.28); background: rgba(128, 128, 128, 0.22); color: #fff; }
    #viewer-floor-nav-export .floor-nav-btn sup { font-size: 10px; margin-left: -1px; }
    .viewer-persistent-label-export { position: absolute; top: 24px; left: 50%; transform: translateX(-50%); z-index: 6005; background-color: rgba(0, 61, 165, 0.85); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); color: #fff; padding: 0 0.5rem; height: 27px; border-radius: 6px; font-family: var(--font-family); font-size: 11px; font-weight: 600; text-transform: uppercase; display: flex; align-items: center; justify-content: center; transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1); pointer-events: none; border: 1px solid rgba(255, 255, 255, 0.1); letter-spacing: 0.1em; white-space: nowrap; }
    .viewer-persistent-label-export.state-visible { opacity: 1; transform: translateX(-50%) translateY(0) scale(1); visibility: visible; }
    .viewer-persistent-label-export.state-hidden { opacity: 0; transform: translateX(-50%) translateY(-1rem) scale(0.9); visibility: hidden; pointer-events: none; }
    .viewer-persistent-label-export.state-shortcut-animate { animation: room-label-shortcut-rise 0.42s cubic-bezier(0.16, 1, 0.3, 1); }
    @keyframes room-label-shortcut-rise {
      0% { opacity: 0.25; transform: translateX(-50%) translateY(10px) scale(0.94); }
      100% { opacity: 1; transform: translateX(-50%) translateY(0) scale(1); }
    }
    #viewer-floor-tags-export { position: relative; z-index: 6006; display: flex; flex-direction: column; align-items: flex-start; gap: 6px; pointer-events: auto; user-select: none; margin-top: 14px; }
    #viewer-floor-tags-export.state-hidden { display: none; }
    #viewer-floor-tags-export .floor-tag-shortcut-row { width: auto; display: grid; grid-template-columns: 1.45em minmax(0, 1fr); align-items: start; justify-items: start; column-gap: 8px; color: #ffffff; font-family: var(--font-family); font-size: 14px; font-weight: 600; line-height: 1.25; border: none; background: transparent; padding: 0; margin: 0; cursor: pointer; pointer-events: auto; text-align: left; text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000; }
    #viewer-floor-tags-export .floor-tag-shortcut-row:hover { transform: translateX(2px); transition: all 0.2s ease; }
    #viewer-floor-tags-export .floor-tag-shortcut-index { font-weight: 800; text-align: left; }
    #viewer-floor-tags-export .floor-tag-shortcut-label { font-weight: 400; letter-spacing: 0.01em; text-transform: none; text-align: left; white-space: normal; overflow-wrap: anywhere; }
    @keyframes glow-sequence { 0%, 100% { fill-opacity: 0; filter: brightness(1); } 10%, 30% { fill-opacity: 0.8; filter: brightness(1.5); } 40% { fill-opacity: 0; filter: brightness(1); } }
    @keyframes diagonal-sweep { 0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); } 20%, 100% { transform: translateX(100%) translateY(100%) rotate(45deg); } }
    .pnlm-hotspot.flat-arrow { display: block !important; background: rgba(255, 255, 255, 0.01) !important; border: 1px solid transparent !important; padding: 0 !important; pointer-events: auto !important; width: __BASE_SIZE__px !important; height: __BASE_SIZE__px !important; margin-left: -__BASE_SIZE_HALF__px !important; margin-top: -__BASE_SIZE_HALF__px !important; overflow: visible !important; cursor: pointer; z-index: 2000 !important; }
    .pnlm-hotspot.flat-arrow.waypoint-pending { opacity: 0 !important; pointer-events: auto !important; cursor: pointer !important; transform: scale(0.82); }
    .pnlm-hotspot.flat-arrow.waypoint-ready { opacity: 1 !important; pointer-events: auto !important; transform: scale(1); transition: opacity 0.24s ease, transform 0.24s ease; }
    .custom-arrow-svg { width: 100% !important; height: 100% !important; display: block; pointer-events: none; transform: none; transform-origin: center center; transition: transform 0.2s ease; filter: drop-shadow(0 8px 4px rgba(0,0,0,0.35)); }
    .export-hotspot-root { position: relative; width: 32px; height: 32px; }
    .export-hotspot-btn { position: absolute; inset: 0; background: #ea580c; border-radius: 10px; box-shadow: 0 10px 16px rgba(0,0,0,0.35); display: flex; align-items: center; justify-content: center; overflow: hidden; transition: background-color 0.2s ease, transform 0.2s ease, filter 0.2s ease; pointer-events: auto; cursor: pointer; }
    .export-hotspot-btn:hover { background: #f97316; transform: scale(1.03); filter: brightness(1.04); }
    .export-hotspot-btn-sweep { position: absolute; inset: 0; background: linear-gradient(to bottom, transparent, rgba(255,255,255,0.25), transparent); pointer-events: none; transform: scale(2); animation: diagonal-sweep var(--sweep-duration, 4s) ease-in-out infinite; }
    .export-hotspot-root.auto-forward .export-hotspot-btn-sweep { --sweep-duration: 1.5s; }
    .export-hotspot-root.auto-forward .export-hotspot-btn { background: #4B0082; }
    .export-hotspot-root.auto-forward .export-hotspot-btn:hover { background: #5D3FD3; }
    .export-hotspot-icon { position: relative; z-index: 2; width: 20px; height: 20px; overflow: visible; }
    .export-hotspot-icon path { stroke: white; stroke-width: 3.0; fill: none; stroke-linecap: round; stroke-linejoin: round; }
    .glow-unit { fill-opacity: 0; fill: var(--glow-color); }
    .glow-bottom { animation: glow-sequence 1.8s infinite; }
    .glow-top { animation: glow-sequence 1.8s infinite; animation-delay: 0.4s; }
    .pnlm-hotspot.flat-arrow:hover .custom-arrow-svg { animation: none; transform: scale(1.08); filter: drop-shadow(0 10px 10px rgba(0,0,0,0.35)); }
    .pnlm-load-box, .pnlm-lbox, .pnlm-lmsg, .pnlm-lbar, .pnlm-ltext, .pnlm-loading-container, [class^="pnlm-l"], [class*="loading"] { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }
    .pnlm-hotspot.flat-arrow[data-target-home] { perspective: none !important; transform-style: flat !important; }
    .pnlm-hotspot.flat-arrow[data-target-home] .custom-arrow-svg { transform: none !important; animation: home-pulse 2s infinite ease-in-out !important; }
    @keyframes home-pulse { 0% { transform: scale(1); } 50% { transform: scale(1.1); } 100% { transform: scale(1); } }
    body.export-state-portrait { padding: var(--export-fallback-padding); box-sizing: border-box; }
    body.export-state-portrait #stage { width: min(calc((100dvh - (var(--export-fallback-padding) * 2)) * 9 / 16), calc(100vw - (var(--export-fallback-padding) * 2)), 375px) !important; min-width: 0 !important; max-width: calc(100vw - (var(--export-fallback-padding) * 2)) !important; aspect-ratio: 9 / 16 !important; border-radius: 12px !important; border: 1px solid #b44409 !important; box-shadow: none !important; max-height: calc(100dvh - (var(--export-fallback-padding) * 2)) !important; }
    body.is-hd-export #viewer-floor-nav-export, body.export-state-tablet #viewer-floor-nav-export, body.export-state-portrait #viewer-floor-nav-export { bottom: 10px; left: 8px; gap: 8px; }
    body.is-hd-export #viewer-floor-nav-export .floor-nav-btn, body.export-state-tablet #viewer-floor-nav-export .floor-nav-btn, body.export-state-portrait #viewer-floor-nav-export .floor-nav-btn { width: 24px; height: 24px; min-width: 24px; min-height: 24px; font-size: 9.36px; }
    body.is-hd-export #viewer-floor-nav-export .floor-nav-btn sup, body.export-state-tablet #viewer-floor-nav-export .floor-nav-btn sup, body.export-state-portrait #viewer-floor-nav-export .floor-nav-btn sup { font-size: 5.8px; margin-left: 0; }
    body.is-hd-export .viewer-persistent-label-export, body.export-state-tablet .viewer-persistent-label-export, body.export-state-portrait .viewer-persistent-label-export { top: 10px; height: 22px; font-size: 9px; padding: 0 0.35rem; border-radius: 5px; letter-spacing: 0.06em; }
    body.is-hd-export #viewer-floor-tags-export, body.export-state-tablet #viewer-floor-tags-export, body.export-state-portrait #viewer-floor-tags-export { width: min(113px, calc(100vw - 24px)); gap: 3px; margin-top: 7px; }
    body.is-hd-export #viewer-floor-tags-export .floor-tag-shortcut-row, body.export-state-tablet #viewer-floor-tags-export .floor-tag-shortcut-row, body.export-state-portrait #viewer-floor-tags-export .floor-tag-shortcut-row { font-size: 11px; grid-template-columns: 1.35em minmax(0, 1fr); column-gap: 4px; }
    body.is-hd-export .watermark, body.export-state-tablet .watermark, body.export-state-portrait .watermark { bottom: 10px; right: 10px; padding: 2px; border-radius: 6px; }

    body.is-hd-export .export-hotspot-root, body.export-state-tablet .export-hotspot-root, body.export-state-portrait .export-hotspot-root { width: 26px; height: 26px; }
    body.is-hd-export .export-hotspot-icon, body.export-state-tablet .export-hotspot-icon, body.export-state-portrait .export-hotspot-icon { width: 15px; height: 15px; }

    /* Lazy Drift Cursor */
    .pnlm-container { cursor: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='%23ffffff' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M5 9l-3 3 3 3M9 5l3-3 3 3M19 9l3 3-3 3M9 19l3 3 3-3M2 12h20M12 2v20'/%3E%3C/svg%3E") 12 12, move; }
    .pnlm-grab { cursor: inherit !important; }
    .pnlm-grabbing { cursor: grabbing !important; }
    /* Looking Mode Indicator */
    .looking-mode-indicator { position: absolute; top: 24px; left: 20px; z-index: 6005; display: flex; flex-direction: row; align-items: flex-start; gap: 10px; pointer-events: none; user-select: none; transition: opacity 0.3s ease; padding: 12px; width: 174px; height: 131.7px; border-radius: 12px; background: rgba(0, 20, 60, 0.45); border: 1px solid rgba(255, 255, 255, 0.12); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); box-shadow: 0 4px 16px rgba(0,0,0,0.2); }
    .mode-label-group { display: flex; flex-direction: column; align-items: flex-start; gap: 2px; color: #ffffff; text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000; }
    .mode-dot { width: 8px; height: 8px; min-width: 8px; min-height: 8px; border-radius: 50%; background-color: #10b981; box-shadow: 0 0 6px rgba(16, 185, 129, 0.5), 0 0 0 1.5px rgba(0,0,0,0.6); transition: background-color 0.3s ease, box-shadow 0.3s ease; margin-top: 5px; }
    .mode-dot.paused { background-color: #f97316; box-shadow: 0 0 8px rgba(249, 115, 22, 0.4), 0 0 0 1.5px rgba(0,0,0,0.6); }
    .mode-title { font-size: 13px; font-weight: 600; line-height: 1.2; }
    .mode-subtitle { font-size: 11px; font-weight: 400; opacity: 0.86; line-height: 1.2; }
    .mode-shortcut-key { font-size: 13px; font-weight: 700; }
    .pnlm-container.mode-paused { cursor: default !important; }
    .pnlm-grab.mode-paused, .pnlm-grabbing.mode-paused { cursor: grab !important; }
    body.is-hd-export .looking-mode-indicator, body.export-state-tablet .looking-mode-indicator, body.export-state-portrait .looking-mode-indicator { top: 10px; left: 8px; padding: 10px; width: 135px; height: 103px; border-radius: 10px; gap: 8px; }
    body.is-hd-export .mode-title, body.export-state-tablet .mode-title, body.export-state-portrait .mode-title { font-size: 11px; }
    body.is-hd-export .mode-subtitle, body.export-state-tablet .mode-subtitle, body.export-state-portrait .mode-subtitle { font-size: 10px; }
    body.is-hd-export .mode-shortcut-key, body.export-state-tablet .mode-shortcut-key, body.export-state-portrait .mode-shortcut-key { font-size: 12px; }
  `

let generateCSS = (firstSceneName, exportType, baseSize, logoSize) => {
  let mediaQuery = switch exportType {
  | "4k" => ` #stage { position: relative; margin: 0 auto; width: 1024px; max-width: calc((90dvh - 10px) * 16 / 10); height: auto; aspect-ratio: 16/10; max-height: 90vh; background: #1a202c; border-radius: 8px; border: 1px solid #b44409; box-shadow: none; overflow: hidden; } body.export-state-tablet #stage { width: 640px; max-width: calc((90dvh - 10px) * 16 / 10); } `
  | "2k" => ` #stage { position: relative; margin: 0 auto; width: 832px; max-width: calc((90dvh - 10px) * 16 / 10); height: auto; aspect-ratio: 16/10; max-height: 90vh; background: #1a202c; border-radius: 8px; border: 1px solid #b44409; box-shadow: none; overflow: hidden; } body.export-state-tablet #stage { width: 640px; max-width: calc((90dvh - 10px) * 16 / 10); } `
  | _ => ` #stage { position: relative; margin: 0 auto; width: 640px; max-width: calc((90dvh - 10px) * 16 / 10); height: auto; aspect-ratio: 16/10; max-height: 90vh; background: #1a202c; border-radius: 8px; border: 1px solid #b44409; box-shadow: none; overflow: hidden; } `
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
