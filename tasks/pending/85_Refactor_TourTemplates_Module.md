# Task 85: Refactor TourTemplates Module (588 lines → <500)

## Priority: 🟡 IMPORTANT

## Context
`TourTemplates.res` is at 588 lines, approaching the 700-line limit set in GEMINI.md. Proactive refactoring will prevent future issues and improve maintainability.

## Current Structure Analysis

The module likely contains:
1. HTML template generation
2. CSS template strings
3. JavaScript embeddings for exported tours
4. Asset handling (images, icons)
5. Configuration options

## Refactoring Strategy

### Extract 1: TourTemplateStyles.res (~150 lines)
Move all CSS generation:
```rescript
// TourTemplateStyles.res

let viewerStyles = `
  .pnlm-container { ... }
  // All viewer CSS
`

let navigationStyles = `
  .nav-button { ... }
  // Navigation CSS
`

let generateStyles = (config) => {
  viewerStyles ++ navigationStyles ++ ...
}
```

### Extract 2: TourTemplateScripts.res (~100 lines)
Move JavaScript embeddings:
```rescript
// TourTemplateScripts.res

let initializerScript = `
  <script>
    pannellum.viewer('panorama', {...});
  </script>
`

let navigationScript = `
  <script>
    function navigateTo(sceneId) { ... }
  </script>
`
```

### Extract 3: TourTemplateAssets.res (~50 lines)
Move asset URIs and icon definitions:
```rescript
// TourTemplateAssets.res

let logoBase64 = "data:image/png;base64,..."
let navigationIcons = { ... }
```

### Refactored TourTemplates.res (~300 lines)
Keep only the main composition logic:
```rescript
// TourTemplates.res

open TourTemplateStyles
open TourTemplateScripts
open TourTemplateAssets

let generateTourHTML = (scenes, config) => {
  let styles = TourTemplateStyles.generateStyles(config)
  let scripts = TourTemplateScripts.generateScripts(scenes)
  let assets = TourTemplateAssets.getAssets()
  
  `<!DOCTYPE html>
  <html>
  <head>${styles}</head>
  <body>
    ${generateViewer(scenes)}
    ${scripts}
  </body>
  </html>`
}
```

## Task Steps

1. [ ] Analyze current `TourTemplates.res` structure
2. [ ] Identify extraction candidates (styles, scripts, assets)
3. [ ] Create `TourTemplateStyles.res` with CSS content
4. [ ] Create `TourTemplateScripts.res` with JS content
5. [ ] Create `TourTemplateAssets.res` if significant
6. [ ] Update `TourTemplates.res` to use new modules
7. [ ] Verify exported tours still work correctly
8. [ ] Confirm total line count is under 500

## Acceptance Criteria
- [ ] `TourTemplates.res` is under 500 lines
- [ ] New modules created as needed
- [ ] All exports still function correctly
- [ ] Tour HTML output is identical
- [ ] `npm run res:build` succeeds with no new warnings

## Files to Create
- `src/systems/TourTemplateStyles.res`
- `src/systems/TourTemplateScripts.res`
- `src/systems/TourTemplateAssets.res` (if needed)

## Files to Modify
- `src/systems/TourTemplates.res`

## Testing
1. Build the project
2. Create a 3+ scene tour
3. Export tour package
4. Open exported `index.html` in browser
5. Verify all navigation works
6. Verify styles are applied correctly
7. Verify logo/branding appears
