# T1899 Troubleshoot Local Setup Auth Flow

## Hypothesis (Ordered Expected Solutions)
- [ ] The setup flow is intentionally redirecting to `/dashboard`, so it must be changed to finish on `/signin` with a success state instead of auto-authenticating.
- [ ] The setup/auth forms are missing strong client-side validation and success/error presentation, causing failed submissions to feel silent.
- [ ] The site shell is not surfacing setup/sign-in transition state clearly enough after first-owner creation.

## Activity Log
- [x] Inspect current setup/sign-in frontend flow and backend bootstrap response.
- [x] Adjust setup completion behavior to lead into sign-in cleanly.
- [x] Improve auth form validation and visible error/success messaging.
- [x] Add an explicit post-setup success dialog with an OK-driven redirect to sign in.
- [x] Diagnose and fix the stale `local_setup_pending` user state that kept redirecting `/signin` back to `/setup`.
- [x] Restore setup-time trusted-device registration so the first normal sign-in on the same browser does not require email OTP.
- [x] Add a localhost-only sign-in fallback so local builder authentication does not depend on configured outbound email.
- [x] Verify the local setup flow manually and with build checks.

## Code Change Ledger
- [x] `backend/src/api/auth_types.rs` - Added a dedicated local setup bootstrap response type so setup completion no longer reuses sign-in payload semantics.
- [x] `backend/src/api/auth_flows_local_setup.rs` - Removed setup-time auto-authentication/device trust creation and now return a plain setup-complete response while clearing auth cookie state.
- [x] `src/site/PageFrameworkAuth.js` - Added explicit field validation, submit-state handling, sign-in prefill from query params, and a custom setup-success dialog that redirects to `/signin` only after OK.
- [x] `src/site/PageFrameworkContent.js` - Added a visible sign-in link on the local setup surface so the route is discoverable.
- [x] `css/components/site-pages-framework.css` - Added site-dialog styling for the setup-success confirmation modal.
- [x] `backend/src/api/auth_flows_local_setup.rs` - Normalized local setup state so stale pending users no longer force setup mode, and auth-only reset now consolidates preserved local data to a single bootstrap owner.
- [x] `backend/src/api/auth_flows_local_setup.rs` - Reintroduced trusted-device registration and device cookie issuance during setup completion without restoring auto-login.
- [x] `backend/src/api/auth_mail.rs` / `backend/src/api/auth.rs` / `backend/src/api/auth_flows_session_signin.rs` - Added an email-provider availability helper and skipped localhost OTP step-up when no provider is configured so local builder sign-in remains usable.

## Rollback Check
- [x] Confirm non-working changes are reverted or the final path is clean.

## Context Handoff
- [x] Local setup no longer auto-authenticates; it returns a setup-complete response and waits for explicit user acknowledgement before leaving setup.
- [x] The setup surface now shows a custom success dialog, and the sign-in page remains the canonical next step with email prefill support.
- [x] Validation errors are surfaced in the message area, setup has a visible sign-in link, and the build is currently clean.
