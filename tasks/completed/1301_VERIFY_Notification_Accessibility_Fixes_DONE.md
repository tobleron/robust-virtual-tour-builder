# Task 1301: Verify Notification & Accessibility Fixes (Comprehensive E2E Verification)

**Aggregates:** Tasks 1297 (Notification Rendering) + 1298 (Linking Button Accessibility)

**Status:** Ready for verification

**Estimated Time:** 20-30 minutes

---

## Prior Context Summary

### Session 1: Rate Limiting Fix (Task 1296) ✅ COMPLETE
- **What was done:** Backend rate limiter increased from 1,000 → 10,000 req/sec in `backend/src/main.rs`
- **Why:** Health check endpoint was returning HTTP 429 errors, cascading to block 13+ tests at initialization
- **Verification:** Zero 429 errors confirmed across 216 test executions

### Session 2: Current Fixes Applied

#### Fix 1: Missing Sonner Toaster Component (Task 1297)
- **File Modified:** `src/App.res` line 68
- **Change:** Added `<Shadcn.Sonner position="top-right" richColors=true expand=true />`
- **Why:** Sonner toast library requires a Toaster component in the React tree to display notifications. NotificationCenter was calling the toast API but had nowhere to render.
- **Impact:** Should fix 6+ notification visibility test failures:
  - "Retrying" notification
  - "Failed to load project" message
  - "Project Saved" text
  - "Rate limit exceeded" message
  - "Cancelled" text
  - "Connection issues" notifications

#### Fix 2: aria-label Binding (Task 1292 - from prior sessions)
- **File Modified:** `src/components/ui/Shadcn.res`
- **Change:** Already applied with `@as("aria-label")` decorator
- **Why:** React needs proper HTML attribute mapping for accessibility
- **Impact:** Linking button should now be discoverable by tests using accessible name

---

## Your Task: Verify Both Fixes Work

### Prerequisites
Ensure you have:
- Fresh clone or clean working directory
- Backend running: `SESSION_KEY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" /path/to/backend/target/release/backend`
  - Or use debug binary: `cd backend && cargo run`
