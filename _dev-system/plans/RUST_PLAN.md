# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines.
*   **Drag:** Complexity multiplier (1.0 = base).
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead for switching context between files.
*   **AI Context Fog:** High-complexity peak regions within a file.

---

## 🛠️ SURGICAL REFACTOR TASKS (7)
- [ ] **../../backend/src/main.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.02, Deps: 0.00] | Drag: 2.38 | LOC: 285/281
- [ ] **../../backend/src/api/media/video.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.05, Deps: 0.00] | Drag: 3.65 | LOC: 372/280
- [ ] **../../backend/src/api/media/image.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.03, Deps: 0.00] | Drag: 3.75 | LOC: 482/275
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 1.05, Density: 0.07, Deps: 0.00] | Drag: 3.60 | LOC: 518/284
- [ ] **../../backend/src/services/upload_quota.rs**
  - *Reason:* [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.73 | LOC: 298/254
- [ ] **../../backend/src/services/media/analysis/quality.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.09, Deps: 0.00] | Drag: 3.69 | LOC: 220/202
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 3.18 | LOC: 246/226

---

