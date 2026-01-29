# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (4)
- [ ] **../../backend/src/api/media/image.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.03, Deps: 0.00] | Drag: 2.75 | LOC: 482/296
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 1.05, Density: 0.07, Deps: 0.00] | Drag: 2.60 | LOC: 518/309
- [ ] **../../backend/src/services/media/analysis/quality.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.09, Deps: 0.00] | Drag: 2.69 | LOC: 220/219
- [ ] **../../backend/src/api/media/video.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.05, Deps: 0.00] | Drag: 2.65 | LOC: 372/304

---

