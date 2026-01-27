# Task 674: Refactor ExifReportGenerator.res (Oversized)

## 🚨 Trigger
File `src/systems/ExifReportGenerator.res` exceeds **360 lines** (Current: 609).

## Objective
Decompose `ExifReportGenerator.res` into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze src/systems/ExifReportGenerator.res. It has 609 lines. Extract the core logic into new specialized modules (e.g. ExifReportGeneratorTypes.res, ExifReportGeneratorLogic.res) while keeping the main module as a lightweight facade."
