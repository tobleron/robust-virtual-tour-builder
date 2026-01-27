# Task 727: Refactor Logger.res (Oversized)

## 🚨 Trigger
File `src/utils/Logger.res` exceeds **360 lines** (Current: 611).

## Objective
Decompose `Logger.res` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze src/utils/Logger.res. It has 611 lines. Extract the core logic into new specialized modules (e.g. LoggerTypes.res, LoggerLogic.res) while keeping the main module as a lightweight facade."
