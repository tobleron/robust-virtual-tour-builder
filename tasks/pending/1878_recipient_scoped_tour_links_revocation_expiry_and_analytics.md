# 1878 Recipient-Scoped Tour Links with Per-Link Control (Simplified)

## Objective
Implement a recipient-tour link system that provides per-link access control while keeping the implementation lean. This is a **simplified approach** that extends the existing assignment model rather than creating entirely new tables.

**Key Principle:** Stable foundation first, advanced analytics later.

---

## Problem Statement

The current portal model has:
- Recipients with a single expiry date
- Tours as reusable library items
- Assignments as many-to-many links (no individual control)

**Limitations:**
- Can't revoke access to one tour without affecting all tours for that recipient
- Can't set custom expiry for individual tour links
- No visibility into which tours are actually being viewed
- All links for a recipient share the same lifecycle

**Goal:** Enable per-link control while keeping the data model simple and extendable.

---

## Solution Overview

### Core Concept
Extend `portal_customer_tour_assignments` table with fields for per-link control:
- `short_code` - Unique identifier for shareable link
- `status` - Active/Revoked state
- `expires_at_override` - Optional per-link expiry (inherits from recipient if NULL)
- `revoked_at` - Timestamp when link was revoked
- `open_count`, `last_opened_at` - Simple usage tracking

### Access Precedence (Evaluation Order)
1. **Recipient active?** → If no, deny (hard gate)
2. **Recipient not expired?** → If expired, deny (hard gate)
3. **Link not revoked?** → If revoked, deny
4. **Link not expired?** → Use override if set, else inherit from recipient
5. **Tour exists and published?** → If no, deny

**Effective Expiry Rule:**
```
effective_expiry = link.expires_at_override ?? recipient.expires_at
```

---

## Required Changes

### 1. Database Schema

**File:** `backend/src/services/portal.rs` (migration logic)

**SQL Migration:**
```sql
-- Add per-link control columns to existing assignments table
ALTER TABLE portal_customer_tour_assignments
ADD COLUMN short_code TEXT UNIQUE,
ADD COLUMN status TEXT DEFAULT 'active',  -- 'active' | 'revoked'
ADD COLUMN expires_at_override DATETIME,  -- NULL = inherit from recipient
ADD COLUMN revoked_at DATETIME,
ADD COLUMN revoked_reason TEXT,
ADD COLUMN last_opened_at DATETIME,
ADD COLUMN open_count INTEGER DEFAULT 0,
ADD COLUMN geo_country_code TEXT,         -- Top country (GeoIP)
ADD COLUMN geo_region TEXT;               -- Top region/state (GeoIP)

-- Index for short_code lookups (performance)
CREATE INDEX idx_assignments_short_code ON portal_customer_tour_assignments(short_code);

-- Index for recipient-tour lookups (admin UI)
CREATE INDEX idx_assignments_recipient_tour ON portal_customer_tour_assignments(recipient_id, tour_id);
```

**Notes:**
- No new tables for Phase 1
- Existing assignments remain functional (short_code will be generated on next access or admin action)
- GeoIP fields are populated but **disabled by default** (see GeoIP section)

---

### 2. Backend Data Models

**File:** `backend/src/services/portal.rs`

**New/Updated Structs:**
```rust
#[derive(Debug, Clone, FromRow)]
struct PortalCustomerTourAssignment {
    id: String,
    customer_id: String,
    tour_id: String,
    short_code: Option<String>,
    status: String,  // "active" | "revoked"
    expires_at_override: Option<DateTime<Utc>>,
    revoked_at: Option<DateTime<Utc>>,
    revoked_reason: Option<String>,
    last_opened_at: Option<DateTime<Utc>>,
    open_count: i64,
    geo_country_code: Option<String>,
    geo_region: Option<String>,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
```

**New Input Types:**
```rust
pub struct CreateRecipientTourLinkInput {
    pub customer_id: String,
    pub tour_id: String,
    pub expires_at_override: Option<DateTime<Utc>>,  // Optional
}

pub struct RevokeRecipientTourLinkInput {
    pub assignment_id: String,
    pub reason: Option<String>,
}

pub struct UpdateLinkExpiryInput {
    pub assignment_id: String,
    pub expires_at_override: Option<DateTime<Utc>>,  // None = clear override, inherit from recipient
}
```

