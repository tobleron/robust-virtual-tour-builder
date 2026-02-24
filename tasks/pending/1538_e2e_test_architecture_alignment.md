# Task 1538: E2E Test Suite Architecture Alignment - Behavior-Based Update

## Assignee
Jules (AI Agent)

## Capacity Class
**B** (Two tightly-coupled objectives within same subsystem)
- Objective 1: Update 8 new E2E test files to match actual architecture behavior
- Objective 2: Update existing E2E tests that reference deprecated/changed features

## Objective
Update all E2E test files (new and existing) to accurately reflect the current application architecture and user interaction patterns as verified through behavior specification session with project owner.

## Boundary
- **Allowed directories**: `tests/e2e/`
- **Allowed files**: All `.spec.ts` files in E2E test directory
- **Related documentation**: `tests/e2e/E2E_BEHAVIOR_SPEC.md` (to be updated with answers)

## Owned Interfaces
- Playwright test specifications
- Test selectors and locators
- Test assertions and expectations

## No-Touch Zones
- **Source code**: `src/`, `backend/` (no implementation changes)
- **Test infrastructure**: `tests/e2e-helpers.ts`, `tests/e2e/ai-helper.ts` (unless minor additions needed)
- **Playwright config**: `playwright.config.ts`
- **Unit tests**: `tests/unit/`

## Independent Verification
Each updated test file must:
1. Pass TypeScript compilation (`npx tsc --noEmit`)
2. Be recognized by Playwright test runner (`npx playwright test --list <file>`)
3. Include console logging for debugging (`console.log()` statements)
4. Use proper stabilization waits (`waitForNavigationStabilization()`)

## Depends On
- Task T1537 (Scene Sequence ID) - COMPLETED
- Behavior specification session with project owner (completed via chat)

---

## Context & Background

### Current State
- 8 new E2E test files created in v4.8.0 with **incorrect behavior assumptions**
- Tests were based on architectural assumptions, not actual implemented behavior
- Many tests expect features that don't exist or work differently than documented

### Discovery Process
A comprehensive behavior specification session was conducted where each feature was verified with the project owner. Key findings:

**⚠️ IMPORTANT: Some answers from the conversation need codebase verification:**

| Feature | Conversation Answer | Codebase Verification | Status |
|---------|---------------------|----------------------|--------|
| `hotspot.isAutoForward` | Yes, hotspot-level | ✅ Confirmed in 86 matches | **VERIFIED** |
| `skipAutoForwardGlobal` | "Doesn't exist" | ❌ **EXISTS** (11 matches in State.res, Simulation.res, etc.) | **NEEDS UPDATE** |
| Return links | "Deprecated" | ❌ **ACTIVE** (43 matches, used in SceneSwitcher, TeaserLogic, etc.) | **NEEDS UPDATE** |
| Timeline drag-drop | "Deprecated" | ⚠️ Only 1 match (TimelineCleanup.res) | **LIKELY CORRECT** |
| Transition types | "Hardcoded, no selection" | ⚠️ Types exist (Cut/Fade), user selection unclear | **NEEDS VERIFY** |
| Export HD/2K/4K selection | "All automatic, no UI" | ⚠️ `is-hd-export` CSS class exists | **NEEDS VERIFY** |
| Floor buttons | "Viewer floor buttons only" | ✅ Confirmed (FloorNavigation.res) | **VERIFIED** |
| Waypoints | "Created during add-link" | ✅ Confirmed (99 matches) | **VERIFIED** |
| ARIA live regions | "Uncertain" | ✅ Found `aria-live="polite"`, `role="alert"` | **VERIFIED** |
| Keyboard shortcuts (export) | "Numbers/letters, h/m" | ✅ Confirmed (81 matches in TourTemplates) | **VERIFIED** |
| High contrast | "Not supported" | ⚠️ Needs verification | **UNCERTAIN** |

---

## Implementation Plan

### Phase 0: Codebase Verification Results (COMPLETED)

**Purpose:** Verify conversation answers against actual codebase before updating tests.

