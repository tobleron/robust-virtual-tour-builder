import { defineConfig, devices } from '@playwright/test';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const isBudgetMode = process.env.PW_BUDGET_MODE === '1';

const CACHE_CANDIDATES = Array.from(
  new Set(
    [
      process.env.PLAYWRIGHT_BROWSERS_PATH,
      path.join(os.homedir(), '.cache', 'ms-playwright'),
      path.join(os.homedir(), 'Library', 'Caches', 'ms-playwright'),
      path.join(process.cwd(), 'node_modules', '.cache', 'ms-playwright'),
    ]
      .filter((entry): entry is string => !!entry)
      .map((entry) => path.resolve(entry)),
  ),
);

function listChildDirs(dir: string) {
  try {
    return fs
      .readdirSync(dir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name);
  } catch {
    return [];
  }
}

function hasBrowserInDir(dir: string, browser: 'chromium' | 'firefox' | 'webkit') {
  return listChildDirs(dir).some((entry) => entry.startsWith(`${browser}-`));
}

function isBrowserAvailable(browser: 'chromium' | 'firefox' | 'webkit') {
  return CACHE_CANDIDATES.some((dir) => hasBrowserInDir(dir, browser));
}

const AVAILABLE_BROWSERS = {
  chromium: isBrowserAvailable('chromium'),
  firefox: isBrowserAvailable('firefox'),
  webkit: isBrowserAvailable('webkit'),
};

const missingBrowsers = Object.entries(AVAILABLE_BROWSERS)
  .filter(([, available]) => !available)
  .map(([browser]) => browser);

if (missingBrowsers.length > 0) {
  console.warn(
    `[playwright] Missing browsers detected (${missingBrowsers.join(
      ', ',
    )}); install them via './scripts/install-browsers.sh' or set SKIP_BROWSER_PROVISIONING=1 to run a subset of the suite.`,
  );
} else {
  console.info('[playwright] All configured browsers are available.');
}

const baseProjects = [
  {
    name: 'chromium',
    grepInvert: /@budget/,
    use: { ...devices['Desktop Chrome'] },
  },
  {
    name: 'firefox',
    grepInvert: /@budget/,
    use: { ...devices['Desktop Firefox'] },
  },
  {
    name: 'webkit',
    grepInvert: /@budget/,
    use: { ...devices['Desktop Safari'] },
  },
  {
    name: 'chromium-budget',
    grep: /@budget/,
    use: { ...devices['Desktop Chrome'] },
  },
];

const browserRequirements: Record<string, keyof typeof AVAILABLE_BROWSERS> = {
  chromium: 'chromium',
  firefox: 'firefox',
  webkit: 'webkit',
  'chromium-budget': 'chromium',
};

const filteredProjects = baseProjects.filter((project) => {
  const requiredBrowser = browserRequirements[project.name];
  if (!requiredBrowser) {
    return true;
  }
  return AVAILABLE_BROWSERS[requiredBrowser];
});

if (filteredProjects.length === 0) {
  console.warn(
    '[playwright] No browsers are provisioned; skipping Playwright project definitions. Run ./scripts/install-browsers.sh to provision them.',
  );
}

export default defineConfig({
  globalSetup: './tests/e2e/global-setup.ts',
  testDir: './tests/e2e',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests to avoid backend session collisions. */
  workers: 1,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: 'http://localhost:3000',
    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
    /* Increase timeouts */
    navigationTimeout: 60000,
    actionTimeout: 30000,
  },
  /* Global timeout for each test */
  timeout: 120000,
  /* Expect timeout */
  expect: {
    timeout: 30000,
  },
  /* Configure projects for major browsers */
  projects: filteredProjects,
  /* Run your local dev server before starting the tests */
  webServer: {
    command:
      'npm run res:build && concurrently --kill-others -n "BACK,FRONT" -c "blue,green" "npm run dev:backend" "npm run dev:frontend"',
    url: 'http://localhost:3000',
    reuseExistingServer: isBudgetMode ? false : true,
    timeout: 120 * 1000,
    env: {
      ...process.env,
      DISABLE_TELEMETRY: 'true',
      BYPASS_AUTH: isBudgetMode ? 'true' : process.env.BYPASS_AUTH,
      VITE_BACKEND_URL: 'http://localhost:3000',
    },
  },
});
