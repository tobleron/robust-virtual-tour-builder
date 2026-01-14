# Task 83: Implement Code Splitting for Faster Initial Load

## Priority: 🟡 IMPORTANT

## Context
Per `docs/ARCHITECTURE_DIAGRAM.md`, code splitting could provide a **40% faster initial load**. Currently, the entire application including all libraries loads synchronously.

Heavy dependencies that could be lazy-loaded:
- **Pannellum** (~150KB) - Only needed when viewing panoramas
- **JSZip** (~100KB) - Only needed for save/export

## Current State

### index.html
```html
<script src="src/libs/pannellum.js"></script>
<script src="src/libs/jszip.min.js"></script>
<script src="src/libs/FileSaver.min.js"></script>
```

All loaded synchronously, blocking initial render.

## Implementation Approach

### Option A: Dynamic Import (Recommended)

**1. Create lazy loaders in ReScript:**

```rescript
// src/utils/LazyLoad.res

@val external import_: string => Promise.t<'a> = "import"

let pannellum: ref<option<unit>> = ref(None)
let jszip: ref<option<unit>> = ref(None)

let loadPannellum = () => {
  switch pannellum.contents {
  | Some(_) => Promise.resolve()
  | None => 
    // Load via script tag injection
    let script = document.createElement("script")
    script.src = "/src/libs/pannellum.js"
    document.body->appendChild(script)
    Promise.make((resolve, _reject) => {
      script.onload = () => {
        pannellum := Some()
        resolve()
      }
    })
  }
}
```

**2. Modify ViewerLoader to wait for Pannellum:**
```rescript
// ViewerLoader.res
let initViewer = () => {
  LazyLoad.loadPannellum()
  ->Promise.then(() => {
    // Now safe to call pannellum.viewer()
  })
}
```

**3. Modify Exporter to load JSZip on demand:**
```rescript
// Exporter.res or DownloadSystem.res
let exportProject = () => {
  LazyLoad.loadJSZip()
  ->Promise.then(() => {
    // Now safe to use JSZip
  })
}
```

### Option B: Module Federation (Complex)
Would require a build tool like Vite or Webpack. Possibly overkill for this project.

### Option C: Preload hints (Simplest)
```html
<link rel="preload" href="src/libs/pannellum.js" as="script">
<link rel="preload" href="src/libs/jszip.min.js" as="script">
```

Doesn't reduce total bytes but starts loading earlier.

## Recommended Implementation

### Phase 1: Remove synchronous scripts
1. Remove `<script src="pannellum.js">` from index.html
2. Add dynamic script loader in ReScript
3. Ensure ViewerLoader waits for Pannellum before init

### Phase 2: Lazy load JSZip
1. Remove `<script src="jszip.min.js">` from index.html
2. Load only when user clicks "Save" or "Export"
3. Show loading indicator during script fetch

### Phase 3: Preload hints for common path
```html
<!-- Start loading early, but don't block -->
<link rel="modulepreload" href="src/libs/pannellum.js">
```

## Metrics to Track

Before (measure with DevTools):
- [ ] Time to First Contentful Paint (FCP)
- [ ] Time to Interactive (TTI)
- [ ] Total JS bundle size

After:
- [ ] Same metrics
- [ ] Target: 40% improvement in FCP

## Acceptance Criteria
- [ ] Pannellum loads only when viewer is needed
- [ ] JSZip loads only when save/export is triggered
- [ ] No visible delay when user triggers lazy-loaded features
- [ ] Initial page load is measurably faster
- [ ] All existing functionality works unchanged

## Files to Modify
- `index.html` - remove/modify script tags
- `src/utils/LazyLoad.res` - create new module
- `src/components/ViewerLoader.res` - await Pannellum
- `src/systems/Exporter.res` - await JSZip
- `src/systems/DownloadSystem.res` - await JSZip

## Testing
1. Clear browser cache
2. Load application
3. Verify UI renders before panorama viewer
4. Click to view a scene - Pannellum should load
5. Save project - JSZip should load
6. Repeat actions - no re-loading (cached)
