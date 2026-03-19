# Security & Licensing Documentation

Authentication, authorization, rate limiting, licensing, and legal policies for the Robust Virtual Tour Builder.

---

## Documents

### [Licensing](./licensing.md)
**Status:** Active

Dual licensing model: AGPL v3 (free for individuals) + Commercial License (for brokerages).

**Key Topics:**
- AGPL v3 license (free for individuals, developers, students)
- Commercial license tiers (Small Brokerage, Enterprise, SaaS)
- License comparison table
- FAQ and compliance
- Educational and non-profit licensing
- Donation and sponsorship programs

🏆 [Support the Project](../../SPONSORS.md)

### [Authentication](./authentication.md)
**Status:** Proposed

Risk-based authentication system with email OTP step-up challenges and trusted device management.

**Key Topics:**
- Risk model and scoring
- Email OTP lifecycle
- Trusted devices
- Session security
- Audit logging
- Rate limiting
- IP reputation
- Extensibility (TOTP, WebAuthn, passkeys)

### [Rate Limits](./rate_limits.md)
Rate limiting policies, thresholds, and background logic for API protection.

### [Legal](./legal.md)
Privacy Policy and Terms of Service.

---

## Security Architecture

### Authentication Flow
```
User → Credentials → Backend Validation → Risk Scoring
                                           │
                    ┌──────────────────────┘
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
└─────────────────┘   └─────────────────┘
```

### Risk Signals

| Signal | Score | Hard Trigger |
|---|---:|---|
| New device | +50 | ✅ Yes |
| Long inactivity (>= 7 days) | +25 | ❌ No |
| Geo anomaly | +40 | ❌ No |
| Bad IP reputation | +40 | ❌ No |
| Recent failed attempts | +30 | ❌ No |
| Context mismatch | +20 | ❌ No |
| Forced step-up (password reset) | +60 | ✅ Yes |

**Challenge Required:** Risk score >= 50 OR hard trigger applies

---

## Related Documentation

- **[Architecture Documentation](../architecture/)** - System robustness patterns
- **[Operations Documentation](../operations/deployment.md)** - Secure deployment
- **[Project Runbook](../project/runbook_and_audits.md)** - Security audits

---

**Last Updated:** March 19, 2026
