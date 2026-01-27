# Task 739: Refactor video.rs (Oversized)

## 🚨 Trigger
File `backend/src/api/media/video.rs` exceeds **360 lines** (Current: 433).

## Objective
Decompose `video.rs` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze backend/src/api/media/video.rs. It has 433 lines. Extract the core logic into new specialized modules (e.g. videoTypes.res, videoLogic.res) while keeping the main module as a lightweight facade."
