# 1573 Fast Shots + Simple Crossfade Teaser Styles

## Objective
Implement `Fast Shots` and `Simple Crossfade` teaser styles so they produce static endpoint-frame WebMs (no camera animation), with style-specific timing constants.

## Scope
- Frontend teaser pipeline only.
- Implement style manifest generation for `Fast Shots` and `Simple Crossfade`.
- Ensure renderer consumes static shots without waypoint animation.
- Add regression unit tests for style timing constants and static-shot manifest behavior.

## Acceptance
- Selecting `Fast Shots` generates a deterministic WebM sequence of static scene endpoint shots.
- Selecting `Simple Crossfade` generates a deterministic static-shot sequence with premium short crossfades.
- Fast Shots default shot duration constant is `1.2s`.
- Simple Crossfade default shot duration constant is `1.8s` with short transition duration constant.
- No regressions in teaser unit tests and frontend unit suite.
