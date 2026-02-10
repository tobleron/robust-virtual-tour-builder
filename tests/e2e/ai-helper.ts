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

  page.on('requestfailed', (request) => {
    console.log(`[AI-DIAGNOSTIC][NET_FAIL] ${request.method()} ${request.url()} - ${request.failure()?.errorText}`);
  });

  // 3. Forward Browser Logs to Terminal
  page.on('console', msg => {
    console.log(`BROWSER: ${msg.text()}`);
  });

  // 3. Inject a state-dumping utility and log capture
  await page.addInitScript(() => {
    // Capture logs for testing verification
    (window as any).__debugLogs = [];
    const originalConsoleLog = console.log;
    const originalConsoleWarn = console.warn;
    const originalConsoleError = console.error;

    console.log = (...args: any[]) => {
      (window as any).__debugLogs.push(args.map(a => String(a)).join(' '));
      originalConsoleLog.apply(console, args);
    };

    console.warn = (...args: any[]) => {
      (window as any).__debugLogs.push(args.map(a => String(a)).join(' '));
      originalConsoleWarn.apply(console, args);
    };

    console.error = (...args: any[]) => {
      // Avoid infinite loops if error logging causes errors
      try {
        (window as any).__debugLogs.push(args.map(a => String(a)).join(' '));
      } catch (e) { }
      originalConsoleError.apply(console, args);
    };

    window.addEventListener('error', (event) => {
      // Use original console error to avoid double capturing if possible, or just accept it.
      // Using console.error here will trigger the overridden console.error above.
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
