# Task 692: Refactor ProjectManager.res (Oversized)

## 🚨 Trigger
File `src/systems/ProjectManager.res` exceeds **360 lines** (Current: 376).

## Objective
Decompose `ProjectManager.res` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze src/systems/ProjectManager.res. It has 376 lines. Extract the core logic into new specialized modules (e.g. ProjectManagerTypes.res, ProjectManagerLogic.res) while keeping the main module as a lightweight facade."
