# Task Report: Refactor ViewerUI Inline Styles to CSS Classes

## Objective
The goal was to improve Separation of Concerns by moving inline styles and hardcode style objects from `src/components/ViewerUI.res` into external CSS classes in `css/components/viewer.css`.

## Realization
1.  **CSS Class Creation**: Defined new semantic classes in `css/components/viewer.css` for:
    -   **Utility Buttons**: `v-util-btn-add-link`, `v-util-btn-autopilot`, `v-util-btn-category`, `v-util-btn-label`.
    -   **Detailed States**: `state-empty`, `state-linking`, `state-idle`, `state-active`, `state-loaded`.
    -   **Categories**: `cat-indoor`, `cat-outdoor`, `cat-none`.
    -   **Category-Specific Icons**: `v-util-btn-icon`.
    -   **Quality Badges**: `quality-badge`, `q-blurry`, `q-soft`, `q-dark`, `q-dim`.
    -   **Linking Hints**: `linking-hint-text`, `linking-hint-subtext`.
    -   **Viewer Logo Mask**: `viewer-logo-masked`.
    -   **Floor Navigation**: `floor-circle-shadow-selected`, `floor-circle-shadow-idle`, `floor-suffix`.

2.  **ReScript Refactoring**:
    -   Removed `style={makeStyle({...})}` blocks from `src/components/ViewerUI.res`.
    -   Replaced them with conditional string logic that concatenates the appropriate class names based on state (e.g., `simActive`, `scenesLoaded`, `isLinking`).

3.  **Verification**:
    -   Successfully compiled ReScript and built the project (`npm run build`).
    -   Verified that the logic for class application matches the original inline style logic (e.g., disabling buttons when no scenes are loaded, changing colors for active states).

## Outcome
The `ViewerUI.res` component is now significantly cleaner, with presentation logic decoulped from the component logic. Visual styles are centralized in `viewer.css`, making future design updates easier.
