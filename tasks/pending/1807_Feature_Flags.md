# Task 1807: Ops: Runtime Feature Flags & Kill Switches

## 🛡️ Objective
Implement a runtime feature flag system to enable gradual rollouts and provide instant kill switches for misbehaving features without requiring a full redeploy.

---

## 🛠️ Execution Roadmap
1. **Module Creation**: Create `FeatureFlags.res`.
2. **Provider**: Implement a provider that reads from `window.CONFIG` or a dedicated local config file.
3. **Integration**: Wrap the `TeaserRecorder` and `AIHelper` features in flags.
4. **Kill Switch**: Add a global "Degraded Mode" flag to disable background heavy tasks.

---

## ✅ Acceptance Criteria
- [ ] Features can be toggled via local config/env without code rebuild.
- [ ] System handles missing/default states for flags safely.