| Feature | Conversation Answer | Code Verification | **FINAL STATUS** |
|---------|---------------------|-------------------|------------------|
| `hotspot.isAutoForward` | Yes, hotspot-level | ✅ 86 matches, UI toggle exists | **ALIVE - VERIFIED** |
| `skipAutoForwardGlobal` | "Doesn't exist" | ⚠️ 11 matches in state/reducer, **NO UI component**, **NO dispatch calls** | **DEAD CODE** |
| Return links (`isReturnLink`) | "Deprecated" | ⚠️ 43 matches, used in components, **BUT NO UI toggle button** | **DEAD CODE** (data exists, UI removed) |
| Timeline drag-drop | "Deprecated" | ⚠️ 1 match only | **DEAD CODE** |
| Export quality selection | "All automatic" | ⚠️ CSS classes exist, **NO UI selector** | **DEAD CODE** (CSS remnants) |
| Transition type selection | "Hardcoded" | ⚠️ Types exist, **NO UI selector** | **DEAD CODE** (types only) |
| Floor buttons | "Viewer buttons only" | ✅ FloorNavigation.res exists | **ALIVE - VERIFIED** |
| Waypoints | "Created during add-link" | ✅ 99 matches, active | **ALIVE - VERIFIED** |
| ARIA live regions | "Uncertain" | ✅ `aria-live="polite"` found | **ALIVE - VERIFIED** |
| Keyboard shortcuts (export) | "Numbers/letters" | ✅ 81 matches in TourTemplates | **ALIVE - VERIFIED** |
| High contrast mode | "Not supported" | ❌ No matches | **NOT IMPLEMENTED** |

---

**CONCLUSIONS:**

1. **`skipAutoForwardGlobal`** - **DEAD CODE**
   - Action `SetSkipAutoForward` exists but never dispatched
   - State field exists but no UI toggle
   - **Test Action:** REMOVE test for this feature

2. **Return Links** - **DEAD CODE**
   - `isReturnLink` field exists in data structure
   - Used in some logic (SceneSwitcher, TeaserLogic)
   - **BUT** no UI toggle button in HotspotActionMenu
   - **Test Action:** DEPRECATE test (feature may be read-only legacy)

3. **Export Quality Selection** - **DEAD CODE**
   - CSS classes (`is-hd-export`) exist but no UI
   - **Test Action:** REMOVE tests for quality selection UI

4. **Transition Type Selection** - **DEAD CODE**
   - Types exist but no UI selector
   - **Test Action:** REMOVE tests for transition type selection

5. **High Contrast Mode** - **NOT IMPLEMENTED**
   - No code found
   - **Test Action:** REMOVE test

### Phase 1: Update New E2E Test Files (8 files)

#### 1.1 `timeline-management.spec.ts` - MAJOR REWRITE
**Current**: 7 tests assuming manual CRUD operations
**Required**: Focus on auto-generation and verification

