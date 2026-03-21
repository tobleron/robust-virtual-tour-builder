# T1922 Troubleshoot Local Reset Checkbox Layout

- [x] **Hypothesis (Ordered Expected Solutions)**
  - [x] Add dedicated `site-checkbox-row` styles so the local reset checkbox no longer inherits generic text-input layout rules.
  - [x] Narrow the generic `.site-form input` selector if checkbox/radio controls are still being stretched by form-wide styling.
  - [x] Verify there is no later site-page CSS override re-expanding checkbox inputs after the local fix.

- [x] **Activity Log**
  - [x] Inspected local reset page markup in `src/site/PageFrameworkContent.js`.
  - [x] Inspected auth/site form styles in `css/components/site-pages-framework.css`.
  - [x] Patched checkbox-row styles and verified with `npm run build`.
  - [x] Excluded unrelated service-worker churn triggered by an untracked image asset in `public/images/`.

- [x] **Code Change Ledger**
  - [x] `css/components/site-pages-framework.css` — added dedicated local reset checkbox row and checkbox input styling; revert if it affects other auth forms.

- [x] **Rollback Check**
  - [x] Confirmed CLEAN or REVERTED non-working changes.

- [x] **Context Handoff**
  - [x] The local reset screen rendered a checkbox inside `.site-form`, but the row had no dedicated CSS and inherited text-input styling. The fix adds explicit `.site-checkbox-row` rules and opts checkbox/radio inputs out of the generic text-field styling. The task stays active until the user validates the fix on `rubox` and approves archiving.
