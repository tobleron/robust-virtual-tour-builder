# T1860 Troubleshoot Tablet Portrait Profile Caps Not Applying

## Hypothesis (Ordered Expected Solutions)

- [ ] The generated portrait stage width rule is still being overridden later in the export CSS, causing HD / 2K / 4K to collapse to the same tablet portrait width.
- [ ] The portrait profile scale is present in source but missing from the latest artifact, so the export was generated from stale code.
- [ ] A shell-specific rule for portrait adaptive mode is widening the stage back to full viewport width after the profile-aware cap is applied.
- [ ] The tablet device is entering a different shell or viewport state than expected, so the profile cap is never used.

## Activity Log

- [ ] Inspect the latest artifact package in `artifacts/Tour`.
- [ ] Compare generated portrait CSS for `tour_hd`, `tour_2k`, and `tour_4k`.
- [ ] Determine whether the issue is stale output, CSS override order, or incorrect viewport-state logic.

## Code Change Ledger

- [ ] No code changes yet.

## Rollback Check

- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff

The current issue is that portrait exports on tablet still appear to fill the screen similarly across HD / 2K / 4K, even though mobile portrait correctly shows size differences by profile. The investigation needs to compare the latest `artifacts/Tour` output against the new portrait profile-cap logic to see whether the cap is missing, overridden, or bypassed by a later shell rule. If the artifact already contains the new CSS, then the next likely cause is rule precedence in portrait adaptive mode.
