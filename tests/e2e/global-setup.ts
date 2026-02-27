import { type FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  const { baseURL } = config.projects[0].use;

  const maxRetries = 60; // 5 minutes (5s * 60)
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch('http://localhost:8080/health');
      if (response.ok) {
        return;
      }
    } catch (e) {
      // Ignore connection refused
    }
    await new Promise(resolve => setTimeout(resolve, 5000));
  }

  // Don't fail global setup, let tests fail if they must, or throw?
  // If we throw, tests won't run.
  console.error('Global Setup: Backend failed to start within timeout.');
  throw new Error('Backend failed to start within timeout.');
}

export default globalSetup;
