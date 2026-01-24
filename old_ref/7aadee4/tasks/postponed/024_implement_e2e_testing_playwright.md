# Task 304: Implement E2E Testing with Playwright

**Priority**: Medium  
**Effort**: Medium (2-3 days)  
**Impact**: Medium  
**Category**: Testing / Quality Assurance

## Objective

Implement end-to-end (E2E) testing using Playwright to cover critical user flows and increase confidence in application functionality across different browsers.

## Current Testing Status

**Current Coverage**: 95% (Unit tests only)
- ✅ 40 unit tests (21 frontend + 19 backend)
- ✅ 100% pass rate
- ✅ Automated on every commit

**Gap**: No E2E tests for user workflows

## Why E2E Testing?

- Validates entire user journeys (not just isolated functions)
- Tests browser interactions (clicks, navigation, file uploads)
- Catches integration issues between frontend/backend
- Ensures UI works correctly across browsers
- Prevents regressions in critical workflows

## Implementation Steps

### Phase 1: Setup Playwright (2-3 hours)

1. Install Playwright:
```bash
npm install -D @playwright/test
npx playwright install
```

2. Create `playwright.config.ts`:
```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30000,
  use: {
    baseURL: 'http://localhost:8080',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
    { name: 'firefox', use: { browserName: 'firefox' } },
    { name: 'webkit', use: { browserName: 'webkit' } },
  ],
});
```

3. Create `tests/e2e/` directory

### Phase 2: Critical User Flows (1-2 days)

Implement tests for these critical workflows:

#### Test 1: Upload and View Scene
```typescript
// tests/e2e/upload-scene.spec.ts
test('should upload image and view in panorama', async ({ page }) => {
  await page.goto('/');
  
  // Upload image
  const fileInput = page.locator('input[type="file"]');
  await fileInput.setInputFiles('tests/fixtures/test-panorama.jpg');
  
  // Wait for processing
  await page.waitForSelector('.scene-item', { timeout: 10000 });
  
  // Verify scene appears in sidebar
  const sceneItem = page.locator('.scene-item').first();
  await expect(sceneItem).toBeVisible();
  
  // Click to view
  await sceneItem.click();
  
  // Verify panorama loads
  await expect(page.locator('#panorama-a')).toBeVisible();
});
```

#### Test 2: Create Hotspot Link
```typescript
// tests/e2e/create-link.spec.ts
test('should create hotspot link between scenes', async ({ page }) => {
  // Setup: Upload 2 scenes first
  // ...
  
  // Enable linking mode
  await page.click('#btn-add-link-fab');
  
  // Click on panorama to create hotspot
  await page.click('#panorama-a', { position: { x: 400, y: 300 } });
  
  // Select target scene in modal
  await page.selectOption('#link-target', 'Scene 2');
  await page.click('#save-link');
  
  // Verify hotspot created
  const hotspot = page.locator('.pnlm-hotspot').first();
  await expect(hotspot).toBeVisible();
});
```

#### Test 3: AutoPilot Simulation
```typescript
// tests/e2e/autopilot.spec.ts
test('should run autopilot simulation', async ({ page }) => {
  // Setup: Upload scenes with links
  // ...
  
  // Start autopilot
  await page.click('#v-scene-sim-toggle');
  
  // Wait for simulation to start
  await expect(page.locator('.in-simulation')).toBeVisible();
  
  // Verify scene transitions
  await page.waitForTimeout(3000);
  
  // Stop autopilot
  await page.click('#v-scene-sim-toggle');
  
  // Verify stopped
  await expect(page.locator('.in-simulation')).not.toBeVisible();
});
```

#### Test 4: Project Save/Load
```typescript
// tests/e2e/project-persistence.spec.ts
test('should save and load project', async ({ page }) => {
  // Create project with scenes
  // ...
  
  // Save project
  await page.click('[data-action="save-project"]');
  
  // Wait for download
  const download = await page.waitForEvent('download');
  const path = await download.path();
  
  // Reload page
  await page.reload();
  
  // Load project
  const fileInput = page.locator('input[type="file"][accept=".zip"]');
  await fileInput.setInputFiles(path);
  
  // Verify scenes restored
  const sceneCount = await page.locator('.scene-item').count();
  expect(sceneCount).toBeGreaterThan(0);
});
```

#### Test 5: Accessibility Navigation
```typescript
// tests/e2e/accessibility.spec.ts
test('should navigate with keyboard only', async ({ page }) => {
  await page.goto('/');
  
  // Tab through UI
  await page.keyboard.press('Tab');
  await page.keyboard.press('Tab');
  
  // Verify focus visible
  const focused = await page.evaluate(() => document.activeElement?.tagName);
  expect(focused).toBeTruthy();
  
  // Press Enter to activate
  await page.keyboard.press('Enter');
  
  // Escape to close modal
  await page.keyboard.press('Escape');
});
```

### Phase 3: Test Fixtures (2-4 hours)

1. Create `tests/fixtures/` directory
2. Add test panorama images (small, valid 360° images)
3. Add test project ZIP files
4. Create helper functions for common setup

### Phase 4: CI Integration (1-2 hours)

Update `.github/workflows/ci.yml`:

```yaml
- name: Run E2E Tests
  run: |
    npm run dev &
    npx wait-on http://localhost:8080
    npx playwright test
    kill %1
```

## Verification

1. Run tests locally:
```bash
npm run dev  # In one terminal
npx playwright test  # In another terminal
```

2. Run with UI mode:
```bash
npx playwright test --ui
```

3. Generate HTML report:
```bash
npx playwright show-report
```

## Success Criteria

- [ ] Playwright installed and configured
- [ ] At least 5 critical user flows tested
- [ ] Tests pass on Chromium, Firefox, and WebKit
- [ ] Test fixtures created
- [ ] CI pipeline includes E2E tests
- [ ] HTML report generated
- [ ] All tests passing
- [ ] Documentation added to TESTING_QUICK_REFERENCE.md

## Benefits

- ✅ Catch integration bugs before production
- ✅ Validate entire user workflows
- ✅ Cross-browser compatibility testing
- ✅ Prevent regressions in critical features
- ✅ Increased deployment confidence
- ✅ Better test coverage (95% → 98%)

## Resources

- Playwright Docs: https://playwright.dev/
- Best Practices: https://playwright.dev/docs/best-practices
- Examples: https://github.com/microsoft/playwright/tree/main/examples
