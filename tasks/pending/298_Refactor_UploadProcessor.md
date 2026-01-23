# Task 298: Refactor UploadProcessor.res (Oversized)

## 🚨 Trigger
File `./src/systems/UploadProcessor.res` exceeds **700 lines** (Current: 759).

## Objective
Decompose `UploadProcessor.res` into smaller, focused modules. Aim for < 400 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze ./src/systems/UploadProcessor.res. It has 759 lines. Extract the core logic into new specialized modules (e.g. UploadProcessorTypes.res, UploadProcessorLogic.res) while keeping the main module as a lightweight facade."
