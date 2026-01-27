# Task 696: Refactor SceneLoader.res (Oversized)

## 🚨 Trigger
File `src/systems/SceneLoader.res` exceeds **360 lines** (Current: 413).

## Objective
Decompose `SceneLoader.res` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze src/systems/SceneLoader.res. It has 413 lines. Extract the core logic into new specialized modules (e.g. SceneLoaderTypes.res, SceneLoaderLogic.res) while keeping the main module as a lightweight facade."
