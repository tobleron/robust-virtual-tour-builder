# Task 742: Refactor media.rs (Oversized)

## 🚨 Trigger
File `backend/src/services/media.rs` exceeds **360 lines** (Current: 684).

## Objective
Decompose `media.rs` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze backend/src/services/media.rs. It has 684 lines. Extract the core logic into new specialized modules (e.g. mediaTypes.res, mediaLogic.res) while keeping the main module as a lightweight facade."
