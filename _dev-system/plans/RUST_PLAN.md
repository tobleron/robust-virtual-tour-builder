# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🛠️ SURGICAL REFACTOR TASKS (24)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../backend/src/middleware/quota_check.rs**
  - *Reason:* LOC 127 > Limit 94 (Role: infra-adapter, Drag: 2.66)
- [ ] **../../backend/src/middleware/auth.rs**
  - *Reason:* LOC 155 > Limit 51 (Role: infra-adapter, Drag: 4.03)
- [ ] **../../backend/src/pathfinder/algorithms/timeline.rs**
  - *Reason:* LOC 125 > Limit 51 (Role: domain-logic, Drag: 3.26)
- [ ] **../../backend/src/pathfinder/algorithms/walk.rs**
  - *Reason:* LOC 178 > Limit 33 (Role: domain-logic, Drag: 4.30)
- [ ] **../../backend/src/pathfinder/tests.rs**
  - *Reason:* LOC 67 > Limit 64 (Role: infra-adapter, Drag: 3.45)
- [ ] **../../backend/src/models/errors.rs**
  - *Reason:* LOC 130 > Limit 128 (Role: data-model, Drag: 2.68)
- [ ] **../../backend/src/api/project/storage/storage_logic.rs**
  - *Reason:* LOC 241 > Limit 31 (Role: service-orchestrator, Drag: 4.47)
- [ ] **../../backend/src/api/project/storage/mod.rs**
  - *Reason:* LOC 295 > Limit 30 (Role: orchestrator, Drag: 4.88)
- [ ] **../../backend/src/api/telemetry_logic.rs**
  - *Reason:* LOC 93 > Limit 65 (Role: util-pure, Drag: 1.73)
- [ ] **../../backend/src/api/media/video/teaser.rs**
  - *Reason:* LOC 113 > Limit 77 (Role: service-orchestrator, Drag: 2.47)
- [ ] **../../backend/src/api/media/video/video_logic.rs**
  - *Reason:* LOC 228 > Limit 47 (Role: service-orchestrator, Drag: 3.40)
- [ ] **../../backend/src/api/media/image/image_logic.rs**
  - *Reason:* LOC 283 > Limit 61 (Role: service-orchestrator, Drag: 2.89)
- [ ] **../../backend/src/api/media/image/tests.rs**
  - *Reason:* LOC 122 > Limit 110 (Role: infra-adapter, Drag: 2.40)
- [ ] **../../backend/src/services/shutdown.rs**
  - *Reason:* LOC 162 > Limit 93 (Role: infra-adapter, Drag: 2.70)
- [ ] **../../backend/src/services/auth/jwt.rs**
  - *Reason:* LOC 69 > Limit 68 (Role: infra-adapter, Drag: 3.30)
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* LOC 246 > Limit 75 (Role: orchestrator, Drag: 2.51)
- [ ] **../../backend/src/services/upload_quota.rs**
  - *Reason:* LOC 298 > Limit 57 (Role: domain-logic, Drag: 3.01)
- [ ] **../../backend/src/services/project/package.rs**
  - *Reason:* LOC 137 > Limit 83 (Role: service-orchestrator, Drag: 2.35)
- [ ] **../../backend/src/services/project/load.rs**
  - *Reason:* LOC 155 > Limit 42 (Role: service-orchestrator, Drag: 3.66)
- [ ] **../../backend/src/services/project/validate.rs**
  - *Reason:* LOC 197 > Limit 100 (Role: domain-logic, Drag: 2.07)
- [ ] **../../backend/src/services/media/analysis/mod.rs**
  - *Reason:* LOC 97 > Limit 86 (Role: orchestrator, Drag: 2.28)
- [ ] **../../backend/src/services/media/analysis/quality.rs**
  - *Reason:* LOC 220 > Limit 103 (Role: domain-logic, Drag: 2.03)
- [ ] **../../backend/src/services/media/analysis/exif.rs**
  - *Reason:* LOC 117 > Limit 74 (Role: infra-adapter, Drag: 3.14)
- [ ] **../../backend/src/services/media/naming.rs**
  - *Reason:* LOC 109 > Limit 39 (Role: domain-logic, Drag: 3.87)

---

