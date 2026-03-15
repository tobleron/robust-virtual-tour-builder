# T1882: Unit Test Regression Prevention - Portal & Builder Stability

## Objective
Update all Vitest unit tests to reflect recent source code changes and prevent regressions. This is a **comprehensive test maintenance pass** following the portal HTTPS, CORS, cookie, and builder stability improvements.

## Context
Recent major changes that require test updates:
- T1877: Portal HTTPS, CORS, SameSite=None cookies ✅ COMPLETED
- T1878: Recipient-scoped tour links (simplified approach) 🔄 IN PROGRESS
- Tablet landscape joystick positioning ✅ COMPLETED
- Dev token authentication with NODE_ENV ✅ COMPLETED
- Incremental build fixes ✅ COMPLETED

## Test Categories to Update

### 1. **Portal Authentication Tests** (HIGH PRIORITY)
**Files:**
- `tests/unit/Portal_v.test.res`
- `tests/unit/AuthenticatedClient_v.test.res`
- `tests/unit/ApiHelpers_v.test.res`

**Changes to Test:**
```rescript
// Test dev-token bypass with NODE_ENV=development
test("dev-token authentication works in development mode", () => {
  // Mock NODE_ENV=development
  // Verify dev-token is accepted
  // Verify dev-token is rejected in production
})

// Test CORS credentials:include for customer API
test("customer API requests include credentials for session cookies", () => {
  // Verify credentials: 'include' is set
  // Verify session cookies are sent with requests
})

// Test SameSite=None cookie compatibility
test("session cookies work with SameSite=None on mobile", () => {
  // Verify cookie configuration
  // Verify mobile browser compatibility
})
```

---

### 2. **Portal Access Link Tests** (HIGH PRIORITY)
**Files:**
- `tests/unit/Portal_v.test.res` (new tests)
- `tests/unit/PortalApi_v.test.res` (if exists, or create)

**Changes to Test:**
```rescript
// Test per-link revocation
test("individual tour link can be revoked without affecting other tours", () => {
  // Create customer with 2 tours
  // Revoke one tour link
  // Verify other tour still accessible
})

// Test per-link expiry override
test("tour link can have custom expiry overriding customer expiry", () => {
  // Create customer with expiry: 2026-12-31
  // Create tour link with override: 2026-06-30
  // Verify link expires on 2026-06-30, not 2026-12-31
})

// Test inherited expiry when override is NULL
test("tour link inherits customer expiry when no override set", () => {
  // Create customer with expiry: 2026-12-31
  // Create tour link with override: NULL
  // Verify link expires on 2026-12-31
})

// Test short code generation uniqueness
test("each tour assignment gets unique short code", () => {
  // Create multiple assignments
  // Verify all short codes are unique
  // Verify 7-character length
})

// Test access precedence logic
test("access control respects all 5 gates", () => {
  // Test: customer inactive → deny
  // Test: customer expired → deny
  // Test: link revoked → deny
  // Test: link expired → deny
  // Test: tour not published → deny
  // Test: all valid → allow
})
```

---

### 3. **Builder Export Tests** (MEDIUM PRIORITY)
**Files:**
- `tests/unit/Exporter_v.test.res`
- `tests/unit/ExporterPackaging_v.test.res` (if exists)

**Changes to Test:**
```rescript
// Test dev-token in export packaging
test("export packaging uses dev-token in development mode", () => {
  // Verify dev-token is used for scene fetching in dev mode
  // Verify proper token is used in production mode
})

// Test tablet landscape joystick CSS
test("joystick appears in landscape-touch mode for tablets", () => {
  // Mock tablet viewport (stage height > 420px)
  // Verify joystick CSS rules are applied
  // Verify positioning above logo (not overlapping)
})
```

---

### 4. **CORS and Network Tests** (MEDIUM PRIORITY)
**Files:**
- `tests/unit/ApiTypes_v.test.res`
- `tests/unit/BackendApi_v.test.res`

**Changes to Test:**
```rescript
// Test CORS allowed origins configuration
test("CORS allows localhost for local development", () => {
  // Verify localhost:3000, localhost:5173 are allowed
  // Verify production origins are allowed
})

// Test credential handling in API requests
test("customer API requests include credentials", () => {
  // Verify credentials: 'include' flag
  // Verify session cookies are sent
})
```

---

### 5. **Session and Cookie Tests** (MEDIUM PRIORITY)
**Files:**
- `tests/unit/OperationLifecycle_v.test.res` (if session-related)
- `tests/unit/PersistenceLayer_v.test.res` (if cookie-related)

**Changes to Test:**
```rescript
// Test session cookie configuration
test("session cookies use SameSite=None for mobile compatibility", () => {
  // Verify cookie SameSite setting
  // Verify Secure flag with HTTPS
})

// Test session persistence across API calls
test("session cookie persists across multiple API requests", () => {
  // Make multiple requests
  // Verify session is maintained
})
```

---

### 6. **GeoIP Tests** (LOW PRIORITY - Feature Disabled by Default)
**Files:**
- `tests/unit/GeoUtils_v.test.res` (if exists, or create)

**Changes to Test:**
```rescript
// Test GeoIP service is disabled by default
test("GeoIP lookup is disabled when GEOIP_ENABLED=false", () => {
  // Verify service returns None when disabled
  // Verify no external API calls are made
})

// Test GeoIP lookup when enabled
test("GeoIP lookup returns country and region when enabled", () => {
  // Mock MaxMind database
  // Verify country code lookup (e.g., "DE", "US")
  // Verify region lookup (e.g., "BY", "CA")
})
```

---

### 7. **Build and Deployment Tests** (LOW PRIORITY)
**Files:**
- `tests/unit/Constants_v.test.res`
- `tests/unit/Version_v.test.res` (if exists)

