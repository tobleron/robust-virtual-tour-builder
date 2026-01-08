import { Debug } from "./Debug.js";

// Initialize global log buffer
window.appLog = window.appLog || [];

/**
 * Log a message to the application buffer
 * @param {string} msg - Message to log
 * @param {string} level - Log level (INFO, WARN, ERROR)
 */
export function logToBuffer(msg, level = "INFO") {
    const timestamp = new Date().toISOString();
    const entry = `[${timestamp}][${level}] ${msg}`;
    window.appLog.push(entry);

    // Keep buffer at max 1000 entries
    if (window.appLog.length > 1000) window.appLog.shift();
    
    // Also send to Debug utility for standardized handling
    if (level === "ERROR") {
        Debug.error("Console", msg);
    } else if (level === "WARN") {
        Debug.warn("Console", msg);
    } else {
        Debug.info("Console", msg);
    }
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
        const msg = args.map(a => String(a)).join(" ");
        logToBuffer(msg, "ERROR");
        originalConsoleError.apply(console, args);
    };

    // Add manual capture trigger for the user
    window.captureUIProblem = (description) => {
        Debug.error("UI_REPORT", `User reported problem: ${description}`, {
            lastLogs: window.appLog.slice(-20)
        });
        return "Problem reported to telemetry.";
    };
}
