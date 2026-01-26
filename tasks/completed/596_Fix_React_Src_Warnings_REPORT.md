# Fix React Src Warnings - REPORT

## Objective
The goal was to eliminate React warnings regarding empty strings passed to the `src` attribute of `<img>` elements. These warnings cause noise in test logs and can trigger redundant network requests in the browser.

## Technical Realization
1.  **Identified Root Cause**: The primary source was `src/components/SceneList.res`, where the `SceneItem` thumbnail `<img>` was being rendered with an empty `thumbUrl` when a scene was first created or if its blob URL generation failed.
2.  **Implemented Conditional Rendering**:
    - In `src/components/SceneList.res`, the `<img>` element is now wrapped in a conditional block: `{if thumbUrl != "" { <img ... /> } else { React.null }}`.
    - This ensures that if no thumbnail URL is available, we simply don't render the image element, satisfying React's requirement for a non-empty `src` or no element.
3.  **Audit of Other Components**:
    - `src/components/ViewerHUD.res` uses a static string `"images/logo.png"`, which is always non-empty and backed by a file in `public/`.
    - `src/systems/TeaserRecorder.res`, `src/utils/ImageOptimizer.res`, and `src/components/VisualPipeline.res` use imperative `Dom.setAttribute(img, "src", ...)` calls which do not trigger the React `src` warning (as they are outside the React render cycle), but already have safety checks for empty URLs.

## Verification
-   Ran `npm test` and captured stderr.
-   Confirmed that the specific warning `"An empty string ("") was passed to the src attribute"` is NO LONGER present in the logs.
-   All 555 tests passed.
