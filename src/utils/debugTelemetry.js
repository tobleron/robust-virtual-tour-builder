/**
 * DebugTelemetry - Centralized error tracking and logging utility
 * 
 * Provides a structured way to log errors and events for debugging.
 * Keeps a rolling buffer of the last 100 entries.
 * 
 * @module DebugTelemetry
 */

export const DebugTelemetry = {
    entries: [],
    maxEntries: 100,

    /**
     * Log an entry with context, message, and optional data
     * @param {string} context - Component or module name (e.g., 'Viewer', 'Store')
     * @param {string} message - Description of the event
     * @param {Object} data - Optional additional data
     */
    log(context, message, data = {}) {
        const entry = {
            timestamp: Date.now(),
            time: new Date().toISOString(),
            context,
            message,
            data
        };

        this.entries.push(entry);
        console.log(`[${context}] ${message}`, Object.keys(data).length > 0 ? data : '');

        // Keep rolling buffer
        if (this.entries.length > this.maxEntries) {
            this.entries.shift();
        }
    },

    /**
     * Log an error with stack trace
     * @param {string} context - Component or module name
     * @param {string} message - Error description
     * @param {Error} error - The error object
     */
    error(context, message, error) {
        this.log(context, message, {
            error: error.message,
            stack: error.stack
        });
        console.error(`[${context}] ${message}`, error);
    },

    /**
     * Get all logged entries
     * @returns {Array} Copy of all entries
     */
    getLog() {
        return [...this.entries];
    },

    /**
     * Get entries filtered by context
     * @param {string} context - Context to filter by
     * @returns {Array} Filtered entries
     */
    getLogByContext(context) {
        return this.entries.filter(e => e.context === context);
    },

    /**
     * Clear all entries
     */
    clear() {
        this.entries = [];
    },

    /**
     * Get a summary of logged entries by context
     * @returns {Object} Count of entries per context
     */
    getSummary() {
        const summary = {};
        this.entries.forEach(e => {
            summary[e.context] = (summary[e.context] || 0) + 1;
        });
        return summary;
    }
};

// Expose globally for console debugging
if (typeof window !== 'undefined') {
    window.DebugTelemetry = DebugTelemetry;
}