---

### 3. Backend API Endpoints

**File:** `backend/src/api/portal.rs`

#### New Endpoints:

**1. Create Recipient-Tour Link**
```rust
POST /api/portal/admin/customers/{customer_id}/tours/{tour_id}/link
Body: { "expiresAtOverride": "2026-12-31T23:59:59Z" }  // Optional
Response: { "shortCode": "abc123", "linkUrl": "https://www.robust-vtb.com/u/ak84/abc123" }
```

**2. Revoke Link**
```rust
POST /api/portal/admin/assignments/{assignment_id}/revoke
Body: { "reason": "Property no longer available" }  // Optional
Response: { "ok": true }
```

**3. Update Link Expiry**
```rust
POST /api/portal/admin/assignments/{assignment_id}/expiry
Body: { "expiresAtOverride": "2026-06-30T23:59:59Z" }  // Null to clear override
Response: { "ok": true, "effectiveExpiry": "2026-06-30T23:59:59Z" }
```

**4. Get Assignment Details** (extend existing)
```rust
GET /api/portal/admin/assignments/{assignment_id}
Response: {
  "id": "...",
  "customer": { "slug": "ak84", "displayName": "Arto Kalishian" },
  "tour": { "slug": "demo-tour", "title": "Demo Tour" },
  "shortCode": "abc123",
  "status": "active",
  "effectiveExpiry": "2026-04-14T11:54:00Z",
  "expiresAtOverride": null,  // null = inherited
  "inheritedFromRecipient": true,
  "revokedAt": null,
  "revokedReason": null,
  "lastOpenedAt": "2026-03-15T14:20:06Z",
  "openCount": 42,
  "geoCountryCode": "DE",  // GeoIP (disabled by default)
  "geoRegion": "BY"
}
```

**5. List Recipient's Tour Links** (extend existing customer tours endpoint)
```rust
GET /api/portal/admin/customers/{customer_id}/tours
Response: {
  "customer": { ... },
  "tours": [
    {
      "assignmentId": "...",
      "tour": { "id": "...", "slug": "...", "title": "..." },
      "shortCode": "abc123",
      "status": "active",
      "effectiveExpiry": "...",
      "expiresAtOverride": null,
      "inheritedFromRecipient": true,
      "lastOpenedAt": "...",
      "openCount": 42
    }
  ]
}
```

**6. List Tour's Recipient Links** (new endpoint for tour-centric view)
```rust
GET /api/portal/admin/tours/{tour_id}/recipients
Response: {
  "tour": { ... },
  "recipients": [
    {
      "assignmentId": "...",
      "customer": { "id": "...", "slug": "ak84", "displayName": "Arto Kalishian", "recipientType": "broker" },
      "shortCode": "abc123",
      "status": "active",
      "effectiveExpiry": "...",
      "lastOpenedAt": "...",
      "openCount": 42
    }
  ]
}
```

#### Modified Endpoints:

**7. Direct Link Access** (update existing `/access/{shortCode}` endpoint)
```rust
GET /access/{shortCode}
```

**Updated Logic:**
```rust
// 1. Look up assignment by short_code
let assignment = find_assignment_by_short_code(pool, &short_code).await?;

// 2. Load recipient (hard gate)
let customer = load_customer(pool, &assignment.customer_id).await?;
if customer.is_active != 1 {
    return redirect_to_expired(customer.slug);
}
if customer.expires_at < Utc::now() {
    return redirect_to_expired(customer.slug);
}

// 3. Check link-specific status
if assignment.status == "revoked" || assignment.revoked_at.is_some() {
    return redirect_to_revoked(customer.slug);
}

// 4. Check link expiry (override or inherited)
let effective_expiry = assignment.expires_at_override.unwrap_or(customer.expires_at);
if effective_expiry < Utc::now() {
    return redirect_to_expired(customer.slug);
}

// 5. Check tour status
let tour = load_tour(pool, &assignment.tour_id).await?;
if tour.status != "published" {
    return redirect_to_unavailable(customer.slug);
}

// 6. Increment counters (fire-and-forget, don't block redirect)
spawn_increment_open_count(assignment.id, client_ip).await;

// 7. Redirect to tour viewer
redirect_to_tour_viewer(customer.slug, tour.slug)
```