- Frontend running: `npm run dev:frontend` (should be on http://localhost:3000)
- Rate limiter fix already in place (verified in backend/src/main.rs lines 107-110)

---

## Step-by-Step Verification

### STEP 1: Build Verification (5 minutes)

```bash
# 1a. Rebuild frontend ReScript
npm run res:build

# Expected: "Compiled X modules" with NO errors
# If errors: Check src/App.res line 68 has <Shadcn.Sonner ... />
```

```bash
# 1b. Full production build
npm run build

# Expected: Frontend bundle ~978 kB, zero warnings
# If fails: Check for TypeScript/React compilation errors
```

### STEP 2: Start Services (5 minutes)

```bash
# 2a. Ensure backend is running with correct SESSION_KEY
curl -s http://localhost:8080/health
# Expected response: "Tour Builder API is running!"
# If fails: Restart backend with SESSION_KEY set (see Prerequisites)

# 2b. Ensure frontend is on port 3000
curl -s http://localhost:3000 | head -10
# Expected: HTML with "robust-virtual-tour-builder" in title
# If fails: Kill port 3000 (lsof -ti:3000 | xargs kill -9) and restart
```

### STEP 3: Run Full E2E Test Suite (15-20 minutes)

```bash
npm run test:e2e 2>&1 | tee /tmp/e2e_final_verification.log &
```

**Monitor progress:**
- Tests will run 108 total tests across 3 browsers (Chromium, Firefox, WebKit)
- Each test takes ~5-10 seconds
- Total run: approximately 12-18 minutes
- Watch for: No HTTP 429 errors (rate limit fix is working)

---

## Step 4: Verify Fix Success

After tests complete, analyze the results:

### ✅ SUCCESS CRITERIA - Notification Fix (Task 1297)

Search test output for notification-related tests:
```bash
grep -i "notification\|rate limit\|cancelled\|retrying\|connection issues" /tmp/e2e_final_verification.log
```

**Expected outcomes:**
- Tests looking for "Rate limit exceeded" text: should now PASS or FAIL with "element found" (not timeout)
- Tests looking for "Cancelled" text: should now PASS or FAIL with "element found" (not timeout)
- Tests looking for "Retrying" text: should now PASS or FAIL with "element found" (not timeout)
- Tests looking for "Connection issues" text: should now PASS or FAIL with "element found" (not timeout)

**Success Definition:**
- If 4+ notification tests that previously timed out now find the elements → ✅ FIX WORKS
- If still timing out on notification text → ❌ TOASTER NOT RENDERING (debug below)

### ✅ SUCCESS CRITERIA - Accessibility Fix (Task 1298)

Search for linking button test:
```bash
grep -i "linking\|add link\|close link mode" /tmp/e2e_final_verification.log
```

**Expected outcomes:**
- Test: "Mode Exclusivity: Linking vs Simulation" (robustness.spec.ts:78)
- Previous failure: Button not found (health check blocked initialization)
- Current expectation: Should either PASS or fail with different error (not initialization timeout)

**Success Definition:**
- If button is now found but test fails for other reason → ✅ ACCESSIBILITY FIX WORKS
- If still can't find button → ❌ ARIA-LABEL NOT APPLIED (debug below)

### ✅ OVERALL SUCCESS METRICS

```bash
# Extract final summary
tail -50 /tmp/e2e_final_verification.log | grep -E "passed|failed|skipped"
```

**Target:**
- Should see something like: "X passed, Y failed, Z skipped"
- No mention of HTTP 429 errors anywhere in log
- At least 5-10 more tests passing compared to previous runs (due to notifications fix)

---

## If Verification FAILS

### Scenario 1: Notification Tests Still Timing Out
**Debugging steps:**

1. Check if Toaster component is in compiled output:
```bash
grep -r "Sonner" src/App.bs.js
```

2. Check browser console during test (via test video):
```bash
# Look in test-results for any of the failed notification tests
# Open the .webm video file to see browser console output
```

3. Verify NotificationCenter is dispatching:
```bash
grep "RENDERED_TOAST\|NotificationCenter" /tmp/e2e_final_verification.log
```

**If no RENDERED_TOAST logs:** NotificationManager may not be receiving notifications. Check:
- `src/systems/NotificationManager.res` - is state being updated?
- Test helper functions - are they dispatching notifications correctly?

### Scenario 2: Linking Button Still Not Found
**Debugging steps:**

1. Check aria-label is in Shadcn Button binding:
```bash
grep -A 5 "external make.*Button" src/components/ui/Shadcn.res | head -10
```

2. Check UtilityBar is using ariaLabel prop:
```bash
grep -A 3 "aria.*[Ll]abel\|Add Link" src/components/UtilityBar.res | head -10
```

3. Run single test with debugging:
```bash
npx playwright test robustness.spec.ts -g "Linking vs Simulation" --headed
```

### Scenario 3: Unexpected Failures
- Document exact error message and test name
- Check test-results/ directory for videos/traces
- Determine if it's a new issue or existing issue unrelated to these fixes

---

## Update Task Status

After verification, update this task:

### If ✅ SUCCESS (both fixes verified):
1. Move this task to: `tasks/completed/1301_VERIFY_Notification_Accessibility_Fixes_DONE.md`
2. Archive original tasks 1297 and 1298:
   - Move `1297_ERR_Notification_Rendering_NotAppearing.md` → `tasks/completed/1297_ERR_Notification_Rendering_NotAppearing_DONE.md`
   - Move `1298_ERR_LinkButton_Accessibility_Discoverability.md` → `tasks/completed/1298_ERR_LinkButton_Accessibility_Discoverability_DONE.md`
3. Create new task for remaining failures (Tasks 1299, 1300)

### If ❌ PARTIAL (one fix works, one doesn't):
1. Update this file with findings
2. Create separate task(s) for remaining failures
3. Keep this task in pending with "PARTIAL" status

### If ❌ FAILURE (neither fix works):
1. Document detailed debugging output
2. Create investigation task with findings
3. Keep this task in pending with debugging notes

---

## Quick Reference: Key Files

| File | Purpose |
|------|---------|
| `src/App.res` | Contains `<Shadcn.Sonner />` component (line 68) |
| `src/components/NotificationCenter.res` | Dispatches toasts when notifications occur |
| `src/components/ui/Shadcn.res` | Sonner and Button bindings |
| `src/components/UtilityBar.res` | Contains linking button with aria-label |
| `backend/src/main.rs` | Rate limiter config (lines 107-110) |
| `tests/e2e/robustness.spec.ts` | Contains notification and linking tests |

---

## Success Checklist

- [ ] Backend health check responds with "Tour Builder API is running!"
- [ ] Frontend builds successfully (npm run build)
- [ ] Frontend runs on http://localhost:3000
- [ ] E2E tests run to completion without hanging
- [ ] Zero HTTP 429 errors in test output
- [ ] Notification tests find toast elements (not timing out)
- [ ] Linking button test finds button (or fails with discovery error, not init timeout)
- [ ] Overall test pass rate improved vs. previous runs
- [ ] Task status updated accordingly

---

## Notes for Next AI

- This combines 2 independent fixes that should both work
- If one fails, the other might still be valid
- The Toaster fix is critical: without it, Sonner API calls have nowhere to render
- The aria-label fix depends on proper HTML attribute binding in ReScript
- Rate limiter fix (1296) is already verified - if you see 429 errors, something is wrong with backend start

Good luck! 🚀
