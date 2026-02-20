# Task 1492: Backend Protective Hardening – Save & Load Project Endpoints

## Objective

Strengthen the backend's Save and Load project endpoints against abuse, malformed input, and
resource exhaustion — **without altering any existing functionality or API contracts that the
frontend relies on**.

This task is advisory / analysis-driven. Every recommendation in the Technical Notes section
was derived from a deep review of the current implementation (Feb 2026). Implement the items
marked **[MUST]** in order; the items marked **[SHOULD]** are improvements that can follow.

---

## Context

The current Save / Load stack passes through these layers (bottom-up):

```
SidebarActions.res          → UI button + AbortController wiring
ProjectSave.res             → OperationJournal + progress + file-handle management
ProjectSystem.res           → createSavePackage / loadProjectZip orchestrators
ProjectApi.res              → chunked import, saveProject helpers (chunked = 3 calls: init/chunk/complete)
AuthenticatedClient.res     → fetch with token injection + retry (Retry.requestWithRetry)
--- HTTP boundary ---
middleware/rate_limiter.rs  → per-IP token-bucket (actix-governor) — "write" class for /project/save, /project/import
middleware.rs               → QuotaCheck (bytes-in-flight per IP) + RequestTracker (graceful drain)
auth.rs                     → JWT / dev-token auth; user attached to request extensions
project.rs                  → save_project / load_project / import_project / import_project_{init,chunk,complete,abort}
project_multipart.rs        → raw multipart parsing helpers
project_logic/validation.rs → validate_project_full_sync (parse JSON → generate summary → validate+clean → attach report)
project_logic/zip.rs        → extract_zip_to_project_dir (path-hardened) + create_project_zip_sync
services/project/load.rs    → process_uploaded_project_zip (re-packs normalized ZIP)
services/project/validate.rs→ validate_and_clean_project (deep structural check)
```

**Existing protections that are already good:**
- `sanitize_id` rejects all non-alphanum/hyphen/underscore chars + 64-char length cap.
- `sanitize_filename` rejects traversal (`..`, absolute, null bytes, backslashes).
- `extract_zip_to_project_dir` uses `enclosed_name()` + per-component `sanitize_filename`.
- `validate_path_safe` uses `canonicalize()` to block path-escape after resolution.
- `QuotaCheck` middleware tracks bytes-in-flight per IP.
- `actix-governor` rate limiter is wired to `write` class for `/project/save` and `/project/import`.
- Auth middleware blocks unauthenticated requests on all project endpoints.
- `TempImagesCleanupGuard` / `ZipCleanupGuard` ensure no temp-file leaks on early returns.
- 10-minute timeout on `create_tour_package`.

---

## Gap Analysis — Issues Found

### [MUST-1] No ZIP Bomb / Decompression-Size Guard in `process_uploaded_project_zip`

**File:** `backend/src/services/project/load.rs`

`load_project` writes the uploaded data into a tempfile (bounded by `MAX_UPLOAD_SIZE = 60 MB`
for the compressed bytes), then passes it to `process_uploaded_project_zip`. That function
iterates the ZIP entries and calls `std::io::copy` into the output writer **without tracking
the total decompressed size**. A malicious ZIP with a high compression ratio (e.g. a ZIP bomb)
could exhaust memory or disk before termination.

**Recommendation:**
Add a cumulative decompressed-bytes counter. Abort and return an error if total extracted size
exceeds a configurable limit (e.g. `MAX_DECOMPRESSED_PROJECT_SIZE = 512 MB`).

```rust
// In process_uploaded_project_zip, inside the copy-images loop:
let mut total_decompressed: u64 = 0;
const MAX_DECOMPRESSED: u64 = 512 * 1024 * 1024; // 512 MB

// ... for each file entry:
let written = std::io::copy(&mut file, &mut zip_writer)
    .map_err(|e| e.to_string())?;
total_decompressed += written;
if total_decompressed > MAX_DECOMPRESSED {
    return Err(format!(
        "Decompressed content exceeds maximum allowed size ({} bytes)",
        MAX_DECOMPRESSED
    ));
}
```

The same guard applies to `extract_zip_to_project_dir` in `project_logic/zip.rs`.

---

### [MUST-2] No File-Count / Entry-Count Cap During ZIP Extraction

**Files:** `backend/src/services/project/load.rs`, `backend/src/api/project_logic/zip.rs`

Both ZIP processing paths iterate every entry in the archive. A crafted ZIP with 100 000+
entries could cause O(n) memory growth in `available_files` and block the thread pool.

**Recommendation:**
Add an entry-count cap (e.g. `MAX_ZIP_ENTRIES = 5_000`) checked before the loop body executes.

```rust
const MAX_ZIP_ENTRIES: usize = 5_000;
if archive.len() > MAX_ZIP_ENTRIES {
    return Err(format!("ZIP contains too many entries ({})", archive.len()));
}
```

---

### [MUST-3] `project.json` Size Not Bounded Before `serde_json::from_str` in Load Path

