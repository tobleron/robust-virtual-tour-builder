# Task 1806: Hygiene: Logger Standardization & console.* Removal

## 🛡️ Objective
Eliminate all 6 remaining direct `console.warn/info` calls in production code to ensure all logs follow the structured telemetry pipeline.

---

## 🛠️ Execution Roadmap
1. **Audit**: Locate remaining calls in `StateInspector.res`, `ViewerAdapter.res`, and `ResizerUtils.res`.
2. **Replacement**: Swap for appropriate `Logger.info/warn` calls with proper module context.
3. **Linter rule**: (Optional) Add a linter rule to forbid future `console.log`.

---

## ✅ Acceptance Criteria
- [ ] `grep -r "console." src` returns zero results in `.res` files.
- [ ] All logs appear correctly in the Telemetry view.
