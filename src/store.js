/* src/store.js */

/**
 * BRIDGE STORE
 * 
 * This file delegates all state management to the ReScript implementation (Store.bs.js).
 * It wraps the ReScript store to ensure 'state' property always reflects the current
 * mutable internal state, managing the reference updates that happen during resets.
 */

import { store as resStore, internalState } from "./Store.bs.js";

// Overwrite the 'state' property on the ReScript store object with a getter.
// This ensures that even if 'internalState.contents' is replaced (e.g. during reset()),
// consumers accessing 'store.state' will always get the fresh object.
try {
    Object.defineProperty(resStore, 'state', {
        get: function () {
            return internalState.contents;
        },
        enumerable: true,
        configurable: true
    });
} catch (e) {
    console.error("Failed to define getter for store.state", e);
}

// Export the ReScript store as the primary 'store' object for the rest of the app.
export const store = resStore;
