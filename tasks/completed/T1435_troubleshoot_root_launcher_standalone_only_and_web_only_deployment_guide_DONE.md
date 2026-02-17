# T1435 - Troubleshoot Root Launcher UX + Web-Only Deployment Guide

## Objective
Make root export launcher customer-safe by showing only 4K/2K/HD tour choices (standalone paths), while preserving `web_only` for technical deployment and including explicit deployment instructions inside `web_only/`.

## Target Outcome
- Root `index.html` contains only customer-facing tour choices.
- No `web_only` selection exposed in root launcher UI.
- `web_only` folder contains a clear deployment/readme guide for developers.

## Hypothesis (Ordered Expected Solutions)
- [x] Root launcher currently exposes variant-level choices that can confuse non-technical users.
- [x] Linking root launcher cards directly to `standalone/tour_*` keeps customer flow simple.
- [x] Writing deployment instructions into `web_only/` provides technical guidance without exposing complexity to customers.

## Activity Log
- [x] Update root index template in backend export packager.
- [x] Add developer deployment guide file under `web_only/` during ZIP generation.
- [x] Verify backend compile and frontend build.

## Code Change Ledger
- [x] `backend/src/services/project/package.rs` - replace root launcher HTML content and write `web_only/DEPLOYMENT_README.txt`.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Root launcher currently presents output variants, which can lead non-technical customers to select the wrong path. The export should default to customer-safe resolution choices routed to standalone tour entries while retaining web-only output for technical hosting workflows. A deployment guide inside `web_only` keeps developer instructions close to the deployable assets.