**File:** `backend/src/services/project/load.rs` (line 40-42), `backend/src/api/project_logic/zip.rs` (lines 19-24)

`read_to_string` on `project.json` inside the ZIP is unbounded. A malicious ZIP could embed a
multi-gigabyte `project.json` that is fully read into memory before parsing.

**Recommendation:**
Use `Read::take` to limit the bytes read from the `project.json` entry before calling
`read_to_string`:

```rust
const MAX_PROJECT_JSON_BYTES: u64 = 16 * 1024 * 1024; // 16 MB
let mut limited = json_file.take(MAX_PROJECT_JSON_BYTES + 1);
let mut json_str = String::new();
limited.read_to_string(&mut json_str)
    .map_err(|e| format!("Failed to read project.json: {}", e))?;
if json_str.len() > MAX_PROJECT_JSON_BYTES as usize {
    return Err("project.json exceeds maximum allowed size".to_string());
}
```

---

### [MUST-4] `parse_save_project_multipart`: `project_data` Field Unbounded

**File:** `backend/src/api/project_multipart.rs` → `parse_save_project_multipart`

`read_string_field` accumulates bytes into a `Vec<u8>` for `project_data` without any
per-field size limit. The outer `MAX_UPLOAD_SIZE` check (in `save_multipart_to_tempfile`) does
NOT apply here — the save path uses `parse_save_project_multipart`, not
`save_multipart_to_tempfile`. A large poisoned `project_data` field could cause memory
exhaustion before any validation runs.

**Recommendation:**
Add an explicit `MAX_PROJECT_JSON_BYTES` cap inside `read_string_field` (or create a
`read_limited_string_field` variant) for the `project_data` parse branch.

```rust
const MAX_PROJECT_JSON_BYTES: usize = 16 * 1024 * 1024;

async fn read_limited_string_field(
    field: &mut actix_multipart::Field,
    max_bytes: usize,
) -> Result<String, AppError> {
    let mut bytes = Vec::new();
    while let Some(chunk) = field.try_next().await? {
        bytes.extend_from_slice(&chunk);
        if bytes.len() > max_bytes {
            return Err(AppError::ValidationError(format!(
                "Field exceeds maximum allowed size ({} bytes)",
                max_bytes
            )));
        }
    }
    Ok(String::from_utf8_lossy(&bytes).to_string())
}
```

Apply this to the `"project_data"` branch in `parse_save_project_multipart`.

---

### [MUST-5] No Per-User Concurrent Save/Import Guard (Beyond Global Quota)

**File:** `backend/src/api/project.rs`

The `QuotaCheck` middleware guards concurrency at the **IP / bytes-in-flight** level. However,
a single authenticated user (whose JWT is valid) can fire multiple simultaneous `/api/project/save`
requests with the same `session_id`, potentially causing race conditions in:
- `project_logic::validate_project_full_sync` writing to the same temp path
- `project_logic::create_project_zip_sync` reading from the same session directory

Although the use of unique temp-file UUIDs (`get_temp_path("zip")`) prevents direct file
conflicts, interleaved reads from the session directory during a save can produce an inconsistent
ZIP if a concurrent save also writes new images there.

**Recommendation:**
Add a per-`(user_id, operation)` in-memory lock (a `DashMap<String, Mutex<()>>` keyed on
`format!("{}/{}", user.id, session_id)`) in an `AppData`-shared service. Acquire the lock at
the start of `save_project`, release on completion. Return `HTTP 409 Conflict` if the lock
cannot be acquired immediately.

This is a lightweight addition that does not alter the API contract.

---

### [SHOULD-1] `session_id` Not Validated Against Authenticated User's Storage Scope

**File:** `backend/src/api/project.rs` → `save_project` (lines 134–139)

The `session_id` field from the multipart body is passed to `StorageManager::get_user_project_path`.
`StorageManager` constructs the path as `<storage_root>/<user_id>/<session_id>`. Since
`session_id` goes through `sanitize_id`, path traversal is blocked. However, there is no check
that the resolved path actually **exists** before treating it as the project's storage scope for
reading server-side images. A non-existent `session_id` silently produces `project_path = None`
at line 139, yet no diagnostic log is emitted.

**Recommendation:**
Add a tracing log (not an error) when `session_id` is present but the path does not exist, to
aid future debugging:

```rust
if let Some(p) = &project_path {
    if !p.exists() {
        tracing::warn!(
            module = "ProjectManager",
            user_id = %user.id,
            session_id = ?session_id,
            "Session path does not exist on disk — save will not include server-side images"
        );
    }
}
```

---

### [SHOULD-2] `load_project` Has No Explicit `Content-Type: application/zip` Validation

**File:** `backend/src/api/project.rs` → `load_project` (line 197)

The `save_multipart_to_tempfile` helper streams all multipart fields without checking that the
uploaded file is actually a ZIP (or even a binary with the `PK` magic header). A text file or
HTML file sent as the payload would merely fail later at `zip::ZipArchive::new(file)` with a
generic "Failed to read ZIP" error.

