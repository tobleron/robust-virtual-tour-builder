/**
 * PubSub.js
 * 
 * Simple Publish/Subscribe event bus for decoupled component communication.
 * Primarily used for navigation events, system alerts, and internal signals 
 * that don't belong in the global state.
 */

const observers = {};

export const PubSub = {
    /**
     * Subscribe to an event
     * @param {string} event - Event name
     * @param {function} callback - Function to call
     * @returns {function} Unsubscribe function
     */
    subscribe(event, callback) {
        if (!observers[event]) {
            observers[event] = [];
        }
        observers[event].push(callback);

        return () => {
            observers[event] = observers[event].filter(cb => cb !== callback);
        };
    },

    /**
     * Publish an event
     * @param {string} event - Event name
     * @param {any} data - Data to pass to subscribers
     */
    publish(event, data) {
        if (!observers[event]) return;
        observers[event].forEach(callback => {
            try {
                callback(data);
            } catch (err) {
                console.error(`[PubSub] Error in subscriber for "${event}":`, err);
            }
        });
    }
};

// Common event names for consistency
export const EVENTS = {
    NAV_START: 'NAV_START',
    NAV_PROGRESS: 'NAV_PROGRESS',
    NAV_COMPLETED: 'NAV_COMPLETED',
    NAV_CANCELLED: 'NAV_CANCELLED',
    SCENE_ARRIVED: 'SCENE_ARRIVED', // Similar to NAV_COMPLETED but focus on the scene
    LINK_PREVIEW_START: 'LINK_PREVIEW_START',
    LINK_PREVIEW_END: 'LINK_PREVIEW_END'
};
