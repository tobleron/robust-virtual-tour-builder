# 🛠️ Troubleshooting: Unicode Label Naming (T1441)

## Hypothesis (Ordered Expected Solutions)
- [x] **Hypothesis 1**: `toSlug` regex `[^a-z0-9_]` is too aggressive and strips non-Latin characters. (Confirmed).
- [x] **Hypothesis 2**: `sanitizeName` handles dangerous characters correctly, but `toSlug` removes all language-specific letters. (Confirmed).

## Activity Log
- [x] Updated `toSlug` in `TourLogic.res` to use Unicode property escapes (`\p{L}`, `\p{N}`) to support all languages while remaining safe and clean.
- [x] Added `normalize('NFKC')` to handle different Unicode representations of the same character.
- [x] Added a fallback for environments that might not support Unicode property escapes.

## Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| src/utils/TourLogic.res | Updated `toSlug` with Unicode-aware regex and normalization. | N/A |

## Rollback Check
- [ ] (Confirmed CLEAN or REVERTED non-working changes).

## Context Handoff
Non-Latin labels (Arabic, Chinese, etc.) now correctly generate human-readable filenames (e.g. `001_مطبخ.webp`) instead of empty slugs. Professionally handled via Unicode property escapes and normalization.