**Recommendation:**
After writing the first ≥ 4 bytes, check the ZIP magic bytes (`PK\x03\x04`) before proceeding
to unbounded streaming. This gives an early, descriptive rejection:

```rust
// After first chunk write:
if bytes_written >= 4 {
    let peek = &first_bytes[..4];
    if peek != b"PK\x03\x04" {
        return Err(AppError::ValidationError(
            "Uploaded file is not a valid ZIP archive".to_string()
        ));
    }
}
```

---

### [SHOULD-3] Chunked Import: No Global Max-Session Cap Per User

**File:** `backend/src/services/project/mod.rs` → `ChunkedProjectImportManager`

A user could initiate many `import_project_init` calls, each creating a session with a future
expiry. Most sessions will expire and be cleaned up, but there is no real-time cap on the number
of **concurrent** active sessions per user. A misbehaving client can pre-allocate arbitrarily
many sessions.

**Recommendation:**
Add a `max_active_sessions_per_user` cap (e.g., `8`) in `ChunkedProjectImportManager::init_session`,
returning a `ValidationError` if exceeded.

---

### [SHOULD-4] `save_project` Returns the Full ZIP in the HTTP Response Body

**File:** `backend/src/api/project.rs` lines 168–184

The current design reads the entire validated+repackaged ZIP file into memory (`tokio::fs::read`)
and returns it as a `200 OK` body. For very large projects this means the backend holds the entire
ZIP in RAM simultaneously during serialization. The temp file is then deleted.

Rather than change the API contract, consider streaming the file using `actix_files::NamedFile`
(as `load_project` already does), which uses efficient sendfile/zero-copy mechanisms:

```rust
// Replace the read + body pattern with:
let named_file = actix_files::NamedFile::from_file(
    std::fs::File::open(&zip_path)?,
    "project.vt.zip"
)?
.set_content_type(mime::APPLICATION_ZIP);
zip_cleanup_guard.keep(); // let actix stream it, then clean up in a post-response hook
Ok(named_file.into_response(&req))
```

Note: cleanup of the temp file must then happen after the response is sent (e.g., via a
`web::block` deferred task or Tokio `spawn`). This is a non-trivial refactor; implement with
care and test that temp files are not leaked.

---

## Acceptance Criteria

- [ ] **[MUST-1]** `process_uploaded_project_zip` and `extract_zip_to_project_dir` both enforce
      a configurable decompressed-bytes limit and return a clean error if exceeded.
- [ ] **[MUST-2]** Both ZIP-processing paths enforce a per-archive entry-count cap before iterating.
- [ ] **[MUST-3]** `project.json` reads inside ZIP archives are bounded by `Read::take`.
- [ ] **[MUST-4]** `parse_save_project_multipart` limits `project_data` field size with
      `read_limited_string_field`.
- [ ] **[MUST-5]** A per-`(user_id, session_id)` serialization lock prevents concurrent Save
      operations for the same project session, returning `409 Conflict` on contention.
- [ ] **[SHOULD-1]** Missing session path emits a `tracing::warn` instead of failing silently.
- [ ] **[SHOULD-2]** `load_project` validates ZIP magic bytes before streaming the full payload.
- [ ] **[SHOULD-3]** `ChunkedProjectImportManager::init_session` enforces a per-user max-session cap.
- [ ] All existing Rust unit tests in `zip.rs`, `utils.rs`, and `upload_quota_tests.rs` pass after changes.
- [ ] No change to frontend API contracts (`ProjectApi.res`, `ProjectSystem.res`).
- [ ] `npm run build` passes after the Rust backend changes.

---

## Technical Notes

- All constants (`MAX_DECOMPRESSED_PROJECT_SIZE`, `MAX_ZIP_ENTRIES`, `MAX_PROJECT_JSON_BYTES`,
  `max_active_sessions_per_user`) SHOULD be sourced from environment variables with safe
  defaults, following the same pattern as `TEMP_DIR` in `api/utils.rs`.
- The in-memory concurrency lock for MUST-5 should use `tokio::sync::Mutex` (not `std::sync::Mutex`)
  to avoid blocking the async executor.
- Do NOT change `MAX_UPLOAD_SIZE` (60 MB) — it is a well-calibrated limit that the frontend
  relies on for chunked-upload threshold decisions.
- Rust linting: zero new `clippy` warnings are permitted. Run `cargo clippy -- -D warnings` before PR.
- The `SHOULD-4` streaming refactor is out of scope for this task unless the team decides
  otherwise; it is noted here for future architectural consideration.

## Files to Modify

| File | Change |
|------|--------|
| `backend/src/services/project/load.rs` | MUST-1, MUST-2, MUST-3 |
| `backend/src/api/project_logic/zip.rs` | MUST-1, MUST-2, MUST-3 |
| `backend/src/api/project_multipart.rs` | MUST-4 |
| `backend/src/api/project.rs` | MUST-5, SHOULD-1, SHOULD-2 |
| `backend/src/services/project/mod.rs` | SHOULD-3 |