---

### 4. Short Code Generation

**File:** `backend/src/services/portal.rs`

**Requirements:**
- 7 characters (like current access codes)
- Alphanumeric (0-9, A-Z, a-z)
- Globally unique
- Non-guessable (use UUID-based generation, not sequential)

**Implementation:**
```rust
fn make_assignment_short_code() -> String {
    let mut value = Uuid::new_v4().as_u128();
    let mut chars = ['0'; 7];
    
    for index in (0..7).rev() {
        let alphabet_index = (value % 62) as usize;
        chars[index] = PORTAL_ACCESS_CODE_ALPHABET[alphabet_index] as char;
        value /= 62;
    }
    
    chars.iter().collect()
}

// Collision handling: retry up to 10 times if short_code already exists
async fn generate_unique_short_code(pool: &SqlitePool) -> Result<String, AppError> {
    for _ in 0..10 {
        let code = make_assignment_short_code();
        let exists = assignment_code_exists(pool, &code).await?;
        if !exists {
            return Ok(code);
        }
    }
    Err(AppError::InternalError("Failed to generate unique short code".into()))
}
```

---

### 5. GeoIP Implementation (Disabled by Default)

**File:** `backend/src/services/geo_ip.rs` (NEW)

**Purpose:** Map IP addresses to country/region for analytics.

**Implementation:**
- Use **MaxMind GeoLite2** database (free, local, no API calls)
- Download database file (~70MB) to `/opt/robust-vtb/geoip/GeoLite2-City.mmdb`
- Query locally on link open
- **DISABLED BY DEFAULT** via feature flag

**Feature Flag:** `GEOIP_ENABLED` (default: `false`)

**Code Structure:**
```rust
// backend/src/services/geo_ip.rs

use maxminddb::{Reader, geoip2::City};

pub struct GeoIpService {
    reader: Option<Reader<Vec<u8>>>,
}

impl GeoIpService {
    pub fn new() -> Self {
        let reader = if std::env::var("GEOIP_ENABLED").unwrap_or_default() == "true" {
            let db_path = std::env::var("GEOIP_DB_PATH")
                .unwrap_or_else(|_| "/opt/robust-vtb/geoip/GeoLite2-City.mmdb".to_string());
            match std::fs::read(&db_path) {
                Ok(data) => Some(Reader::from_source(&data[..]).ok()),
                Err(e) => {
                    tracing::warn!(geoip_db_path = %db_path, error = %e, "GeoIP database not found, disabling GeoIP");
                    None
                }
            }
        } else {
            tracing::debug!("GeoIP is disabled (GEOIP_ENABLED != true)");
            None
        };
        
        Self { reader }
    }
    
    pub fn lookup(&self, ip: &str) -> Option<GeoIpResult> {
        self.reader.as_ref().and_then(|reader| {
            let ip: std::net::IpAddr = ip.parse().ok()?;
            let city: City = reader.lookup(ip).ok()?;
            
            Some(GeoIpResult {
                country_code: city.country.and_then(|c| c.iso_code).map(String::from),
                region: city.subdivisions.and_then(|s| s.first())
                    .and_then(|sub| sub.iso_code).map(String::from),
                city: city.city.and_then(|c| c.names).and_then(|names| {
                    names.get("en").cloned().map(String::from)
                }),
            })
        })
    }
}

pub struct GeoIpResult {
    pub country_code: Option<String>,  // e.g., "DE", "US"
    pub region: Option<String>,        // e.g., "BY", "CA"
    pub city: Option<String>,          // e.g., "Munich", "San Francisco"
}
```

