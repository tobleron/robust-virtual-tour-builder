// src/systems/Exporter.js

async function resizeImage(file, width) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      const canvas = document.createElement("canvas");
      const scale = width / img.width;
      canvas.width = width;
      canvas.height = img.height * scale;
      [span_3](start_span)const ctx = canvas.getContext("2d");[span_3](end_span)
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = "high";
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      canvas.toBlob((blob) => {
        URL.revokeObjectURL(url);
        resolve(blob);
      [span_4](start_span)}, "image/webp", 0.92);[span_4](end_span)
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Failed to load image for resizing"));
    };
    img.src = url;
  });
}

async function fetchLib(filename) {
  const response = await fetch(`src/libs/${filename}`);
  [span_5](start_span)if (!response.ok) throw new Error(`Missing Library: ${filename}`);[span_5](end_span)
  return await response.blob();
}

export async function exportTour(scenes) {
  const { store } = await import("../store.js");
  const tourName = store.state.tourName || [span_6](start_span)"Virtual_Tour";[span_6](end_span)
  const safeName = tourName.replace(/[^a-z0-9]/gi, "_").toLowerCase();

  const zip = new JSZip();
  const f4k = zip.folder("tour_4k");
  const f2k = zip.folder("tour_2k");
  [span_7](start_span)const fhd = zip.folder("tour_hd");[span_7](end_span)

  const folders = [f4k, f2k, fhd];
  folders.forEach((f) => {
    f.folder("assets");
    f.folder("libs");
  });

  try {
    [span_8](start_span)const panJS = await fetchLib("pannellum.js");[span_8](end_span)
    const panCSS = await fetchLib("pannellum.css");
    folders.forEach((f) => {
      f.folder("libs").file("pannellum.js", panJS);
      f.folder("libs").file("pannellum.css", panCSS);
    });
  } catch (e) {
    alert("Error bundling libraries: " + e.message);
    return;
  }

  let logoBlob = null;
  try {
    [span_9](start_span)const response = await fetch("images/logo.png");[span_9](end_span)
    if (response.ok) {
      logoBlob = await response.blob();
      folders.forEach((f) => {
        f.folder("assets").file("logo.png", logoBlob);
      });
    }
  } catch (e) {
    console.warn("Logo not found");
  }

  for (const s of scenes) {
    [span_10](start_span)const sourceFile = s.originalFile || s.file;[span_10](end_span)
    try {
      const blob4k = await resizeImage(sourceFile, 4096);
      f4k.folder("assets").file(`images/${s.name}`, blob4k);
      const blob2k = await resizeImage(sourceFile, 2048);
      f2k.folder("assets").file(`images/${s.name}`, blob2k);
      const blobHD = await resizeImage(sourceFile, 1280);
      fhd.folder("assets").file(`images/${s.name}`, blobHD);
    } catch (err) {
      folders.forEach(f => f.folder("assets").file(`images/${s.name}`, sourceFile));
    }
  }

  const generateHTML = (maxW) => {
    const firstSceneName = scenes[0].name;
    const rawScenesData = {};
    scenes.forEach((s) => {
      rawScenesData[s.name] = {
        panorama: `assets/images/${s.name}`,
        autoLoad: true,
        hotSpots: s.hotspots.map((h) => ({
          pitch: h.pitch,
          yaw: h.yaw,
          target: h.target,
          viewFrame: h.viewFrame || null,
        })),
      };
    });

    const customCSS = `
            body { 
                margin: 0; padding: 0; width: 100%; height: 100%; 
                display: flex; align-items: center; justify-content: center;
                overflow: hidden; background-color: #111;
            }
            
            body::before {
                content: ""; position: fixed;
                top: -20px; left: -20px; right: -20px; bottom: -20px;
                background: url('assets/images/${firstSceneName}') no-repeat center center fixed;
                background-size: cover; filter: blur(25px) brightness(0.4);
                z-index: -1;
            }

            #stage {
                position: relative; width: 100%; height: 100%;
                max-width: ${maxW}; max-height: 90vh;
                aspect-ratio: 16/9; box-shadow: 0 20px 50px rgba(0,0,0,0.8);
                border-radius: 8px; overflow: hidden; background: #000;
            }

            @media (max-width: 600px) {
                #stage { max-width: 100%; max-height: 100%; border-radius: 0; aspect-ratio: auto; }
            }
            
            #panorama { width: 100%; height: 100%; }

            @keyframes gentle-pulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.1); }
                100% { transform: scale(1); }
            }

            /* FORCE SPECIFICITY TO OVERRIDE LIB DEFAULTS */
            div.pnlm-hotspot.flat-arrow {
                display: block !important;
                background: none !important;
                border: none !important;
                padding: 0 !important;
                
                /* DESKTOP SIZE */
                width: 60px !important;
                height: 60px !important;
                margin-left: -30px !important;
                margin-top: -30px !important;
                overflow: visible !important;
                cursor: pointer;
                z-index: 50;
            }

            @media (max-width: 600px) {
                div.pnlm-hotspot.flat-arrow {
                    /* MOBILE SIZE (SIZE A - 40px) */
                    width: 40px !important;
                    height: 40px !important;
                    margin-left: -20px !important;
                    margin-top: -20px !important;
                }
            }

            .custom-arrow-svg {
                width: 100% !important;
                height: 100% !important;
                display: block;
                transform: rotateX(70deg); 
                animation: gentle-pulse 3s infinite ease-in-out;
                transform-origin: center center;
                transition: transform 0.3s;
                filter: drop-shadow(0 5px 3px rgba(0,0,0,0.7));
            }

            div.pnlm-hotspot.flat-arrow:hover .custom-arrow-svg {
                animation: none;
                transform: rotateX(45deg) translateY(-10px) scale(1.1);
                filter: drop-shadow(0 15px 8px rgba(0,0,0,0.5));
            }

            .watermark { 
                position: absolute; bottom: 20px; right: 20px; 
                z-index: 10; pointer-events: none; opacity: 0.9;
            }
            .watermark img { height: 50px; width: auto; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5)); }
        `;

    const renderFunctionScript = `
            function renderGoldArrow(hotSpotDiv, args) {
                hotSpotDiv.innerHTML = \`
                    <svg class="custom-arrow-svg" viewBox="0 0 100 100" style="overflow:visible;">
                        <defs>
                            <linearGradient id="goldGradient_\${Math.floor(Math.random() * 10000)}" x1="0%" y1="0%" x2="100%" y2="100%">
                                <stop offset="0%" style="stop-color:#BF953F;stop-opacity:1" />
                                <stop offset="50%" style="stop-color:#FCF6BA;stop-opacity:1" />
                                <stop offset="100%" style="stop-color:#B38728;stop-opacity:1" />
                            </linearGradient>
                        </defs>
                        <g stroke="#5e4b25" stroke-width="14" fill="none" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M15 65 L50 30 L85 65" /><path d="M15 90 L50 55 L85 90" />
                        </g>
                        <g stroke="url(#goldGradient)" stroke-width="10" fill="none" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M15 65 L50 30 L85 65" /><path d="M15 90 L50 55 L85 90" />
                        </g>
                        <circle cx="50" cy="50" r="50" fill="transparent" /> 
                    </svg>
                \`;
                const gradId = hotSpotDiv.querySelector('linearGradient').id;
                hotSpotDiv.querySelectorAll('g[stroke^="url(#"]').forEach(g => {
                    g.setAttribute('stroke', 'url(#' + gradId + ')');
                });
                hotSpotDiv.onclick = function() {
                    let lookPitch = 0, lookYaw = args.yaw; 
                    if (args.viewFrame) { lookPitch = args.viewFrame.pitch; lookYaw = args.viewFrame.yaw; }
                    window.viewer.lookAt(lookPitch, lookYaw, 40, 800);
                    setTimeout(() => { window.viewer.loadScene(args.targetSceneId, "same", "same", "same"); }, 800);
                };
            }
        `;

    return `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="libs/pannellum.css"/><script src="libs/pannellum.js"></script><style>${customCSS}</style></head><body><div id="stage"><div id="panorama"></div>${logoBlob ? '<div class="watermark"><img src="assets/logo.png"></div>' : ""}</div><script>${renderFunctionScript} const config = {"default":{"firstScene":"${scenes[0].name}","sceneFadeDuration":1000,"autoRotate":0},"scenes":{}}; const scenesData = ${JSON.stringify(rawScenesData)}; for (const [name, data] of Object.entries(scenesData)) { config.scenes[name] = { panorama: data.panorama, autoLoad: true, hotSpots: data.hotSpots.map(h => ({ pitch: h.pitch, yaw: h.yaw, type: "info", cssClass: "flat-arrow", createTooltipFunc: renderGoldArrow, createTooltipArgs: { targetSceneId: h.target, yaw: h.yaw, viewFrame: h.viewFrame } })) }; } window.viewer = pannellum.viewer('panorama', config);</script></body></html>`;
  };

  f4k.file("index.html", generateHTML("1600px"));
  f2k.file("index.html", generateHTML("1100px"));
  fhd.file("index.html", generateHTML("500px"));

  zip.file("embed_codes.txt", `REMAX VIRTUAL TOUR - EMBED CODES\n\n1. 4K: <iframe src="tour_4k/index.html" width="100%" height="900"></iframe>\n2. 2K: <iframe src="tour_2k/index.html" width="100%" height="700"></iframe>\n3. HD: <iframe src="tour_hd/index.html" width="100%" height="600"></iframe>`);
  
  const content = await zip.generateAsync({ type: "blob" });
  saveAs(content, `Remax_${safeName}_Ambient_v10.zip`);
}
