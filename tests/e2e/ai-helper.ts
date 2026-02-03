import { Page } from '@playwright/test';

/**
 * AI-Helper: Enhances Playwright logs with application-specific context
 * to help AI agents diagnose and fix code.
 */
export async function setupAIObservability(page: Page) {
  // 1. Capture Unhandled Exceptions that might not trigger a crash but indicate bugs
  page.on('pageerror', (exception) => {
    console.log(`[AI-DIAGNOSTIC][EXCEPTION] ${exception.stack || exception.message}`);
  });

  // 2. Capture Failed Network Requests with specific detail
  page.on('requestfailed', (request) => {
    console.log(`[AI-DIAGNOSTIC][NET_FAIL] ${request.method()} ${request.url()} - ${request.failure()?.errorText}`);
  });

  // 3. Inject a state-dumping utility if the app allows it
  // This allows the AI to see the exact ReScript state at the moment of failure
  await page.addInitScript(() => {
    window.addEventListener('error', (event) => {
      console.error('[AI-STATE-DUMP]', {
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        state: (window as any).__RE_STATE__ // If we expose it in App.res
      });
    });
  });
}