**REMOVE** (features don't exist):
- Test: "should add timeline item from scene context menu"
- Test: "should update timeline transition type"
- Test: "should update timeline duration"
- Test: "should reorder timeline items via drag-and-drop"
- Test: "should remove timeline item"

**KEEP & UPDATE**:
- Test: "should navigate to scene on timeline click" → Verify click navigation works
- Test: "should preserve timeline through save/load" → Verify auto-generation persists

**ADD** (actual behavior):
- Test: "should auto-generate timeline square when hotspot created"
- Test: "should color-code squares by histogram (orange-brown for simple, emerald for auto-forward)"
- Test: "should show tooltip with linkId after 3-second hover"
- Test: "should show thumbnail preview on hover"
- Test: "should delete timeline square when hotspot deleted"
- Test: "should allow sidebar scene drag-drop reordering" (this IS supported)

---

#### 1.2 `auto-forward-comprehensive.spec.ts` - UPDATE
**Current**: 6 tests with some incorrect assumptions
**Required**: Align with actual auto-forward behavior

**REMOVE**:
- Test: "should respect skipAutoForwardGlobal toggle" → Feature doesn't exist

**SKIP** (hard to test):
- Test: "should migrate scene-level auto-forward to link-level" → Requires old project ZIP

**KEEP & UPDATE**:
- Test: "should create auto-forward link via hotspot action menu"
  - Update: Emerald green double-chevron button appears on hover
  - Update: Click toggles auto-forward on/off
  
- Test: "should navigate auto-forward chain during simulation"
  - Update: Include waypoint animation details (arrow travels start→end)
  - Update: First scene pans to waypoint start, subsequent scenes don't pan
  
- Test: "should enforce one auto-forward per scene (link-level)"
  - Update: Toast notification shown
  - Update: 2nd attempt reverts to simple link
  
- Test: "should handle broken auto-forward links gracefully"
  - Update: App auto-deletes links pointing to deleted scenes
  - Update: This applies to ALL links (auto-forward and simple)

---

#### 1.3 `export-templates.spec.ts` - MAJOR REWRITE
**Current**: 7 tests assuming quality selection UI
**Required**: Reflect automatic multi-quality export

**REMOVE** (no user selection):
- Test: "should export HD template with correct dimensions"
- Test: "should export 2K template with enhanced quality"
- Test: "should export 4K template with maximum quality"
- Test: "should show file protocol warning for non-desktop exports"

**KEEP & UPDATE**:
- Test: "should include custom logo in export"
  - Update: Logo auto-resized and compressed
  
- Test: "should generate self-contained HTML with embedded viewer"
  - Update: Verify blobs embedded, no external deps
  
- Test: "should validate exported tour navigation works"
  - Update: Mark as needs verification for loop prevention
  - Update: Verify auto-forward priority (last in multi-link scenes)

**ADD** (actual behavior):
- Test: "should include all qualities (HD/2K/4K) automatically"
- Test: "should include standalone HTML with blobs"
- Test: "should include web_only folder for server-based viewing"
- Test: "should include instructions inside ZIP"

---

#### 1.4 `multi-floor-management.spec.ts` - UPDATE
**Current**: 6 tests assuming floor navigation UI exists
**Required**: Reflect actual floor button behavior

**REMOVE** (features don't exist):
- Test: "should navigate floors using floor navigation UI"
- Test: "should filter scenes by floor in sidebar"

**KEEP & UPDATE**:
- Test: "should assign scenes to different floors"
  - Update: Via floor buttons in viewer (left side)
  - Update: Only one floor per scene
  
- Test: "should assign multiple scenes to different floors"
  - Update: Verify persistence across project lifetime
  
- Test: "should display floor tags in viewer HUD"
  - Update: Blue tag shows room label (not floor name)
  - Update: Tag at top center, persists for project lifecycle
  
- Test: "should preserve floor assignments through export"
  - Update: Active floor shown in orange, others white/transparent
  - Update: Only floors with scenes are displayed (empty floors hidden)

**ADD** (actual behavior):
- Test: "should set floor via viewer floor buttons"
- Test: "should set room label via utility bar # button"
- Test: "should show only floors with scenes in exported tour"

---

#### 1.5 `hotspot-advanced.spec.ts` - MAJOR REWRITE
**Current**: 7 tests with many incorrect assumptions
**Required**: Reflect 3-state hotspot model (added/auto-forward/deleted)

**DEPRECATE** (feature deprecated):
- Test: "should toggle return link on hotspot" → Mark as `test.skip()` with comment

**REMOVE** (features don't exist):
- Test: "should configure Director View target yaw/pitch/hfov"
- Test: "should edit hotspot transition type"
- Test: "should edit hotspot duration"
- Test: "should add/edit hotspot label"

**KEEP & UPDATE**:
- Test: "should add waypoints to hotspot"
  - Update: Created during add-link mode only
  - Update: Yellow dashed line (user cursor) + orange dashed line (auto camera heading)
  - Update: Orange lines persist after successful creation (if ESC not pressed)
  - Update: Orange arrow at start is clickable (triggers travel animation preview)
  - Update: User clicks final point + presses ENTER to finalize
  - Update: Waypoint NOT editable (only delete and recreate)
  
- Test: "should display hotspot connection lines"
  - Update: PCB-like orange lines from floor buttons to squares
  - Update: Each floor has separate row in visual pipeline
  - Update: Simple links: orange-brown (histogram-based)
  - Update: Auto-forward links: emerald green

**ADD** (actual behavior):
- Test: "should show orange arrow at waypoint start"
- Test: "should allow waypoint preview via arrow click"
- Test: "should persist orange dashed lines after link creation"

---

#### 1.6 `teaser-advanced.spec.ts` - UPDATE
**Current**: 6 tests assuming multiple styles and backend features
**Required**: Reflect frontend-only WebM with Cinematic style

**REMOVE** (features don't exist):
- Test: "should select teaser style (Cinematic/Fast Shots/Simple Crossfade)"
- Test: "should configure teaser duration"
- Test: "should show server-side teaser rendering option"

**UPDATE**:
- Test: "should fallback to WebM when MP4 encoding fails"
  - Change to: "should generate WebM format (MP4 not implemented)"
  - Note: MP4 is future backend feature
  
- Test: "should display teaser progress with ETA"
  - Update: Progress bar shows ETA during generation
  - Update: Other ETAs shown in orange toast notifications

**KEEP**:
- Test: "should cancel teaser recording"
  - Update: Cancel button on progress bar + ESC key global listener

**ADD** (actual behavior):
- Test: "should use Cinematic style (default, only working style)"

---

#### 1.7 `import-export-edge-cases.spec.ts` - UPDATE
**Current**: 7 tests, many for uncertain features
**Required**: Focus on verified behavior only

**SKIP** (uncertain/not implemented):
- Test: "should reject corrupted ZIP files gracefully" → Task exists, not implemented
- Test: "should migrate old project versions during import" → Uncertain if implemented
- Test: "should handle export timeout gracefully" → Uncertain
- Test: "should handle missing images in imported project" → Uncertain

**REMOVE** (not applicable):
- Test: "should block export when no floors assigned" → Floor G is default, never blocked

**KEEP**:
- Test: "should handle large project import (100+ scenes)"
  - Update: Reference x700.zip stress test file in artifacts
  
- Test: "should cancel export on user request"
  - Update: Cancel button + ESC key

**ADD** (actual behavior):
- Test: "should assign Floor G by default to all scenes"

---

#### 1.8 `accessibility-comprehensive.spec.ts` - UPDATE
**Current**: 7 tests assuming full accessibility implementation
**Required**: Reflect actual limited implementation

**REMOVE** (not supported):
- Test: "should support high contrast mode" → Not implemented
- Test: "should provide skip links for repetitive content" → Not implemented, unnecessary

**SKIP** (uncertain implementation):
- Test: "should navigate entire app using keyboard only"
- Test: "should announce state changes to screen readers"
- Test: "should have proper ARIA labels on interactive elements"
- Test: "should have proper heading hierarchy"

**KEEP**:
- Test: "should maintain focus order through modals"
  - Update: Focus trapping works, return behavior uncertain

**ADD** (actual behavior):
- Test: "should support keyboard shortcuts in exported tours"
  - Numbers and letters for navigation
  - 'h' for home, 'm' for more

---

### Phase 2: Update Existing E2E Tests

#### 2.1 `simulation-teaser.spec.ts`
**UPDATE**: Auto-forward validation test
- Verify emerald double-chevron button
- Verify toast notification on 2nd auto-forward attempt
- Verify revert to simple link behavior

#### 2.2 `perf-budgets.spec.ts`
**UPDATE**: Hotspot isAutoForward references
- Ensure tests use `hotspot.isAutoForward` (not `scene.isAutoForward`)

#### 2.3 `editor.spec.ts`
**VERIFY**: Hotspot creation flow
- Ensure waypoint creation with ENTER key is documented
- Verify orange arrow preview functionality

---

### Phase 3: Documentation Updates

#### 3.1 Update `E2E_BEHAVIOR_SPEC.md`
- Add all verified answers to the document
- Mark each feature with ✅ (verified), ⚠️ (partial), or ❌ (not implemented)
- Create quick reference table for future test authors

#### 3.2 Create Test Behavior Summary
Add to `docs/_pending_integration/`:
- One-page summary of actual vs. assumed behavior
- List of deprecated features
- List of future features (not yet implemented)
- Common pitfalls for test authors

---

## Verification Steps

### Step 1: TypeScript Compilation
```bash
cd /Users/r2/Desktop/robust-virtual-tour-builder
npx tsc --noEmit tests/e2e/*.spec.ts
```
**Expected**: No compilation errors

### Step 2: Playwright Test Listing
```bash
npx playwright test --list tests/e2e/timeline-management.spec.ts
npx playwright test --list tests/e2e/auto-forward-comprehensive.spec.ts
npx playwright test --list tests/e2e/export-templates.spec.ts
npx playwright test --list tests/e2e/multi-floor-management.spec.ts
npx playwright test --list tests/e2e/hotspot-advanced.spec.ts
npx playwright test --list tests/e2e/teaser-advanced.spec.ts
npx playwright test --list tests/e2e/import-export-edge-cases.spec.ts
npx playwright test --list tests/e2e/accessibility-comprehensive.spec.ts
```
**Expected**: All tests recognized and listed

### Step 3: Behavior Verification
For each updated test, verify:
- [ ] Console logging present for debugging
- [ ] Proper waits/stabilization used
- [ ] Selectors match actual UI elements
- [ ] Assertions reflect actual behavior (not assumed)
- [ ] Deprecated features marked with `test.skip()` and comment

---

## Acceptance Criteria

### Code Quality
- [ ] All 8 new test files compile without errors
- [ ] All tests are recognized by Playwright test runner
- [ ] No TypeScript errors or warnings
- [ ] Console logging added for debugging

### Behavior Alignment
- [ ] Timeline tests reflect auto-generation (no manual CRUD)
- [ ] Auto-forward tests use hotspot-level toggle (emerald double-chevron)
- [ ] Export tests reflect automatic multi-quality packaging
- [ ] Floor tests use viewer floor buttons (not separate UI)
- [ ] Hotspot tests reflect 3-state model (added/auto-forward/deleted)
- [ ] Teaser tests reflect Cinematic-only WebM generation
- [ ] Accessibility tests reflect actual implementation (focus trapping only)

### Documentation
- [ ] `E2E_BEHAVIOR_SPEC.md` updated with all verified answers
- [ ] Test behavior summary created in `docs/_pending_integration/`
- [ ] Deprecated features clearly marked in test files
- [ ] Future features noted with "not yet implemented" comments

### Test Integrity
- [ ] No tests assume features that don't exist
- [ ] All tests have proper stabilization waits
- [ ] Selectors use role/name/data-testid where available
- [ ] Fallback selectors documented for portal-based elements

---

## Deliverables

1. **Updated Test Files** (8 files):
   - `tests/e2e/timeline-management.spec.ts`
   - `tests/e2e/auto-forward-comprehensive.spec.ts`
   - `tests/e2e/export-templates.spec.ts`
   - `tests/e2e/multi-floor-management.spec.ts`
   - `tests/e2e/hotspot-advanced.spec.ts`
   - `tests/e2e/teaser-advanced.spec.ts`
   - `tests/e2e/import-export-edge-cases.spec.ts`
   - `tests/e2e/accessibility-comprehensive.spec.ts`

2. **Updated Existing Tests** (3 files):
   - `tests/e2e/simulation-teaser.spec.ts`
   - `tests/e2e/perf-budgets.spec.ts`
   - `tests/e2e/editor.spec.ts`

3. **Documentation**:
   - Updated `tests/e2e/E2E_BEHAVIOR_SPEC.md`
   - New `docs/_pending_integration/E2E_TEST_BEHAVIOR_SUMMARY.md`

4. **Verification Evidence**:
   - TypeScript compilation output (no errors)
   - Playwright test list output (all tests recognized)
   - Console log examples from test runs

---

## Merge Risk

**Expected conflict files**:
- `tests/e2e/*.spec.ts` (only files being modified)
- `tests/e2e/E2E_BEHAVIOR_SPEC.md` (documentation update)
- `docs/_pending_integration/` (new documentation)

**No conflict expected**:
- Source code (`src/`, `backend/`)
- Test infrastructure (`tests/e2e-helpers.ts`, etc.)
- Configuration files

---

## Notes for Reviewer

### Key Behavior Changes to Verify
1. **Timeline**: Auto-generated from hotspots, NOT manually editable
2. **Auto-Forward**: Emerald double-chevron button on hover, one-per-scene validation
3. **Export**: All qualities included automatically (no selection UI)
4. **Floors**: Viewer floor buttons only (no filtering UI)
5. **Hotspots**: 3 states only (added, auto-forward toggle, deleted)
6. **Teaser**: Cinematic WebM only (frontend generation)
7. **Accessibility**: Focus trapping works, rest uncertain/not implemented

### Deprecated Features (Marked in Tests)
- Return links (deprecated)
- skipAutoForwardGlobal toggle (never implemented)
- Timeline drag-drop reordering (deprecated)
- Manual timeline CRUD (never existed)

### Future Features (Not Yet Implemented)
- MP4 teaser generation (backend)
- Fast Shots / Simple Crossfade teaser styles
- Floor filtering UI
- High contrast mode
- ARIA live regions
- Skip links

---

## Estimated Effort
- Phase 1 (8 new files): ~6 hours
- Phase 2 (3 existing files): ~2 hours
- Phase 3 (documentation): ~1 hour
- Verification: ~1 hour
- **Total**: ~10 hours

---

## Task Completion Evidence

Upon completion, this task file should be renamed to:
`1538_e2e_test_architecture_alignment_DONE.md`

And moved to `tasks/completed/` folder.

No additional report needed - the updated test files and documentation serve as completion evidence.
