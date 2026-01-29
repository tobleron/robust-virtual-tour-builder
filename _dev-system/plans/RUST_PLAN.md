# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines.
*   **Drag:** Complexity multiplier (1.0 = base).
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead for switching context between files.
*   **AI Context Fog:** High-complexity peak regions within a file.

---

## 🛠️ SURGICAL REFACTOR TASKS (18)
- [ ] **../../backend/src/middleware/quota_check.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.06, Deps: 0.00] | Drag: 2.66 | LOC: 127/94
- [ ] **../../backend/src/middleware/auth.rs**
  - *Reason:* [Nesting: 0.90, Density: 0.13, Deps: 0.00] | Drag: 4.03 | LOC: 155/51
- [ ] **../../backend/src/models.rs**
  - *Reason:* [Nesting: 0.15, Density: 0.02, Deps: 0.00] | Drag: 3.67 | LOC: 520/80
- [ ] **../../backend/src/main.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.04, Deps: 0.00] | Drag: 3.14 | LOC: 285/54
- [ ] **../../backend/src/api/telemetry.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.12, Deps: 0.00] | Drag: 2.22 | LOC: 154/124
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 1.05, Density: 0.13, Deps: 0.00] | Drag: 7.18 | LOC: 518/30
- [ ] **../../backend/src/api/media/image.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.07, Deps: 0.00] | Drag: 6.32 | LOC: 482/30
- [ ] **../../backend/src/api/media/video.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.11, Deps: 0.00] | Drag: 4.46 | LOC: 372/43
- [ ] **../../backend/src/services/shutdown.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.15, Deps: 0.00] | Drag: 2.70 | LOC: 162/93
- [ ] **../../backend/src/services/auth/jwt.rs**
  - *Reason:* [Nesting: 0.30, Density: 0.00, Deps: 0.00] | Drag: 3.30 | LOC: 69/68
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* [Nesting: 0.45, Density: 0.06, Deps: 0.00] | Drag: 2.51 | LOC: 246/75
- [ ] **../../backend/src/services/upload_quota.rs**
  - *Reason:* [Nesting: 0.45, Density: 0.06, Deps: 0.00] | Drag: 3.01 | LOC: 298/57
- [ ] **../../backend/src/services/project/package.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.10, Deps: 0.00] | Drag: 2.35 | LOC: 137/83
- [ ] **../../backend/src/services/project/load.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.06, Deps: 0.00] | Drag: 3.66 | LOC: 155/42
- [ ] **../../backend/src/services/project/validate.rs**
  - *Reason:* [Nesting: 0.90, Density: 0.17, Deps: 0.00] | Drag: 2.07 | LOC: 197/100
- [ ] **../../backend/src/services/media/analysis/quality.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.18, Deps: 0.00] | Drag: 1.78 | LOC: 220/126
- [ ] **../../backend/src/services/media/analysis/exif.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.14, Deps: 0.00] | Drag: 2.89 | LOC: 117/84
- [ ] **../../backend/src/services/media/naming.rs**
  - *Reason:* [Nesting: 0.30, Density: 0.07, Deps: 0.00] | Drag: 3.87 | LOC: 109/39

---