**Usage in Access Endpoint:**
```rust
// Only increment GeoIP if enabled
if geo_ip_service.is_enabled() {
    if let Some(geo) = geo_ip_service.lookup(&client_ip) {
        sqlx::query(
            "UPDATE portal_customer_tour_assignments 
             SET geo_country_code = ?, geo_region = ? 
             WHERE id = ?"
        )
        .bind(&geo.country_code)
        .bind(&geo.region)
        .bind(&assignment.id)
        .execute(pool)
        .await?;
    }
}
```

**Setup Instructions (for later activation):**
1. Download GeoLite2 database:
   ```bash
   mkdir -p /opt/robust-vtb/geoip
   wget https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=YOUR_KEY&suffix=tar.gz
   tar -xzf GeoLite2-City.tar.gz -C /opt/robust-vtb/geoip --strip-components=1
   ```
2. Set environment variable:
   ```bash
   GEOIP_ENABLED=true
   ```
3. Restart service

**Default Behavior:** GeoIP lookups are skipped, `geo_country_code` and `geo_region` remain NULL.

---

### 6. Frontend Admin UI

**File:** `src/site/PortalApp.res` (and related components)

#### Customer Detail View Updates

**Add Tour Assignment Table:**
```rescript
type assignmentRow = {
  id: string,
  tourId: string,
  tourSlug: string,
  tourTitle: string,
  shortCode: option<string>,
  status: string,  // "active" | "revoked"
  effectiveExpiry: string,
  expiresAtOverride: option<string>,
  inheritedFromRecipient: bool,
  lastOpenedAt: option<string>,
  openCount: int,
}

// In customer detail view:
let renderTourAssignments = (assignments: array<assignmentRow>) => {
  <div className="portal-card">
    <h2> {React.string("Assigned tours")} </h2>
    <table className="portal-table">
      <thead>
        <tr>
          <th> {React.string("Tour")} </th>
          <th> {React.string("Status")} </th>
          <th> {React.string("Expires")} </th>
          <th> {React.string("Opens")} </th>
          <th> {React.string("Actions")} </th>
        </tr>
      </thead>
      <tbody>
        {assignments->Belt.Array.map(assignment => {
          <tr key={assignment.id}>
            <td> {React.string(assignment.tourTitle)} </td>
            <td>
              <span className={"portal-chip " ++ (
                assignment.status == "active" ? "is-active" : "is-revoked"
              )}>
                {React.string(assignment.status->String.capitalizeFirst)}
              </span>
            </td>
            <td>
              {switch assignment.inheritedFromRecipient {
              | true => <span className="portal-muted"> {React.string("Inherits from recipient")} </span>
              | false => React.string(assignment.effectiveExpiry->formatDate)
              }}
            </td>
            <td> {React.string(Belt.Int.toString(assignment.openCount))} </td>
            <td>
              <div className="portal-inline-actions">
                <button
                  className="site-btn site-btn-ghost"
                  onClick={_ => copyLink(assignment.shortCode)}>
                  {React.string("Copy Link")}
                </button>
                {switch assignment.status {
                | "active" =>
                  <button
                    className="site-btn site-btn-ghost"
                    onClick={_ => setExpiryOverride(assignment.id)}>
                    {React.string("Set Expiry")}
                  </button>
                  <button
                    className="site-btn site-btn-ghost"
                    onClick={_ => revokeLink(assignment.id)}>
                    {React.string("Revoke")}
                  </button>
                | "revoked" =>
                  <button
                    className="site-btn site-btn-ghost"
                    onClick={_ => reactivateLink(assignment.id)}>
                    {React.string("Reactivate")}
                  </button>
                }}
              </div>
            </td>
          </tr>
        })}
      </tbody>
    </table>
  </div>
}
```

#### New Modals/Dialogs

