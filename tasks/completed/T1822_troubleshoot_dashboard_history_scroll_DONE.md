# T1822 Troubleshoot Dashboard History Scroll

## Hypothesis (Ordered Expected Solutions)
- [x] Global site-page overflow lock is preventing the dashboard document from scrolling when history rows expand.
- [ ] The dashboard history panel needs its own scroll container or flex/min-height fix inside the table row.
- [ ] A builder-only overlay/body mode is leaking into the dashboard page and suppressing scrolling.

## Activity Log
- [x] Read `MAP.md`, `DATA_FLOW.md`, and `tasks/TASKS.md`.
- [x] Located the dashboard history renderer in `src/site/PageFrameworkDashboard.js`.
- [x] Located site-page layout CSS in `css/base.css` and `css/components/site-pages-framework.css`.
- [x] Applied a narrow scroll fix for site-framework pages.
- [x] Identified `#app` as the remaining scroll lock because it still enforced `height: 100dvh` and `overflow: hidden`.
- [x] Applied a site-framework-only `#app` override so dashboard pages can extend vertically.
- [x] Verified the shared frontend production build passes after the CSS change.

## Code Change Ledger
- [x] `css/components/site-pages-framework.css` — added site-framework-only `html`/`body` overflow overrides so dashboard pages can scroll when project history expands without affecting builder-mode layout.
- [x] `css/components/site-pages-framework.css` — added a site-framework-only `#app` override to remove the fixed-height/hidden-overflow builder shell behavior on dashboard pages.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- The dashboard history rows render inline inside the site-framework document flow. Global base CSS and the shared `#app` shell were forcing a fixed viewport with hidden overflow, so expanding history clipped content instead of allowing page scroll. The fix is a site-framework-only override in `css/components/site-pages-framework.css` for `html`, `body`, and `#app`, validated with `npm run build`.
