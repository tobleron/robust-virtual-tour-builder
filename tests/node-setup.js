// tests/node-setup.js
const mockWindow = {
    location: { hostname: 'localhost', toString: () => 'http://localhost' },
    screen: { width: 1920, height: 1080 },
    devicePixelRatio: 1,
    navigator: {
        userAgent: 'NodeTest',
        platform: 'Node',
        hardwareConcurrency: 8,
        deviceMemory: 16,
        serviceWorker: {
            register: () => Promise.resolve({}),
            getRegistrations: () => Promise.resolve([]),
            addEventListener: () => { }
        }
    },
    addEventListener: () => { },
    removeEventListener: () => { },
    pannellumViewer: null,
    document: {
        createElement: (tag) => ({
            tag: tag,
            getContext: () => ({
                getExtension: () => null,
                getParameter: () => 'mock',
                fillRect: () => { },
                beginPath: () => { },
                stroke: () => { },
                fill: () => { },
                save: () => { },
                restore: () => { },
            }),
            style: {},
            appendChild: () => { },
            setAttribute: () => { },
            classList: { add: () => { }, remove: () => { }, contains: () => false, toggle: () => { } }
        }),
        getElementById: () => null,
        querySelector: () => null,
        querySelectorAll: () => [],
        addEventListener: () => { },
        body: {
            appendChild: () => { },
            addEventListener: () => { },
            style: {}
        }
    }
};

const defineGlobal = (name, value) => {
    Object.defineProperty(globalThis, name, {
        value,
        writable: true,
        configurable: true,
        enumerable: true
    });
    if (typeof global !== 'undefined') {
        global[name] = value;
    }
};

defineGlobal('window', mockWindow);
defineGlobal('document', mockWindow.document);
defineGlobal('navigator', mockWindow.navigator);
defineGlobal('location', mockWindow.location);
defineGlobal('screen', mockWindow.screen);
defineGlobal('FormData', class { append() { } });
defineGlobal('Blob', class { constructor() { this.size = 0; this.type = ''; } });
