# Project Testing Strategy

**Last Updated:** March 19, 2026  
**Version:** 5.3.6

---

## 1. Safety Nets & Three-Tier Strategy

Our testing system is built on three pillars to ensure long-term maintainability:

### Tier 1: Unit Tests (Logic Guards)

Verify mathematical and logical correctness of isolated functions.

**Examples:**
- `NavigationFSM_v.test.res` - FSM state transitions
- `SimulationFSM_v.test.res` - Simulation state machine
- `ColorPalette_v.test.res` - Color utilities
- `HotspotHelpers_v.test.res` - Hotspot coordinate calculations
- `SceneHelpers_v.test.res` - Scene operations

**Coverage Target:** 90% of core logic modules

### Tier 2: Integration Tests (Component Guards)

Ensure major UI components boot and render without crashing.

**Examples:**
- `ViewerUI_v.test.res` - Viewer component rendering
- `Sidebar_v.test.res` - Sidebar component bootstrap
- `VisualPipeline_v.test.res` - Graph visualization rendering

**Coverage Target:** All orchestrator components

### Tier 3: E2E Tests (Bug Guards)

Codify past bugs into permanent tests and validate critical user journeys.

**Examples:**
- `navigation.spec.ts` - Scene switching flows
- `upload.spec.ts` - Image upload pipeline
- `export.spec.ts` - Export/delivery flows
- `perf-budgets.spec.ts` - Performance regression

**Coverage Target:** All critical user journeys

---

## 2. Test Execution

### Frontend Tests (Vitest)

```bash
# Run all frontend tests
npm run test:frontend

# Watch mode
npm run test:watch

# Vitest UI
npm run test:ui

# Single test file
npx vitest tests/unit/NavigationFSM_v.test.bs.js

# Test with coverage
npx vitest run --coverage
```

**Test Structure:**
```rescript
open Vitest

describe("NavigationFSM", () => {
  test("transitions from Idle to Preloading on UserClickedScene", t => {
    let state = IdleFsm
    let event = UserClickedScene({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    t->expect(nextState)->Expect.toMatchPattern(Preloading(_))
  })
})
```

### Backend Tests (Cargo)

```bash
# Run all backend tests
cd backend && cargo test

# Single test
cd backend && cargo test test_image_processing

# Test with output
cd backend && cargo test -- --nocapture
```

### E2E Tests (Playwright)

```bash
# Run all E2E tests
npm run test:e2e

# Playwright UI mode
npm run test:e2e:ui

# Single test file
npx playwright test tests/e2e/navigation.spec.ts

# Performance budget tests
npm run test:e2e:budgets

# Headless mode (CI)
npm run test:e2e:headless
```

### All Tests

```bash
# Run everything (ReScript build + frontend + backend)
npm test
```

---

## 3. Optimistic Updates & Recovery Validation

### Rollback Testing

**Scene Deletion Rollback:**
1. Delete a scene while offline
2. Verify scene reappears after rollback
3. Verify warning notification is shown
4. Verify OperationJournal logs the failure

**Hotspot Rollback:**
1. Add a hotspot while offline
2. Verify hotspot is removed after rollback
3. Verify warning notification is shown
4. Verify state consistency

### Interruption Recovery Testing

**Interrupted Save:**
1. Start save operation
2. Close tab mid-operation
3. Reopen app
4. Verify recovery prompt appears
5. Click "Retry All"
6. Verify save completes successfully

**Interrupted Upload:**
1. Start image upload
2. Force close browser mid-upload
3. Reopen app
4. Verify recovery prompt shows upload
5. Verify upload can be resumed or cancelled

**Recovery System Tests:**
- `tests/unit/OperationJournal_v.test.res` - Journal persistence
- `tests/unit/RecoveryManager_v.test.res` - Recovery handlers
- `tests/unit/PersistenceLayer_v.test.res` - Autosave/recovery

---

## 4. Race Reliability Certification (Task 1504)

We target strict race reliability against arbitrary user interaction speed or CPU throttling.

### Success Criteria

| Success Criterion | Verification Method | Expected Evidence |
|---|---|---|
| **No navigation/simulation desync under CPU throttle** | 100-run interaction loop + 6x CPU throttle | Trace logs showing FSM state transitions and simulation move rejection during active nav |
| **Deterministic sequence** | Automated E2E stress suite executing 100x | Pass/Fail report (100% pass required) |
| **No stale async callback mutation** | Targeted unit tests + run-token instrumentation | `REJECTED_STALE_CALLBACK` logs |
| **Backend operations preserve identity** | Trace log audit for Load/Upload/Export | Consistent Operation ID from request to final update |
| **No LONG_TASK bursts** | Perf trace analysis during Navigation + Thumbnail Gen | Long task count <= 2 during transition window |

### Critical Module Run-Token Status

| Module | Protection Mechanism | Status |
|---|---|---|
| `Simulation.res` | FSM-gated (`NavigationFSM` state check + `sceneId` match) | ✅ Protected |
| `NavigationSupervisor.res` | Structured Concurrency (`AbortSignal` + `runId` validation) | ✅ Protected |
| `SceneLoader.res` | Token-based loading (`loadId` checks in callbacks) | ✅ Protected |
| `ThumbnailProjectSystem.res` | Interaction lock-gating via `Capability.Policy` | ✅ Protected |
| `AuthenticatedClient.res` | Correlation-ID header injection + response metadata alignment | ✅ Protected |
| `OperationLifecycle.res` | Operation ID tracking + stale callback rejection | ✅ Protected |

---

## 5. Performance Budget Testing

### Budget Gates

**Bundle Gate:**
```bash
npm run budget:bundle
```

