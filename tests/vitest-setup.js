// @efficiency: infra-adapter
import { vi } from 'vitest';

if (typeof globalThis.Caml_option === 'undefined') {
    globalThis.Caml_option = {
        valFromOption: (x) => {
            if (x === null || x === undefined || x.BS_PRIVATE_NESTED_SOME_NONE === undefined) {
                return x;
            }
            let depth = x.BS_PRIVATE_NESTED_SOME_NONE;
            if (depth === 0) {
                return undefined;
            } else {
                return {
                    BS_PRIVATE_NESTED_SOME_NONE: depth - 1
                };
            }
        }
    };
}

// Mock idb-keyval
// We use a global store to allow inspection if needed, or just let it be persistent across imports but cleared per test if needed.
// Since tests run in parallel or isolation, having it module-scoped here is fine for per-file isolation?
// Vitest runs test files in threads usually.
// But setup file runs once per file? Yes.
vi.mock("idb-keyval", () => {
    let store = {};
    return {
        set: (key, val) => {
            store[key] = val;
            return Promise.resolve();
        },
        get: (key) => {
            return Promise.resolve(store[key]);
        },
        del: (key) => {
            delete store[key];
            return Promise.resolve();
        },
        clear: () => {
            store = {};
            return Promise.resolve();
        }
    };
});

// Mock localStorage
const localStorageMock = (() => {
    let store = {};
    return {
        getItem: (key) => store[key] || null,
        setItem: (key, value) => { store[key] = value.toString(); },
        removeItem: (key) => { delete store[key]; },
        clear: () => { store = {}; },
        key: (index) => Object.keys(store)[index] || null,
        get length() { return Object.keys(store).length; }
    };
})();

// Apply to globalThis and window
Object.defineProperty(globalThis, 'localStorage', {
    value: localStorageMock,
    writable: true
});

if (typeof window !== 'undefined') {
    Object.defineProperty(window, 'localStorage', {
        value: localStorageMock,
        writable: true
    });

    // Ensure window is globally available (fixes React DOM issues in some environments)
    if (typeof global !== 'undefined' && !global.window) {
        global.window = window;
    }
}

// Mock URL methods usually missing in JSDOM
if (typeof globalThis.URL !== 'undefined') {
    if (typeof globalThis.URL.createObjectURL === 'undefined') {
        globalThis.URL.createObjectURL = (obj) => obj ? `blob:mock-${Math.random()}` : '';
    }
    if (typeof globalThis.URL.revokeObjectURL === 'undefined') {
        globalThis.URL.revokeObjectURL = () => { };
    }
}
