# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../backend/src/services/geocoding/osm.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 78)
- [ ] **../../backend/src/services/geocoding/mod.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 119)
- [ ] **../../backend/src/services/geocoding/cache.rs**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 210)

---

