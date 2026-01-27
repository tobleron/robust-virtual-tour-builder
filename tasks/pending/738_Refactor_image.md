# Task 738: Refactor image.rs (Oversized)

## 🚨 Trigger
File `backend/src/api/media/image.rs` exceeds **360 lines** (Current: 713).

## Objective
Decompose `image.rs` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze backend/src/api/media/image.rs. It has 713 lines. Extract the core logic into new specialized modules (e.g. imageTypes.res, imageLogic.res) while keeping the main module as a lightweight facade."
