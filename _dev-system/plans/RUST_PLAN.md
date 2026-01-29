# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (29)
- [ ] **../../backend/src/services/project/mod.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 116)
- [ ] **../../backend/src/services/media/naming.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 109)
- [ ] **../../backend/src/services/media/resizing.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 54)
- [ ] **../../backend/src/services/media/analysis_exif.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 117)
- [ ] **../../backend/src/middleware/quota_check.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 127)
- [ ] **../../backend/src/api/media/image_logic.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 290)
- [ ] **../../backend/src/services/shutdown.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 162)
- [ ] **../../backend/src/pathfinder.rs**
  - *Reason:* [Nesting: 1.05, Density: 0.07, Coupling: 0.05] | Drag: 2.40 | LOC: 583/250
- [ ] **../../backend/src/services/media/mod.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 98)
- [ ] **../../backend/src/services/auth/jwt.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 69)
- [ ] **../../backend/src/services/geocoding/logic.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 129)
- [ ] **../../backend/src/api/telemetry.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 154)
- [ ] **../../backend/src/api/media/similarity.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 197)
- [ ] **../../backend/src/middleware/auth.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 155)
- [ ] **../../backend/src/api/media/image.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 198)
- [ ] **../../backend/src/middleware/request_tracker.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 90)
- [ ] **../../backend/src/api/project_logic.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 181)
- [ ] **../../backend/src/api/media/video.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 173)
- [ ] **../../backend/src/services/project/validate.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 197)
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 246)
- [ ] **../../backend/src/api/media/video_logic.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 200)
- [ ] **../../backend/src/services/media/analysis_quality.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 220)
- [ ] **../../backend/src/services/project/load.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 155)
- [ ] **../../backend/src/api/media/serve.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 72)
- [ ] **../../backend/src/api/geocoding.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 153)
- [ ] **../../backend/src/services/upload_quota.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 298)
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 375)
- [ ] **../../backend/src/services/project/package.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 137)
- [ ] **../../backend/src/services/media/analysis.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 97)

---

