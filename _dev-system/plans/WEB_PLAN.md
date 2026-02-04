# WEB MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (4)
- [ ] **../../tests/unit/LabelMenu_v.test.setup.jsx**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 117)
- [ ] **../../tests/vitest-setup.js**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 80)
- [ ] **../../tests/unit/Components_v.test.setup.jsx**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 73)
- [ ] **../../tests/node-setup.js**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 185)

---

