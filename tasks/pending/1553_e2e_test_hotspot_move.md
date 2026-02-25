# 1553 — Add E2E Test for Hotspot Move Feature

## Priority: P2 — Test Coverage

## Objective
Create a dedicated E2E test covering the hotspot move feature end-to-end, since no existing test covers this workflow.

## Context
The hotspot move feature has well-defined behavior (documented in `docs/product_specification.md` Section 7):
1. Hover hotspot → click Move button
2. Center button turns yellow, notification appears
3. Click on panorama to commit new position
4. Hotspot blinks and settles at new position
5. ESC cancels the move

No existing E2E test covers this flow. The closest tests are in `hotspot-advanced.spec.ts` but they focus on link creation, not movement.

## Test Scenarios

### Test 1: Successful Hotspot Move
- Upload 2 images and create a link between them
- Hover the created hotspot
- Click the Move button (bottom of hover menu)
- Verify center button shows Move icon and is yellow
- Verify "Move Mode Active" notification appears
- Click at a different position on the panorama
- Verify hotspot position changed (compare before/after coordinates)

### Test 2: Cancel Move via ESC
- Set up a link as above
- Click Move button to enter move mode
- Press ESC
- Verify "Move Cancelled" notification appears
- Verify hotspot position unchanged

### Test 3: Cancel Move via Center Button
- Set up a link as above
- Click Move button to enter move mode
- Click the center button (should show X icon)
- Verify move mode exits
- Verify hotspot position unchanged

### Test 4: Other Hotspots Disabled During Move
- Create 2 links on the same scene
- Start moving one hotspot
- Verify the other hotspot's action buttons are disabled/dimmed

## Acceptance Criteria
- [ ] New test file `tests/e2e/hotspot-move.spec.ts` created
- [ ] All 4 test scenarios implemented
- [ ] Tests use proper helpers from `e2e-helpers.ts`
- [ ] Tests run successfully against the dev server

## Files to Create
- `tests/e2e/hotspot-move.spec.ts`
