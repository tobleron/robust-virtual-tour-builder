# 1774 Audit - "Rendering...please wait" Configuration & Stage Viewer Stability

## Scope
Investigation-only audit of the frontend paths that emit `"Rendering...please wait"`, including trigger frequency mechanics, navigation fan-out sources, notification lifecycle behavior, and safe optimization options for stage-viewer stability.

## Evidence Summary (Code-Referenced)

### 1) Source of the message
- The notification is emitted only in [`src/components/ViewerSnapshot.res`](src/components/ViewerSnapshot.res) at line `78`.
- Trigger branch is the `Error(_)` arm from `InteractionGuard.attempt(...)` for:
  - `SlidingWindow(10, 60000, 2000)` at line `68`.

### 2) Guard mechanics (what creates the 4 conditions)
- Sliding-window branch logic in [`src/core/InteractionGuard.res`](src/core/InteractionGuard.res):
  - `intervalPassed` check (`minIntervalMs`) at line `127`
  - quota check (`maxCalls/windowMs`) at lines `128-135`
- Current behavior:
  - If min interval fails: returns `Error("Throttled")`
  - If quota fails: returns `Error("Rate limited")`
  - In `ViewerSnapshot`, both error types are collapsed into the same toast.

### 3) Fan-out trigger path (why this appears during active work)
- `ViewerSnapshot.requestIdleSnapshot(...)` is called after swap completion in [`src/systems/Scene/SceneTransition.res`](src/systems/Scene/SceneTransition.res) line `222`.
- `SceneTransition.performSwap(...)` is executed from navigation stabilization in [`src/systems/Navigation/NavigationController.res`](src/systems/Navigation/NavigationController.res) lines `77-115`.
- Upstream navigation entrypoints that can reach this path:
  - Scene list click: [`src/components/SceneList.res`](src/components/SceneList.res) line `134`
  - Hotspot click: [`src/systems/HotspotLine.res`](src/systems/HotspotLine.res) line `123`
  - Auto-forward / scene switcher: [`src/systems/Scene/SceneSwitcher.res`](src/systems/Scene/SceneSwitcher.res) lines `61`, `93`, `117-156`
  - Visual pipeline click: [`src/components/VisualPipelineNavigation.res`](src/components/VisualPipelineNavigation.res) line `1`
  - Simulation advancement: [`src/systems/Simulation.res`](src/systems/Simulation.res) lines `228-238`
  - Teaser playback scene switching via `SetActiveScene(...)`: [`src/systems/TeaserPlaybackManifest.res`](src/systems/TeaserPlaybackManifest.res) lines `230-235`, [`src/systems/TeaserPlayback.res`](src/systems/TeaserPlayback.res) lines `104`, `156-159` (which ultimately drive scene change handling and swaps)

### 4) Notification dedupe/refresh behavior
- Notification refresh-by-context behavior in [`src/core/NotificationManager.res`](src/core/NotificationManager.res) lines `146-166`.
- Same `context+message` (`Operation("viewer_snapshot") + "Rendering...please wait"`) refreshes existing toast instead of creating a new one.
- Duration is reset on refresh (`createdAt` and `duration` refreshed), which can keep the toast visible continuously during sustained blocking.

---

## Configuration Audit Matrix

| Condition | Current Config | Where Applied | User Effect | Stability Risk |
|---|---|---|---|---|
| Min-interval throttle | `minIntervalMs=2000` | `ViewerSnapshot -> InteractionGuard.SlidingWindow` | Frequent "please wait" under rapid switching even when quota exists | Medium |
| Sliding-window quota | `maxCalls=10`, `windowMs=60000` | same | At >10 accepted captures/minute, subsequent captures block; message can repeatedly refresh | High (UX noise) |
| Fan-out trigger path | Snapshot requested on every completed swap | `SceneTransition.completeSwapTransition` | Message can appear from many workflows (manual + simulation + teaser) | High |
| Notification dedupe refresh | Refresh existing toast by context+message | `NotificationManager.dispatch` | Avoids toast spam count, but can produce near-permanent single toast | Medium-High |

---

## Stress Scenario Findings

| Scenario | Expected UX | Current Observed-from-code Behavior | Root Cause |
|---|---|---|---|
| Fast scene switching (sidebar) | Smooth switching, minimal blocking messaging | Snapshot request after each swap; once limits hit, same toast can persist | Swap-trigger fan-out + strict limiter + refresh reset |
| Hotspot rapid navigation | Navigation feedback, not rendering noise | Same as above; in parallel there is separate "Switching too fast..." flow | Multiple independent throttles without coordinated UX policy |
| Simulation run on dense graph | Stable autonomous traversal with low UI noise | Simulation steps trigger scene swaps; snapshot limiter may repeatedly hit | Snapshot flow not mode-aware (simulation path included) |
| Teaser playback/render | Deterministic run with focused progress UI | Scene changes during teaser still route through swap lifecycle; snapshot limiter still eligible | Snapshot flow not teaser-aware |

---

## Test Coverage Assessment (Current)

