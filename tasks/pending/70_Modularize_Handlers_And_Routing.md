# Task 70: Modularize Handlers and Scoped Routing

**Status:** Pending  
**Priority:** LOW  
**Category:** Backend Refactoring  
**Estimated Effort:** 2 hours

---

## Objective

Split the remaining code in `handlers.rs` (which should now only contain HTTP glue) into focused modules and clean up the router in `main.rs` using scopes.

---

## Context

**Current State:**
Even after extracting services (Tasks 67-69), `handlers.rs` contains many HTTP-specific entry points. `main.rs` registration is a long list of flat routes.

**Why This Matters:**
- **Clarity:** It's easier to find the "API entry point" for a feature if handlers are grouped by feature.
- **Middleware:** Scoped routing allows applying middleware (like rate limiting or auth) to specific groups of routes easily.

---

## Requirements

### Technical Requirements
1. Split `handlers.rs` into `backend/src/api/`.
2. Group routes into logical scopes (e.g., `/media`, `/project`, `/logs`).
3. Update `main.rs` to use `web::scope`.

---

## Implementation Steps

### Step 1: Create API Modules
Create `backend/src/api/` with:
- `media.rs`: handlers for image processing, metadata, similarity.
- `project.rs`: handlers for save, load, validate, package.
- `geocoding.rs`: handlers for geocode lookups and stats.
- `telemetry.rs`: handlers for logs and error reporting.

### Step 2: Refactor `main.rs`
Clean up route registration:
```rust
App::new()
    .service(web::scope("/api/v1")
        .service(web::scope("/project")
            .route("/save", web::post().to(api::project::save_project))
            // ...
        )
        .service(web::scope("/media")
            .route("/optimize", web::post().to(api::media::optimize_image))
            // ...
        )
    )
```

**Note:** Be careful not to break the frontend's expected URL paths unless you also update `BackendApi.res`. If you want to avoid frontend changes, don't add path prefixes like `/api/v1` yet, just use scopes for organizational purposes.

---

## Testing Criteria

### Correctness
- [ ] Backend compiles.
- [ ] No broken links in the frontend. All API calls successfully reach the new handler locations.
- [ ] `handlers.rs` can be safely deleted.

---

## Rollback Plan
- Git revert.

---

## Related Files
- `backend/src/handlers.rs` (Delete after move)
- `backend/src/main.rs`
- `backend/src/api/` (New)
