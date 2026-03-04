let cssTemplate = `
    :root { --viewer-bg: #1e1e1e; --stage-border: #333; --glow-color: #fff4d1; --font-family: 'Outfit', sans-serif; --gold-1: #ea580c; --gold-2: #f97316; --gold-3: #c2410c; --gold-text: #ffffff; --gold-border: #7c2d12; --arrow-white: rgba(255, 255, 255, 0.4); --texture-noise: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E"); --export-fallback-padding: 5px; }
    body { margin: 0; padding: 0; width: 100%; min-height: 100vh; display: flex; align-items: center; justify-content: center; overflow: auto; background-color: var(--viewer-bg); font-family: var(--font-family); }
    body::after { content: ""; position: fixed; inset: 0; background-image: var(--texture-noise); opacity: 0.04; pointer-events: none; z-index: 0; filter: contrast(120%) brightness(100%); }
    #stage { z-index: 1; }
    __MEDIA_QUERY_CSS__
    #panorama { width: 100%; height: 100%; border-radius: inherit; background-image: url("__FIRST_SCENE_BACKGROUND_URL__"); background-size: cover; background-position: center; }
    .pnlm-controls-container, .pnlm-zoom-controls, .pnlm-fullscreen-toggle-button, .pnlm-zoom-in, .pnlm-zoom-out, .pnlm-controls { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }
    .watermark { position: absolute; bottom: 22px; right: 24px; z-index: 10; pointer-events: none; display: flex; align-items: center; justify-content: center; overflow: visible; }
    .watermark img { height: __LOGO_SIZE__px; width: auto; display: block; object-fit: contain; filter: drop-shadow(1.5px 1.5px 0px rgba(0,0,0,0.95)) drop-shadow(0px 0px 4px rgba(0,0,0,0.25)); }
    #viewer-marketing-banner-export { position: absolute; left: 50%; transform: translateX(-50%); bottom: 0; width: fit-content; max-width: min(84%, 920px); min-height: 29px; align-items: stretch; color: #000; overflow: visible; z-index: 5003; pointer-events: none; display: flex; justify-content: center; }
    .viewer-marketing-chip-export { display: inline-flex; align-items: center; justify-content: center; padding: 5px 9px 4px 9px; font-family: "Open Sans", var(--font-family); font-size: 13px; line-height: 1.2; font-weight: 600; color: #fff; border-top: 1px solid rgba(0, 0, 0, 0.12); border-right: 1px solid rgba(0, 0, 0, 0.12); border-bottom: 1px solid rgba(0, 0, 0, 0.12); }
    .viewer-marketing-chip-rent-export { background: #0e2d52; }
    .viewer-marketing-chip-sale-export { background: #ea580c; }
    .viewer-marketing-chip-left-export { border-top-left-radius: 8px; }
    .viewer-marketing-chip-left-only-export { border-left: 1px solid rgba(0, 0, 0, 0.12); }
    .viewer-marketing-text-wrap-export { position: relative; display: inline-flex; align-items: center; justify-content: center; background: #facc15; padding: 5px 16px 4px 16px; border-top-right-radius: 8px; border-left: 1px solid rgba(0, 0, 0, 0.12); border-top: 1px solid rgba(0, 0, 0, 0.12); border-right: 1px solid rgba(0, 0, 0, 0.12); box-shadow: 0 -1px 8px rgba(0, 0, 0, 0.2); }
    .viewer-marketing-text-wrap-export-left { border-top-left-radius: 8px; }
    .viewer-marketing-text-wrap-export::after { content: ""; position: absolute; left: 15%; right: 15%; bottom: -4px; height: 8px; background: #facc15; border-bottom-left-radius: 999px; border-bottom-right-radius: 999px; border-left: 1px solid rgba(0, 0, 0, 0.12); border-right: 1px solid rgba(0, 0, 0, 0.12); border-bottom: 1px solid rgba(0, 0, 0, 0.12); }
    .viewer-marketing-banner-text-export { font-family: "Open Sans", var(--font-family); font-size: 13px; line-height: 1.2; font-weight: 700; letter-spacing: 0.01em; color: #000; word-break: break-word; }
    #viewer-marketing-portrait-export { display: none; pointer-events: none; }
    .viewer-marketing-portrait-badges-export { display: flex; flex-direction: row; align-items: center; justify-content: flex-end; gap: 4px; }
    .viewer-marketing-portrait-badge-export { display: inline-flex; align-items: center; justify-content: center; min-height: 16px; padding: 2px 7px; border-radius: 6px; color: #fff; font-family: "Open Sans", var(--font-family); font-size: 9px; line-height: 1; font-weight: 700; border: 1px solid rgba(0, 0, 0, 0.14); letter-spacing: 0.02em; }
    .viewer-marketing-portrait-badge-rent-export { background: #0e2d52; }
    .viewer-marketing-portrait-badge-sale-export { background: #ea580c; }
    .viewer-marketing-portrait-phones-export { display: flex; flex-direction: column; align-items: flex-end; gap: 3px; }
    .viewer-marketing-portrait-phone-export { display: inline-flex; align-items: center; justify-content: center; min-height: 18px; padding: 2px 8px; border-radius: 6px; background: #facc15; color: #000; font-family: "Open Sans", var(--font-family); font-size: 10px; line-height: 1.1; font-weight: 700; border: 1px solid rgba(0, 0, 0, 0.12); white-space: nowrap; }
    #viewer-floor-nav-export { position: absolute; bottom: 22px; left: 24px; z-index: 5002; display: flex; flex-direction: column-reverse; gap: 6px; align-items: center; pointer-events: none; }
    #viewer-floor-nav-export .floor-nav-btn { width: 32px; height: 32px; min-width: 32px; min-height: 32px; border-radius: 9999px; font-size: 14px; font-weight: 500; line-height: 1; display: inline-flex; align-items: center; justify-content: center; transition: all 0.2s ease; box-sizing: border-box; user-select: none; }
    #viewer-floor-nav-export .floor-nav-btn.state-active { border: 2px solid #ea580c; background: #ea580c; color: #fff; }
    #viewer-floor-nav-export .floor-nav-btn.state-idle { border: 1px solid rgba(255, 255, 255, 0.28); background: rgba(128, 128, 128, 0.22); color: #fff; }
    #viewer-floor-nav-export .floor-nav-btn sup { font-size: 8px; margin-left: -1px; }
    .viewer-persistent-label-export { position: absolute; top: 22px; left: 50%; transform: translateX(-50%); z-index: 6005; background-color: rgba(0, 61, 165, 0.85); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); color: #fff; padding: 0 0.4rem 0 0; height: 24px; border-radius: 6px; font-family: var(--font-family); font-size: 10.5px; font-weight: 600; text-transform: uppercase; display: flex; align-items: center; justify-content: center; gap: 0; transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1); pointer-events: none; border: 1px solid rgba(255, 255, 255, 0.1); letter-spacing: 0.1em; white-space: nowrap; text-shadow: 1.5px 1.5px 0px rgba(0,0,0,0.95), 0px 0px 4px rgba(0,0,0,0.25); overflow: hidden; }
    .viewer-persistent-label-export-seq { display: inline-flex; align-items: center; justify-content: center; align-self: stretch; min-width: 32px; padding: 0 0.32rem; margin-right: 0.38rem; border-radius: 6px 0 0 6px; background: #0a2a66; color: #ffffff; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; font-size: 10px; font-weight: 800; letter-spacing: 0.02em; line-height: 1; text-transform: none; }
    .viewer-persistent-label-export-name { display: inline-flex; align-items: center; justify-content: center; padding-right: 0.1rem; line-height: 1; letter-spacing: 0.08em; }
    .viewer-persistent-label-export.state-visible { opacity: 1; transform: translateX(-50%) translateY(0) scale(1); visibility: visible; }
    .viewer-persistent-label-export.state-hidden { opacity: 0; transform: translateX(-50%) translateY(-1rem) scale(0.9); visibility: hidden; pointer-events: none; }
    .viewer-persistent-label-export.state-shortcut-animate { animation: room-label-shortcut-rise 0.42s cubic-bezier(0.16, 1, 0.3, 1); }
    @keyframes room-label-shortcut-rise {
      0% { opacity: 0.25; transform: translateX(-50%) translateY(10px) scale(0.94); }
      100% { opacity: 1; transform: translateX(-50%) translateY(0) scale(1); }
    }
    #viewer-floor-tags-export { position: relative; z-index: 6006; display: flex; flex-direction: column; align-items: flex-start; gap: 5px; pointer-events: auto; user-select: none; width: fit-content; border-top: 1px solid rgba(255, 255, 255, 0.08); margin-top: 8px; padding-top: 8px; }
    #viewer-floor-tags-export.state-hidden { display: none; }
    #viewer-floor-tags-export .floor-tag-shortcut-row { width: fit-content; display: grid; grid-template-columns: 8px 1.25em auto; align-items: center; justify-items: start; column-gap: 6px; color: #ffffff; font-family: var(--font-family); font-size: 13px; font-weight: 600; line-height: 1.25; border: none; background: transparent; padding: 0; margin: 0; cursor: pointer; pointer-events: auto; text-align: left; text-shadow: 1.5px 1.5px 0px rgba(0,0,0,0.95), 0px 0px 4px rgba(0,0,0,0.25); }
    .shortcut-indicator-arrow { color: #10b981; opacity: 0; transition: opacity 0.1s ease; display: flex; align-items: center; justify-content: center; width: 8px; height: 1.25em; overflow: visible; }
    .floor-tag-shortcut-row.state-selected .shortcut-indicator-arrow { opacity: 1; }
    .shortcut-indicator-spacer { width: 8px; display: inline-block; }
    #viewer-floor-tags-export .floor-tag-shortcut-row:hover { transform: translateX(2px); transition: all 0.2s ease; }
    #viewer-floor-tags-export .floor-tag-shortcut-index { font-weight: 800; text-align: left; width: 1.45em; display: flex; align-items: center; }
    #viewer-floor-tags-export .floor-tag-shortcut-label { font-weight: 400; letter-spacing: 0.01em; text-transform: none; text-align: left; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    #viewer-floor-tags-export .floor-map-shortcut-row { width: fit-content; max-width: 100%; display: grid; grid-template-columns: 8px 1.1em auto; align-items: center; column-gap: 8px; color: #ffffff; font-family: var(--font-family); font-size: 13px; font-weight: 600; line-height: 1.25; border: none; background: transparent; padding: 0; margin: 0; cursor: pointer; pointer-events: auto; text-align: left; text-shadow: 1.5px 1.5px 0px rgba(0,0,0,0.95), 0px 0px 4px rgba(0,0,0,0.25); }
    #viewer-floor-tags-export .floor-map-shortcut-row:hover { transform: translateX(2px); transition: transform 0.2s ease; }
    #viewer-floor-tags-export .floor-map-shortcut-row.state-selected .shortcut-indicator-arrow { opacity: 1; }
    #viewer-floor-tags-export .floor-map-shortcut-row.state-current { cursor: default; pointer-events: none; }
    #viewer-floor-tags-export .floor-map-shortcut-row.state-current:hover { transform: none; }
    #viewer-floor-tags-export .floor-map-shortcut-key { min-width: 1ch; font-size: 13px; font-weight: 800; text-transform: lowercase; color: #ffffff; }
    #viewer-floor-tags-export .floor-map-shortcut-text { font-weight: 400; letter-spacing: 0.01em; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    #viewer-floor-tags-export .floor-map-shortcut-row-exit .floor-map-shortcut-text { color: #ffffff; }
    #viewer-floor-tags-export .floor-map-shortcut-empty { width: 100%; color: #cbd5e1; font-size: 12.5px; text-transform: lowercase; letter-spacing: 0.01em; }
    @keyframes glow-sequence { 0%, 100% { fill-opacity: 0; filter: brightness(1); } 10%, 30% { fill-opacity: 0.8; filter: brightness(1.5); } 40% { fill-opacity: 0; filter: brightness(1); } }
    @keyframes diagonal-sweep { 0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); } 20%, 100% { transform: translateX(100%) translateY(100%) rotate(45deg); } }
    .pnlm-hotspot.flat-arrow { display: block !important; background: rgba(255, 255, 255, 0.01) !important; border: 1px solid transparent !important; padding: 0 !important; pointer-events: auto !important; width: __BASE_SIZE__px !important; height: __BASE_SIZE__px !important; margin-left: -__BASE_SIZE_HALF__px !important; margin-top: -__BASE_SIZE_HALF__px !important; overflow: visible !important; cursor: pointer; z-index: 2000 !important; }
    .pnlm-hotspot.flat-arrow.waypoint-pending { opacity: 0 !important; pointer-events: auto !important; cursor: pointer !important; transform: scale(0.82); }
    .pnlm-hotspot.flat-arrow.waypoint-ready { opacity: 1 !important; pointer-events: auto !important; transform: scale(1); transition: opacity 0.24s ease, transform 0.24s ease; }
    .custom-arrow-svg { width: 100% !important; height: 100% !important; display: block; pointer-events: none; transform: none; transform-origin: center center; transition: transform 0.2s ease; filter: drop-shadow(0 8px 4px rgba(0,0,0,0.35)); }
    .export-hotspot-root { position: relative; width: 28px; height: 28px; }
    .export-hotspot-label {
      position: absolute;
      top: -34px;
      left: 50%;
      display: inline-flex;
      align-items: center;
      font-size: 13px;
      font-weight: 600;
      letter-spacing: 0.04em;
      line-height: 1;
      color: #ffffff;
      text-shadow: 1.5px 1.5px 0px rgba(0,0,0,0.95), 0px 0px 4px rgba(0,0,0,0.25);
      pointer-events: none;
      white-space: nowrap;
      transform: translateX(-50%);
      z-index: 6100;
      transition: opacity 0.2s ease;
    }
    body.is-auto-tour-active .export-hotspot-label {
      opacity: 0;
    }
    .export-hotspot-btn { position: absolute; inset: 0; background: #ea580c; border-radius: 9px; box-shadow: 0 10px 16px rgba(0,0,0,0.35); display: flex; align-items: center; justify-content: center; overflow: hidden; transition: background-color 0.2s ease, transform 0.2s ease, filter 0.2s ease; pointer-events: auto; cursor: pointer; }
    .export-hotspot-btn:hover { background: #f97316; transform: scale(1.03); filter: brightness(1.04); }
    .export-hotspot-btn-sweep { position: absolute; inset: 0; background: linear-gradient(to bottom, transparent, rgba(255,255,255,0.25), transparent); pointer-events: none; transform: scale(2); animation: diagonal-sweep var(--sweep-duration, 4s) ease-in-out infinite; }
    .export-hotspot-root.auto-forward .export-hotspot-btn-sweep { --sweep-duration: 1.5s; }
    .export-hotspot-face-text { position: relative; z-index: 2; color: #ffffff; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; font-size: 13px; font-weight: 800; letter-spacing: -0.02em; line-height: 1; user-select: none; text-shadow: 0 1px 2px rgba(0,0,0,0.8); }
    .export-hotspot-face-text.is-return { color: #ffffff; text-shadow: 0 1px 2px rgba(0,0,0,0.88); }
    .export-hotspot-icon { position: relative; z-index: 2; width: 18px; height: 18px; overflow: visible; }
    .export-hotspot-icon path { stroke: white; stroke-width: 3.0; fill: none; stroke-linecap: round; stroke-linejoin: round; }
    .glow-unit { fill-opacity: 0; fill: var(--glow-color); }
    .glow-bottom { animation: glow-sequence 1.8s infinite; }
    .glow-top { animation: glow-sequence 1.8s infinite; animation-delay: 0.4s; }
    .pnlm-hotspot.flat-arrow:hover .custom-arrow-svg { animation: none; transform: scale(1.08); filter: drop-shadow(0 10px 10px rgba(0,0,0,0.35)); }
    .pnlm-load-box, .pnlm-lbox, .pnlm-lmsg, .pnlm-lbar, .pnlm-ltext, .pnlm-loading-container, [class^="pnlm-l"], [class*="loading"] { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }
    body.export-state-portrait { padding: var(--export-fallback-padding); box-sizing: border-box; }
    body.export-state-portrait #stage { width: min(calc((100dvh - (var(--export-fallback-padding) * 2)) * 9 / 16), calc(100vw - (var(--export-fallback-padding) * 2)), 375px) !important; min-width: 0 !important; max-width: calc(100vw - (var(--export-fallback-padding) * 2)) !important; aspect-ratio: 9 / 16 !important; border-radius: 12px !important; border: 1px solid #b44409 !important; box-shadow: none !important; max-height: calc(100dvh - (var(--export-fallback-padding) * 2)) !important; }
    body.is-hd-export #viewer-floor-nav-export, body.export-state-tablet #viewer-floor-nav-export { bottom: 12px; left: 13px; gap: 6px; }
    body.is-hd-export #viewer-floor-nav-export .floor-nav-btn, body.export-state-tablet #viewer-floor-nav-export .floor-nav-btn { width: 22px; height: 22px; min-width: 22px; min-height: 22px; font-size: 8.5px; }
    body.is-hd-export #viewer-floor-nav-export .floor-nav-btn sup, body.export-state-tablet #viewer-floor-nav-export .floor-nav-btn sup { font-size: 5.5px; margin-left: 0; }
    body.export-state-tablet #viewer-marketing-banner-export { min-height: 24px; max-width: min(84%, 700px); }
    body.export-state-tablet .viewer-marketing-banner-text-export { font-size: 11px; }
    body.export-state-tablet .viewer-marketing-chip-export { font-size: 11px; padding: 4px 7px 3px 7px; }
    body.export-state-tablet .viewer-marketing-text-wrap-export { padding: 4px 13px 3px 13px; border-top-right-radius: 7px; }
    body.export-state-tablet .viewer-marketing-chip-left-export { border-top-left-radius: 7px; }
    body.export-state-tablet .viewer-marketing-text-wrap-export-left { border-top-left-radius: 7px; }
    body.export-state-tablet .viewer-marketing-text-wrap-export::after { bottom: -3px; height: 6px; }
    body.is-hd-export #viewer-marketing-banner-export { min-height: 19px; max-width: min(82%, 525px); }
    body.is-hd-export .viewer-marketing-banner-text-export { font-size: 9px; }
    body.is-hd-export .viewer-marketing-chip-export { font-size: 9px; padding: 3px 6px 2px 6px; }
    body.is-hd-export .viewer-marketing-text-wrap-export { padding: 3px 10px 2px 10px; border-top-right-radius: 5px; }
    body.is-hd-export .viewer-marketing-chip-left-export { border-top-left-radius: 5px; }
    body.is-hd-export .viewer-marketing-text-wrap-export-left { border-top-left-radius: 5px; }
    body.is-hd-export .viewer-marketing-text-wrap-export::after { bottom: -2px; height: 5px; }
    body.export-state-portrait #viewer-floor-nav-export { bottom: 12px; left: 13px; gap: 8px; }
    body.export-state-portrait #viewer-floor-nav-export .floor-nav-btn { width: 28px; height: 28px; min-width: 28px; min-height: 28px; font-size: 12px; }
    body.export-state-portrait #viewer-floor-nav-export .floor-nav-btn sup { font-size: 7px; margin-left: 0; }
    body.export-state-portrait #viewer-marketing-banner-export { display: none !important; }
    body.export-state-portrait #viewer-marketing-portrait-export { position: absolute; right: 13px; bottom: calc(12px + (__LOGO_SIZE__px * 0.88) + 8px); z-index: 5003; display: flex; flex-direction: column; align-items: flex-end; gap: 4px; max-width: calc(100% - 26px); }
    body.is-hd-export .viewer-persistent-label-export, body.export-state-tablet .viewer-persistent-label-export { top: 12px; height: 20px; font-size: 9px; padding: 0 0.35rem 0 0; border-radius: 5px; letter-spacing: 0.06em; }
    body.export-state-portrait .viewer-persistent-label-export { top: 12px; height: 20px; font-size: 9px; padding: 0 0.35rem 0 0; border-radius: 5px; letter-spacing: 0.06em; left: auto; right: 13px; transform: none; }
    body.export-state-portrait .viewer-persistent-label-export.state-visible { opacity: 1; transform: translateY(0) scale(1); }
    body.export-state-portrait .viewer-persistent-label-export.state-hidden { opacity: 0; transform: translateY(-1rem) scale(0.9); }
    body.is-hd-export #viewer-floor-tags-export, body.export-state-tablet #viewer-floor-tags-export, body.export-state-portrait #viewer-floor-tags-export { width: fit-content; max-width: calc(100vw - 36px); gap: 3px; margin-top: 7px; }
    body.is-hd-export #viewer-floor-tags-export .floor-tag-shortcut-row, body.export-state-tablet #viewer-floor-tags-export .floor-tag-shortcut-row, body.export-state-portrait #viewer-floor-tags-export .floor-tag-shortcut-row { font-size: 11.5px; grid-template-columns: 8px 1.15em minmax(0, 1fr); column-gap: 5px; }
    body.is-hd-export .watermark, body.export-state-tablet .watermark { bottom: 12px; right: 13px; }
    body.export-state-portrait .watermark { bottom: 12px; right: 13px; }
    body.export-state-portrait .watermark img { height: calc(__LOGO_SIZE__px * 0.88); }

    body.is-hd-export .export-hotspot-root, body.export-state-tablet .export-hotspot-root, body.export-state-portrait .export-hotspot-root { width: 24px; height: 24px; }
    body.is-hd-export .export-hotspot-icon, body.export-state-tablet .export-hotspot-icon, body.export-state-portrait .export-hotspot-icon { width: 14px; height: 14px; }

    /* Lazy Drift Cursor */
    .pnlm-container { cursor: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='%23ffffff' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M5 9l-3 3 3 3M9 5l3-3 3 3M19 9l3 3-3 3M9 19l3 3 3-3M2 12h20M12 2v20'/%3E%3C/svg%3E") 12 12, move; }
    .pnlm-grab { cursor: inherit !important; }
    .pnlm-grabbing { cursor: grabbing !important; }
    /* Portrait: no custom cursor (touch/mobile context) */
    body.export-state-portrait .pnlm-container { cursor: default !important; }
    body.export-state-portrait .pnlm-grab { cursor: default !important; }
    body.export-state-portrait .pnlm-grabbing { cursor: grabbing !important; }
    /* Looking Mode Indicator */
    .looking-mode-indicator { position: absolute; top: 22px; left: 24px; z-index: 6005; display: flex; flex-direction: column; align-items: flex-start; gap: 0; pointer-events: none; user-select: none; transition: opacity 0.3s ease, transform 0.45s cubic-bezier(0.22, 1, 0.36, 1), top 0.45s cubic-bezier(0.22, 1, 0.36, 1), left 0.45s cubic-bezier(0.22, 1, 0.36, 1), width 0.45s cubic-bezier(0.22, 1, 0.36, 1), max-width 0.45s cubic-bezier(0.22, 1, 0.36, 1); transform-origin: top left; padding: 12px 20px 12px 12px; width: fit-content; max-width: min(240px, calc(100vw - 16px)); height: auto; border-radius: 12px; background: rgba(0, 20, 60, 0.45); border: 1px solid rgba(255, 255, 255, 0.12); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); box-shadow: 0 4px 16px rgba(0,0,0,0.2); }
    .mode-status-line { display: flex; flex-direction: row; align-items: flex-start; gap: 10px; width: 100%; }
    .mode-label-group { display: flex; flex-direction: column; align-items: flex-start; gap: 2px; color: #ffffff; text-shadow: 1.5px 1.5px 0px rgba(0,0,0,0.95), 0px 0px 4px rgba(0,0,0,0.25); }
    .mode-dot { width: 8px; height: 8px; min-width: 8px; min-height: 8px; border-radius: 50%; background-color: #10b981; transition: background-color 0.3s ease; margin-top: 5px; }
    .mode-dot.paused { background-color: #f97316; }
    .mode-title { font-size: 13px; font-weight: 600; line-height: 1.2; }
    .mode-subtitle { font-size: 11px; font-weight: 400; opacity: 0.86; line-height: 1.2; }
    .mode-shortcut-key { font-size: 13px; font-weight: 700; }
    .pnlm-container.mode-paused { cursor: default !important; }
    .pnlm-grab.mode-paused, .pnlm-grabbing.mode-paused { cursor: grab !important; }
    body.is-hd-export .looking-mode-indicator, body.export-state-tablet .looking-mode-indicator { top: 12px; left: 13px; padding: 10px 16px 10px 10px; width: fit-content; max-width: min(210px, calc(100vw - 28px)); height: auto; border-radius: 10px; gap: 0; }
    body.export-state-portrait .looking-mode-indicator { top: 12px; left: 13px; padding: 10px 16px 10px 10px; width: fit-content; max-width: min(210px, calc(100vw - 28px)); height: auto; border-radius: 10px; gap: 0; }
    body.is-hd-export .mode-status-line, body.export-state-tablet .mode-status-line, body.export-state-portrait .mode-status-line { gap: 8px; }
    body.export-state-portrait .mode-status-line, body.is-auto-tour-active .mode-status-line { display: none !important; }
    body.export-state-portrait .looking-mode-indicator, body.is-auto-tour-active .looking-mode-indicator { padding: 10px 16px 10px 10px !important; }
    body.export-state-portrait #viewer-floor-tags-export, body.is-auto-tour-active #viewer-floor-tags-export { border-top: none !important; margin-top: 0 !important; padding-top: 0 !important; }
    body.is-map-open .mode-status-line { display: none !important; }
    body.is-map-open .looking-mode-indicator { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%) scale(1); pointer-events: auto; width: fit-content; max-width: calc(100% - 16px); max-height: calc(100% - 16px); }
    body.is-map-open #viewer-floor-tags-export { width: fit-content; max-width: 100%; gap: 7px; border-top: none; margin-top: 0; padding-top: 0; overflow: auto; }
    body.export-state-portrait.is-map-open #viewer-floor-tags-export { gap: 6px; }
    body.is-hd-export .mode-title, body.export-state-tablet .mode-title, body.export-state-portrait .mode-title { font-size: 11px; }
    body.is-hd-export .mode-subtitle, body.export-state-tablet .mode-subtitle, body.export-state-portrait .mode-subtitle { font-size: 10px; }
    body.is-hd-export .mode-shortcut-key, body.export-state-tablet .mode-shortcut-key, body.export-state-portrait .mode-shortcut-key { font-size: 12px; }
  `

