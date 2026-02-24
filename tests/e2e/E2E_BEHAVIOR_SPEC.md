# E2E Test Behavior Specification

**Document Purpose:** Verify that all E2E tests match the current application architecture and expected behavior.

**Date:** February 24, 2026  
**Version:** 4.8.0

---

## ⚠️ DEPRECATED FEATURES

### Return Links (DEPRECATED)
**Status:** No longer required/implemented  
**Tests Affected:** `hotspot-advanced.spec.ts` - Test "should toggle return link on hotspot"  
**Action Needed:** This test should be removed or marked as skip.

---

## NEW E2E TESTS (v4.8.0) - Behavior Verification Required

### P0 - CRITICAL TESTS

---

#### 1. `timeline-management.spec.ts` (7 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 1.1 | `should add timeline item from scene context menu` | Adding timeline items via UI | User can add timeline items to scenes via + button or context menu | ⬜ |
| 1.2 | `should update timeline transition type (Cut/Fade/Link)` | Changing transition types | Users can select Cut/Fade/Link for each timeline item | ⬜ |
| 1.3 | `should update timeline duration` | Setting transition duration | Users can set custom duration (ms) per timeline item | ⬜ |
| 1.4 | `should reorder timeline items via drag-and-drop` | Reordering timeline | Users can drag timeline items to change order | ⬜ |
| 1.5 | `should remove timeline item` | Deleting timeline items | Users can delete timeline items with confirmation | ⬜ |
| 1.6 | `should navigate to active timeline step` | Timeline navigation | Clicking "Play/Go" on timeline item navigates to that scene | ⬜ |
| 1.7 | `should preserve timeline through save/load cycle` | Timeline persistence | Timeline survives project save/reload | ⬜ |

**Questions:**
- Does the timeline feature exist in current UI?
- What UI elements are used for timeline management?
- Is drag-and-drop reordering supported?
- What transition types are available (Cut/Fade/Link)?

---

#### 2. `auto-forward-comprehensive.spec.ts` (6 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 2.1 | `should create auto-forward link via hotspot action menu` | Creating auto-forward links | Users can enable auto-forward toggle when creating hotspots | ⬜ |
| 2.2 | `should navigate auto-forward chain during simulation` | Auto-navigation in simulation | Simulation follows auto-forward links automatically | ⬜ |
| 2.3 | `should respect skipAutoForwardGlobal toggle` | Global skip toggle | When enabled, simulation skips auto-forward bridges | ⬜ |
| 2.4 | `should enforce one auto-forward per scene (link-level)` | Validation rule | Only ONE hotspot per scene can have auto-forward enabled | ⬜ |
| 2.5 | `should migrate scene-level auto-forward to link-level` | Backward compatibility | Old projects with `scene.isAutoForward` migrate to `hotspot.isAutoForward` | ⬜ |
| 2.6 | `should handle broken auto-forward links gracefully` | Error handling | Simulation handles links pointing to non-existent scenes | ⬜ |

**Questions:**
- Is auto-forward now at the **hotspot level** (not scene level)?
- Is there validation preventing multiple auto-forwards per scene?
- Does `skipAutoForwardGlobal` toggle exist?
- What happens when auto-forward link target doesn't exist?

---

#### 3. `export-templates.spec.ts` (7 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 3.1 | `should export HD template with correct dimensions` | HD export | Users can select HD template for export | ⬜ |
| 3.2 | `should export 2K template with enhanced quality` | 2K export | Users can select 2K template for export | ⬜ |
| 3.3 | `should export 4K template with maximum quality` | 4K export | Users can select 4K template for export | ⬜ |
| 3.4 | `should include custom logo in export` | Logo customization | Users can upload custom logo included in export | ⬜ |
| 3.5 | `should generate self-contained HTML with embedded viewer` | Standalone export | Export includes embedded Pannellum (no external deps) | ⬜ |
| 3.6 | `should show file protocol warning for non-desktop exports` | Protocol warning | Warning shown about file:// limitations | ⬜ |
| 3.7 | `should validate exported tour navigation works` | Export validation | Exported tour has working hotspot navigation | ⬜ |

**Questions:**
- Are HD/2K/4K template options available in export dialog?
- Can users upload custom logos?
- Is there a "self-contained HTML" option?
- Is there a file:// protocol warning?

---

### P1 - HIGH PRIORITY TESTS

---

