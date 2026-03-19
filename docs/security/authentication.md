# Authentication & Security

**Last Updated:** March 19, 2026  
**Scope:** Risk-based authentication, email OTP step-up, trusted devices  
**Related Files:** `backend/src/api/auth.rs`, `backend/src/middleware/`, `backend/src/services/auth/`

---

## 1. Overview

This document defines the risk-based authentication system with email OTP step-up challenges. The system evaluates login risk signals and requires additional verification for suspicious login attempts.

### Design Principles

1. **Risk-Based:** Authentication challenge level adapts to detected risk
2. **User-Friendly:** Low-risk logins complete without friction
3. **Secure:** High-risk logins require step-up verification
4. **Auditable:** All auth events logged for security analysis
5. **Extensible:** Modular design supports future auth methods (TOTP, WebAuthn, passkeys)

---

## 2. Authentication Flow

### 2.1 Standard Login Flow

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   User      │─────▶│  Backend     │─────▶│  Risk       │
│  (Credentials)     │  (Validate)  │      │  Scorer     │
└─────────────┘      └──────────────┘      └──────┬──────┘
                                                   │
                    ┌──────────────────────────────┘
                    │
           ┌────────▼────────┐
           │  Risk Score >= 50? │
           └────────┬────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
        Yes                   No
         │                     │
         ▼                     ▼
┌─────────────────┐   ┌─────────────────┐
│  Email OTP      │   │  Login Complete │
│  Step-Up        │   │  (JWT issued)   │
└────────┬────────┘   └─────────────────┘
         │
         ▼
┌─────────────────┐
│  OTP Verified?  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
   Yes       No
    │         │
    ▼         ▼
┌─────────┐ ┌──────────┐
│  Login  │ │  Error   │
│ Complete│ │  (Lock)  │
└─────────┘ └──────────┘
```

### 2.2 Decision Flow

1. User signs in with email/password
2. Backend validates credentials
3. Backend evaluates risk signals
4. **If** risk score >= 50 **or** hard trigger applies:
   - Require step-up email OTP
5. **If** no challenge needed:
   - Login completes directly

---

## 3. Risk Model

### 3.1 Risk Signals (Additive)

| Signal | Score | Description | Hard Trigger |
|---|---:|---|---|
| `new_device` | +50 | First login from unknown device | ✅ Yes |
| `long_inactivity` | +25 | No login for >= 7 days (configurable) | ❌ No |
| `geo_anomaly` | +40 | Impossible travel / major region jump | ❌ No |
| `ip_reputation_bad` | +40 | Proxy/VPN/Tor/hosting detected | ❌ No |
| `recent_failed_attempts` | +30 | Multiple recent failures | ❌ No |
| `context_mismatch` | +20 | UA/timezone/language mismatch + other signal | ❌ No |
| `forced_step_up` | +60 | Sensitive flow (password reset) | ✅ Yes |

### 3.2 Risk Score Calculation

```rust
let mut risk_score = 0;

if new_device {
    risk_score += 50;
}

if days_since_last_login >= 7 {
    risk_score += 25;
}

if geo_anomaly_detected {
    risk_score += 40;
}

if ip_reputation_bad {
    risk_score += 40;
}

if recent_failed_attempts >= 3 {
    risk_score += 30;
}

if context_mismatch && risk_score > 0 {
    risk_score += 20;
}

if forced_step_up_reason {
    risk_score += 60;
}

// Challenge required if:
let challenge_required = risk_score >= 50 || new_device || forced_step_up_reason;
```

### 3.3 Hard Triggers

These always require step-up regardless of total score:

1. **First login on new device** (`new_device`)
   - Device not found in `trusted_devices` table
   - Device token not present in cookie

2. **Password reset flow** (`forced_step_up`)
   - User just completed password reset
   - All previous trusted devices revoked

---

## 4. Email OTP System

### 4.1 OTP Properties

| Property | Value |
|---|---|
| **Format** | 6-digit numeric |
| **Delivery** | Email via Resend API |
| **Validity** | 10 minutes |
| **Max Attempts** | 5 per OTP |
| **Resend Cooldown** | 45 seconds (default) |
| **Issuance Rate Limit** | Per user and IP (per hour cap) |
| **Storage** | Hash only (`otp_hash`) |

### 4.2 OTP Lifecycle

```
┌─────────────┐
│  OTP Issued │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Email Sent │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  User Input │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Verify     │◀─────┐
└──────┬──────┘      │
       │             │
  ┌────┴────┐        │
  │         │        │
 Valid    Invalid    │
  │         │        │
  ▼         ▼        │
┌─────┐   ┌──────────┘
│ OK  │   │ Attempts < 5?
└─────┘   └──────┬───┘
                 │
            ┌────┴────┐
            │         │
           Yes       No
            │         │
            ▼         ▼
       ┌────────┐ ┌─────────┐
       │ Retry  │ │ Lockout │
       └────────┘ └─────────┘