let generateCSS = (firstSceneName, exportType, baseSize, logoSize) => {
  let firstSceneBackgroundUrl = if String.startsWith(firstSceneName, "data:image") {
    firstSceneName
  } else {
    "../../assets/images/" ++ firstSceneName
  }
  let mediaQuery = switch exportType {
  | "4k" => ` #stage { position: relative; margin: 0 auto; width: 1024px; max-width: calc((90dvh - 10px) * 16 / 10); height: auto; aspect-ratio: 16/10; max-height: 90vh; background: #1a202c; border-radius: 8px; border: 1px solid #b44409; box-shadow: none; overflow: hidden; } body.export-state-tablet #stage { width: 640px; max-width: calc((90dvh - 10px) * 16 / 10); } `
  | "2k" => ` #stage { position: relative; margin: 0 auto; width: 832px; max-width: calc((90dvh - 10px) * 16 / 10); height: auto; aspect-ratio: 16/10; max-height: 90vh; background: #1a202c; border-radius: 8px; border: 1px solid #b44409; box-shadow: none; overflow: hidden; } body.export-state-tablet #stage { width: 640px; max-width: calc((90dvh - 10px) * 16 / 10); } `
  | _ => ` #stage { position: relative; margin: 0 auto; width: 640px; max-width: calc((90dvh - 10px) * 16 / 10); height: auto; aspect-ratio: 16/10; max-height: 90vh; background: #1a202c; border-radius: 8px; border: 1px solid #b44409; box-shadow: none; overflow: hidden; } `
  }
  let baseCss =
    cssTemplate
    ->String.replaceRegExp(/__FIRST_SCENE_BACKGROUND_URL__/g, firstSceneBackgroundUrl)
    ->String.replaceRegExp(/__MEDIA_QUERY_CSS__/g, mediaQuery)
    ->String.replaceRegExp(/__LOGO_SIZE__/g, Belt.Int.toString(logoSize))
    ->String.replaceRegExp(/__BASE_SIZE__/g, Belt.Int.toString(baseSize))
    ->String.replaceRegExp(
      /__BASE_SIZE_HALF__/g,
      Belt.Float.toString(Belt.Int.toFloat(baseSize) /. 2.0),
    )

  switch exportType {
  | "2k" =>
    baseCss ++ `
      #viewer-floor-nav-export { bottom: 18px; left: 20px; gap: 5px; }
      #viewer-floor-nav-export .floor-nav-btn { width: 28px; height: 28px; min-width: 28px; min-height: 28px; font-size: 13px; }
      #viewer-floor-nav-export .floor-nav-btn sup { font-size: 8px; margin-left: 0px; }
      #viewer-marketing-banner-export { min-height: 24px; max-width: min(84%, 700px); }
      .viewer-marketing-banner-text-export { font-size: 11px; }
      .viewer-marketing-chip-export { font-size: 11px; padding: 4px 7px 3px 7px; }
      .viewer-marketing-text-wrap-export { padding: 4px 13px 3px 13px; border-top-right-radius: 7px; }
      .viewer-marketing-chip-left-export { border-top-left-radius: 7px; }
      .viewer-marketing-text-wrap-export-left { border-top-left-radius: 7px; }
      .viewer-marketing-text-wrap-export::after { bottom: -3px; height: 6px; }
      .looking-mode-indicator { top: 18px; left: 20px; padding: 11px 18px 11px 11px; }
      .viewer-persistent-label-export { top: 18px; height: 22px; font-size: 10px; }
      .watermark { bottom: 18px; right: 20px; }
    `
  | _ => baseCss
  }
}
