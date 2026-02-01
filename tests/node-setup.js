// @efficiency: infra-adapter
// tests/node-setup.js
import { register } from 'node:module';
import { pathToFileURL } from 'node:url';

// Register JSX loader for Node ESM
try {
    register('./jsx-loader.mjs', pathToFileURL('./tests/'));
} catch (e) {
    // Older Node versions might use --loader instead
}

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
        createElement: (tag) => {
            const el = {
                tag: tag,
                width: 0,
                height: 0,
                src: '',
                getContext: () => ({
                    getExtension: () => null,
                    getParameter: () => 'mock',
                    fillRect: () => { },
                    beginPath: () => { },
                    stroke: () => { },
                    fill: () => { },
                    save: () => { },
                    restore: () => { },
                    drawImage: () => { },
                    imageSmoothingQuality: 'high'
                }),
                toBlob: (cb, type, quality) => {
                    setTimeout(() => {
                        cb({ size: 1024, type: type || 'image/webp' });
                    }, 0);
                },
                style: {},
                appendChild: () => { },
                setAttribute: (name, value) => {
                    el[name] = value;
                    if (tag === 'img' && name === 'src') {
                        setTimeout(() => {
                            if (el.onload) el.onload();
                        }, 0);
                    }
                },
                classList: { add: () => { }, remove: () => { }, contains: () => false, toggle: () => { } },
                addEventListener: (event, cb) => {
                    if (event === 'load') el.onload = cb;
                    if (event === 'error') el.onerror = cb;
                },
                removeEventListener: () => { }
            };
            return el;
        },
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
defineGlobal('self', mockWindow);
defineGlobal('document', mockWindow.document);
if (typeof global !== 'undefined') global.document = mockWindow.document;
defineGlobal('navigator', mockWindow.navigator);
defineGlobal('location', mockWindow.location);
defineGlobal('screen', mockWindow.screen);
defineGlobal('URL', globalThis.URL);
globalThis.URL.createObjectURL = (obj) => obj ? `blob:mock-${Math.random()}` : '';
globalThis.URL.revokeObjectURL = () => { };
defineGlobal('FormData', class { append() { } });
defineGlobal('Blob', class { constructor() { this.size = 0; this.type = ''; } });
defineGlobal('caches', {
    open: () => Promise.resolve({
        addAll: () => Promise.resolve(),
        match: () => Promise.resolve(null),
        put: () => Promise.resolve()
    }),
    keys: () => Promise.resolve([]),
    match: () => Promise.resolve(null),
    delete: () => Promise.resolve(true)
});

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
defineGlobal('localStorage', localStorageMock);
mockWindow.localStorage = localStorageMock;


// Mock React for tests
defineGlobal('React', {
    createElement: () => ({}),
    forwardRef: (fn) => fn,
    useState: (init) => [typeof init === 'function' ? init() : init, () => { }],
    useEffect: () => { },
    useRef: () => ({ current: null }),
    useMemo: (fn) => fn(),
    useCallback: (fn) => fn,
});

// Mock shadcn UI components for tests
const mockComponent = () => ({});
const mockModule = {
    Button: mockComponent,
    Popover: mockComponent,
    PopoverTrigger: mockComponent,
    PopoverContent: mockComponent,
    PopoverAnchor: mockComponent,
    Tooltip: mockComponent,
    TooltipProvider: mockComponent,
    TooltipTrigger: mockComponent,
    TooltipContent: mockComponent,
    DropdownMenu: mockComponent,
    DropdownMenuTrigger: mockComponent,
    DropdownMenuContent: mockComponent,
    DropdownMenuItem: mockComponent,
    DropdownMenuSeparator: mockComponent,
    ContextMenu: mockComponent,
    ContextMenuTrigger: mockComponent,
    ContextMenuContent: mockComponent,
    ContextMenuItem: mockComponent,
    ContextMenuSeparator: mockComponent,
};

// Create module cache for shadcn components
const moduleCache = new Map();
moduleCache.set(new URL('file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/button.jsx').href, mockModule);
moduleCache.set(new URL('file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/popover.jsx').href, mockModule);
moduleCache.set(new URL('file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/tooltip.jsx').href, mockModule);
moduleCache.set(new URL('file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/dropdown-menu.jsx').href, mockModule);
moduleCache.set(new URL('file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/context-menu.jsx').href, mockModule);

// Shim for legacy ReScript runtime names used by some libraries (like rescript-schema v9)
defineGlobal('Caml_option', {
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
});

// End of setup
