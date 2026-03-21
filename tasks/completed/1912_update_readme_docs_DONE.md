# 1912 Refresh README And Split Developer Guide

- [x] **Objective**
  - Update the primary `README.md` so it only contains end-user facing guidance, workflow, and contact/donation messaging.
  - Extract the developer-specific setup / `_dev-system` instructions into a new `DEVELOPERS_README.md`.
  - Emphasize the local-first, free-for-individual-broker usage terms and donation channels (PayPal + crypto).

- [x] **Steps**
  - [x] Create `DEVELOPERS_README.md` summarizing the dev workflow, `_dev-system` role, and build/test commands.
  - [x] Remove development-only sections from `README.md` and point readers to the developer guide.
  - [x] Add a sincere donation/contact section to `README.md` noting that the app is free for individual brokers (personal & commercial) and donations help cover maintenance costs.
  - [x] Mention the temporary demo link notice and the live demo screenshot from `public/images/DemoTour.png`.

- [x] **Activity Log**
  - [x] Extracted the development workflow content from `README.md` and replaced it with a pointer to `DEVELOPERS_README.md`.
  - [x] Drafted `DEVELOPERS_README.md` covering setup, dev commands, `_dev-system`, and additional resources.
  - [x] Added the donation messaging plus crypto addresses to `README.md` and kept contact information.
- [x] **Code Change Ledger**
  - [x] `README.md` — slimmed to end-user content, inserted documentation map link, donation section, maintained demo note, removed dev workflow.
  - [x] `DEVELOPERS_README.md` — new file describing developer workflow, `_dev-system`, and commands.

- [x] **Verification**
  - [x] Confirm that `README.md` focuses only on end-user content.
  - [x] Confirm that `DEVELOPERS_README.md` contains the setup/dev instructions previously in `README.md` plus a summary of `_dev-system`.
