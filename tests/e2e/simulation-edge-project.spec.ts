import { test, expect } from '@playwright/test';
import path from 'path';
import { loadProjectZipAndWait, resetClientState, setupAuthentication } from './e2e-helpers';

const EDGE_ZIP_PATH = path.resolve(process.cwd(), 'artifacts/edge.zip');

test.describe('Simulation Play Button: Edge Project', () => {
  test.beforeEach(async ({ page }) => {
    test.setTimeout(120000);
    await setupAuthentication(page, 'dev-token');
    await resetClientState(page, { authToken: 'dev-token' });
    await page.goto('/');
    
    // Load edge project
    console.log(`Loading project from ${EDGE_ZIP_PATH}...`);
    await loadProjectZipAndWait(page, EDGE_ZIP_PATH, 90000);
    console.log('Project loaded and hydrated.');
  });

  test('should start simulation and advance scenes', async ({ page }) => {
    test.setTimeout(180000);

    // Find and click the play button
    // The button usually has a lucide-play icon or title "Start Simulation"
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"]), button[title*="Simulation"], button:has-text("Play")').first();
    await expect(simBtn).toBeVisible({ timeout: 30000 });
    
    const initialSceneIndex = await page.evaluate(() => {
      const state = (window as any).__RE_STATE__ || (window as any).store?.state;
      return state?.activeIndex ?? -1;
    });
    
    const sceneCount = await page.locator('.scene-item').count();
    console.log(`Initial scene index: ${initialSceneIndex}, Total scenes: ${sceneCount}`);

    if (sceneCount <= 1) {
      console.warn('Warning: Project has only one scene or scenes not loaded properly in sidebar.');
    }

    // Check for hotspots/auto-forward in all scenes
    const scenesWithMovement = await page.evaluate(() => {
      const state = (window as any).__RE_STATE__ || (window as any).store?.state;
      const scenes = state?.project?.scenes ?? [];
      return scenes.map((s: any, i: number) => ({
        index: i,
        name: s.name,
        hotspotCount: s.hotspots?.length ?? 0,
        isAutoForward: s.isAutoForward || false
      })).filter((s: any) => s.hotspotCount > 0 || s.isAutoForward);
    });
    console.log(`Scenes with movement (hotspots or AF): ${scenesWithMovement.length} / ${sceneCount}`);
    if (scenesWithMovement.length > 0) {
      console.log(`First scene with movement: index ${scenesWithMovement[0].index}, count: ${scenesWithMovement[0].hotspotCount}, AF: ${scenesWithMovement[0].isAutoForward}`);
    } else {
      console.warn('Warning: No scenes in this project have movement potential!');
    }

    await simBtn.click();
    console.log('Clicked play button.');

    // Verify stop button appears (indicates simulation is running)
    const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"]), button[title*="Stop Simulation"], button:has-text("Stop")').first();
    await expect(stopBtn).toBeVisible({ timeout: 15000 });
    
    // Check simulation state
    const simStatus = await page.evaluate(() => {
      const state = (window as any).__RE_STATE__ || (window as any).store?.state;
      return state?.simulation?.status ?? 'Unknown';
    });
    console.log(`Simulation status in state: ${simStatus}`);

    // Wait for scene to advance
    console.log('Waiting for scene to advance...');
    let advanced = false;
    const deadline = Date.now() + 60000; // 60s timeout for first advancement
    
    while (Date.now() < deadline) {
      const state = await page.evaluate(() => {
        const s = (window as any).__RE_STATE__ || (window as any).store?.state;
        return {
          activeIndex: s?.activeIndex ?? -1,
          simStatus: s?.simulation?.status ?? 'Unknown',
          visitedLinkIds: s?.simulation?.visitedLinkIds ?? [],
        };
      });
      
      if (state.activeIndex !== initialSceneIndex && state.activeIndex !== -1) {
        console.log(`Scene advanced to index: ${state.activeIndex}`);
        advanced = true;
        break;
      }
      
      if (Date.now() % 5000 < 1000) {
        console.log(`Still at index ${state.activeIndex}, status: ${state.simStatus}, visitedLinks: ${state.visitedLinkIds.length}`);
      }

      await page.waitForTimeout(1000);
    }

    expect(advanced, 'Simulation should advance to a different scene').toBe(true);

    // Let it run for a bit more to see if it continues
    await page.waitForTimeout(5000);
    
    const finalSceneIndex = await page.evaluate(() => {
      const state = (window as any).__RE_STATE__ || (window as any).store?.state;
      return state?.activeIndex ?? -1;
    });
    console.log(`Scene index after 5 more seconds: ${finalSceneIndex}`);

    // Stop simulation
    await stopBtn.click();
    console.log('Clicked stop button.');
    
    await expect(simBtn).toBeVisible({ timeout: 10000 });
    console.log('Play button returned, simulation stopped.');
  });
});
