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

## 🛠️ SURGICAL REFACTOR TASKS (17)
**Action:** Extract logic to new modules to reduce complexity/bloat.
**Target:** To be determined by AI Agent (Create new modules as needed).

- [ ] **../../backend/src/pathfinder/utils.rs**
  - *Reason:* LOC 100 > Limit 54 (Role: util-pure, Drag: 1.97)
- [ ] **../../backend/src/models/mod.rs**
  - *Reason:* LOC 216 > Limit 181 (Role: orchestrator, Drag: 1.40)
- [ ] **../../backend/src/api/telemetry.rs**
  - *Reason:* LOC 157 > Limit 134 (Role: infra-adapter, Drag: 2.11)
- [ ] **../../backend/src/api/project/storage/storage_logic.rs**
  - *Reason:* LOC 241 > Limit 58 (Role: service-orchestrator, Drag: 2.97)
- [ ] **../../backend/src/api/project/storage/mod.rs**
  - *Reason:* LOC 295 > Limit 61 (Role: orchestrator, Drag: 2.88)
- [ ] **../../backend/src/api/project/navigation.rs**
  - *Reason:* LOC 109 > Limit 58 (Role: infra-adapter, Drag: 3.67)
- [ ] **../../backend/src/api/geocoding.rs**
  - *Reason:* LOC 153 > Limit 99 (Role: infra-adapter, Drag: 2.58)
- [ ] **../../backend/src/api/media/video/mod.rs**
  - *Reason:* LOC 175 > Limit 70 (Role: orchestrator, Drag: 2.61)
- [ ] **../../backend/src/api/media/video/video_logic.rs**
  - *Reason:* LOC 228 > Limit 86 (Role: service-orchestrator, Drag: 2.30)
- [ ] **../../backend/src/api/media/similarity.rs**
  - *Reason:* LOC 197 > Limit 144 (Role: infra-adapter, Drag: 2.01)
- [ ] **../../backend/src/api/media/image/mod.rs**
  - *Reason:* LOC 306 > Limit 36 (Role: orchestrator, Drag: 4.08)
- [ ] **../../backend/src/api/media/image/image_logic.rs**
  - *Reason:* LOC 283 > Limit 81 (Role: service-orchestrator, Drag: 2.39)
- [ ] **../../backend/src/services/geocoding/logic.rs**
  - *Reason:* LOC 129 > Limit 98 (Role: service-orchestrator, Drag: 2.11)
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* LOC 246 > Limit 37 (Role: orchestrator, Drag: 4.01)
- [ ] **../../backend/src/services/project/mod.rs**
  - *Reason:* LOC 116 > Limit 30 (Role: orchestrator, Drag: 5.65)
- [ ] **../../backend/src/services/media/analysis/mod.rs**
  - *Reason:* LOC 97 > Limit 86 (Role: orchestrator, Drag: 2.28)
- [ ] **../../backend/src/services/media/mod.rs**
  - *Reason:* LOC 94 > Limit 30 (Role: orchestrator, Drag: 6.80)

---

