# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (11)
- [ ] **../../backend/src/services/geocoding/cache.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.04, Coupling: 0.02] | Drag: 3.87 | LOC: 380/300
- [ ] **../../backend/src/api/project_multipart.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.03, Coupling: 0.03] | Drag: 4.74 | LOC: 327/300  ⚠️ Trigger: Drag above target (1.80) with file already at 327 LOC.
- [ ] **../../backend/src/api/mod.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.00, Coupling: 0.04] | Drag: 1.60 | LOC: 390/300
- [ ] **../../backend/src/api/media/video_capture.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.10, Coupling: 0.02] | Drag: 5.18 | LOC: 327/300  ⚠️ Trigger: Drag above target (1.80) with file already at 327 LOC.
- [ ] **../../backend/src/api/auth.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.03, Coupling: 0.01] | Drag: 3.44 | LOC: 2209/300
- [ ] **../../backend/src/auth.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.04, Coupling: 0.03] | Drag: 3.44 | LOC: 452/300
- [ ] **../../backend/src/api/media/video_runtime_generate.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.07, Coupling: 0.03] | Drag: 3.85 | LOC: 315/300  ⚠️ Trigger: Drag above target (1.80) with file already at 315 LOC.
- [ ] **../../backend/src/services/upload_quota.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.05, Coupling: 0.02] | Drag: 3.45 | LOC: 326/300  ⚠️ Trigger: Drag above target (1.80) with file already at 326 LOC.
- [ ] **../../backend/src/middleware/rate_limiter.rs**
  - *Reason:* [Nesting: 3.60, Density: 0.04, Coupling: 0.02] | Drag: 4.66 | LOC: 343/300  ⚠️ Trigger: Drag above target (1.80) with file already at 343 LOC.
- [ ] **../../backend/src/services/project/package.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.05, Coupling: 0.02] | Drag: 4.41 | LOC: 378/300
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.03, Coupling: 0.02] | Drag: 4.08 | LOC: 927/300

---