```

### 4.3 OTP Behavior

**Before Issuing New OTP:**
- Invalidate any prior pending OTP challenges for same user
- Check rate limits (user + IP)
- Check resend cooldown (45 seconds)

**On Successful Verification:**
- Mark device as trusted (if not already)
- Issue JWT with `step_up_verified_until` claim
- Log `otp_verified` event

**On Failure:**
- Increment attempt counter
- If attempts >= 5: lockout user temporarily
- Log `otp_failed` event

**On Expiry:**
- Invalidate OTP
- Log `otp_expired` event

---

## 5. Trusted Devices

### 5.1 Device Token Management

**Storage:**
- **Client:** Secure HttpOnly cookie (`rvtb_device`)
- **Server:** Token hash only in `trusted_devices` table

**Lifecycle:**
```
┌──────────────┐
│ New Device   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ OTP Verified │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Generate     │
│ Device Token │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Store Hash   │
│ Set Cookie   │
└──────────────┘
```

### 5.2 Trust Properties

| Property | Value |
|---|---|
| **Trust Duration** | 30 days (configurable) |
| **Trust Scope** | Per device + browser |
| **Revocation** | Password reset revokes all |
| **Manual Revocation** | Endpoint available |

### 5.3 Device Token Cookie

```http
Set-Cookie: rvtb_device=<token>;
  Path=/;
  Secure;
  HttpOnly;
  SameSite=Lax;
  Max-Age=2592000  // 30 days