**1. Set Expiry Override Modal:**
```rescript
type expiryOverrideState = {
  assignmentId: string,
  effectiveExpiry: string,
  currentOverride: option<string>,
  newOverride: option<string>,
}

// Modal content:
<div>
  <p> {React.string("Current expiry: " ++ state.effectiveExpiry)} </p>
  {switch state.currentOverride {
  | Some(_) => <p className="portal-muted"> {React.string("Custom override (inherits from recipient if cleared)")} </p>
  | None => <p className="portal-muted"> {React.string("Inherited from recipient")} </p>
  }}
  <input
    type_="datetime-local"
    value={state.newOverride->Option.getOr("")}
    onChange={e => setState(_ => {...state, newOverride: Some(ReactEvent.Form.target(e)["value"])})}
  />
  <div className="modal-actions">
    <button onClick={_ => clearOverride()}> {React.string("Clear Override (Inherit)")} </button>
    <button onClick={_ => saveOverride()}> {React.string("Save")} </button>
  </div>
</div>
```

**2. Revoke Link Modal:**
```rescript
<div>
  <p> {React.string("Are you sure you want to revoke access to this tour?")} </p>
  <p className="portal-muted"> {React.string("This will not affect other tours for this recipient.")} </p>
  <textarea
    placeholder="Revocation reason (optional)"
    value={reason}
    onChange={e => setReason(ReactEvent.Form.target(e)["value"])}
  />
  <div className="modal-actions">
    <button onClick={_ => confirmRevoke()}> {React.string("Revoke")} </button>
  </div>
</div>
```

#### Tour Detail View (New)

**Route:** `/portal-admin/tours/{tourId}`

**Content:**
- Tour info (title, status, cover image)
- Table of all recipients who have this tour
- Same row structure as customer detail view
- Bulk actions: Revoke All, Set Expiry for All

---

### 7. Bulk Assignment Compatibility

**File:** `backend/src/api/portal.rs` (existing `admin_bulk_assign_tours` endpoint)

**Updated Behavior:**
```rust
pub async fn admin_bulk_assign_tours(
    pool: &SqlitePool,
    input: BulkAssignToursInput,
    actor: Option<&User>,
) -> Result<BulkAssignResult, AppError> {
    let mut created_count = 0;
    let mut skipped_count = 0;
    
    for customer_id in &input.customer_ids {
        for tour_id in &input.tour_ids {
            // Check if active assignment already exists
            let existing = find_active_assignment(pool, customer_id, tour_id).await?;
            
            match existing {
                Some(assignment) if assignment.status == "revoked" => {
                    // Option 1: Reactivate revoked assignment (create new short code)
                    let new_short_code = generate_unique_short_code(pool).await?;
                    sqlx::query(
                        "UPDATE portal_customer_tour_assignments 
                         SET short_code = ?, status = 'active', revoked_at = NULL, updated_at = ? 
                         WHERE id = ?"
                    )
                    .bind(&new_short_code)
                    .bind(Utc::now())
                    .bind(&assignment.id)
                    .execute(pool)
                    .await?;
                    created_count += 1;
                }
                Some(_) => {
                    // Already active, skip
                    skipped_count += 1;
                }
                None => {
                    // Create new assignment
                    let short_code = generate_unique_short_code(pool).await?;
                    sqlx::query(
                        "INSERT INTO portal_customer_tour_assignments 
                         (customer_id, tour_id, short_code, status, created_at, updated_at) 
                         VALUES (?, ?, ?, 'active', ?, ?)"
                    )
                    .bind(customer_id)
                    .bind(tour_id)
                    .bind(&short_code)
                    .bind(Utc::now())
                    .bind(Utc::now())
                    .execute(pool)
                    .await?;
                    created_count += 1;
                }
            }
        }
    }
    
    Ok(BulkAssignResult { created_count, skipped_count })
}
```

---

## Migration Strategy (Clean Slate)

**Since you're OK with a clean slate:**

1. **Delete all existing data:**
   ```sql
   DELETE FROM portal_customer_tour_assignments;
   DELETE FROM portal_access_links;
   DELETE FROM portal_customers;
   -- Optionally: DELETE FROM portal_library_tours; (or keep tours)
   ```

2. **Run schema migration:**
   ```sql
   -- Run ALTER TABLE statements from Schema section
   ```

3. **Recreate recipients and tours:**
   - Use admin UI to create recipients
   - Upload tours via portal UI
   - Assign tours to recipients (generates short codes automatically)

**No backward compatibility needed.**

---

