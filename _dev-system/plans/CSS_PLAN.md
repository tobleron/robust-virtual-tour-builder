# CSS MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Estimated modification-risk multiplier. Higher Drag means edits are more likely to miss state, flow, or boundary details.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (6)
- [ ] **../../css/components/portal-pages-admin-ui.css**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 305)
- [ ] **../../css/components/portal-pages.css**
  - *Reason:* [Nesting: 1.20, Density: 0.17, Coupling: 0.00] | Drag: 2.37 | LOC: 1078/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.
- [ ] **../../css/components/portal-pages-admin-tables.css**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 159)
- [ ] **../../css/components/portal-pages-auth.css**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 76)
- [ ] **../../css/components/portal-pages-customer.css**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 319)
- [ ] **../../css/components/portal-pages-base.css**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 238)

---

