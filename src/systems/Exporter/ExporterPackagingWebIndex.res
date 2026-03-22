/* Exporter Packaging Templates - Web Index HTML Generation */

type webIndexConfig = {
  tourName: string,
  version: string,
  logoFilename: option<string>,
  has4k: bool,
  has2k: bool,
}

/* Generate adaptive target JavaScript for web index */
let generateAdaptiveTarget = (~has4k, ~has2k): string => {
  if !(has4k && has2k) {
    let fallbackHref = if has4k {
      "tour_4k/index.html"
    } else if has2k {
      "tour_2k/index.html"
    } else {
      "tour_hd/index.html"
    }
    "'" ++ fallbackHref ++ "'"
  } else {
    `(() => {
        const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
        const coarse = !!(window.matchMedia && (
          window.matchMedia('(pointer: coarse)').matches ||
          window.matchMedia('(any-pointer: coarse)').matches
        ));
        const width = window.innerWidth || 0;
        const height = window.innerHeight || 0;
        const safeViewportWidth = Math.max(width - 10, 0);
        const safeViewportHeight = Math.max(height - 10, 0);
        const estimatePortraitStageWidth = maxWidth =>
          Math.min(
            safeViewportWidth,
            (safeViewportHeight * 9) / 16,
            maxWidth,
          );
        const estimatePortraitHfov = (stageWidth, minHfov) => {
          const portraitMaxHfov = clamp(Math.floor((90 * 0.93) * 10) / 10, minHfov, 90);
          if (stageWidth >= 700) return portraitMaxHfov;
          if (stageWidth >= 600) return clamp(78, minHfov, portraitMaxHfov);
          if (stageWidth >= 480) return clamp(72, minHfov, portraitMaxHfov);
          return minHfov;
        };
        const dpr = clamp(window.devicePixelRatio || 1, 1, 2);
        const estimated2kStageWidth = estimatePortraitStageWidth(493);
        const predicted2kPortraitHfov = estimatePortraitHfov(estimated2kStageWidth, 50);
        const visible2kSourcePixels = 2048 * (predicted2kPortraitHfov / 360);
        const requiredDisplayPixels = estimated2kStageWidth * dpr;
        const qualityAcceptable = visible2kSourcePixels >= requiredDisplayPixels * 0.9;
        if (!coarse || !qualityAcceptable) {
          return 'tour_4k/index.html';
        }
        const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
        const saveData = !!connection?.saveData;
        const effectiveType = typeof connection?.effectiveType === 'string'
          ? connection.effectiveType
          : '';
        const slowNetwork =
          effectiveType === 'slow-2g' ||
          effectiveType === '2g' ||
          effectiveType === '3g';
        const lowMemory =
          typeof navigator.deviceMemory === 'number' && navigator.deviceMemory <= 2;
        return lowMemory || saveData || slowNetwork
          ? 'tour_2k/index.html'
          : 'tour_4k/index.html';
      })()`
  }
}

/* Generate logo block HTML */
let generateLogoBlock = (logoFilename: option<string>): string => {
  switch logoFilename {
  | Some(filename) =>
    `<div style="position:fixed;right:16px;bottom:16px;background:rgba(255,255,255,0.1);padding:5px;border-radius:10px;"><img src="../assets/logo/${filename}" style="height:64px;width:auto;display:block;" /></div>`
  | None => ""
  }
}

/* Generate full web index HTML */
let generateWebIndex = (config: webIndexConfig): string => {
  let {tourName, version, logoFilename, has4k, has2k} = config
  let adaptiveTarget = generateAdaptiveTarget(~has4k, ~has2k)
  let logoBlock = generateLogoBlock(logoFilename)
  let fallbackHref = if has4k {
    "tour_4k/index.html"
  } else if has2k {
    "tour_2k/index.html"
  } else {
    "tour_hd/index.html"
  }

  `<!doctype html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>${tourName}</title></head><body style="margin:0;font-family:Outfit,Arial,sans-serif;background:#0b1931;color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center;"><div style="width:min(92vw,760px);padding:24px;text-align:center;"><h1 style="margin:0 0 16px 0;font-size:32px;">${tourName->String.replaceRegExp(
      /_/g,
      " ",
    )}</h1><p style="margin:0 0 18px 0;color:rgba(255,255,255,0.75);">Adaptive web package v${version}</p><p style="margin:0 0 24px 0;color:rgba(255,255,255,0.68);">4K loads by default, with a 2K fallback only on constrained devices when image detail remains acceptable.</p><a href="${fallbackHref}" style="display:inline-block;padding:14px 18px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">Open Tour</a><noscript><p style="margin:16px 0 0 0;color:rgba(255,255,255,0.6);">JavaScript is disabled, so the default tour entry is being shown.</p></noscript></div><script>window.location.replace(${adaptiveTarget});</script>${logoBlock}</body></html>`
}
