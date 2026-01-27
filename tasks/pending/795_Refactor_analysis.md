# Task 795: Refactor analysis.rs (Oversized)

## 🚨 Trigger
File `backend/src/services/media/analysis.rs` exceeds **360 lines** (Current: 414).

## Objective
Decompose `analysis.rs` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze backend/src/services/media/analysis.rs. It has 414 lines. Extract the core logic into new specialized modules (e.g. analysisTypes.res, analysisLogic.res) while keeping the main module as a lightweight facade."
