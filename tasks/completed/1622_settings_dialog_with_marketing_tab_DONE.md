# 1622 Settings Dialog With Marketing Tab

## Objective
Replace the current About entrypoint with a Settings entrypoint (gear icon), implement a centered large settings dialog with left-side tabs (Marketing first, About last), and add configurable marketing text (comment + two phone numbers) that renders as a bottom-center viewer badge.

## Scope
- Replace sidebar About button with Settings gear button while preserving existing typography/icon sizing rhythm.
- Build settings modal layout (centered, large) with left tab rail.
- Add `Marketing` tab form with:
  - comment field
  - phone number 1 field
  - phone number 2 field
  - 127-char total limit for final rendered text
  - preview of exact rendered bottom text
- Add Save / Cancel behavior.
- Render bottom-center marketing badge in viewer, styled similarly to link-creation top-center yellow label style language.
- Keep About content accessible as the last tab.

## Acceptance Criteria
- Settings button replaces About button and opens settings dialog.
- Dialog is visually larger and centered within viewer area.
- Left-side tab list exists with Marketing first and About last.
- Marketing tab enforces 127 max total rendered chars and shows exact preview.
- Save persists settings; Cancel discards unsaved edits.
- Bottom-center viewer badge reflects saved marketing content.

## Verification
- `npm run res:build`
- `npm run test:frontend`
- manual smoke check in dev UI
