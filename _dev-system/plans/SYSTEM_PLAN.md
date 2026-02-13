# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `../../src/components/VisualPipeline`
- **Reason:** Read Tax high (Score 2.00). Projected Limit: 300 (Drag 3.30)
- **Files:**
  - `../../src/components/VisualPipeline/VisualPipelineComponent.res`
  - `../../src/components/VisualPipeline/VisualPipelineStyles.res`
