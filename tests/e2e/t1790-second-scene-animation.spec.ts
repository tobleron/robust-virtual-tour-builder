import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadProjectZipAndWait } from './e2e-helpers';

// Force headed mode for WebGL support
test.use({ headless: false });

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const EDGE_ZIP_PATH = path.resolve(process.cwd(), 'artifacts/edge.zip');

test.describe('T1790: Second Scene Waypoint Animation Edge Case', () => {
  
  // Capture console logs
  const consoleLogs: Array<{ type: string; text: string; time: number }> = [];
  const networkErrors: Array<{ url: string; error: string }> = [];
  
  test.beforeEach(async ({ page }) => {
    consoleLogs.length = 0;
    networkErrors.length = 0;

    // Capture console messages
    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('SIM_') || text.includes('DISPATCH_') || text.includes('Simulation') || text.includes('SceneTransition') || text.includes('Error') || text.includes('Failed') || text.includes('panic') || text.includes('Exception')) {
        consoleLogs.push({
          type: msg.type(),
          text: text,
          time: Date.now(),
        });
      }
    });
    
    // Capture page errors
    page.on('pageerror', error => {
      consoleLogs.push({
        type: 'error',
        text: error.message,
        time: Date.now(),
      });
    });
    
    // Capture network errors
    page.on('requestfailed', request => {
      networkErrors.push({
        url: request.url(),
        error: request.failure()?.errorText ?? 'Unknown error',
      });
    });
    
    await page.goto('/');

    // Clear state
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();

    // Load edge case project
    try {
      await loadProjectZipAndWait(page, EDGE_ZIP_PATH, 60000);
    } catch (error) {
      console.log('ERROR loading project:', error);
    }
    
    // Wait a bit for viewer to initialize
    await page.waitForTimeout(5000);
    
    // Debug: Check viewer containers
    console.log('=== Checking Viewer Containers ===');
    try {
      const panoramaA = await page.$('#panorama-a');
      const panoramaB = await page.$('#panorama-b');
      console.log('panorama-a exists:', panoramaA != null);
      console.log('panorama-b exists:', panoramaB != null);
      
      if (panoramaA) {
        const boxA = await panoramaA.boundingBox();
        console.log('panorama-a dimensions:', boxA);
        const innerHTML = await page.$eval('#panorama-a', el => el.innerHTML.substring(0, 200));
        console.log('panorama-a innerHTML:', innerHTML);
      }
      if (panoramaB) {
        const boxB = await panoramaB.boundingBox();
        console.log('panorama-b dimensions:', boxB);
      }
    } catch (error) {
      console.log('ERROR checking viewer containers:', error);
    }
    
    // Wait for images to load
    await page.waitForFunction(() => {
      const scenes = document.querySelectorAll('.scene-item');
      if (scenes.length === 0) return false;
      // Check if first scene has loaded image
      const firstScene = scenes[0];
      const img = firstScene.querySelector('img');
      return img != null && img.complete;
    }, { timeout: 30000 }).catch(() => {
      console.log('WARNING: Scene images did not load within timeout');
    });
    
    // Debug: Check if Pannellum is loaded
    const hasPannellum = await page.evaluate(() => typeof window.pannellum !== 'undefined');
    console.log('Pannellum loaded:', hasPannellum);
    
    // Check if any canvas exists in viewer
    const canvasCount = await page.$$eval('#viewer-stage canvas', els => els.length);
    console.log('Canvas elements in viewer-stage:', canvasCount);
  });

  test('should animate waypoint in second scene after transition', async ({ page }) => {
    test.setTimeout(180000);

    console.log('=== T1790: Starting Second Scene Animation Test ===');

    // Start simulation
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    await expect(simBtn).toBeVisible();
    await simBtn.click();
    console.log('[T1790] Simulation started');

    // Verify simulation is running
    const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
    await expect(stopBtn).toBeVisible({ timeout: 5000 });
    console.log('[T1790] Simulation confirmed running');

    // Collect detailed state snapshots
    const snapshots: Array<{
      time: number;
      activeIndex: number;
      activeSceneId: string | null;
      visitedLinkIds: string[];
      simulationStatus: string;
      navigationFsm: string;
      activeTimelineStepId: string | null;
      timeline: Array<{ id: string; sceneId: string; linkId: string }>;
    }> = [];

    // Poll state every 500ms for 60 seconds (120 snapshots)
    console.log('[T1790] Starting state polling...');
    for (let i = 0; i < 120; i++) {
      const snapshot = await page.evaluate(() => {
        const state = (window as any).__RE_STATE__;
        return {
          time: Date.now(),
          activeIndex: state?.activeIndex ?? -1,
          activeSceneId: state?.inventory?.[state?.sceneOrder?.[state?.activeIndex]]?.scene?.name ?? null,
          visitedLinkIds: state?.simulation?.visitedLinkIds ?? [],
          simulationStatus: state?.simulation?.status ?? 'unknown',
          navigationFsm: state?.navigationState?.navigationFsm ?? 'unknown',
          activeTimelineStepId: state?.activeTimelineStepId ?? null,
          timeline: state?.timeline ?? [],
        };
      });
      snapshots.push(snapshot);
      
      // Log scene changes
      if (i > 0 && snapshot.activeIndex !== snapshots[i - 1].activeIndex) {
        console.log(`[T1790] Scene change at ${i * 500}ms: ${snapshots[i - 1].activeIndex} -> ${snapshot.activeIndex}`);
        console.log(`[T1790]   New scene: ${snapshot.activeSceneId}`);
        console.log(`[T1790]   Navigation FSM: ${snapshot.navigationFsm}`);
        console.log(`[T1790]   Visited LinkIds: [${snapshot.visitedLinkIds.join(', ')}]`);
      }
      
      await page.waitForTimeout(500);
    }

    // Stop simulation
    await stopBtn.click();
    console.log('[T1790] Simulation stopped');

    // Print ALL captured console logs
    console.log('\n=== T1790: Browser Console Logs ===');
    consoleLogs.forEach(log => {
      console.log(`[${log.type}] ${log.text}`);
    });
    console.log(`Total captured logs: ${consoleLogs.length}`);
    
    // Print network errors
    if (networkErrors.length > 0) {
      console.log('\n=== T1790: Network Errors ===');
      networkErrors.forEach(err => {
        console.log(`[NETWORK ERROR] ${err.url}: ${err.error}`);
      });
      console.log(`Total network errors: ${networkErrors.length}`);
    }

    // Analyze results
    console.log('\n=== T1790: Analysis Results ===');
    
    // 1. Check if simulation advanced beyond first scene
    const uniqueIndices = new Set(snapshots.map(s => s.activeIndex));
    const indexSequence = [...uniqueIndices].sort((a, b) => a - b);
    console.log(`Scenes visited: [${indexSequence.join(', ')}]`);
    console.log(`Total unique scenes: ${uniqueIndices.size}`);

    // 2. Check for second scene presence
    const secondScenePresent = indexSequence.some(idx => idx >= 1);
    console.log(`Second scene reached: ${secondScenePresent}`);

    // 3. Analyze time spent in each scene
    const sceneDurations: Map<number, number> = new Map();
    let prevIndex = -1;
    let startTime = 0;
    
    for (let i = 0; i < snapshots.length; i++) {
      if (snapshots[i].activeIndex !== prevIndex) {
        if (prevIndex !== -1 && startTime > 0) {
          const duration = snapshots[i].time - startTime;
          const prevDuration = sceneDurations.get(prevIndex) ?? 0;
          sceneDurations.set(prevIndex, prevDuration + duration);
        }
        prevIndex = snapshots[i].activeIndex;
        startTime = snapshots[i].time;
      }
    }
    // Add last scene duration
    if (prevIndex !== -1 && startTime > 0) {
      const lastDuration = snapshots[snapshots.length - 1].time - startTime;
      const prevDuration = sceneDurations.get(prevIndex) ?? 0;
      sceneDurations.set(prevIndex, prevDuration + lastDuration);
    }

    console.log('\nTime spent per scene:');
    sceneDurations.forEach((duration, index) => {
      console.log(`  Scene ${index}: ${(duration / 1000).toFixed(1)}s`);
    });

    // 4. Check timeline progression (indicates waypoint animation)
    const timelineChanges: Array<{ time: number; stepId: string | null }> = [];
    for (let i = 0; i < snapshots.length; i++) {
      if (i === 0 || snapshots[i].activeTimelineStepId !== snapshots[i - 1].activeTimelineStepId) {
        timelineChanges.push({
          time: i * 500,
          stepId: snapshots[i].activeTimelineStepId,
        });
      }
    }
    console.log(`\nTimeline step changes: ${timelineChanges.length}`);
    timelineChanges.forEach(change => {
      console.log(`  ${change.time}ms: ${change.stepId ?? 'null'}`);
    });

    // 5. Check navigation FSM states
    const fsmStates = new Set(snapshots.map(s => s.navigationFsm));
    console.log(`\nNavigation FSM states observed: [${[...fsmStates].join(', ')}]`);

    // 6. Check for FSM stuck in non-Idle state
    const nonIdleSnapshots = snapshots.filter(s => 
      s.navigationFsm !== 'IdleFsm' && 
      s.navigationFsm !== 'unknown'
    );
    const nonIdlePercentage = (nonIdleSnapshots.length / snapshots.length) * 100;
    console.log(`Non-Idle FSM percentage: ${nonIdlePercentage.toFixed(1)}%`);

    // 7. Final state analysis
    const finalState = snapshots[snapshots.length - 1];
    console.log('\n=== Final State ===');
    console.log(`Active Index: ${finalState.activeIndex}`);
    console.log(`Active Scene: ${finalState.activeSceneId}`);
    console.log(`Simulation Status: ${finalState.simulationStatus}`);
    console.log(`Navigation FSM: ${finalState.navigationFsm}`);
    console.log(`Visited LinkIds: [${finalState.visitedLinkIds.join(', ')}]`);
    console.log(`Timeline Steps: ${finalState.timeline.length}`);

    // Assertions
    console.log('\n=== Assertions ===');
    
    // Should have visited at least 2 scenes
    expect(uniqueIndices.size).toBeGreaterThanOrEqual(2);
    console.log('✓ Visited at least 2 scenes');

    // Second scene should have been active for some time (> 2 seconds)
    const secondSceneDuration = sceneDurations.get(1) ?? 0;
    expect(secondSceneDuration).toBeGreaterThan(2000);
    console.log(`✓ Second scene active for ${(secondSceneDuration / 1000).toFixed(1)}s`);

    // Timeline should have progressed (waypoint animation started)
    expect(timelineChanges.length).toBeGreaterThanOrEqual(2);
    console.log(`✓ Timeline progressed (${timelineChanges.length} changes)`);

    // Navigation FSM should have returned to Idle (not stuck)
    const idleSnapshots = snapshots.filter(s => s.navigationFsm === 'IdleFsm');
    expect(idleSnapshots.length).toBeGreaterThan(0);
    console.log(`✓ Navigation FSM returned to Idle (${idleSnapshots.length} times)`);
  });

  test('should detect if navigationCompleteRef causes second scene stall', async ({ page }) => {
    test.setTimeout(120000);

    console.log('=== T1790: Navigation Complete Ref Diagnostic Test ===');

    // Start simulation
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    await simBtn.click();

    // Wait for first scene transition to complete
    await page.waitForTimeout(5000);

    // Poll for specific diagnostic conditions
    const diagnostics: Array<{
      time: number;
      activeIndex: number;
      navigationFsm: string;
      isNavigationCompleteRefLikelyTrue: boolean;
      advancingForSceneId: string | null;
    }> = [];

    for (let i = 0; i < 60; i++) {
      const diag = await page.evaluate(() => {
        const state = (window as any).__RE_STATE__;
        // Infer navigationCompleteRef state from behavior
        // If FSM is Idle but no advancement happening, ref might be false
        const isLikelyReady = state?.navigationState?.navigationFsm === 'IdleFsm' &&
                              state?.simulation?.status === 'Running';
        return {
          time: Date.now(),
          activeIndex: state?.activeIndex ?? -1,
          navigationFsm: state?.navigationState?.navigationFsm ?? 'unknown',
          isNavigationCompleteRefLikelyTrue: isLikelyReady,
          advancingForSceneId: null, // Internal ref, not exposed
        };
      });
      diagnostics.push(diag);
      await page.waitForTimeout(500);
    }

    // Stop simulation
    const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
    if (await stopBtn.isVisible()) {
      await stopBtn.click();
    }

    // Analyze for stall patterns
    console.log('\n=== Stall Pattern Analysis ===');
    
    // Look for pattern: FSM=Idle for extended period without scene change
    const idlePeriods: Array<{ start: number; end: number; sceneIndex: number }> = [];
    let inIdlePeriod = false;
    let idleStart = 0;
    let idleScene = -1;

    for (let i = 0; i < diagnostics.length; i++) {
      if (diagnostics[i].navigationFsm === 'IdleFsm' && !inIdlePeriod) {
        inIdlePeriod = true;
        idleStart = i * 500;
        idleScene = diagnostics[i].activeIndex;
      } else if (diagnostics[i].navigationFsm !== 'IdleFsm' && inIdlePeriod) {
        inIdlePeriod = false;
        idlePeriods.push({ start: idleStart, end: i * 500, sceneIndex: idleScene });
      }
    }
    if (inIdlePeriod) {
      idlePeriods.push({ start: idleStart, end: diagnostics.length * 500, sceneIndex: idleScene });
    }

    console.log('Idle periods (FSM=IdleFsm):');
    idlePeriods.forEach(period => {
      const duration = period.end - period.start;
      console.log(`  Scene ${period.sceneIndex}: ${duration}ms (${period.start}ms - ${period.end}ms)`);
      
      // Flag suspicious patterns: Idle for > 10s without advancement
      if (duration > 10000) {
        console.log(`    ⚠️  SUSPICIOUS: Idle for > 10s - possible navigationCompleteRef stall!`);
      }
    });

    // Check for second scene idle period
    const secondSceneIdle = idlePeriods.find(p => p.sceneIndex === 1);
    if (secondSceneIdle) {
      const duration = secondSceneIdle.end - secondSceneIdle.start;
      if (duration > 10000) {
        console.log(`\n⚠️  DIAGNOSIS: Second scene idle for ${duration}ms`);
        console.log('   This suggests navigationCompleteRef was not set properly after transition.');
      }
    }

    // Assertions
    expect(idlePeriods.length).toBeGreaterThan(0);
    
    // If second scene was reached, it should not be idle for too long
    if (secondSceneIdle) {
      const duration = secondSceneIdle.end - secondSceneIdle.start;
      // Allow some time for intro pan + waypoint animation (max ~10s)
      expect(duration).toBeLessThan(15000);
    }
  });
});
