// src/components/Simulator.js

const style = document.createElement("style");
style.innerHTML = `
    /* 1. BASE SIMULATOR STYLES */
    body.sim-mode { overflow: hidden; }
    body.sim-mode #sidebar { display: none !important; }
    body.sim-mode #btn-record, body.sim-mode #btn-teaser { opacity: 0; pointer-events: none; }
    
    #sim-overlay {
        display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(10, 10, 10, 0.95); z-index: 9990;
        align-items: center; justify-content: center;
    }
    body.sim-mode #sim-overlay { display: flex !important; }

    /* 2. VIEWER CONTAINER (Default Portrait) */
    body.sim-mode #viewer-container {
        position: fixed !important; z-index: 9995;
        box-shadow: 0 0 50px rgba(0,0,0,0.8); border: 4px solid #333; border-radius: 8px;
        top: 0 !important; bottom: 0 !important; left: 0 !important; right: 0 !important;
        margin: auto !important;
        transition: all 0.3s ease;
    }
    
    body.sim-desktop #viewer-container { width: 80vw; height: auto; aspect-ratio: 16/9; max-height: 80vh; }
    body.sim-mobile #viewer-container { width: 340px; height: 600px; aspect-ratio: unset; }

    /* 3. CONTROLS (Default Portrait: Bottom Center) */
    .sim-controls {
        position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%);
        z-index: 2147483647;
        background: rgba(0, 0, 0, 0.8); padding: 12px 25px;
        border-radius: 50px; backdrop-filter: blur(10px); display: flex; gap: 15px;
        border: 1px solid rgba(255,255,255,0.2);
        box-shadow: 0 10px 30px rgba(0,0,0,0.5);
        flex-direction: row;
    }

    /* 4. LANDSCAPE FIX (Buttons Left, Viewer Centered in Remaining Space) */
    @media (orientation: landscape) {
        /* Stack buttons on the left */
        .sim-controls {
            bottom: auto; left: 20px; top: 50%; 
            transform: translateY(-50%);
            flex-direction: column;
            width: auto;
            padding: 20px 12px; 
        }
        
        /* Center Viewer relative to the EMPTY SPACE on the right */
        body.sim-mode #viewer-container {
            margin: 0 !important;
            top: 50% !important;
            
            /* Shift center point to the right to account for buttons */
            left: calc(50% + 50px) !important; 
            transform: translate(-50%, -50%) !important;
            
            /* Ensure it fits */
            max-width: 70vw !important;  
            max-height: 85vh !important;
        }
    }

    .sim-btn {
        background: transparent; border: 1px solid rgba(255,255,255,0.4); color: white;
        padding: 10px 20px; border-radius: 20px; cursor: pointer; font-weight: bold; font-size: 13px; transition: 0.2s; white-space: nowrap;
    }
    .sim-btn:hover { background: rgba(255,255,255,0.2); transform: translateY(-2px); }
    .sim-btn.active { background: #003da5; border-color: #003da5; color: white; box-shadow: 0 0 10px #003da5; }
    .sim-btn.exit-btn { background: #dc3545; border-color: #dc3545; }
`;
document.head.appendChild(style);

export const Simulator = {
  init() {
    if (document.getElementById("sim-overlay")) return;
    const simOverlay = document.createElement("div");
    simOverlay.id = "sim-overlay";
    simOverlay.innerHTML = `
            <div class="sim-controls">
                <button class="sim-btn active" id="sim-desktop">Desktop (16:9)</button>
                <button class="sim-btn" id="sim-mobile">Mobile</button>
                <button class="sim-btn exit-btn" id="sim-exit">Exit</button>
            </div>
        `;
    document.body.appendChild(simOverlay);
    document.getElementById("sim-desktop").onclick = () =>
      this.setMode("desktop");
    document.getElementById("sim-mobile").onclick = () =>
      this.setMode("mobile");
    document.getElementById("sim-exit").onclick = () => this.exit();
  },
  open() {
    this.init();
    this.setMode("desktop");
    document.body.classList.add("sim-mode");
    setTimeout(() => {
      if (window.pannellumViewer) window.pannellumViewer.resize();
    }, 350);
  },
  setMode(mode) {
    document.body.classList.remove("sim-desktop", "sim-mobile");
    document.body.classList.add(`sim-${mode}`);
    document
      .getElementById("sim-desktop")
      .classList.toggle("active", mode === "desktop");
    document
      .getElementById("sim-mobile")
      .classList.toggle("active", mode === "mobile");
    setTimeout(() => {
      if (window.pannellumViewer) window.pannellumViewer.resize();
    }, 350);
  },
  exit() {
    document.body.classList.remove("sim-mode", "sim-desktop", "sim-mobile");
    setTimeout(() => {
      if (window.pannellumViewer) window.pannellumViewer.resize();
    }, 350);
  },
};