#### 4. `multi-floor-management.spec.ts` (6 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 4.1 | `should assign scenes to different floors` | Floor assignment | Users can assign scenes to floors (ground/first/second) | ⬜ |
| 4.2 | `should assign multiple scenes to different floors` | Multiple floor assignment | Multiple scenes can have different floor assignments | ⬜ |
| 4.3 | `should navigate floors using floor navigation UI` | Floor navigation | UI exists to filter/navigate by floor | ⬜ |
| 4.4 | `should display floor tags in viewer HUD` | Floor tags | Current floor shown in viewer HUD | ⬜ |
| 4.5 | `should filter scenes by floor in sidebar` | Floor filtering | Sidebar can filter scenes by floor | ⬜ |
| 4.6 | `should preserve floor assignments through export` | Floor persistence | Floor assignments preserved in exported tours | ⬜ |

**Questions:**
- What floor options exist (ground/first/second/outdoor)?
- Is there a floor navigation UI component?
- Are floor tags visible in the viewer HUD?
- Can users filter scenes by floor in sidebar?

---

#### 5. `hotspot-advanced.spec.ts` (7 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 5.1 | `should configure Director View target yaw/pitch/hfov` | Director View | Users can set target camera position (yaw/pitch/hfov) for hotspots | ⬜ |
| 5.2 | `should toggle return link on hotspot` | **DEPRECATED** | ⚠️ **REMOVE THIS TEST** - Return links are deprecated | ⬜ |
| 5.3 | `should add waypoints to hotspot` | Waypoint animation | Users can add intermediate camera positions for animated transitions | ⬜ |
| 5.4 | `should edit hotspot transition type` | Transition types | Users can select transition type (fade/cut/zoom) per hotspot | ⬜ |
| 5.5 | `should edit hotspot duration` | Transition duration | Users can set custom transition duration (ms) per hotspot | ⬜ |
| 5.6 | `should add/edit hotspot label` | Hotspot labels | Users can add custom text labels to hotspots | ⬜ |
| 5.7 | `should display hotspot connection lines` | Visual connections | Lines showing hotspot connections in visual pipeline | ⬜ |

**Questions:**
- Does Director View (target yaw/pitch/hfov) exist?
- **Return links are deprecated - confirm removal**
- Do waypoints exist for animated transitions?
- What transition types are available?
- Can users set custom duration per hotspot?
- Can users add custom labels to hotspots?
- Are connection lines shown in visual pipeline?

---

#### 6. `teaser-advanced.spec.ts` (6 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 6.1 | `should select teaser style (Cinematic/Fast Shots/Simple Crossfade)` | Teaser styles | Users can select teaser style (Cinematic/Fast/Simple) | ⬜ |
| 6.2 | `should configure teaser duration` | Teaser duration | Users can set custom teaser duration | ⬜ |
| 6.3 | `should cancel teaser recording` | Cancellation | Users can cancel teaser generation mid-process | ⬜ |
| 6.4 | `should fallback to WebM when MP4 encoding fails` | Format fallback | WebM used as fallback when MP4 fails | ⬜ |
| 6.5 | `should display teaser progress with ETA` | Progress UI | Progress bar/ETA shown during teaser generation | ⬜ |
| 6.6 | `should show server-side teaser rendering option` | Server rendering | Option for server-side/cloud teaser rendering | ⬜ |

**Questions:**
- What teaser styles are available (Cinematic/Fast Shots/Simple Crossfade)?
- Can users configure teaser duration?
- Is there a cancel button during recording?
- Does MP4/WebM fallback exist?
- Is there a progress bar with ETA?
- Is server-side rendering an option?

---

### P2 - MEDIUM PRIORITY TESTS

---

#### 7. `import-export-edge-cases.spec.ts` (7 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 7.1 | `should handle large project import (100+ scenes)` | Large imports | App can import projects with 100+ scenes | ⬜ |
| 7.2 | `should reject corrupted ZIP files gracefully` | Corrupted files | Error shown for invalid ZIP files, app remains functional | ⬜ |
| 7.3 | `should migrate old project versions during import` | Version migration | Old projects auto-migrate to current format | ⬜ |
| 7.4 | `should block export when no floors assigned` | Floor validation | Export blocked/warned if no floors assigned | ⬜ |
| 7.5 | `should cancel export on user request` | Export cancellation | Users can cancel export mid-process | ⬜ |
| 7.6 | `should handle export timeout gracefully` | Timeout handling | Graceful error shown on export timeout | ⬜ |
| 7.7 | `should handle missing images in imported project` | Missing images | App handles missing image references gracefully | ⬜ |

