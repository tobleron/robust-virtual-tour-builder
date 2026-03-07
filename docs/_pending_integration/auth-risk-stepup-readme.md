# Risk-Based Login Challenge (Email OTP Step-Up)

## Decision flow
1. User signs in with email/password.
2. Backend validates credentials, then evaluates risk signals.
3. If risk score >= 50, or hard trigger applies, backend requires step-up email OTP.
4. If no challenge is needed, login completes directly.

## Risk model (additive)
- `new_device`: +50 (also hard trigger for first login on unknown device)
- `long_inactivity` (default >= 7 days): +25
- `geo_anomaly` (impossible travel / major region jump): +40
- `ip_reputation_bad|proxy|vpn|tor|hosting`: +40 (pluggable via `X-IP-Reputation` signal)
- `recent_failed_attempts`: +30
- `context_mismatch` (UA/timezone/language mismatch combined with other signal): +20
- forced step-up reason from sensitive flow (example password reset): +60 (hard trigger)

## Hard triggers currently enforced
- First login on new device
- `password_reset_flow` forced step-up marker

## OTP behavior
- Email OTP step-up (6-digit numeric)
- Single-use
- Expires in 10 minutes
- Prior pending OTP challenges are invalidated before issuing a new challenge
- Max 5 attempts per OTP
- Resend cooldown (default 45 seconds)
- Issuance rate-limited by user and IP (default per hour cap)
- Stored as hash only (`otp_hash`)

## Trusted devices
- Device token stored in secure HttpOnly cookie (`rvtb_device`)
- Server stores only token hash in `trusted_devices`
- On successful OTP verification, device becomes trusted
- Trust expiry is configurable (default 30 days)
- Password reset revokes all trusted devices for the user
- Endpoint available to revoke all trusted devices

## Sessions / security
- Auth and device cookies: `Secure` (production), `HttpOnly`, `SameSite=Lax`
- JWT rotated on successful sign-in and after successful OTP challenge
- Step-up state embedded in JWT (`step_up_verified_until`)
- `StepUpMiddleware` enforces step-up for sensitive endpoints

## Audit logging
Events are written to `auth_events` with timestamp + context (when available):
- sign-in success/failure
- OTP issued / resent / failed / expired / lockout / success
- trusted device revocation
- password reset completion forcing step-up

## Extensibility
- IP reputation source is pluggable (`evaluate_ip_reputation`)
- Model is modular to add passkeys/TOTP/WebAuthn later without replacing risk scorer
