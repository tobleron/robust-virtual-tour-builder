import { store } from "../store.js";
import { exportTour } from "../systems/Exporter.js";
import { processImage } from "../systems/Resizer.js";
import { startAutoTeaser } from "../systems/TeaserSystem.js";
import { Simulator } from "./Simulator.js";

export function initSidebar() {
  const container = document.getElementById("sidebar");
  if (!container) return;

  // Inject Sidebar HTML
  container.innerHTML = `
        <div class="sidebar-header">
            <h2>REMAX Virtual Tour Builder</h2>
            <small>Version 10.0 (Fast Teaser)</small>
        </div>
        
        <div style="padding: 15px; background: #f1f5f9; border-bottom: 1px solid #ddd;">
            <label style="font-size: 11px; font-weight: bold; color: #64748b; text-transform: uppercase;">Property Name</label>
            <input type="text" id="tour-name-input" value="New Virtual Tour" 
                style="width: 100%; box-sizing: border-box; padding: 8px; margin-top: 5px; border: 1px solid #cbd5e1; border-radius: 4px; font-weight: 600; color: #334155;">
        </div>

        <div class="sidebar-content">
            <label class="upload-box" id="upload-label">
                <strong>Upload 360 Images</strong><br>
                <small>Auto-compresses to 4K WebP</small>
                <input type="file" id="file-input" multiple accept="image/*" hidden>
            </label>
            <div id="processing-ui" style="display:none; margin-bottom:20px;">
                <div style="font-weight:bold; color:#003da5; margin-bottom:5px;">Optimizing...</div>
                <div style="background:#eee; height:10px; border-radius:5px; overflow:hidden;">
                    <div id="progress-bar" style="width:0%; height:100%; background:#003da5; transition:width 0.2s;"></div>
                </div>
                <small id="progress-text" style="color:#666;">0/0 processed</small>
            </div>
            <hr style="margin: 20px 0; border: 0; border-top: 1px solid #eee;">
            <div id="scene-list-container"></div>
        </div>
        
        <div style="padding: 15px; border-top: 1px solid #ddd; background: #fff;">
            <button id="btn-link" class="btn btn-primary" disabled style="opacity:0.5; margin-bottom:5px;">Add Link</button>
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:5px; margin-bottom:15px;">
                <button id="btn-preview" class="btn" disabled style="background:#17a2b8; color:white; opacity:0.5;"> Preview</button>
                <button id="btn-export" class="btn" disabled style="background:#28a745; opacity:0.5;">Export</button>
            </div>
            <label style="font-size: 11px; font-weight: bold; color: #64748b; text-transform: uppercase;">Director Tools</label>
            <button id="btn-record" class="btn" disabled style="background:#dc3545; opacity:0.5; margin-top:5px; margin-bottom:5px;">
                 Record Clip (Manual)
            </button>
            <button id="btn-teaser" class="btn" disabled style="background:#6f42c1; color:white; opacity:0.5;">
                 Auto-Teaser (AI)
            </button>
        </div>

        <div id="context-menu" style="display:none; position:fixed; z-index:100; background:white; border:1px solid #ccc; box-shadow:2px 2px 10px rgba(0,0,0,0.2); padding:5px; border-radius:4px;">
            <div id="btn-clear-links" style="padding:8px 15px; cursor:pointer; color:#003da5; font-weight:bold; border-bottom:1px solid #eee;">Clear Links </div>
            <div id="btn-delete-scene" style="padding:8px 15px; cursor:pointer; color:#dc3545; font-weight:bold;">Delete Scene </div>
        </div>
    `;

  // --- ELEMENTS ---
  const fileInput = document.getElementById("file-input");
  const tourNameInput = document.getElementById("tour-name-input");
  const processingUi = document.getElementById("processing-ui");
  const progressBar = document.getElementById("progress-bar");
  const progressText = document.getElementById("progress-text");
  const list = document.getElementById("scene-list-container");
  const contextMenu = document.getElementById("context-menu");
  const btnDelete = document.getElementById("btn-delete-scene");
  const btnClearLinks = document.getElementById("btn-clear-links");

  // Buttons
  const btnLink = document.getElementById("btn-link");
  const btnPreview = document.getElementById("btn-preview");
  const btnExport = document.getElementById("btn-export");
  const btnRecord = document.getElementById("btn-record");
  const btnTeaser = document.getElementById("btn-teaser");
  const viewerContainer = document.getElementById("viewer-container");

  let targetContextIndex = -1;

  // --- BUTTON LOGIC ---
  btnPreview.addEventListener("click", () => Simulator.open());

  // Single Teaser Mode
  btnTeaser.addEventListener("click", () => {
    if (confirm("Start Auto-Director? Please do not touch the mouse.")) {
      startAutoTeaser();
    }
  });

  btnRecord.addEventListener("click", () => {
    if (window.toggleRecording) {
      const isRecordingNow = window.toggleRecording();
      if (isRecordingNow) {
        btnRecord.innerText = " Stop Recording";
        btnRecord.classList.add("blink");
      } else {
        btnRecord.innerText = " Record Clip (Manual)";
        btnRecord.classList.remove("blink");
      }
    }
  });

  // ... Standard Events ...
  tourNameInput.addEventListener("input", (e) =>
    store.setTourName(e.target.value),
  );
  fileInput.addEventListener("change", async (e) => {
    const files = Array.from(e.target.files);
    if (files.length === 0) return;

    document.getElementById("upload-label").style.display = "none";
    processingUi.style.display = "block";

    const sceneDataList = []; // New array to hold pairs

    for (let i = 0; i < files.length; i++) {
      progressText.innerText = `Processing ${i + 1} of ${files.length}`;
      progressBar.style.width = ((i + 1) / files.length) * 100 + "%";

      try {
        // 1. Create the lightweight "Preview" for the browser (Fast)
        const previewFile = await processImage(files[i]);

        // 2. Keep the "Original" for the Exporter (High Quality)
        // We pair them together:
        sceneDataList.push({
          original: files[i],
          preview: previewFile,
          name: previewFile.name,
        });
      } catch (err) {
        console.error(err);
      }
    }

    // Send the PAIRS to the store
    store.addScenes(sceneDataList);

    processingUi.style.display = "none";
    document.getElementById("upload-label").style.display = "block";
    fileInput.value = "";
  });

  document.addEventListener("click", () => {
    contextMenu.style.display = "none";
  });
  btnDelete.addEventListener("click", () => {
    if (targetContextIndex > -1 && confirm("Remove this image?")) {
      store.deleteScene(targetContextIndex);
    }
    contextMenu.style.display = "none";
  });
  btnClearLinks.addEventListener("click", () => {
    if (
      targetContextIndex > -1 &&
      confirm("Clear all links from this image?")
    ) {
      store.clearHotspots(targetContextIndex);
    }
    contextMenu.style.display = "none";
  });
  btnLink.addEventListener("click", () => {
    store.state.isLinking = !store.state.isLinking;
    if (store.state.isLinking) {
      btnLink.classList.add("active");
      btnLink.innerText = "Cancel Link";
      if (viewerContainer) viewerContainer.classList.add("linking-mode");
    } else {
      btnLink.classList.remove("active");
      btnLink.innerText = "Add Link";
      if (viewerContainer) viewerContainer.classList.remove("linking-mode");
    }
  });
  btnExport.addEventListener("click", () => exportTour(store.state.scenes));

  store.subscribe((state) => {
    // 1. Check Linking Mode UI
    if (!state.isLinking) {
      btnLink.classList.remove("active");
      btnLink.innerText = "Add Link";
      if (viewerContainer) viewerContainer.classList.remove("linking-mode");
    } else {
      btnLink.classList.add("active");
      btnLink.innerText = "Cancel Link";
      if (viewerContainer) viewerContainer.classList.add("linking-mode");
    }

    // 2. Handle Empty State
    if (state.scenes.length === 0) {
      list.innerHTML = `<div style="text-align:center; color:#999; font-size:0.9rem; padding:20px;">No scenes loaded.</div>`;
      btnLink.disabled = true;
      btnLink.style.opacity = 0.5;
      btnExport.disabled = true;
      btnExport.style.opacity = 0.5;
      btnRecord.disabled = true;
      btnRecord.style.opacity = 0.5;
      btnTeaser.disabled = true;
      btnTeaser.style.opacity = 0.5;
      btnPreview.disabled = true;
      btnPreview.style.opacity = 0.5;
      return;
    }

    // 3. Render List (Clean Reset)
    list.innerHTML = "";

    state.scenes.forEach((scene, index) => {
      const item = document.createElement("div");
      item.className = `scene-item ${index === state.activeIndex ? "active" : ""}`;

      // Enable dragging
      item.draggable = true;
      item.dataset.index = index;

      const thumbUrl = URL.createObjectURL(scene.file);

      // --- NEW LAYOUT WITH EVENT KILLERS ---
      // 1. Drag Zone: oncontextmenu="return false" blocks the menu
      // 2. Image: pointer-events:none + oncontextmenu blocks interactions
      item.innerHTML = `
                <div class="drag-zone" title="Drag to Reorder" oncontextmenu="event.preventDefault(); return false;">
                    <svg viewBox="0 0 24 24" style="pointer-events:none;">
                        <path d="M9 3H11V21H9V3ZM13 3H15V21H13V3Z" /> 
                    </svg>
                </div>

                <div class="scene-content">
                    <img src="${thumbUrl}" 
                         oncontextmenu="event.preventDefault(); return false;" 
                         style="width:60px; height:40px; object-fit:cover; border-radius:4px; background:#ddd; box-shadow:0 1px 3px rgba(0,0,0,0.1); pointer-events:none; -webkit-touch-callout:none;">
                    
                    <div style="overflow:hidden; display:flex; flex-direction:column; justify-content:center;">
                        <span style="overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; font-size:14px; color:#333;">
                            ${scene.name}
                        </span>
                        <span style="font-size:11px; color:#64748b; margin-top:2px;">
                            ${scene.hotspots.length} links
                        </span>
                    </div>
                </div>
            `;

      // A. View Handler
      const contentDiv = item.querySelector(".scene-content");
      contentDiv.onclick = () => store.setActiveScene(index);

      // Custom Context Menu (Delete/Clear) - Only for the CONTENT area
      contentDiv.oncontextmenu = (e) => {
        e.preventDefault();
        e.stopPropagation(); // Stop it from bubbling
        targetContextIndex = index;
        contextMenu.style.display = "block";
        contextMenu.style.left = e.pageX + "px";
        contextMenu.style.top = e.pageY + "px";
      };

      // B. Drag Handler
      item.addEventListener("dragstart", (e) => {
        e.dataTransfer.setData("text/plain", index);
        e.dataTransfer.effectAllowed = "move";
        setTimeout(() => item.classList.add("dragging"), 0);
      });
      item.addEventListener("dragend", () => {
        item.classList.remove("dragging");
        document
          .querySelectorAll(".scene-item")
          .forEach((el) => el.classList.remove("drag-over"));
      });
      item.addEventListener("dragover", (e) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = "move";
        item.classList.add("drag-over");
      });
      item.addEventListener("dragleave", () =>
        item.classList.remove("drag-over"),
      );
      item.addEventListener("drop", (e) => {
        e.preventDefault();
        const fromIndex = parseInt(e.dataTransfer.getData("text/plain"));
        const toIndex = index;
        item.classList.remove("drag-over");
        store.reorderScenes(fromIndex, toIndex);
      });

      list.appendChild(item);
    });

    // 4. Enable Buttons
    btnLink.disabled = false;
    btnLink.style.opacity = 1;
    btnExport.disabled = false;
    btnExport.style.opacity = 1;
    btnRecord.disabled = false;
    btnRecord.style.opacity = 1;
    btnTeaser.disabled = false;
    btnTeaser.style.opacity = 1;
    btnPreview.disabled = false;
    btnPreview.style.opacity = 1;
  });
}
