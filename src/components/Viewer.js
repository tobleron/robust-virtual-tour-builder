import { store } from "../store.js";

let viewer = null;
let mediaRecorder = null;
let recordedChunks = [];
let isRecording = false;

export function initViewer() {
  const viewerContainer = document.getElementById("viewer-container");

  // --- 1. CSS INJECTION ---
  const oldStyle = document.getElementById("viewer-styles");
  if (oldStyle) oldStyle.remove();

  const style = document.createElement("style");
  style.id = "viewer-styles";
  style.innerHTML = `
        /* ANIMATION DEFINITION: Clean Mechanical Pulse (No Glow) */
        @keyframes gentle-pulse {
            0% { transform: rotateX(60deg) scale(1); }
            50% { transform: rotateX(60deg) scale(1.1); }
            100% { transform: rotateX(60deg) scale(1); }
        }

        /* Container */
        .pnlm-hotspot.flat-arrow {
            overflow: visible !important;
            background: none !important;
            border: none !important;
            
            /* SIZE: 90px */
            width: 90px !important;
            height: 90px !important;
            margin-left: -45px !important; 
            margin-top: -45px !important;
            
            cursor: pointer;
            perspective: 800px; 
            z-index: 50;
        }

        /* The Graphic */
        .custom-arrow-svg {
            width: 90px !important;
            height: 90px !important;
            display: block;
            
            /* Apply the Animation */
            animation: gentle-pulse 3s infinite ease-in-out;
            transform-origin: center center;
            transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            
            /* STATIC REALISTIC SHADOW (No blinking color) */
            filter: drop-shadow(0 10px 5px rgba(0,0,0,0.5)); 
        }

        /* Hover: STOP animation and Lift */
        .pnlm-hotspot.flat-arrow:hover .custom-arrow-svg {
            animation: none; /* Stop moving so it's easy to click */
            transform: rotateX(60deg) translateY(-10px) scale(1.2);
            /* Slightly deeper shadow on lift, but still black/realistic */
            filter: drop-shadow(0 20px 10px rgba(0,0,0,0.4)); 
        }
        
        /* DELETE BUTTON STYLING */
        .delete-hotspot {
            position: absolute; 
            top: 0; right: 0; 
            width: 24px; height: 24px; 
            background: #dc3545; 
            color: white; 
            border-radius: 50%; 
            display: flex; align-items: center; justify-content: center; 
            cursor: pointer; 
            font-weight: bold; font-size: 16px; font-family: sans-serif;
            z-index: 100; 
            box-shadow: 0 2px 5px rgba(0,0,0,0.3);
            border: 2px solid white;
            transition: transform 0.2s;
        }
        .delete-hotspot:hover {
            transform: scale(1.2);
            background: #bd2130;
        }

        .viewer-watermark {
            position: absolute;
            bottom: 20px; right: 20px; z-index: 10;
            pointer-events: none; opacity: 0.9;
        }
        .viewer-watermark img { height: 50px; width: auto; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5));
        }
    `;
  document.head.appendChild(style);

  if (viewerContainer && !document.getElementById("viewer-watermark")) {
    const logo = document.createElement("div");
    logo.id = "viewer-watermark";
    logo.className = "viewer-watermark";
    logo.innerHTML = `<img src="images/logo.png" alt="Remax">`;
    viewerContainer.appendChild(logo);
  }

  // 2. Global Recording Function
  window.toggleRecording = () => {
    const canvas = document.querySelector(".pnlm-render-container canvas");
    if (!isRecording) {
      if (!canvas) {
        alert("Viewer not ready.");
        return false;
      }
      const stream = canvas.captureStream(60);
      const mimeType = MediaRecorder.isTypeSupported("video/webm;codecs=vp9")
        ? "video/webm;codecs=vp9"
        : "video/webm";
      try {
        mediaRecorder = new MediaRecorder(stream, {
          mimeType,
          videoBitsPerSecond: 8000000,
        });
      } catch (e) {
        alert("Recorder failed: " + e.message);
        return false;
      }
      recordedChunks = [];
      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) recordedChunks.push(e.data);
      };
      mediaRecorder.onstop = () => {
        const blob = new Blob(recordedChunks, { type: "video/webm" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.style.display = "none";
        a.href = url;
        a.download = `Remax_Clip_${Date.now()}.webm`;
        document.body.appendChild(a);
        a.click();
        setTimeout(() => {
          document.body.removeChild(a);
          window.URL.revokeObjectURL(url);
        }, 100);
      };
      mediaRecorder.start();
      isRecording = true;
      if (viewerContainer) viewerContainer.style.border = "5px solid #dc3545";
      return true;
    } else {
      if (mediaRecorder && mediaRecorder.state !== "inactive")
        mediaRecorder.stop();
      isRecording = false;
      if (viewerContainer) viewerContainer.style.border = "none";
      return false;
    }
  };

  // 3. Store Subscription
  store.subscribe((state) => {
    if (state.scenes.length === 0) return;
    const placeholder = document.getElementById("placeholder-text");
    if (placeholder) placeholder.style.display = "none";

    const currentScene = state.scenes[state.activeIndex];
    if (viewer) {
      try {
        viewer.destroy();
      } catch (e) {}
    }

    const reader = new FileReader();
    reader.onload = function (e) {
      viewer = pannellum.viewer("panorama", {
        type: "equirectangular",
        panorama: e.target.result,
        autoLoad: true,
        autoRotate: 0,
        sceneFadeDuration: 0,
        hfov: 85,
        minHfov: 40,
        maxHfov: 100,
        yaw: state.activeYaw,
        // MAP WITH INDEX (i) to allow deletion
        hotSpots: currentScene.hotspots.map((h, i) => ({
          pitch: h.pitch,
          yaw: h.yaw,
          type: "info",
          cssClass: "flat-arrow",
          text: `Go to ${h.target}`,
          createTooltipArgs: { i: i }, // PASS INDEX TO TOOLTIP

          // --- METALLIC GOLD ARROW + DELETE BUTTON ---
          createTooltipFunc: (hotSpotDiv, args) => {
            hotSpotDiv.style.width = "90px";
            hotSpotDiv.style.height = "90px";

            // ONLY SHOW DELETE IF LINKING MODE IS ON
            const deleteBtn = state.isLinking
              ? `<div class="delete-hotspot" title="Delete Link">&times;</div>`
              : "";

            hotSpotDiv.innerHTML = `
                            ${deleteBtn}
                            <svg class="custom-arrow-svg" viewBox="0 0 100 100" width="90" height="90" style="overflow:visible;">
                                <defs>
                                    <linearGradient id="goldGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                                        <stop offset="0%" style="stop-color:#BF953F;stop-opacity:1" />
                                        <stop offset="50%" style="stop-color:#FCF6BA;stop-opacity:1" />
                                        <stop offset="100%" style="stop-color:#B38728;stop-opacity:1" />
                                    </linearGradient>
                                </defs>

                                <g stroke="#5e4b25" stroke-width="14" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M15 65 L50 30 L85 65" />
                                    <path d="M15 90 L50 55 L85 90" />
                                </g>

                                <g stroke="url(#goldGradient)" stroke-width="10" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M15 65 L50 30 L85 65" />
                                    <path d="M15 90 L50 55 L85 90" />
                                </g>
                                
                                <circle cx="50" cy="50" r="50" fill="transparent" /> 
                            </svg>
                        `;

            // 1. DELETE HANDLER
            const delBtn = hotSpotDiv.querySelector(".delete-hotspot");
            if (delBtn) {
              delBtn.onclick = (e) => {
                e.stopPropagation(); // STOP SCENE JUMP
                if (confirm("Remove this link?")) {
                  store.removeHotspot(state.activeIndex, args.i);
                }
              };
            }

            // 2. NAVIGATE HANDLER
            hotSpotDiv.onclick = (e) => {
              // Safety: Do not jump if we clicked the delete button
              if (e.target.classList.contains("delete-hotspot")) return;

              const targetIndex = state.scenes.findIndex(
                (s) => s.name === h.target,
              );
              if (targetIndex !== -1) {
                // --- CLICK FIX: Look at VIEW, not FLOOR ---
                let lookPitch = 0; // Default: Horizon
                let lookYaw = h.yaw;
                if (h.viewFrame) {
                  // Use Saved Director View
                  lookPitch = h.viewFrame.pitch;
                  lookYaw = h.viewFrame.yaw;
                }

                viewer.lookAt(lookPitch, lookYaw, 40, 800);
                setTimeout(() => {
                  store.setActiveScene(targetIndex, h.yaw);
                }, 800);
              }
            };
          },
        })),
      });
      window.pannellumViewer = viewer;

      // Capture Camera for "Director's View"
      viewer.on("mousedown", (event) => {
        const coords = viewer.mouseEventToCoords(event);
        const camPitch = viewer.getPitch();
        const camYaw = viewer.getYaw();
        const camHfov = viewer.getHfov();
        document.dispatchEvent(
          new CustomEvent("viewer-click", {
            detail: {
              pitch: coords[0],
              yaw: coords[1],
              camPitch,
              camYaw,
              camHfov,
            },
          }),
        );
      });
    };
    reader.readAsDataURL(currentScene.file);
  });
}