**Changes to Test:**
```rescript
// Test NODE_ENV detection
test("NODE_ENV=development enables dev features", () => {
  // Verify dev-token bypass is allowed
  // Verify verbose logging is enabled
})

test("NODE_ENV=production enforces security", () => {
  // Verify dev-token is rejected
  // Verify CORS is strict
  // Verify Secure cookie flag is set
})
```

---

## Test Files Requiring Updates

### Priority 1 (Critical - Auth & Access):
- [ ] `tests/unit/AuthenticatedClient_v.test.res`
- [ ] `tests/unit/Portal_v.test.res`
- [ ] `tests/unit/ApiHelpers_v.test.res`
- [ ] `tests/unit/BackendApi_v.test.res`

### Priority 2 (Important - Export & CORS):
- [ ] `tests/unit/Exporter_v.test.res`
- [ ] `tests/unit/ApiTypes_v.test.res`
- [ ] `tests/unit/Constants_v.test.res`

### Priority 3 (Nice to Have):
- [ ] `tests/unit/GeoUtils_v.test.res` (create if needed)
- [ ] `tests/unit/OperationLifecycle_v.test.res` (session parts)
- [ ] `tests/unit/PersistenceLayer_v.test.res` (cookie parts)

---

## Test Execution Strategy

### Phase 1: Run Existing Tests (Baseline)
```bash
npm run test:frontend
```

**Goal:** Identify which existing tests are failing due to recent changes.

### Phase 2: Fix Failing Tests
For each failing test:
1. **Understand why it's failing** (code changed vs test is wrong)
2. **Update test** to match new behavior
3. **Verify test passes**

### Phase 3: Add New Tests
Add tests for new functionality:
- Per-link revocation
- Per-link expiry override
- Short code generation
- CORS credentials
- SameSite=None cookies
- Tablet joystick positioning

### Phase 4: Verify Full Suite
```bash
npm run test:frontend
npm run test:e2e  # If E2E tests exist for portal
```

**Goal:** All tests pass, no regressions.

---

## Test Coverage Goals

| Component | Current Coverage | Target Coverage | Priority |
|-----------|-----------------|-----------------|----------|
| Portal Auth | ~60% | 85% | HIGH |
| Access Links | ~0% (new) | 90% | HIGH |
| Export System | ~70% | 80% | MEDIUM |
| CORS/Network | ~50% | 75% | MEDIUM |
| Session/Cookies | ~40% | 70% | MEDIUM |
| GeoIP | ~0% (disabled) | 50% | LOW |

---

## Mock Data Requirements

### Test Fixtures to Create:

**1. Customer Fixtures:**
```rescript
let mockCustomer = {
  id: "test-customer-1",
  slug: "test-customer",
  displayName: "Test Customer",
  isActive: true,
  expiresAt: "2026-12-31T23:59:59Z",
}
```

**2. Tour Assignment Fixtures:**
```rescript
let mockAssignment = {
  id: "test-assignment-1",
  customerId: "test-customer-1",
  tourId: "test-tour-1",
  shortCode: "abc1234",
  status: "active",
  expiresAtOverride: None,  // or Some("2026-06-30T23:59:59Z")
  revokedAt: None,
  openCount: 0,
}
```

**3. API Response Mocks:**
```rescript
let mockSessionResponse = {
  authenticated: true,
  session: {
    accessLink: {
      active: true,
      expiresAt: "2026-12-31T23:59:59Z",
      revokedAt: None,
    },
    canOpenTours: true,
    expired: false,
  },
}
```

---

## Verification Checklist

Before marking task complete:

- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Test coverage reports show no significant regressions
- [ ] Auth/access tests cover all 5 gates
- [ ] CORS/credentials tests verify session cookie handling
- [ ] Export tests verify dev-token usage
- [ ] GeoIP tests verify disabled-by-default behavior
- [ ] Documentation updated with test patterns
- [ ] CI/CD pipeline runs tests successfully

---

## Estimated Effort

| Phase | Hours | Notes |
|-------|-------|-------|
| Phase 1: Baseline | 2h | Run tests, identify failures |
| Phase 2: Fix Failing | 8h | Update existing tests |
| Phase 3: Add New | 12h | Write new test cases |
| Phase 4: Verify | 4h | Full suite verification |
| **Total** | **~26h** | ~3-4 working days |

---

## Related Tasks

- T1877: Portal HTTPS and VPS Hardening (COMPLETED)
- T1878: Recipient-Scoped Tour Links (IN PROGRESS)
- T1881: VPS Security Hardening (PENDING)
- T1882: **THIS TASK** - Unit Test Regression Prevention

---

## Notes for Developer

1. **Start with Auth tests** - Most critical, highest risk of regressions
2. **Use existing test patterns** - Follow the structure of existing tests
3. **Mock external services** - Don't make real API calls in unit tests
4. **Test edge cases** - Expired links, revoked links, inactive customers
5. **Document test scenarios** - Add comments explaining what each test verifies
6. **Keep tests fast** - Unit tests should run in <100ms each
7. **Use descriptive names** - Test names should explain the scenario being tested

---

## Success Criteria

1. ✅ All 194 existing unit tests pass
2. ✅ At least 20 new tests added for new functionality
3. ✅ No critical functionality is untested
4. ✅ Test suite runs in <5 minutes total
5. ✅ CI/CD pipeline passes with new tests
6. ✅ Test coverage maintained or improved

---

**Priority:** HIGH - This prevents regressions in production after major changes

**Dependencies:** T1877 (COMPLETED), T1878 (partially complete - core functionality)

**Blockers:** None - Can start immediately
