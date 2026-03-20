# 1843 Export Manual Waypoint Animation Gate

## Objective
Change exported tours so waypoint-based arrival animation is disabled during normal manual navigation by default, while preserving animated waypoint playback for auto-tour. Keep the implementation easy to reverse by centralizing the behavior behind a single runtime policy helper/flag.

## Scope
- Exported tour runtime only.
- Do not change teaser cinematic behavior.
- Do not change builder navigation behavior.

## Acceptance Criteria
- Manual navigation in exported tours no longer runs waypoint/pan arrival animation by default.
- Auto-tour in exported tours still runs waypoint/pan arrival animation.
- The behavior can be reverted by changing one clear runtime policy constant/helper rather than undoing scattered logic.
- Export template tests reflect the new runtime policy.
- `npm run build` passes.

## Notes
- Prefer a single exported runtime policy such as `auto-tour-only` rather than hardcoded branches spread across hotspot playback logic.
- Preserve end-of-auto-tour focus behavior unless it explicitly depends on manual arrival animation.