```

---

## 6. Session Security

### 6.1 Cookie Security

| Cookie | Secure | HttpOnly | SameSite | Purpose |
|---|---|---|---|---|
| `rvtb_session` | ✅ (prod) | ✅ | Lax | JWT session token |
| `rvtb_device` | ✅ (prod) | ✅ | Lax | Device trust token |

### 6.2 JWT Claims

```typescript
{
  sub: "user-id",
  email: "user@example.com",
  iat: 1234567890,
  exp: 1234567890,
  step_up_verified_until: 1234567890,  // Present if step-up completed
  device_trusted: true                   // Present if device trusted
}
```

### 6.3 JWT Rotation

**When JWT is Rotated:**
1. On successful sign-in
2. After successful OTP challenge verification
3. On session refresh (if implemented)

**Rotation Process:**
1. Generate new JWT with updated claims
2. Invalidate old JWT (add to denylist if using JWTi)
3. Set new session cookie

### 6.4 Step-Up Middleware

Enforces step-up verification for sensitive endpoints:

```rust
// Example protected endpoint
#[post("/account/change-password")]
async fn change_password(
    req: HttpRequest,
    step_up: StepUpMiddleware,  // Enforces step_up_verified_until
) -> Result<Json<Response>> {
    // step_up ensures user completed step-up within valid window
}
```

**Sensitive Endpoints:**
- Password change
- Email change
- Account deletion
- Payment method changes
- API key generation

---

## 7. Audit Logging

### 7.1 Auth Events

All events written to `auth_events` table:

| Event | Context |
|---|---|
| `sign_in_success` | user_id, ip, device_fingerprint |
| `sign_in_failure` | email, ip, reason |
| `otp_issued` | user_id, delivery_method |
| `otp_resent` | user_id, attempt_number |
| `otp_failed` | user_id, attempts_remaining |
| `otp_expired` | user_id |
| `otp_lockout` | user_id, lockout_duration |
| `otp_verified` | user_id, device_trusted |
| `trusted_device_revoked` | user_id, device_id |
| `password_reset_completed` | user_id, forced_step_up |

### 7.2 Event Schema

```typescript
{
  event_id: string,
  event_type: string,
  user_id: option<string>,
  email: option<string>,
  ip: string,
  user_agent: string,
  timestamp: number,
  context: object  // Event-specific metadata
}
```

### 7.3 Retention

- **Active events:** 90 days
- **Archived events:** 1 year
- **Security incidents:** Indefinite

---

## 8. Rate Limiting

### 8.1 Rate Limits

| Endpoint | Limit | Window |
|---|---|---|
| Login (per IP) | 10 requests | 1 minute |
| Login (per email) | 5 requests | 5 minutes |
| OTP issuance (per user) | 5 requests | 1 hour |
| OTP issuance (per IP) | 10 requests | 1 hour |
| OTP verification (per OTP) | 5 attempts | OTP lifetime |
| Resend OTP | 1 request | 45 seconds |

### 8.2 Rate Limit Headers

```http
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 5
X-RateLimit-Reset: 1234567890
X-RateLimit-After: 60  // Seconds to wait
```

---

## 9. IP Reputation

### 9.1 Reputation Sources

IP reputation is pluggable via `evaluate_ip_reputation()` function:

**Supported Signals:**
- Proxy detection
- VPN detection
- Tor exit nodes
- Hosting providers (datacenters)
- Known bad IP ranges

### 9.2 Integration

```rust
// Example IP reputation evaluation
async fn evaluate_ip_reputation(ip: &str) -> IpReputation {
    // Pluggable: integrate with IPQualityScore, MaxMind, etc.
    // For now, use basic heuristics
}
```

### 9.3 Custom Integration

To add IP reputation provider:

1. Implement `evaluate_ip_reputation()` function
2. Add provider API key to environment
3. Cache results to avoid excessive API calls
4. Handle provider failures gracefully (fail-open or fail-closed)

---

## 10. Extensibility

### 10.1 Future Auth Methods

The modular design supports adding:

**TOTP (Time-based OTP):**
- Add `totp_secret` column to users table
- Implement TOTP verification endpoint
- Add QR code generation for setup
- Risk score reduction for TOTP users

**WebAuthn/Passkeys:**
- Add `webauthn_credentials` table
- Implement registration ceremony
- Implement authentication ceremony
- Replace password entirely (optional)

**SMS OTP:**
- Add SMS provider integration (Twilio, etc.)
- Add phone number to users table
- Support SMS as OTP delivery method
- Higher cost, consider rate limits

### 10.2 Adding New Risk Signals

To add new risk signal:

1. Add signal to risk scorer
2. Assign score weight
3. Determine if hard trigger
4. Add audit logging
5. Update documentation

**Example:**
```rust
// New signal: suspicious browser fingerprint
if browser_fingerprint_mismatch {
    risk_score += 35;
}
```

---

## 11. Security Considerations

### 11.1 OTP Security

**Protection Against:**
- **Brute Force:** Max 5 attempts, rate limiting
- **Replay:** Single-use, hash storage
- **Interception:** 10-minute expiry
- **Spam:** Resend cooldown, issuance rate limits

### 11.2 Device Token Security

**Protection Against:**
- **Theft:** HttpOnly cookie (not accessible to JS)
- **CSRF:** SameSite=Lax
- **MITM:** Secure flag (HTTPS only)
- **Reuse:** Token hash stored, not plaintext

### 11.3 Session Security

**Protection Against:**
- **Session Fixation:** JWT rotation on login
- **Session Hijacking:** Secure cookies, short expiry
- **Privilege Escalation:** Step-up middleware

---

## 12. Testing

### 12.1 Test Scenarios

**Unit Tests:**
- Risk score calculation
- OTP generation and verification
- Device token generation
- JWT claims validation

**Integration Tests:**
- Full login flow (low risk)
- Full login flow with OTP (high risk)
- Device trust persistence
- Step-up middleware enforcement

**E2E Tests:**
- User signup and login
- Password reset flow
- Trusted device revocation
- Account security settings

### 12.2 Security Tests

**Penetration Testing:**
- OTP brute force attempts
- Rate limit bypass attempts
- Session fixation attempts
- CSRF attacks

**Chaos Testing:**
- OTP provider failure
- Database connection loss
- Rate limiter failure

---

## 13. Related Documents

- [Rate Limits](./rate_limits.md) - Rate limiting configuration
- [Deployment](../operations/deployment.md) - Production deployment
- [Async Processing](../architecture/async_processing.md) - Backend scaling

---

## 14. Appendix: Environment Variables

```env
# JWT & Session
JWT_SECRET=<32+ char random secret>
SESSION_KEY=<64+ byte random secret>
JWT_EXPIRY=86400  # 24 hours

# Email OTP
RESEND_API_KEY=<resend key>
EMAIL_FROM=no-reply@robust-vtb.com
OTP_EXPIRY=600  # 10 minutes
OTP_MAX_ATTEMPTS=5
OTP_RESEND_COOLDOWN=45  # seconds

# Trusted Devices
DEVICE_TRUST_DURATION=2592000  # 30 days
DEVICE_COOKIE_NAME=rvtb_device

# Rate Limiting
LOGIN_RATE_LIMIT_IP=10  # per minute
LOGIN_RATE_LIMIT_EMAIL=5  # per 5 minutes
OTP_ISSUANCE_RATE_LIMIT=5  # per hour

# Risk Model
RISK_THRESHOLD=50
NEW_DEVICE_SCORE=50
LONG_INACTIVITY_SCORE=25
LONG_INACTIVITY_DAYS=7
GEO_ANOMALY_SCORE=40
IP_REPUTATION_BAD_SCORE=40
RECENT_FAILED_ATTEMPTS_SCORE=30
CONTEXT_MISMATCH_SCORE=20
FORCED_STEP_UP_SCORE=60
```

---

**Document History:**
- March 19, 2026: Initial authentication & security documentation from risk-based login spec
