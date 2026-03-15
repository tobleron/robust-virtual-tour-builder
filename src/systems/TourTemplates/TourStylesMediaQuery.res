/* Tour Templates - CSS Media Query Generation */

type exportProfile = K4k | K2k | Hd

/* Get stage dimensions for export profile */
let getStageDimensions = (profile: exportProfile): (string, string, string) => {
  switch profile {
  | K4k => ("1024px", "607px", "1080px")
  | K2k => ("832px", "493px", "877px")
  | Hd => ("640px", "379px", "675px")
  }
}

/* Generate media query CSS for export profile */
let generateMediaQuery = (profile: exportProfile): string => {
  let (width, _, _) = getStageDimensions(profile)
  ` #stage { position: relative; margin: 0 auto; width: ${width}; max-width: min(calc((100dvh - (var(--export-fallback-padding) * 2)) * 16 / 10), calc(100vw - (var(--export-fallback-padding) * 2))); height: auto; aspect-ratio: 16/10; max-height: calc(100dvh - (var(--export-fallback-padding) * 2)); background: #1a202c; border-radius: 8px; border: 1px solid #b44409; box-shadow: none; overflow: hidden; } `
}

/* Get HD-specific CSS overrides */
let getHdOverrides = (): string => {
  `
    #viewer-floor-nav-export { bottom: 18px; left: 20px; gap: 5px; }
    #viewer-floor-nav-export .floor-nav-btn { width: 28px; height: 28px; min-width: 28px; min-height: 28px; font-size: 13px; }
    #viewer-floor-nav-export .floor-nav-btn sup { font-size: 8px; margin-left: 0px; }
    #viewer-marketing-banner-export { min-height: 24px; max-width: min(84%, 700px); }
    .viewer-marketing-banner-text-export { font-size: clamp(8px, 0.95vw, 11px); }
    .viewer-marketing-chip-export { font-size: 11px; padding: 4px 7px 3px 7px; }
    .viewer-marketing-text-wrap-export { padding: 4px 13px 3px 13px; border-top-right-radius: 7px; }
    .viewer-marketing-chip-left-export { border-top-left-radius: 7px; }
    .viewer-marketing-text-wrap-export-left { border-top-left-radius: 7px; }
    .viewer-marketing-text-wrap-export::after { bottom: -3px; height: 6px; }
    .looking-mode-indicator { top: 18px; left: 20px; padding: 11px 18px 11px 11px; }
    .viewer-persistent-label-export { top: 18px; height: 22px; font-size: 10px; }
    .watermark { bottom: 18px; right: 20px; }
  `
}
