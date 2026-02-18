# Task: 1477 - Export panel ratio tuning and auto-forward looking-mode gating

## Objective
Refine glass panel dimensions and fix looking-mode restoration behavior during auto-forward transitions.

## Requirements
- Decrease panel width by ~10% from current values.
- Increase portrait bottom padding to better satisfy root-2 portrait feel.
- During scene animation completion: do not restore Looking mode ON if the scene is auto-forwarding.
- For non-auto-forward scenes, keep existing restoration behavior.

## Verification
- `npm run build` succeeds.
- Looking mode remains OFF while auto-forward chain continues.
