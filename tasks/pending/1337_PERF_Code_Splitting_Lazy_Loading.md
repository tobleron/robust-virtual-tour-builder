# [1337] Code Splitting — Lazy Load Rarely-Used Features

## Priority: P1 (High)

## Context
The entire application bundle is loaded upfront (~280KB JS). Several features are rarely used and only activated by explicit user action, yet they are included in the initial bundle:

| Feature Module | LOC | Usage Frequency | Trigger |
|---------------|-----|-----------------|---------|
| `TeaserRecorder.res` | 315 | Rare — only during recording | User clicks "Record Teaser" |
| `TourTemplates.res` | 319 | Rare — only at export | User clicks "Export" |
| `ExifParser.res` | 317 | Rare — only on explicit action | User opens EXIF report |
| `VisualPipeline.res` | 323 | Conditional — toggled panel | User opens pipeline view |

## Objective
Use `React.lazy()` + `Suspense` to defer loading these modules until they're needed. Expected initial bundle reduction: **~15-20%**.

## Implementation

### Step 1: Create Lazy Wrappers

For each module, create a lazy wrapper using ReScript's `%raw` binding for dynamic import:

```rescript
// src/components/LazyTeaserRecorder.res
let lazyComponent = React.lazy_(() => 
  Js.import(TeaserRecorder.make)
)

@react.component
let make = (~props) => {
  <React.Suspense fallback={<div className="lazy-loading-spinner" />}>
    {React.createElement(lazyComponent, props)}
  </React.Suspense>
}
```

**Note**: ReScript's `React.lazy_` binding may need verification with ReScript v12. Check if `Js.import` works or if a `%raw` wrapper is needed for the dynamic `import()` call.

### Step 2: Replace Static Imports

In parent components that render these features:
```rescript
// OLD:
<TeaserRecorder ... />

// NEW:
<LazyTeaserRecorder ... />
```

### Step 3: Add Loading Spinner CSS

```css
.lazy-loading-spinner {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100px;
  /* Use existing design system spinner if available */
}
```

### Step 4: Verify Bundle Split

```bash
npm run build
# Check dist/ for separate chunks
ls -la dist/assets/*.js
```

Verify that the lazy-loaded modules appear as separate chunks in the build output.

## Verification
- [ ] Initial bundle size reduced (measure before/after)
- [ ] Lazy-loaded features still work when activated
- [ ] Loading spinner appears briefly during lazy load
- [ ] `npm run build` passes cleanly
- [ ] No flash of unstyled content (FOUC) when lazy modules load
- [ ] E2E: `simulation-teaser.spec.ts` passes (teaser is lazy-loaded)

## Estimated Effort: 1 day
