# Task 740: Refactor storage.rs (Oversized)

## 🚨 Trigger
File `backend/src/api/project/storage.rs` exceeds **360 lines** (Current: 541).

## Objective
Decompose `storage.rs` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze backend/src/api/project/storage.rs. It has 541 lines. Extract the core logic into new specialized modules (e.g. storageTypes.res, storageLogic.res) while keeping the main module as a lightweight facade."
