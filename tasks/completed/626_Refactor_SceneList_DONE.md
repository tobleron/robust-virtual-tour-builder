# Task 626: Refactor SceneList.res (Oversized)

## 🚨 Trigger
File `src/components/SceneList.res` exceeds **360 lines** (Current: 440).

## Objective
Decompose `SceneList.res` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze src/components/SceneList.res. It has 440 lines. Extract the core logic into new specialized modules (e.g. SceneListTypes.res, SceneListLogic.res) while keeping the main module as a lightweight facade."
