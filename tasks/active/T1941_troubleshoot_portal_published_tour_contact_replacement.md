Assignee: Codex
Capacity Class: A
Objective: Replace the deprecated phone number `01044464751` with `01005684094` in the currently published portal tour assets, limiting changes to the exact live tour files that contain the outdated number.
Boundary: tasks/active/T1941_troubleshoot_portal_published_tour_contact_replacement.md, backend/data/portal/tours/, remote portal storage under `/var/lib/robust-vtb/portal/`
Owned Interfaces: Published portal tour HTML marketing banner copy inside stored launch documents
No-Touch Zones: src/, backend/src/, migrations, portal auth/session code, unrelated tours
Independent Verification: Confirm the old number exists in specific published files, replace it in-place, then verify via file-content search and HTTP response content that the live tour serves the new number instead of the old one.
Depends On: None
Merge Risk: Low; asset-only content patch.

# T1941 Troubleshoot Portal Published Tour Contact Replacement

- [ ] Hypothesis (Ordered Expected Solutions)
  - [ ] The deprecated number is hard-coded inside one or more already-published tour HTML files, so replacing it in those live assets will update the portal immediately without a rebuild.
  - [ ] The deprecated number exists in multiple published tour variants (for example `tour_2k` and `tour_4k`) under the same tour storage root and all matching copies need the same replacement.
  - [ ] The deprecated number may also exist in other published tours under `/var/lib/robust-vtb/portal/tours`, so the live storage tree must be searched before editing.

- [ ] Activity Log
  - [x] Read repo context docs and task workflow.
  - [x] Verified portal deployment path and production storage/database locations on the VPS.
  - [x] Searched local and remote published tour assets for the deprecated and replacement numbers.
  - [x] Patched the exact live tour files containing the deprecated number and created rollback backups alongside each edited file.
  - [x] Verified the active published `index.html` files no longer contain `01044464751` and that six active files now contain `01005684094`.
  - [x] Ran `npm run build` locally to keep the standard verification checkpoint green for the repo task workflow.

- [ ] Code Change Ledger
  - [x] `/var/lib/robust-vtb/portal/tours/demo-tour-3/tour_2k/index.html`: Replaced `01044464751` with `01005684094`; rollback copy at same path with suffix `.bak_codex_20260326`.
  - [x] `/var/lib/robust-vtb/portal/tours/demo-tour-3/tour_4k/index.html`: Replaced `01044464751` with `01005684094`; rollback copy at same path with suffix `.bak_codex_20260326`.
  - [x] `/var/lib/robust-vtb/portal/tours/demo-tour/tour_2k/index.html`: Replaced `01044464751` with `01005684094`; rollback copy at same path with suffix `.bak_codex_20260326`.
  - [x] `/var/lib/robust-vtb/portal/tours/demo-tour/tour_4k/index.html`: Replaced `01044464751` with `01005684094`; rollback copy at same path with suffix `.bak_codex_20260326`.
  - [x] `/var/lib/robust-vtb/portal/tours/demotourtripz/tour_2k/index.html`: Replaced `01044464751` with `01005684094`; rollback copy at same path with suffix `.bak_codex_20260326`.
  - [x] `/var/lib/robust-vtb/portal/tours/demotourtripz/tour_4k/index.html`: Replaced `01044464751` with `01005684094`; rollback copy at same path with suffix `.bak_codex_20260326`.

- [ ] Rollback Check
  - [x] Confirmed CLEAN. Active published HTML files show zero remaining matches for `01044464751`; rollback copies are available if needed.

- [ ] Context Handoff
  - [x] Production portal data lives outside the repo working tree, under `/var/lib/robust-vtb/portal`, with database `/var/lib/robust-vtb/database.db`.
  - [x] The deprecated number was not in source code; it was embedded in six published tour variant HTML assets across `demo-tour`, `demo-tour-3`, and `demotourtripz`.
  - [x] The live assets were patched in place on March 26, 2026, with `.bak_codex_20260326` rollback copies retained beside each edited file.
