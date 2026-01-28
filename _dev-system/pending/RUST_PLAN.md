# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🚨 CRITICAL VIOLATIONS (15)
**Action:** Fix these patterns immediately using project standards.

### Pattern: `unwrap`
- [ ] `../../backend/src/pathfinder/utils.rs`
- [ ] `../../backend/src/api/telemetry.rs`
- [ ] `../../backend/src/api/project/export.rs`
- [ ] `../../backend/src/api/project/storage/storage_logic.rs`
- [ ] `../../backend/src/api/project/storage/mod.rs`
- [ ] `../../backend/src/api/project/navigation.rs`
- [ ] `../../backend/src/api/geocoding.rs`
- [ ] `../../backend/src/api/media/video/mod.rs`
- [ ] `../../backend/src/api/media/video/video_logic.rs`
- [ ] `../../backend/src/api/media/similarity.rs`
- [ ] `../../backend/src/api/media/image/image_utils.rs`
- [ ] `../../backend/src/api/media/image/mod.rs`
- [ ] `../../backend/src/services/auth/mod.rs`
- [ ] `../../backend/src/services/geocoding/logic.rs`
- [ ] `../../backend/src/services/geocoding/mod.rs`

---

## 🛠️ SURGICAL REFACTOR TASKS (20)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../backend/src/pathfinder/mod.rs**
  - *Reason:* LOC 77 > Limit 42 (Role: orchestrator, Drag: 3.70)
- [ ] **../../backend/src/pathfinder/utils.rs**
  - *Reason:* LOC 100 > Limit 30 (Role: util-pure, Drag: 9.27)
- [ ] **../../backend/src/models/mod.rs**
  - *Reason:* LOC 216 > Limit 181 (Role: orchestrator, Drag: 1.40)
- [ ] **../../backend/src/models/errors.rs**
  - *Reason:* LOC 146 > Limit 112 (Role: data-model, Drag: 2.93)
- [ ] **../../backend/src/api/telemetry.rs**
  - *Reason:* LOC 157 > Limit 30 (Role: infra-adapter, Drag: 8.61)
- [ ] **../../backend/src/api/project/export.rs**
  - *Reason:* LOC 94 > Limit 48 (Role: infra-adapter, Drag: 4.16)
- [ ] **../../backend/src/api/project/storage/storage_logic.rs**
  - *Reason:* LOC 241 > Limit 30 (Role: service-orchestrator, Drag: 10.97)
- [ ] **../../backend/src/api/project/storage/mod.rs**
  - *Reason:* LOC 295 > Limit 30 (Role: orchestrator, Drag: 11.38)
- [ ] **../../backend/src/api/project/navigation.rs**
  - *Reason:* LOC 109 > Limit 35 (Role: infra-adapter, Drag: 5.17)
- [ ] **../../backend/src/api/geocoding.rs**
  - *Reason:* LOC 153 > Limit 36 (Role: infra-adapter, Drag: 5.08)
- [ ] **../../backend/src/api/media/serve.rs**
  - *Reason:* LOC 72 > Limit 60 (Role: infra-adapter, Drag: 3.59)
- [ ] **../../backend/src/api/media/video/mod.rs**
  - *Reason:* LOC 175 > Limit 30 (Role: orchestrator, Drag: 8.11)
- [ ] **../../backend/src/api/media/video/video_logic.rs**
  - *Reason:* LOC 228 > Limit 30 (Role: service-orchestrator, Drag: 8.40)
- [ ] **../../backend/src/api/media/similarity.rs**
  - *Reason:* LOC 197 > Limit 36 (Role: infra-adapter, Drag: 5.01)
- [ ] **../../backend/src/api/media/image/image_utils.rs**
  - *Reason:* LOC 68 > Limit 47 (Role: infra-adapter, Drag: 4.21)
- [ ] **../../backend/src/api/media/image/mod.rs**
  - *Reason:* LOC 306 > Limit 30 (Role: orchestrator, Drag: 8.08)
- [ ] **../../backend/src/api/media/image/image_logic.rs**
  - *Reason:* LOC 283 > Limit 48 (Role: service-orchestrator, Drag: 3.39)
- [ ] **../../backend/src/services/geocoding/logic.rs**
  - *Reason:* LOC 129 > Limit 43 (Role: service-orchestrator, Drag: 3.61)
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* LOC 246 > Limit 30 (Role: orchestrator, Drag: 6.01)
- [ ] **../../backend/src/services/media/analysis/mod.rs**
  - *Reason:* LOC 97 > Limit 64 (Role: orchestrator, Drag: 2.78)

---

