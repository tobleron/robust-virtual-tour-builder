# Task 741: Refactor geocoding.rs (Oversized)

## 🚨 Trigger
File `backend/src/services/geocoding.rs` exceeds **360 lines** (Current: 449).

## Objective
Decompose `geocoding.rs` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze backend/src/services/geocoding.rs. It has 449 lines. Extract the core logic into new specialized modules (e.g. geocodingTypes.res, geocodingLogic.res) while keeping the main module as a lightweight facade."