**Thresholds:**
- Total JS bytes <= 4,500,000
- Total gzip bytes <= 750,000
- Largest chunk <= 2,000,000

**Runtime Gate:**
```bash
npm run test:e2e:budgets
npm run budget:runtime
```

**Thresholds:**
- Rapid navigation p95 <= 1500ms
- Rapid navigation long tasks <= 15
- Bulk upload latency <= 90,000ms
- Long simulation distinct active scenes >= 2
- Long simulation long tasks <= 30

### Performance Test Scenarios

**Scenario A: Steady-State Navigation**
- 50 scene switches at normal pace
- Measure p95 latency
- Verify long task count

**Scenario B: Rapid Navigation Stress**
- 50 scene switches as fast as possible
- Measure memory growth ratio
- Verify no crashes or hangs

**Scenario C: Upload Pipeline**
- Upload 100 images (4K panoramas)
- Measure total completion time
- Verify memory stability

**Scenario D: Simulation Run**
- Run full simulation on 20-scene project
- Verify distinct scenes visited >= 2
- Measure long task count

---

## 6. Portal System Testing (v5.3.6)

### Admin Dashboard Tests

**Tour Management:**
- Create new tour
- Edit tour metadata
- Delete tour
- Assign tour to recipient

**Recipient Management:**
- Add recipient
- Assign tour to recipient
- Revoke access
- Send access email

**Access Code Generation:**
- Generate short code
- Verify code validity
- Expire code
- Regenerate code

### Customer Gallery Tests

**Access Authentication:**
- Enter valid access code
- Enter invalid access code
- Expired code handling
- Rate limiting on failed attempts

**Tour Viewing:**
- Load tour list
- Open tour viewer
- Navigate scenes
- View on mobile

**Shared Links:**
- Click email link
- Deep link authentication
- Expired link handling

---

## 7. OperationLifecycle Testing (v5.3.6)

### Operation Tracking Tests

**Navigation Operation:**
```rescript
test("tracks navigation operation lifecycle", t => {
  let state = initialState
  dispatch(StartNavigation({targetSceneId: "scene-1"}))
  
  // Verify operation started
  let op = OperationLifecycle.getCurrentOperation(state)
  t->expect(op)->Expect.toMatch(Some(Operation(_, {operationType: Navigation, progress: _})))
  
  // Complete navigation
  dispatch(CompleteNavigation({sceneId: "scene-1"}))
  
  // Verify operation completed
  let completedOp = OperationLifecycle.getCurrentOperation(state)
  t->expect(completedOp)->Expect.toEqual(None)
})
```

**Progress Reporting:**
- Upload progress (0-100%)
- Export progress (packaging, zipping, uploading)
- Teaser recording progress (frames captured)

**Error Handling:**
- Operation failure with error message
- Retry mechanism
- Cancellation via AbortSignal

---

## 8. Test Coverage Reports

### Current Coverage (v5.3.6)

| Category | Files | Tests | Status |
|---|---|---|---|
| Unit Tests | 196 files | 998 tests | ✅ Passing |
| E2E Tests | 25 specs | 150+ scenarios | ✅ Passing |
| Backend Tests | 45 modules | 200+ tests | ✅ Passing |

### Coverage Gaps

**Priority 1 (High):**
- [ ] VisualPipeline graph layout tests
- [ ] OperationLifecycle progress tracking tests
- [ ] Portal admin surface tests
- [ ] NavigationSupervisor structured concurrency tests

**Priority 2 (Medium):**
- [ ] TeaserRendererRegistry tests
- [ ] Chunked import/export tests
- [ ] EXIF report generation tests
- [ ] LabelMenu tab switching tests

**Priority 3 (Low):**
- [ ] FloorNavigation component tests
- [ ] LockFeedback progress indicator tests
- [ ] Thumbnail enhancement tests

---

## 9. Test Data Management

### Test Fixtures

**Sample Projects:**
- `edge.zip` - Complex scene graph for simulation testing
- `x445.zip` - Standard residential property
- `large-project.zip` - 200 scenes for performance testing
- `multi-floor.zip` - Multi-story property for floor navigation

**Test Images:**
- `4k-panorama.jpg` - High-resolution test image
- `invalid-mime.txt` - Invalid file type testing
- `corrupted-exif.jpg` - EXIF parsing edge cases

### Test Environment

**JSDOM Setup:**
```javascript
// tests/node-setup.js
global.URL = require('url').URL;
global.Blob = require('buffer').Blob;
```

**Mock Services:**
```rescript
// Mock backend API
module MockApi = {
  let upload = jest.fn(() => Promise.resolve({id: "test-123"}))
  let load = jest.fn(() => Promise.resolve(testProject))
}
```

---

## 10. Continuous Integration

### CI Pipeline

```yaml
# GitHub Actions (simplified)
test:
  - npm ci
  - npm run build
  - npm run budget:bundle
  - npm run test:frontend
  - cd backend && cargo test
  - npm run test:e2e:budgets
  - npm run budget:runtime
```

### Budget Enforcement

CI fails if:
- Bundle size exceeds thresholds
- Runtime performance regresses >10%
- Test coverage drops below 90%
- Any test fails

---

## 11. Related Documents

- **[Runbook & Audits](./runbook_and_audits.md)** - Performance budgets and code quality audits
- **[Architecture Overview](../architecture/overview.md)** - System architecture for test planning
- **[Dev System](./dev_system.md)** - Codebase analyzer for test coverage tracking

---

**Document History:**
- March 19, 2026: Updated for v5.3.6 with Portal system tests, OperationLifecycle tests, and current coverage reports
