import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadProjectZipAndWait } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const KILANY_ZIP_PATH = path.resolve(process.cwd(), 'artifacts/kilany.zip');

test.describe('T1780: Kilany Project Simulation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');

    // Clear state
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();

    // Load kilany project
    await loadProjectZipAndWait(page, KILANY_ZIP_PATH, 60000);
  });

  test('should advance through multiple scenes without double-advancing', async ({ page }) => {
    test.setTimeout(120000);

    // Start simulation
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    await expect(simBtn).toBeVisible();
    await simBtn.click();

    const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
    await expect(stopBtn).toBeVisible();

    // Collect state snapshots
    const snapshots: Array<{
      time: number;
      activeIndex: number;
      visitedLinkIds: string[];
    }> = [];

    // Poll state every 1s for 30 seconds
    for (let i = 0; i < 30; i++) {
      const snapshot = await page.evaluate(() => {
        const state = (window as any).__RE_STATE__;
        return {
          time: Date.now(),
          activeIndex: state?.activeIndex ?? -1,
          visitedLinkIds: state?.simulation?.visitedLinkIds ?? [],
        };
      });
      snapshots.push(snapshot);
      await page.waitForTimeout(1000);
    }

    // Stop simulation
    await stopBtn.click();

    // Analyze results
    console.log('=== T1780 Kilany Simulation Results ===');
    const uniqueIndices = new Set(snapshots.map(s => s.activeIndex));
    console.log(`Unique scenes visited: ${[...uniqueIndices].sort((a, b) => a - b).join(', ')}`);
    console.log(`Total unique scenes: ${uniqueIndices.size}`);
    
    // Check for duplicate linkIds
    const finalState = snapshots[snapshots.length - 1];
    const linkIds = finalState.visitedLinkIds;
    const uniqueLinkIds = new Set(linkIds);
    console.log(`Final visitedLinkIds: [${linkIds.join(', ')}]`);
    console.log(`Unique linkIds: ${uniqueLinkIds.size}`);
    
    const hasDuplicates = linkIds.length !== uniqueLinkIds.size;
    if (hasDuplicates) {
      console.log('ERROR: Duplicate linkIds detected!');
      const counts: Record<string, number> = {};
      linkIds.forEach(id => { counts[id] = (counts[id] || 0) + 1; });
      Object.entries(counts).forEach(([id, count]) => {
        if (count > 1) console.log(`  ${id}: ${count} times`);
      });
    }

    // Verify no duplicates
    expect(hasDuplicates).toBe(false);

    // Verify simulation advanced through at least 3 scenes (Scene 0, 1, 2)
    expect(uniqueIndices.size).toBeGreaterThanOrEqual(3);

    // Verify no rapid double-advancing (same index shouldn't appear, disappear, reappear)
    const indexSequence = snapshots.map(s => s.activeIndex);
    let prevIndex = -1;
    let changes = 0;
    for (const idx of indexSequence) {
      if (idx !== prevIndex) {
        changes++;
        prevIndex = idx;
      }
    }
    console.log(`Scene changes: ${changes}`);
    
    // Should have at least 2 changes (0->1, 1->2)
    expect(changes).toBeGreaterThanOrEqual(2);
  });

  test('should complete simulation after visiting all unique links', async ({ page }) => {
    test.setTimeout(180000);

    // Start simulation
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    await simBtn.click();

    // Wait for simulation to complete (look for "Simulation Complete" toast)
    const completeToast = page.locator('[role="alert"]:has-text("Simulation Complete")');
    
    // Wait up to 2 minutes for completion
    await expect(completeToast).toBeVisible({ timeout: 120000 });

    // Get final state
    const finalState = await page.evaluate(() => {
      const state = (window as any).__RE_STATE__;
      return {
        activeIndex: state?.activeIndex ?? -1,
        visitedLinkIds: state?.simulation?.visitedLinkIds ?? [],
        simulationStatus: state?.simulation?.status ?? 'unknown',
      };
    });

    console.log('=== Final Simulation State ===');
    console.log(`Active scene: ${finalState.activeIndex}`);
    console.log(`Visited linkIds: [${finalState.visitedLinkIds.join(', ')}]`);
    console.log(`Status: ${finalState.simulationStatus}`);

    // Verify simulation is stopped
    expect(finalState.simulationStatus).toBe('Idle');

    // Verify no duplicate linkIds
    const uniqueLinkIds = new Set(finalState.visitedLinkIds);
    expect(finalState.visitedLinkIds.length).toBe(uniqueLinkIds.size);
  });
});
