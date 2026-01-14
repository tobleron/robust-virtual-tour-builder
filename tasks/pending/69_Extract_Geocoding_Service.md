# Task 69: Backend Service Extraction: Geocoding and Persistence

**Status:** Pending  
**Priority:** MEDIUM  
**Category:** Backend Refactoring  
**Estimated Effort:** 1.5 hours

---

## Objective

Extract the geocoding logic, OSM Nominatim integration, and the LRU cache management into a dedicated `GeocodeService`.

---

## Context

**Current State:**
The geocoding system uses `lazy_static` for the cache and stats in `handlers.rs`. It also handles its own disk persistence and LRU eviction logic.

**Why This Matters:**
- **Isolation:** Geocoding is an external dependency (OSM). Isolating it makes it easier to swap providers or mock for tests.
- **State Management:** The cache is global state. Moving it to a service makes the stateful nature of this component explicit.

---

## Requirements

### Technical Requirements
1. Create `backend/src/services/geocoding.rs`.
2. Move `GEOCODE_CACHE` and `CACHE_STATS` globals.
3. Move all OSM networking logic (using `reqwest`).
4. Move disk persistence logic (`save_cache_to_disk`, `load_cache_from_disk`).

---

## Implementation Steps

### Step 1: Create Geocode Service
- Create `backend/src/services/geocoding.rs`.

### Step 2: Extract Logic
Move from `handlers.rs`:
- `round_coords`
- `call_osm_nominatim`
- `save_cache_to_disk`
- `load_cache_from_disk`
- `evict_lru_entry`

### Step 3: Refactor Handlers
Update handlers to use the service:
- `reverse_geocode`
- `geocode_stats`
- `clear_geocode_cache`

---

## Testing Criteria

### Correctness
- [ ] Backend compiles.
- [ ] Geocoding still works (check logs for OSM calls vs cache hits).
- [ ] Cache persistence still works across restarts.

---

## Rollback Plan
- Git revert the commit.

---

## Related Files
- `backend/src/handlers.rs`
- `backend/src/services/geocoding.rs` (New)
