# Task: 1471 - Export shortcuts alignment and wrapping

## Objective
Refine exported shortcut typography/alignment so keyboard index and labels read cleanly across variable label lengths.

## Requirements
- Keep right-side padding while making index numbers align consistently in one vertical column.
- Ensure long tag labels wrap onto next line within panel bounds.
- Keep only shortcut token bold (`1-6`, `m`, `L`), descriptive text normal.

## Verification
- `npm run build` succeeds.
- Overlay keeps right padding and aligned index column with wrapped labels.
