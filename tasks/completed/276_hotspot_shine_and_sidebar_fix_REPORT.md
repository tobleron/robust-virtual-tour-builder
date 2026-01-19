# Task 276: Hotspot Shine and Sidebar Switch Fix - REPORT (V3 Surgical Update)

## Objective
Finalize the golden hotspot arrow effects:
1. **Disable all growth/scale** transitions on hover.
2. Enable the **white shine effect by default** (always on).
3. Implement an **elegant highlight** on hover without using glowing aura effects.

## Technical Implementation

### 1. Hotspot Arrow Visuals Refinement
- **CSS Modification**: Updated `css/components/viewer.css`.
- **Scaling Locked**: Standardized `scale(0.8)` for both default and hover states of `::before` and `::after`. This effectively removes any size flickering or growth.
- **Rotation Locked**: Kept `rotateX(60deg)` consistent in both states to prevent perspective shifts that could look like growth.
- **Always-on Shine**:
    - Moved the `hotspot-shine` animation to the default state of `::after`.
    - Set default `opacity: 0.6` for a subtle, constant glimmer.
    - Set a 2s linear loop for the default state to keep it calm but active.
- **Hover Highlight**:
    - Increased `brightness(1.15)` and `opacity: 1` on hover for a clean, non-glowing highlight.
    - Sped up the shine animation to `0.8s` on hover for responsive feedback.
    - Maintained `translateY(-25px)` to give the arrow a distinct "lift" interaction without changing its size.

### 2. Sidebar Logic (Final State)
- The throttle limit logic in `src/components/SceneList.res` is preserved with your preferred `650.0` value.
- The active scene click guard ensures no "Switching too fast" warnings appear when clicking the current image.

## Verification
- **Build**: Successfully ran `npm run build`.
- **Logic**: No scale values change between states, so the arrow stays perfectly sized.
