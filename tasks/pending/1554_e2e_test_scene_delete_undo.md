# 1554 — Add E2E Test for Scene Delete Undo Flow

## Priority: P2 — Test Coverage

## Objective
Create an E2E test that validates the scene delete → undo → restore flow, including the 9-second undo window and the `U` keyboard shortcut.

## Context
Scene deletion with undo is a critical user safety feature. The implementation exists (`SidebarLogicHandler.res` lines 667-736) but has no dedicated E2E test. The `robustness.spec.ts` tests optimistic rollback via API failure, but doesn't test the user-initiated undo flow.

## Test Scenarios

### Test 1: Delete Scene and Undo via Button
- Upload 2 images (2 scenes)
- Delete scene 2 via three-dot menu → "Remove Scene"
- Verify scene count drops to 1
- Verify notification "Scene deleted. Press U to undo." appears
- Click the "Undo" button in the notification
- Verify scene count returns to 2
- Verify "Scene deletion undone" notification appears

### Test 2: Delete Scene and Undo via U Key
- Same setup as Test 1
- After delete, press `U` key
- Verify scene restored

### Test 3: Delete Scene Without Undo (Timeout)
- Delete a scene
- Wait >9 seconds (use `page.waitForTimeout(10000)`)
- Verify the undo notification has disappeared
- Verify the scene remains deleted
- Verify backend sync was triggered (mock API and check call count)

### Test 4: Clear Links and Undo
- Create a scene with links
- Use three-dot menu → "Clear Links"
- Verify links are removed
- Click Undo
- Verify links are restored

## Acceptance Criteria
- [ ] New test file `tests/e2e/scene-delete-undo.spec.ts` created
- [ ] All 4 scenarios implemented
- [ ] Tests validate both the notification UI and the actual state change
- [ ] Tests run successfully

## Files to Create
- `tests/e2e/scene-delete-undo.spec.ts`