**Questions:**
- Is there a floor assignment requirement for export?
- Can users cancel export mid-process?
- What happens on export timeout?
- How are missing images handled?

---

#### 8. `accessibility-comprehensive.spec.ts` (7 tests)

| # | Test Name | What It Tests | Expected Behavior | Verify? |
|---|-----------|---------------|-------------------|---------|
| 8.1 | `should navigate entire app using keyboard only` | Keyboard navigation | Full app usable with Tab/Enter/Escape only | ⬜ |
| 8.2 | `should maintain focus order through modals` | Focus trapping | Focus trapped in modals, returns on close | ⬜ |
| 8.3 | `should announce state changes to screen readers` | ARIA live regions | State changes announced via aria-live | ⬜ |
| 8.4 | `should have proper ARIA labels on interactive elements` | ARIA labels | Buttons/links have aria-labels or text content | ⬜ |
| 8.5 | `should support high contrast mode` | High contrast | App respects forced-colors/prefer-contrast | ⬜ |
| 8.6 | `should provide skip links for repetitive content` | Skip links | Skip-to-content links for keyboard users | ⬜ |
| 8.7 | `should have proper heading hierarchy` | Heading structure | H1-H6 hierarchy without skipped levels | ⬜ |

**Questions:**
- Is full keyboard navigation supported?
- Are modals focus-trapped?
- Are ARIA live regions used for announcements?
- Do all interactive elements have accessible names?
- Is high contrast/forced-colors supported?
- Are skip links provided?
- Is heading hierarchy valid (single H1, no skipped levels)?

---

## EXISTING E2E TESTS - Behavior Verification

### Previously Updated Tests (v4.7.8)

| File | Tests | Behavior | Verify? |
|------|-------|----------|---------|
| `simulation-teaser.spec.ts` | Auto-forward validation | "Only one auto-forward per scene" error shown | ⬜ |
| `perf-budgets.spec.ts` | Hotspot isAutoForward | Hotspots have `isAutoForward` property | ⬜ |
| `optimistic-rollback.spec.ts` | Scene/hotspot rollback | Optimistic updates with rollback on failure | ⬜ |

---

## SUMMARY: Questions for Verification

### Critical Architecture Questions:

1. **Auto-Forward:** Is it now at **hotspot level** (`hotspot.isAutoForward`) instead of scene level?
2. **Validation:** Is there a rule preventing multiple auto-forwards per scene?
3. **Timeline:** Does the timeline feature exist? What's the UI for managing it?
4. **Floors:** What floor options exist? Is there floor filtering UI?
5. **Export Templates:** Are HD/2K/4K options available?
6. **Director View:** Can users set target yaw/pitch/hfov for hotspots?
7. **Waypoints:** Do animated waypoint transitions exist?
8. **Teaser Styles:** What styles are available (Cinematic/Fast/Simple)?
9. **Return Links:** **CONFIRMED DEPRECATED** - should remove related tests

### Features to Confirm Exist:

- [ ] Timeline management UI
- [ ] Auto-forward toggle in hotspot modal
- [ ] One auto-forward per scene validation
- [ ] HD/2K/4K export templates
- [ ] Custom logo upload
- [ ] Floor assignment dropdown
- [ ] Floor navigation/filtering UI
- [ ] Director View camera settings
- [ ] Hotspot waypoints
- [ ] Hotspot transition type selector
- [ ] Hotspot duration input
- [ ] Hotspot label input
- [ ] Teaser style selector
- [ ] Teaser progress indicator
- [ ] Export cancellation
- [ ] Keyboard navigation support
- [ ] ARIA live regions
- [ ] Focus trapping in modals

---

## ACTION ITEMS

1. **Remove deprecated test:** `hotspot-advanced.spec.ts` → "should toggle return link on hotspot"
2. **Update tests** based on actual UI implementation
3. **Add skip annotations** for features not yet implemented
4. **Verify selector paths** match actual DOM structure

---

**Please review each test above and mark:**
- ✅ = Behavior is correct, test is valid
- ⚠️ = Behavior partially correct, test needs updates
- ❌ = Behavior is wrong, test needs rewrite
- ⬜ = Feature doesn't exist, test should be removed/skipped
