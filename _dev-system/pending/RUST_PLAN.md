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

## 🛠️ SURGICAL REFACTOR TASKS (13)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../backend/src/pathfinder/utils.rs**
  - *Reason:* LOC 100 > Limit 75 (Role: util-pure, Drag: 1.32)
- [ ] **../../backend/src/models/mod.rs**
  - *Reason:* LOC 216 > Limit 190 (Role: orchestrator, Drag: 1.05)
- [ ] **../../backend/src/api/project/storage/storage_logic.rs**
  - *Reason:* LOC 241 > Limit 131 (Role: service-orchestrator, Drag: 1.52)
- [ ] **../../backend/src/api/project/storage/mod.rs**
  - *Reason:* LOC 295 > Limit 139 (Role: orchestrator, Drag: 1.43)
- [ ] **../../backend/src/api/project/navigation.rs**
  - *Reason:* LOC 109 > Limit 89 (Role: infra-adapter, Drag: 3.07)
- [ ] **../../backend/src/api/geocoding.rs**
  - *Reason:* LOC 153 > Limit 129 (Role: infra-adapter, Drag: 2.13)
- [ ] **../../backend/src/api/media/video/mod.rs**
  - *Reason:* LOC 175 > Limit 146 (Role: orchestrator, Drag: 1.36)
- [ ] **../../backend/src/api/media/video/video_logic.rs**
  - *Reason:* LOC 228 > Limit 160 (Role: service-orchestrator, Drag: 1.25)
- [ ] **../../backend/src/api/media/image/mod.rs**
  - *Reason:* LOC 306 > Limit 63 (Role: orchestrator, Drag: 3.13)
- [ ] **../../backend/src/api/media/image/image_logic.rs**
  - *Reason:* LOC 283 > Limit 161 (Role: service-orchestrator, Drag: 1.24)
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* LOC 246 > Limit 62 (Role: orchestrator, Drag: 3.21)
- [ ] **../../backend/src/services/project/mod.rs**
  - *Reason:* LOC 116 > Limit 39 (Role: orchestrator, Drag: 5.05)
- [ ] **../../backend/src/services/media/mod.rs**
  - *Reason:* LOC 94 > Limit 32 (Role: orchestrator, Drag: 6.10)

---