### Covered
- `ViewerSnapshot` has unit test asserting notification under rate limit: [`tests/unit/ViewerSnapshot_v.test.res`](tests/unit/ViewerSnapshot_v.test.res) lines `180-238`.
- `InteractionGuard` covers both quota and minInterval semantics in generic tests: [`tests/unit/InteractionGuard_v.test.res`](tests/unit/InteractionGuard_v.test.res) lines `86-140`.
- Notification queue/manager behavior is unit tested in isolation.

### Gaps (Important)
1. No end-to-end test validating viewer snapshot notification behavior under rapid scene switching in real stage flows.
2. No explicit unit/e2e for **min-interval** branch mapped to this exact message (viewer path uses collapsed `Error(_)`).
3. No test asserting toast persistence behavior when repeated refresh events occur over time.
4. No test ensuring simulation/teaser modes avoid non-essential stage toasts.
5. `ViewerSnapshot` tests call internals via `%raw` (`debouncedSnapshot.call()`), which validates branch behavior but not full integration timing realism.

---

## Optimization Proposals (Ranked)

### Proposal A - Conservative (Lowest Risk)
**Goal:** Keep capture mechanics unchanged, reduce UX noise safely.

Changes:
1. Keep `SlidingWindow(10, 60000, 2000)` unchanged.
2. In `ViewerSnapshot`, suppress toast for `"Throttled"`-equivalent events (min-interval hits).
3. Show toast only on true sustained quota pressure (e.g., cooldown gate: one toast every 10-15s).

Expected impact:
- Eliminates persistent low-value toast churn during active switching.
- Zero change to capture cadence, swap logic, or navigation correctness.

Regression risk: **Low**
Rollback: Revert only `ViewerSnapshot` notification gate logic.

---

### Proposal B - Balanced (Recommended)
**Goal:** Improve user-perceived stability while preserving safety constraints.

Changes:
1. Externalize snapshot policy into constants (avoid hardcoded tuple).
2. Tune defaults for stage editing:
   - `maxCalls`: `10 -> 18`
   - `windowMs`: `60000` (unchanged)
   - `minIntervalMs`: `2000 -> 1200`
3. Keep Proposal A notification cooldown behavior.

Why these values:
- Current profile hard-caps accepted captures to 10/minute.
- New profile permits more realistic editing cadence while still bounding work.
- 1.2s min interval remains conservative for `toBlob` stability.

Expected impact:
- Fewer limiter hits during real editing.
- Lower chance of long-running "please wait" state.

Regression risk: **Low-Medium** (higher snapshot frequency)
Rollback: Restore old constants in one place.

---

### Proposal C - Aggressive (Optional)
**Goal:** Maximum UX clarity and resource focus during non-editing automated flows.

Changes:
1. Skip snapshot requests when `simulation.status == Running` or `isTeasing == true`.
2. Keep snapshot capture best-effort only for manual stage interactions.

Expected impact:
- Removes non-essential snapshot work/noise during autonomous modes.
- Cleaner teaser/simulation operation UX.

Regression risk: **Medium** (if hidden dependencies rely on capture during these modes)
Rollback: Remove mode guard and restore universal snapshot request.

---

## No-Code / No-Risk Option
Before any logic change, run a telemetry-backed observation pass using existing `SNAPSHOT_RATE_LIMITED` logs and manual stress protocol:
- Collect 3 runs (normal edit, rapid switch edit, simulation-heavy).
- Record frequency and duration of `Rendering...please wait` visibility.
- Use this to select between Proposal A and B confidently.

This option requires no production behavior change.

---

## Recommended Defaults (If Implementing)
Use **Proposal B** as default rollout:
1. `SlidingWindow(18, 60000, 1200)`
2. Toast cooldown for snapshot-limit message (10-15s)
3. Min-interval branch does not emit user toast

Reasoning:
- Best balance of stability (bounded work) and UX (avoids persistent noise).
- Minimal touch radius.

---

## Verification Plan (Pre-merge)

### Unit
1. `ViewerSnapshot_v.test.res`
   - Add assertions for differentiated behavior: interval-throttle vs quota-limit.
   - Add cooldown behavior test for repeated blocked calls.
2. Add integration-level unit around swap->snapshot trigger cadence under rapid mock swaps.

### E2E
1. Rapid scene-switch stress test (sidebar + hotspot mix) with toast assertions:
   - No persistent `Rendering...please wait` toast beyond policy window.
2. Simulation run test:
   - Ensure no excessive rendering-wait toast churn.
3. Teaser run test:
   - Ensure progress UX remains primary; snapshot wait toast follows new policy.

### Manual Stage Checklist
1. 30-50 scene-switch interactions within ~60s.
2. Alternate hotspot and scene-list navigation.
3. Run simulation start/stop cycles.
4. Run teaser generation start/cancel.
5. Confirm no degraded responsiveness and no stale lock behavior.

---

## Key Conclusion
Current configuration is functionally safe but **not UX-optimal** for active stage work because:
- Snapshot attempts fan out from every swap,
- limiter is strict for high-cadence editing,
- and notification refresh can keep one toast effectively persistent.

Best safe path: **Proposal B** (policy tuning + notification cooldown), with Proposal A immediately acceptable if zero-behavior-risk is prioritized.
