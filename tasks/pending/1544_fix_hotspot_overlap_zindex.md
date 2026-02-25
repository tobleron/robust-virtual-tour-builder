# 1544 — Fix Hotspot Overlap Z-Index (Waypoint Arrow Precedes Hotspot Button)

## Priority: P0 — Active UI Bug

## Objective
Resolve the z-index layering issue where waypoint/arrow SVG elements overlap and block interaction with hotspot action buttons (the hover menu).

## Context
This is a known active bug confirmed by the product owner. Recent conversations (454e5f0c, b6c8e14b) attempted fixes but the issue persists. The problem: when a user hovers over a hotspot to reveal the action menu (center/right/bottom/far-bottom buttons), the SVG overlay containing waypoint lines and arrows sits on top, intercepting pointer events.

## Current State
- `PreviewArrow.res` sets `z-[6000]` on the hotspot container
- Waypoint guide lines/arrows are drawn via `SvgManager` / `HotspotLineDrawing`
- The E2E test `hotspot-overlap-a01.spec.ts` tests for this scenario
- Previous fix attempts introduced a suppression logic in T1533 that may have side effects

## Acceptance Criteria
- [ ] Hotspot hover menu (all 4 buttons) is always clickable, even when waypoint guides are visible
- [ ] Waypoint lines/arrows remain visible (don't disappear on hotspot hover)
- [ ] No regression in hotspot move functionality (arrow responsive after move commit)
- [ ] `hotspot-overlap-a01.spec.ts` passes
- [ ] Builds cleanly

## Investigation Steps
1. Read `src/systems/HotspotLine/HotspotLineDrawing.res` — check SVG z-index
2. Read `src/systems/HotspotLine/HotspotLineState.res` — check suppression logic
3. Read `src/systems/SvgManager.res` — check overlay element positioning
4. Read `css/tailwind.css` — check z-index layer definitions
5. Compare z-index of SVG overlay vs hotspot container (z-6000)
6. Solution likely: SVG overlay needs `pointer-events: none` on the lines/arrows themselves, with `pointer-events: auto` only on interactive elements, OR the SVG z-index must be lower than z-6000

## Files to Investigate
- `src/systems/HotspotLine/HotspotLineDrawing.res`
- `src/systems/HotspotLine/HotspotLineState.res`
- `src/systems/SvgManager.res`
- `src/components/PreviewArrow.res`
- `css/tailwind.css`
