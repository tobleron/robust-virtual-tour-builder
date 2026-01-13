/**
 * Debug Module
 * Centralized debugging utility with runtime enable/disable,
 * module namespacing, log levels, and rolling buffer.
 * 
 * Usage:
 *   import { Debug } from '../utils/Debug.js';
 *   Debug.log('Teaser', 'debug', 'Processing step', { step: 1, data });
 * 
 * Console Commands:
 *   window.DEBUG.enable()           - Enable all debug output
 *   window.DEBUG.disable()          - Disable all debug output
 *   window.DEBUG.enableModule('Teaser') - Enable only Teaser logs
 *   window.DEBUG.disableModule('Teaser') - Disable Teaser logs
 *   window.DEBUG.getLog()           - Get all logged entries
 *   window.DEBUG.export()           - Export logs as JSON
 *   window.DEBUG.clear()            - Clear log buffer
 * 
 * @module Debug
 */

import {
    DEBUG_ENABLED_DEFAULT,
    DEBUG_LOG_LEVEL,
    DEBUG_MAX_ENTRIES
} from '../constants.js';

// Log level priority (lower = more verbose)
const LOG_LEVELS = {
    debug: 0,
    info: 1,
    warn: 2,
    error: 3
};

// Console styling for different modules
const MODULE_COLORS = {
    Teaser: '#f97316',      // Orange
    Navigation: '#3b82f6',  // Blue
    Store: '#10b981',       // Green
    Viewer: '#8b5cf6',      // Purple
    Hotspot: '#ec4899',     // Pink
    Export: '#14b8a6',      // Teal
    default: '#64748b'      // Slate
};

