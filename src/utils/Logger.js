/**
 * Logger Module
 * Provides application-wide debug logging with buffer management
 * 
 * @module Logger
 */

// Initialize global log buffer
window.appLog = window.appLog || [];

/**
 * Log a message to the application buffer
 * @param {string} msg - Message to log
 * @param {string} level - Log level (INFO, WARN, ERROR)
 */
export function logToBuffer(msg, level = "INFO") {
    const timestamp = new Date().toISOString();
    window.appLog.push(`[${timestamp}][${level}] ${msg}`);

    // Keep buffer at max 1000 entries
    if (window.appLog.length > 1000) window.appLog.shift();
}

/**
 * Initialize logger and intercept console.error
 * Should be called once at app startup
 */
export function initLogger() {
    logToBuffer("Application initialized.");

    // Intercept console.error to capture errors in buffer
    const originalConsoleError = console.error;
    console.error = (...args) => {
        logToBuffer(args.map(a => String(a)).join(" "), "ERROR");
        originalConsoleError.apply(console, args);
    };
}
