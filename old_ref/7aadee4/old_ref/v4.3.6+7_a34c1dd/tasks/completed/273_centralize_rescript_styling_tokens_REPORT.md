# Task: Centralize ReScript Styling Tokens to CSS Variables (COMPLETED)

## Objective
Eliminate hardcoded hex color codes and dimension constants from ReScript components and replace them with CSS variable references (`var(--...)`).

## Execution
1. Searched for all hex color codes in `src/**/*.res`.
2. Updated `css/variables.css` with new variables:
    - `--warning-light`
    - `--success-light`
    - `--danger-light`
    - Gold theme colors (`--gold-1`, `--gold-2`, `--gold-3`, etc.)
    - Exported tour colors in `TourTemplateStyles.res` root block.
3. Replaced hex codes with var references in:
    - `src/components/ErrorFallbackUI.res`
    - `src/components/LinkModal.res`
    - `src/components/ModalContext.res`
    - `src/components/VisualPipeline.res`
    - `src/systems/HotspotLine.res`
    - `src/systems/TeaserRecorder.res`
    - `src/systems/TourTemplateAssets.res`
    - `src/systems/TourTemplateScripts.res`
    - `src/systems/TourTemplateStyles.res`
4. Verified build success.

## Verification
- [x] Visual consistency: The colors remain identical to user perception.
- [x] Themeability test: Changing variables in `css/variables.css` now propagates to components.
- [x] `npm run build` verification passed.
Line 1: # Task: Centralize ReScript Styling Tokens to CSS Variables
