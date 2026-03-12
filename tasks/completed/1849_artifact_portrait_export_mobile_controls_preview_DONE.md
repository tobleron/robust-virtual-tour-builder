## Objective

Patch the generated artifact export at `artifacts/Export_RMX_kamel_al_kilany_080326_1528_v5.2.4 (2)/desktop/index.html` directly to preview a portrait/mobile-friendly navigation control scheme before making any source-level implementation changes.

## Scope

- Do not change application source modules.
- Do not rebuild the project.
- Edit the artifact HTML/CSS/JS in place so the user can inspect the behavior immediately.

## Requested Preview Changes

1. Replace the current glass-panel command list with a simplified circular action button in the same visual language.
   - Initial state text: `(auto)`
   - First click: start auto-tour / show `1x`
   - Second click: speed up / show `1.7x`
   - Third click: stop auto-tour / reset to `(auto)`
2. Remove map access from the portrait glass-panel interaction model.
3. Make the left-side floor buttons clickable.
   - Clicking a floor should navigate to the first scene in that floor.
4. Add a bottom-center portrait joystick control:
   - Circular up button
   - Circular down button
   - Transparent/white visual style matching non-selected floor buttons
   - Highlight only when a forward/backward route exists
5. Keep this as a preview-only artifact experiment so the user can decide whether the actual source should later adopt the pattern.

## Verification

- Sanity-check the patched artifact for obvious syntax/runtime breakage.
- No source build is required because the preview is limited to the generated export artifact.
