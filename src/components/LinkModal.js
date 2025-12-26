import { store } from "../store.js";
import { calculateReturnVector } from "../systems/AutoLinker.js";

export function showLinkModal(pitch, yaw, camPitch, camYaw, camHfov) {
  const state = store.state;
  const container = document.getElementById("modal-container");

  // SMART SELECTION: Calculate the next scene index
  const nextIndex = state.activeIndex + 1;

  container.innerHTML = `
        <div class="modal-overlay">
            <div class="modal-box">
                <h3>Link Destination</h3>
                <p style="font-size:12px; color:#666; margin-bottom:10px;">
                    Saving current view as "Target"
                </p>
                <select id="link-target" style="width: 100%; padding: 8px; margin-bottom: 10px;">
                    <option value="">-- Select Room --</option>
                    ${state.scenes
                      .map((s, i) => {
                        // AUTO-SELECT LOGIC: If this is the next image, select it by default
                        const isNext = i === nextIndex ? "selected" : "";
                        // Don't allow linking to self
                        if (i === state.activeIndex) return "";
                        return `<option value="${s.name}" ${isNext}>${s.name}</option>`;
                      })
                      .join("")}
                </select>
                
                <div>
                    <input type="checkbox" id="auto-return" checked>
                    <label for="auto-return">Auto-create return link</label>
                </div>
                <hr style="margin: 15px 0; border: 0; border-top: 1px solid #eee;">
                
                <button class="btn btn-primary" id="save-link">Save Link</button>
                <button class="btn" id="cancel-link" style="background:#ccc; color:#333">Cancel</button>
            </div>
        </div>
    `;

  document.getElementById("save-link").onclick = () => {
    const targetName = document.getElementById("link-target").value;
    const autoReturn = document.getElementById("auto-return").checked;

    if (targetName) {
      // 1. Save Forward Link
      store.addHotspot(state.activeIndex, {
        pitch,
        yaw,
        target: targetName,
        viewFrame: { pitch: camPitch, yaw: camYaw, hfov: camHfov },
      });

      // 2. Save Return Link (Auto)
      if (autoReturn) {
        const targetIndex = state.scenes.findIndex(
          (s) => s.name === targetName,
        );
        if (targetIndex !== -1) {
          const returnCoords = calculateReturnVector(pitch, yaw);
          store.addHotspot(targetIndex, {
            pitch: returnCoords.pitch,
            yaw: returnCoords.yaw,
            target: state.scenes[state.activeIndex].name,
            viewFrame: {
              pitch: 0,
              yaw: returnCoords.yaw,
              hfov: 100,
            },
          });
        }
      }
    }
    container.innerHTML = "";
    store.state.isLinking = false;
  };

  document.getElementById("cancel-link").onclick = () => {
    container.innerHTML = "";
    store.state.isLinking = false;
  };
}
