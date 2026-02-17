# 🛠️ Troubleshooting: Label Menu Keyboard Interception (T1439)

## Hypothesis (Ordered Expected Solutions)
- [ ] **Hypothesis 1**: Global keyboard listener in `ViewerHUD.res` or `InputSystem.res` is intercepting keys even when an input is focused.
- [x] **Hypothesis 2**: `LabelMenu.res` or `ViewerLabelMenu.res` has a local keydown handler that implements "type-to-search" but doesn't exclude the custom label input field. (Confirmed: Radix DropdownMenu type-ahead).
- [ ] **Hypothesis 3**: The custom label input field is not correctly handling `stopPropagation()` on key events. (Root cause).

## Activity Log
- [x] Initial investigation of `LabelMenu.res` and `ViewerLabelMenu.res`.
- [x] Check `InputSystem.res` for global keyboard matching logic.
- [x] Applied `stopPropagation` to the custom label input in `LabelMenu.res`.

## Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| src/components/LabelMenu.res | Added `JsxEvent.Keyboard.stopPropagation(e)` to custom label input. | N/A |

## Rollback Check
- [ ] (Confirmed CLEAN or REVERTED non-working changes).

## Context Handoff
Investigating why custom label input in the label menu is hijacked by keyboard listeners meant for list navigation/matching. Likely a missing focus check or event propagation issue.