## Verification Checklist

### Backend
- [ ] Schema migration runs successfully
- [ ] Short code generation creates unique 7-char codes
- [ ] Access precedence logic works (test all 5 gates)
- [ ] Expiry override works (NULL = inherit, Some = use override)
- [ ] Revocation works (individual link, not customer-wide)
- [ ] Open counters increment on link access
- [ ] GeoIP code exists but is disabled by default (GEOIP_ENABLED=false)
- [ ] All new API endpoints return correct responses

### Frontend
- [ ] Customer detail view shows tour assignments table
- [ ] Copy Link button copies correct URL (`https://www.robust-vtb.com/u/{slug}/{shortCode}`)
- [ ] Set Expiry modal works (set override, clear override)
- [ ] Revoke Link modal works (with optional reason)
- [ ] Reactivate Link works for revoked assignments
- [ ] Tour detail view shows recipient list (if implemented)
- [ ] Bulk assignment creates/updates assignments correctly

### Integration
- [ ] Direct link `/u/{slug}/{shortCode}` resolves correctly
- [ ] Expired link redirects to expired message
- [ ] Revoked link redirects to revoked message
- [ ] Inactive recipient blocks all links
- [ ] Open counters increment (check database after access)
- [ ] GeoIP fields remain NULL when disabled (GEOIP_ENABLED=false)

---

## Out of Scope (Deferred)

- [ ] Full analytics event table (per-event tracking)
- [ ] Analytics dashboard with charts
- [ ] Multiple link codes per recipient-tour pair
- [ ] User agent/referrer/session tracking
- [ ] GeoIP activation (code exists, but not enabled by default)
- [ ] QR code generation
- [ ] SMS/WhatsApp sharing optimization

---

## Deployment Notes

**IMPORTANT: This task does NOT include VPS deployment.**

After completing all code changes and local testing:

1. **Commit all changes** with a clear commit message
2. **DO NOT run `update-portal.sh`** as part of this task
3. **Document any manual steps** needed for deployment (e.g., running SQL migration)
4. **Create a follow-up task** for VPS deployment and testing if needed

**Deployment will be handled separately by the developer.**

---

## Estimated Effort

| Component | Hours | Notes |
|-----------|-------|-------|
| Database Schema | 2h | ALTER TABLE, indexes |
| Backend Models | 3h | New structs, input types |
| Backend API | 8h | 6 new endpoints, modify access logic |
| Short Code Logic | 2h | Generation, collision handling |
| GeoIP Service | 3h | MaxMind integration (disabled by default) |
| Frontend Admin UI | 12h | Customer detail view, modals, tour view |
| Bulk Assignment | 3h | Update existing endpoint |
| Testing | 6h | All access scenarios, UI testing |
| **Total** | **~39h** | ~5 working days |

---

## Success Criteria

1. ✅ Can create recipient-tour links with unique short codes
2. ✅ Can revoke individual links without affecting other tours for same recipient
3. ✅ Can set per-link expiry override (or clear to inherit from recipient)
4. ✅ Direct links work: `/u/{slug}/{shortCode}`
5. ✅ Access control respects all 5 gates (recipient active, recipient expiry, link status, link expiry, tour status)
6. ✅ Open counters increment on link access
7. ✅ GeoIP code exists but is disabled by default
8. ✅ Admin UI shows all link info and actions
9. ✅ Bulk assignment compatible with new model
10. ✅ Clean migration (no backward compatibility needed)

---

## Related Tasks

- T1877: Portal HTTPS and VPS Hardening (COMPLETED)
- T1881: VPS Security Hardening (PENDING)
- [Future]: Analytics Dashboard for Recipient-Tour Links (TBD)

---

## Notes for Developer

- **Start with backend schema** - get the data model right first
- **Test access logic thoroughly** - this is the core of the feature
- **GeoIP is optional** - make sure it's truly disabled by default
- **Keep URLs simple** - `/u/{slug}/{shortCode}` is good enough for now
- **Don't over-engineer analytics** - counters are sufficient for Phase 1
- **Commit frequently** - this is a foundational change, keep history clean
