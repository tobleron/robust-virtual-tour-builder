# Task 650: Refactor SceneHelpers.res (Oversized)

## 🚨 Trigger
File `src/core/SceneHelpers.res` exceeds **360 lines** (Current: 410).

## Objective
Decompose `SceneHelpers.res` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze src/core/SceneHelpers.res. It has 410 lines. Extract the core logic into new specialized modules (e.g. SceneHelpersTypes.res, SceneHelpersLogic.res) while keeping the main module as a lightweight facade."