export const Debug = {
    // State
    enabled: DEBUG_ENABLED_DEFAULT,
    minLevel: DEBUG_LOG_LEVEL,
    enabledModules: new Set(), // Empty = all modules, populated = only listed modules
    entries: [],
    maxEntries: DEBUG_MAX_ENTRIES,

    /**
     * Enable debug output globally
     */
    enable() {
        this.enabled = true;
        this.enabledModules.clear();
        console.log('%c[DEBUG] Debug mode ENABLED', 'color: #10b981; font-weight: bold;');
    },

    /**
     * Disable debug output globally
     */
    disable() {
        this.enabled = false;
        console.log('%c[DEBUG] Debug mode DISABLED', 'color: #ef4444; font-weight: bold;');
    },

    /**
     * Enable debug output for a specific module only
     * @param {string} moduleName - Module to enable (e.g., 'Teaser')
     */
    enableModule(moduleName) {
        this.enabled = true;
        this.enabledModules.add(moduleName);
        console.log(`%c[DEBUG] Module '${moduleName}' enabled`, 'color: #3b82f6; font-weight: bold;');
    },

    /**
     * Disable debug output for a specific module
     * @param {string} moduleName - Module to disable
     */
    disableModule(moduleName) {
        this.enabledModules.delete(moduleName);
        if (this.enabledModules.size === 0) {
            console.log(`%c[DEBUG] All modules enabled (no filter)`, 'color: #64748b;');
        }
    },

    /**
     * Set minimum log level
     * @param {'debug'|'info'|'warn'|'error'} level - Minimum level to display
     */
    setLevel(level) {
        if (LOG_LEVELS[level] !== undefined) {
            this.minLevel = level;
            console.log(`%c[DEBUG] Log level set to '${level}'`, 'color: #64748b;');
        }
    },

    /**
     * Log a debug message
     * @param {string} module - Module name (e.g., 'Teaser', 'Navigation')
     * @param {'debug'|1|'warn'|'error'} level - Log level
     * @param {string} message - Log message
     * @param {Object} data - Optional data object
     */
    log(module, level, message, data = null) {
        // Always store in buffer (for later review even if disabled)
        const entry = {
            timestamp: Date.now(),
            time: new Date().toISOString(),
            module,
            level,
            message,
            data
        };
        this.entries.push(entry);

        // Keep buffer at max size
        if (this.entries.length > this.maxEntries) {
            this.entries.shift();
        }

        // AUTO-TELEMETRY: Send all logs to backend for AI analysis
        // (Previously only errors were sent, now we capture everything)
        const systemContext = {
            ua: navigator.userAgent,
            screen: `${window.screen.width}x${window.screen.height}`,
            url: window.location.href,
            memory: navigator.deviceMemory ? `${navigator.deviceMemory}GB` : 'unknown'
        };
        this.sendTelemetry({ ...entry, systemContext });

        // Check if output should be displayed
        if (!this.enabled) return;
        if (LOG_LEVELS[level] < LOG_LEVELS[this.minLevel]) return;
        if (this.enabledModules.size > 0 && !this.enabledModules.has(module)) return;

        // Console output with styling
        const color = MODULE_COLORS[module] || MODULE_COLORS.default;
        const prefix = `%c[${module}]%c`;
        const prefixStyle = `color: ${color}; font-weight: bold;`;
        const resetStyle = 'color: inherit;';

        if (data !== null) {
            console[level === 'debug' ? 'log' : level](prefix, prefixStyle, resetStyle, message, data);
        } else {
            console[level === 'debug' ? 'log' : level](prefix, prefixStyle, resetStyle, message);
        }
    },

    /**
     * Send log entry to backend telemetry
     */
    async sendTelemetry(entry) {
        // Only send crucial logs to backend to save bandwidth and noise
        // Respect minLevel threshold for backend transmission, but ALWAYS send errors
        if (entry.level !== 'error' && LOG_LEVELS[entry.level] < LOG_LEVELS[this.minLevel]) return;

        try {
            // Import constant dynamically to avoid circular dependencies
            const { BACKEND_URL } = await import('../constants.js');
            await fetch(`${BACKEND_URL}/log-telemetry`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    level: entry.level,
                    module: entry.module,
                    message: entry.message,
                    data: entry.data,
                    timestamp: entry.time
                })
            });
        } catch (e) {
            // Silent fail for telemetry to avoid infinite loops
        }
    },

    /**
     * Shorthand for debug level
     */
    debug(module, message, data = null) {
        this.log(module, 'debug', message, data);
    },

    /**
     * Shorthand for info level
     */
    info(module, message, data = null) {
        this.log(module, 'info', message, data);
    },

    /**
     * Shorthand for warn level
     */
    warn(module, message, data = null) {
        this.log(module, 'warn', message, data);
    },

    /**
     * Shorthand for error level
     */
    error(module, message, data = null) {
        this.log(module, 'error', message, data);
    },

    /**
     * Get all logged entries
     * @returns {Array} Copy of all entries
     */
    getLog() {
        return [...this.entries];
    },

    /**
     * Get entries filtered by module
     * @param {string} module - Module to filter by
     * @returns {Array} Filtered entries
     */
    getLogByModule(module) {
        return this.entries.filter(e => e.module === module);
    },

    /**
     * Clear all entries
     */
    clear() {
        this.entries = [];
        console.log('%c[DEBUG] Log buffer cleared', 'color: #64748b;');
    },

    /**
     * Export logs as JSON string (copies to clipboard if available)
     * @returns {string} JSON string of all entries
     */
    export() {
        const json = JSON.stringify(this.entries, null, 2);

        if (navigator.clipboard) {
            navigator.clipboard.writeText(json).then(() => {
                console.log(`%c[DEBUG] ${this.entries.length} entries copied to clipboard`, 'color: #10b981; font-weight: bold;');
            }).catch(() => {
                console.log('%c[DEBUG] Clipboard access denied. JSON logged below:', 'color: #f59e0b;');
                console.log(json);
            });
        } else {
            console.log('%c[DEBUG] Clipboard not available. JSON logged below:', 'color: #f59e0b;');
            console.log(json);
        }

        return json;
    },

    /**
     * Get a summary of logged entries by module
     * @returns {Object} Count of entries per module
     */
    getSummary() {
        const summary = {};
        this.entries.forEach(e => {
            summary[e.module] = (summary[e.module] || 0) + 1;
        });
        return summary;
    },

    /**
     * Check if debug mode is currently enabled
     * @returns {boolean}
     */
    isEnabled() {
        return this.enabled;
    },

    /**
     * Toggle debug mode on/off
     * @returns {boolean} New enabled state
     */
    toggle() {
        if (this.enabled) {
            this.disable();
        } else {
            this.enable();
        }
        return this.enabled;
    },

    /**
     * Download logs as a timestamped JSON file
     * @param {string} prefix - Optional filename prefix (default: 'debug_log')
     */
    downloadLog(prefix = 'debug_log') {
        const now = new Date();
        const timestamp = now.toISOString()
            .replace(/[:.]/g, '-')
            .replace('T', '_')
            .slice(0, 19);

        const filename = `${prefix}_${timestamp}.json`;
        const json = JSON.stringify(this.entries, null, 2);
        const blob = new Blob([json], { type: 'application/json' });
        const url = URL.createObjectURL(blob);

        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        console.log(`%c[DEBUG] Downloaded ${this.entries.length} entries as ${filename}`, 'color: #10b981; font-weight: bold;');
    }
};

// Expose globally for console debugging
if (typeof window !== 'undefined') {
    window.DEBUG = Debug;
}
