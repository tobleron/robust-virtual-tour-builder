# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🛠️ SURGICAL REFACTOR TASKS (30)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../backend/src/middleware/quota_check.rs**
  - *Reason:* LOC 127 > Limit 82 (Role: infra-adapter, Drag: 2.91)
- [ ] **../../backend/src/middleware/auth.rs**
  - *Reason:* LOC 155 > Limit 46 (Role: infra-adapter, Drag: 4.28)
- [ ] **../../backend/src/pathfinder/algorithms/timeline.rs**
  - *Reason:* LOC 125 > Limit 41 (Role: domain-logic, Drag: 3.76)
- [ ] **../../backend/src/pathfinder/algorithms/walk.rs**
  - *Reason:* LOC 178 > Limit 30 (Role: domain-logic, Drag: 4.80)
- [ ] **../../backend/src/pathfinder/tests.rs**
  - *Reason:* LOC 67 > Limit 57 (Role: infra-adapter, Drag: 3.70)
- [ ] **../../backend/src/models/errors.rs**
  - *Reason:* LOC 130 > Limit 112 (Role: data-model, Drag: 2.93)
- [ ] **../../backend/src/api/project/export_utils.rs**
  - *Reason:* LOC 52 > Limit 46 (Role: util-pure, Drag: 2.18)
- [ ] **../../backend/src/api/project/storage/storage_logic.rs**
  - *Reason:* LOC 241 > Limit 30 (Role: service-orchestrator, Drag: 4.97)
- [ ] **../../backend/src/api/project/storage/mod.rs**
  - *Reason:* LOC 295 > Limit 30 (Role: orchestrator, Drag: 5.38)
- [ ] **../../backend/src/api/telemetry_logic.rs**
  - *Reason:* LOC 93 > Limit 53 (Role: util-pure, Drag: 1.98)
- [ ] **../../backend/src/api/geocoding.rs**
  - *Reason:* LOC 153 > Limit 137 (Role: infra-adapter, Drag: 2.08)
- [ ] **../../backend/src/api/media/serve.rs**
  - *Reason:* LOC 72 > Limit 60 (Role: infra-adapter, Drag: 3.59)
- [ ] **../../backend/src/api/media/video/transcode.rs**
  - *Reason:* LOC 63 > Limit 55 (Role: service-orchestrator, Drag: 3.10)
- [ ] **../../backend/src/api/media/video/teaser.rs**
  - *Reason:* LOC 113 > Limit 58 (Role: service-orchestrator, Drag: 2.97)
- [ ] **../../backend/src/api/media/video/video_logic.rs**
  - *Reason:* LOC 228 > Limit 39 (Role: service-orchestrator, Drag: 3.90)
- [ ] **../../backend/src/api/media/similarity.rs**
  - *Reason:* LOC 197 > Limit 144 (Role: infra-adapter, Drag: 2.01)
- [ ] **../../backend/src/api/media/image/image_logic.rs**
  - *Reason:* LOC 283 > Limit 48 (Role: service-orchestrator, Drag: 3.39)
- [ ] **../../backend/src/api/media/image/tests.rs**
  - *Reason:* LOC 122 > Limit 83 (Role: infra-adapter, Drag: 2.90)
- [ ] **../../backend/src/services/shutdown.rs**
  - *Reason:* LOC 162 > Limit 81 (Role: infra-adapter, Drag: 2.95)
- [ ] **../../backend/src/services/auth/jwt.rs**
  - *Reason:* LOC 69 > Limit 55 (Role: infra-adapter, Drag: 3.80)
- [ ] **../../backend/src/services/geocoding/logic.rs**
  - *Reason:* LOC 129 > Limit 98 (Role: service-orchestrator, Drag: 2.11)
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* LOC 246 > Limit 57 (Role: orchestrator, Drag: 3.01)
- [ ] **../../backend/src/services/upload_quota.rs**
  - *Reason:* LOC 298 > Limit 50 (Role: domain-logic, Drag: 3.26)
- [ ] **../../backend/src/services/project/package.rs**
  - *Reason:* LOC 137 > Limit 62 (Role: service-orchestrator, Drag: 2.85)
- [ ] **../../backend/src/services/project/load.rs**
  - *Reason:* LOC 155 > Limit 35 (Role: service-orchestrator, Drag: 4.16)
- [ ] **../../backend/src/services/project/validate.rs**
  - *Reason:* LOC 197 > Limit 72 (Role: domain-logic, Drag: 2.57)
- [ ] **../../backend/src/services/media/analysis/mod.rs**
  - *Reason:* LOC 97 > Limit 64 (Role: orchestrator, Drag: 2.78)
- [ ] **../../backend/src/services/media/analysis/quality.rs**
  - *Reason:* LOC 220 > Limit 74 (Role: domain-logic, Drag: 2.53)
- [ ] **../../backend/src/services/media/analysis/exif.rs**
  - *Reason:* LOC 117 > Limit 59 (Role: infra-adapter, Drag: 3.64)
- [ ] **../../backend/src/services/media/naming.rs**
  - *Reason:* LOC 109 > Limit 32 (Role: domain-logic, Drag: 4.37)

---

