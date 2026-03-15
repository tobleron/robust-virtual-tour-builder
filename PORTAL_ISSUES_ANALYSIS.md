# Portal Issues Investigation & Fixes

## Issue 1: Recipient Gallery Shows "Already Expired"

### Root Cause Analysis

After extensive investigation, the expiry date handling in the backend is **CORRECT**. The issue is likely one of the following:

1. **Accessing gallery without proper session**: The public endpoint (`/api/portal/customers/{slug}/public`) doesn't include tour access information - it only shows customer info.

2. **Session not established**: Users must access the gallery via the access link (e.g., `/u/{slug}/{access_code}`) which creates a session, OR sign in through the session endpoint first.

3. **Frontend routing issue**: The CustomerSurface component checks `gallery.canOpenTours` which comes from the backend's session-based endpoint, not the public endpoint.

### How It Should Work

1. Admin creates customer with expiry date → Access link is created with that expiry
2. User clicks access link (e.g., `http://www.robust-vtb.com/u/ak84/rQLbSbj`) → Session is created
3. Frontend calls `/api/portal/customers/ak84/session` → Returns `canOpenTours: true/false`
4. Frontend calls `/api/portal/customers/ak84/tours` → Returns gallery with `canOpenTours: true/false`
5. If `canOpenTours` is false, show "Access expired" message

### Verification Steps

```bash
# 1. Check the access link expiry (should be in future)
ssh robust-vps "sqlite3 /var/lib/robust-vtb/database.db \"SELECT short_code, datetime(expires_at) FROM portal_access_links WHERE customer_id = (SELECT id FROM portal_customers WHERE slug = 'ak84');\""

# 2. Check server time
ssh robust-vps "curl -s http://127.0.0.1:8080/api/health | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"timestamp\"])'"

# 3. Test session endpoint (requires session cookie from access link)
ssh robust-vps "curl -s 'http://127.0.0.1:8080/api/portal/customers/ak84/session' -H 'Cookie: portal_access_link_id=YOUR_LINK_ID'"
```

### Expected Database Values

For customer "ak84" (Arto Kalishian):
- Access link expiry: `2026-04-21 09:11:00` (April 21, 2026 - IN FUTURE)
- Server time: `2026-03-15 11:35:46` (March 15, 2026 - CURRENT)
- Status: Should be **ACTIVE** (not expired)

### Fix Required

The backend code is correct. The issue is likely in how the gallery is being accessed. Users should:

1. **Use the access link** generated when creating the customer (e.g., `http://www.robust-vtb.com/u/ak84/rQLbSbj`)
2. **OR** ensure the session is properly established before viewing the gallery

---

## Issue 2: Multi-Tour Upload with Progress Bar

### Current State

- Single tour upload works correctly
- Shows "Starting upload..." flash message
- No visual progress bar
- No support for uploading multiple tours simultaneously

### Required Implementation

1. **Upload queue system**: Allow selecting multiple ZIP files
2. **Progress tracking**: Show individual progress for each upload
3. **Upload list UI**: Display list of tours being uploaded with status
4. **Batch completion**: Show summary when all uploads complete

### Implementation Plan

#### Backend Changes
None required - the upload endpoint already handles single files correctly.

#### Frontend Changes

1. **State Management**:
```rescript
type uploadJob = {
  id: string,
  file: File.t,
  title: string,
  status: Pending | Uploading(progress: float) | Completed | Failed(string),
}

let (uploadQueue, setUploadQueue) = React.useState(() => [])
```

2. **UI Components**:
- Multi-file input
- Upload queue list with progress bars
- Batch action buttons

3. **Upload Logic**:
```rescript
let processUploadQueue = async () => {
  for job in uploadQueue {
    setUploadingJobStatus(job.id, Uploading(0.0))
    try {
      let result = await PortalApi.uploadTour(~title=job.title, ~file=job.file)
      setUploadingJobStatus(job.id, Completed)
    } catch {
    | exn => setUploadingJobStatus(job.id, Failed("Upload failed"))
    }
  }
}
```

---

## Recommended Actions

### For Expiry Issue:
1. Test accessing the gallery via the actual access link: `http://www.robust-vtb.com/u/ak84/rQLbSbj`
2. Check browser console for any errors
3. Verify the session is being created properly

### For Multi-Upload:
1. Implement upload queue state management
2. Add multi-file input UI
3. Add progress bar component
4. Implement sequential/parallel upload processing

---

## Technical Notes

### Backend Expiry Logic (CORRECT)

```rust
// backend/src/services/portal.rs:358
let expired = record.expires_at < Utc::now();
// active = !expired && revoked_at.is_none()
// can_open_tours = customer.is_active && active
```

### Frontend Date Conversion (CORRECT)

```rescript
// src/site/PortalApp.res:173
let localDateTimeToIso = value => {
  makeDate(value)->toISOString  // Converts local time to UTC ISO string
}
```

### Database Storage (CORRECT)

```sql
-- Stored as TEXT with timezone
expires_at: "2026-04-21T09:11:00+00:00"
```

All components are working correctly. The issue is in the access flow, not the expiry calculation.
