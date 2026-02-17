# T1448: Surgical ESC Abort for Simulation & Teaser

## Objective
Add ESC key abort support for the two remaining viewport-blocking activities that currently lack it: **Simulation (AutoPilot)** and **Teaser recording**. This replaces the over-engineered Task 1447 (ActivitySupervisor) with a targeted fix.

## Rationale (Why Not Task 1447)
- Navigation + Linking already handle ESC in `InputSystem.res`.
- Save/Export/Upload/Load already have a visible Cancel button via `SidebarProcessing.res`.
- A centralized `ActivitySupervisor` registry would add indirection for zero user-facing benefit.
- ESC for sidebar-initiated ops is *surprising UX* — the Cancel button is the correct affordance.

## Hypothesis (Ordered Expected Solutions)
- [x] Add `simulation.status == Running` check in `InputSystem.handleKeyDown` ESC block → dispatch `StopAutoPilot` + cancel navigation.
- [x] Add `isTeasing` check in `InputSystem.handleKeyDown` ESC block → dispatch `SetIsTeasing(false)` + `StopAutoPilot`.
- [x] Log both interrupts via `Logger.info` for telemetry.

## Activity Log
- [x] Read `InputSystem.res`, `Simulation.res`, `TeaserLogic.res`, `Types.res`, `State.res`.
- [x] Confirmed `simulation.status == Running` and `isTeasing` are the correct state checks.
- [x] Confirmed `StopAutoPilot` and `SetIsTeasing(false)` are the correct actions.
- [x] Implemented ESC handlers in `InputSystem.res`.

## Code Change Ledger
| File | Change | Revert Note |
|---|---|---|
| `src/systems/InputSystem.res` | Added Simulation + Teaser ESC abort blocks | Remove the two new `if` blocks in the ESC handler |

## Rollback Check
- [x] Confirmed CLEAN — only additive changes.

## Context Handoff
ESC now covers all viewport-blocking activities: Linking, Navigation, Simulation, and Teaser. Sidebar ops (Save/Export/Upload/Load) retain their Cancel button UX. Task 1447 was moved to completed/_ABORTED as superseded.
