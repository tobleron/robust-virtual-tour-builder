# Task 1815 - Google Auth Activation and Vercel Test Deployment

## Objective
Enable production-like Google OAuth testing for the web app using a Vercel-hosted frontend and correctly configured backend callback endpoints, without disrupting the current local development flow.

## Scope
- Prepare deployment checklist for frontend on Vercel.
- Define required environment variables for frontend and backend.
- Define Google Cloud OAuth Console setup for development + hosted test environment.
- Verify redirect URI/origin correctness across signin and callback routes.
- Document known limitations when frontend and backend are deployed on different hosts.

## Deliverables
1. Deployment checklist document for Vercel frontend testing.
2. Backend environment variable checklist for OAuth.
3. Google OAuth Console configuration checklist (origins + redirects).
4. Validation steps for end-to-end signin callback behavior.
5. Fallback/troubleshooting matrix for common OAuth misconfiguration errors.

## Acceptance Criteria
- A tester can deploy the frontend on Vercel and load public pages.
- Google OAuth consent and client credentials are configured with matching origins/redirects.
- Callback URL used by backend is explicit and environment-specific.
- Auth cookies/session behavior across domains is documented with constraints.
- No existing local dev auth flow is broken by configuration changes.

## Risk Notes
- Vercel is suitable for frontend hosting here; backend runtime may require a separate host unless converted to Vercel Functions.
- Cookie-based auth across different domains requires careful SameSite/Secure/CORS handling.
- Mismatch between APP_BASE_URL / GOOGLE_REDIRECT_URL / authorized redirect URI is the most likely failure class.

## Out of Scope
- Full backend infrastructure migration to Vercel serverless.
- Passkey/WebAuthn implementation.
- Billing/payments production rollout.
