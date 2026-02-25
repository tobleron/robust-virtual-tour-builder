# 1555 — Add E2E Test for ESC Key Universal Cancel

## Priority: P2 — Test Coverage

## Objective
Create a comprehensive E2E test validating that the ESC key correctly cancels all active operations, as documented in the product specification.

## Context
`InputSystem.res` handles ESC as a universal cancel key for: linking, hotspot move, navigation, simulation, teaser, modals, and context menus. While individual tests may incidentally use ESC, there's no dedicated test that validates ALL cancel scenarios systematically.

## Test Scenarios

### Test 1: ESC Cancels Linking Mode
- Click "Add Link +" → verify linking mode active
- Press ESC → verify linking mode inactive
- Verify "Link Cancelled" notification

### Test 2: ESC Cancels Hotspot Move
- Start moving a hotspot
- Press ESC → verify move cancelled
- Verify "Move Cancelled" notification

### Test 3: ESC Closes Modal
- Open any modal (e.g., trigger link modal)
- Press ESC → verify modal closed

### Test 4: ESC Cancels Active Export
- Start an export (mock the API for a slow response)
- Press ESC → verify "Export cancelled" notification
- Verify progress bar removed

### Test 5: ESC Stops Simulation
- Start Tour Preview
- Press ESC → verify simulation stopped

## Acceptance Criteria
- [ ] New test file `tests/e2e/esc-key-cancel.spec.ts` created
- [ ] All 5 test scenarios implemented
- [ ] Each scenario verifies both the state change and the notification
- [ ] Tests run successfully

## Files to Create
- `tests/e2e/esc-key-cancel.spec.ts`
