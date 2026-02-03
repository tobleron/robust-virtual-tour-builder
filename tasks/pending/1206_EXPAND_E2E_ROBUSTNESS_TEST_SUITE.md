# TASK: Expand E2E Robustness Test Suite

**Priority**: 🟡 Medium
**Estimated Effort**: Medium (2-3 hours)
**Dependencies**: 1200 (must complete before expanding tests)
**Related Tasks**: 1200, 1201, 1202, 1203, 1204, 1205

---

## 1. Problem Statement

The current `robustness.spec.ts` has only 4 test scenarios:

1. Concurrent Mode Transitions
2. Rapid Scene Switching
3. Rapid Saving during Interaction
4. Keyboard/Mouse Interruptions

This is insufficient coverage for the robustness features being implemented.

---

## 2. Technical Requirements

### A. Add Circuit Breaker Tests (After Task 1201)

```typescript
test('Area: Network - Circuit Breaker Activation', async ({ page }) => {
  // Mock backend to return 500 errors
  await page.route('**/api/**', route => {
    route.fulfill({ status: 500, body: 'Internal Server Error' });
  });

  // Trigger multiple save operations
  const saveBtn = page.getByLabel('Save');
  for (let i = 0; i < 6; i++) {
    await saveBtn.click();
    await page.waitForTimeout(100);
  }

  // Expected: Circuit breaker notification appears
  await expect(page.locator('text=/Connection issues/i')).toBeVisible();
  
  // Expected: Subsequent clicks are immediately rejected (no network call)
  const networkPromise = page.waitForRequest('**/api/**', { timeout: 1000 });
  await saveBtn.click();
  await expect(networkPromise).rejects.toThrow();
});
```

### B. Add Optimistic Rollback Tests (After Task 1202)

```typescript
test('Area: State - Optimistic Rollback on API Failure', async ({ page }) => {
  // Count initial scenes
  const initialCount = await page.locator('.scene-list-item').count();
  
  // Mock delete to fail
  await page.route('**/api/project/scene/**', route => {
    route.fulfill({ status: 500, body: 'Delete failed' });
  });

  // Delete a scene
  const firstScene = page.locator('.scene-list-item').first();
  await firstScene.hover();
  await page.locator('button[aria-label="Delete scene"]').click();
  await page.locator('button:has-text("Confirm")').click();

  // Expected: Scene count restored after rollback
  await page.waitForTimeout(2000);
  const finalCount = await page.locator('.scene-list-item').count();
  expect(finalCount).toBe(initialCount);

  // Expected: Rollback notification shown
  await expect(page.locator('text=/reverted/i')).toBeVisible();
});
```

### C. Add Debounce/Rate Limit Tests (After Task 1203)

```typescript
test('Area: Input - Save Button Debouncing', async ({ page }) => {
  let saveCallCount = 0;
  await page.route('**/api/project/save', route => {
    saveCallCount++;
    route.fulfill({ status: 200, body: '{}' });
  });

  const saveBtn = page.getByLabel('Save');
  
  // Rapid clicks
  for (let i = 0; i < 10; i++) {
    await saveBtn.click({ force: true });
  }
  await page.waitForTimeout(3000); // Wait for debounce

  // Expected: Only 1-2 actual API calls (debounced)
  expect(saveCallCount).toBeLessThanOrEqual(2);
});

test('Area: Input - Rate Limiter Notification', async ({ page }) => {
  const saveBtn = page.getByLabel('Save');
  
  // Exhaust rate limit (5 calls)
  for (let i = 0; i < 6; i++) {
    await saveBtn.click();
    await page.waitForTimeout(100);
  }

  // Expected: Rate limit notification shown
  await expect(page.locator('text=/wait/i')).toBeVisible();
});
```

### D. Add Recovery Tests (After Task 1205)

```typescript
test('Area: Persistence - Interrupted Operation Recovery', async ({ page, context }) => {
  // Start a save operation
  const saveBtn = page.getByLabel('Save');
  await saveBtn.click();
  
  // Immediately refresh (simulate crash)
  await page.reload();
  
  // Expected: Recovery modal appears
  await expect(page.locator('text=/Interrupted Operations/i')).toBeVisible({ timeout: 10000 });
  
  // Dismiss recovery
  await page.locator('button:has-text("Dismiss")').click();
  await expect(page.locator('text=/Interrupted Operations/i')).not.toBeVisible();
});
```

### E. Add Barrier Action Tests (After Task 1200)

```typescript
test('Area: State - LoadProject Barrier Blocks Other Actions', async ({ page }) => {
  // Start loading a project
  const projectFile = path.join(__dirname, 'fixtures', 'test-project.zip');
  const importBtn = page.locator('input[type="file"][accept*=".zip"]');
  await importBtn.setInputFiles(projectFile);
  
  // Immediately try to add a scene (should be blocked)
  const addBtn = page.locator('button:has-text("Add")');
  await addBtn.click();
  
  // Expected: Add action is queued, not executed
  // (verification via console log or state inspection)
  const logs = await page.evaluate(() => window.__debugLogs || []);
  const queueLogs = logs.filter(l => l.includes('BARRIER_BLOCKING'));
  expect(queueLogs.length).toBeGreaterThan(0);
});
```

---

## 3. Test Organization

Update `robustness.spec.ts` structure:

```typescript
test.describe('Application Robustness', () => {
  test.describe('State Machine', () => {
    // Existing: Concurrent Mode Transitions
    // New: LoadProject Barrier
  });

  test.describe('Navigation', () => {
    // Existing: Rapid Scene Switching
  });

  test.describe('Persistence', () => {
    // Existing: Rapid Saving
    // New: Interrupted Operation Recovery
  });

  test.describe('Input Handling', () => {
    // Existing: Keyboard/Mouse Interruptions
    // New: Debouncing
    // New: Rate Limiting
  });

  test.describe('Network Resilience', () => {
    // New: Circuit Breaker
    // New: Optimistic Rollback
  });
});
```

---

## 4. Verification Criteria

- [ ] All new tests pass consistently (no flaky tests).
- [ ] Each robustness feature has at least one dedicated test.
- [ ] Tests are isolated (no shared state between tests).
- [ ] Test names clearly identify the area being tested.
- [ ] `npx playwright test robustness.spec.ts` passes 100%.

---

## 5. File Checklist

- [ ] `tests/e2e/robustness.spec.ts` - Expand with new tests
- [ ] `tests/e2e/fixtures/test-project.zip` - Test fixture for import tests
- [ ] `tests/e2e/ai-helper.ts` - Add debug log capture helper

---

## 6. References

- `tests/e2e/robustness.spec.ts`
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- Task 1200, 1201, 1202, 1203, 1204, 1205
