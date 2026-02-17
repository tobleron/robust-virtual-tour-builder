# T1431 - Troubleshoot Floor Button Active-State Parity (Simulation + Export)

## Objective
Ensure floor navigation visual behavior is consistent and correct between builder simulation mode and exported tours:
- Idle floor buttons render grey/transparent in exported tours.
- Active floor button renders orange.
- Simulation mode preserves active orange floor instead of grayscaling it.

## Hypothesis (Ordered Expected Solutions)
- [x] Legacy auto-pilot CSS selector references a class no longer used by floor buttons, causing active floor to be grayscaled in simulation.
- [x] Export template idle floor style uses blue background instead of required grey/transparent palette.
- [x] Explicit active/idle state classes on floor buttons will provide deterministic CSS targeting across modes.

## Activity Log
- [x] Inspect floor button class generation in builder HUD component.
- [x] Inspect simulation/auto-pilot CSS overrides for floor nav.
- [x] Inspect export template floor button CSS state rules.
- [x] Implement class/state and style fixes.
- [x] Run build verification.

## Code Change Ledger
- [x] `src/components/FloorNavigation.res` - Add deterministic `state-active` / `state-idle` classes for floor buttons to enable robust state-specific CSS targeting.
- [x] `css/components/floor-nav.css` - Replace legacy active selector with `state-active` and scope grayscale to `state-idle` only.
- [x] `src/systems/TourTemplates.res` - Update export idle floor button style to grey/transparent while keeping active orange.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Simulation mode currently applies grayscale to all floor buttons due to outdated selector logic, which masks active-state orange. Export tour floor idle style still uses blue background, conflicting with the requested grey/transparent appearance. Fix is to unify on explicit state class targeting and verify build before completion.
