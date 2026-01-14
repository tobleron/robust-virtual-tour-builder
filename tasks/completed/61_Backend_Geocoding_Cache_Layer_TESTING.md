# Manual Testing Guide: Task 61 - Geocoding Cache Persistence

**Purpose:** Verify that the geocoding cache persists to disk, loads on startup, tracks statistics, and implements LRU eviction correctly.

---

## Prerequisites

1. **Start the backend server:**
   ```bash
   cd backend
   cargo run
   ```

2. **Verify logs directory exists:**
   ```bash
   ls -la ../logs/
   ```

---

## Test 1: Cache Persistence Across Restarts

### Steps:

1. **Make a geocoding request:**
   ```bash
   curl -X POST http://localhost:8080/reverse-geocode \
     -H "Content-Type: application/json" \
     -d '{"lat": 40.7128, "lon": -74.0060}'
   ```
   
   **Expected:** Returns address for New York City

2. **Check cache file created:**
   ```bash
   cat ../logs/geocode_cache.json | jq
   ```
   
   **Expected:** 
   - File exists
   - Contains cache entry for coordinates
   - Has `saved_at` timestamp

3. **Restart backend:**
   ```bash
   # Stop backend (Ctrl+C)
   cargo run
   ```

4. **Check startup logs:**
   ```bash
   # Should see: "CACHE_LOADED_FROM_DISK" with entry count
   ```

5. **Repeat same request:**
   ```bash
   curl -X POST http://localhost:8080/reverse-geocode \
     -H "Content-Type: application/json" \
     -d '{"lat": 40.7128, "lon": -74.0060}'
   ```
   
   **Expected:** 
   - Instant response (no API call)
   - Logs show "CACHE_HIT"

✅ **Pass Criteria:** Cache persists across restart, no duplicate API calls

---

## Test 2: Statistics Endpoint

### Steps:

1. **View initial stats:**
   ```bash
   curl http://localhost:8080/geocode-stats | jq
   ```
   
   **Expected:**
   ```json
   {
     "cacheSize": 1,
     "maxCacheSize": 5000,
     "hitRate": 50.0,
     "totalRequests": 2,
     "hits": 1,
     "misses": 1,
     "evictions": 0,
     "lastSave": "2026-01-14T13:00:45Z"
   }
   ```

2. **Make duplicate requests:**
   ```bash
   for i in {1..5}; do
     curl -X POST http://localhost:8080/reverse-geocode \
       -H "Content-Type: application/json" \
       -d '{"lat": 40.7128, "lon": -74.0060}'
   done
   ```

3. **Check updated stats:**
   ```bash
   curl http://localhost:8080/geocode-stats | jq
   ```
   
   **Expected:**
   - `hits` increased by 5
   - `hitRate` increased (should be ~85%)
   - `cacheSize` still 1 (same coordinates)

✅ **Pass Criteria:** Hit rate increases with duplicate requests

---

## Test 3: Access Count Tracking

### Steps:

1. **Check backend logs for access count:**
   ```bash
   # Look for log lines like:
   # CACHE_HIT access_count=3
   ```

2. **Inspect cache file:**
   ```bash
   cat ../logs/geocode_cache.json | jq '.cache'
   ```
   
   **Expected:** Entry shows `access_count` > 1

✅ **Pass Criteria:** Access count increments on each hit

---

## Test 4: LRU Eviction (Stress Test)

### Note: This test requires generating 5000+ unique coordinates

### Steps:

1. **Create test script:**
   ```bash
   # test_lru.sh
   for lat in $(seq 40.0 0.01 90.0); do
     curl -s -X POST http://localhost:8080/reverse-geocode \
       -H "Content-Type: application/json" \
       -d "{\"lat\": $lat, \"lon\": -74.0060}" &gt; /dev/null
   done
   ```

2. **Run test:**
   ```bash
   bash test_lru.sh
   ```

3. **Check stats for evictions:**
   ```bash
   curl http://localhost:8080/geocode-stats | jq '.evictions'
   ```
   
   **Expected:** `evictions` &gt; 0 when cache size exceeds 5000

4. **Check cache size:**
   ```bash
   curl http://localhost:8080/geocode-stats | jq '.cacheSize'
   ```
   
   **Expected:** Stays at or below 5000

✅ **Pass Criteria:** Cache evicts oldest entries when full

---

## Test 5: Cache Clearing

### Steps:

1. **Clear cache:**
   ```bash
   curl -X DELETE http://localhost:8080/geocode-cache | jq
   ```
   
   **Expected:**
   ```json
   {
     "success": true,
     "message": "Cache cleared"
   }
   ```

2. **Verify stats reset:**
   ```bash
   curl http://localhost:8080/geocode-stats | jq
   ```
   
   **Expected:**
   - `cacheSize`: 0
   - `hits`: 0
   - `misses`: 0
   - `evictions`: 0

3. **Check cache file:**
   ```bash
   cat ../logs/geocode_cache.json | jq '.cache'
   ```
   
   **Expected:** Empty object `{}`

✅ **Pass Criteria:** All cache data and stats cleared

---

## Test 6: Debounced Saves

### Steps:

1. **Make rapid requests:**
   ```bash
   for i in {1..10}; do
     curl -s -X POST http://localhost:8080/reverse-geocode \
       -H "Content-Type: application/json" \
       -d "{\"lat\": 40.$i, \"lon\": -74.0060}" &gt; /dev/null
     sleep 0.5
   done
   ```

2. **Check backend logs:**
   ```bash
   # Look for "CACHE_SAVED_TO_DISK" messages
   # Should appear FEWER times than requests (debounced)
   ```

3. **Wait 6 seconds, then check file modified time:**
   ```bash
   ls -la ../logs/geocode_cache.json
   ```
   
   **Expected:** File modified recently (within 6 seconds)

✅ **Pass Criteria:** Saves are debounced, not on every request

---

## Test 7: Error Handling (Corrupted Cache File)

### Steps:

1. **Stop backend**

2. **Corrupt cache file:**
   ```bash
   echo "invalid json" &gt; ../logs/geocode_cache.json
   ```

3. **Start backend:**
   ```bash
   cargo run
   ```

4. **Check logs:**
   ```bash
   # Should see warning: "Failed to load cache"
   # Backend should start successfully
   ```

5. **Verify cache works:**
   ```bash
   curl -X POST http://localhost:8080/reverse-geocode \
     -H "Content-Type: application/json" \
     -d '{"lat": 40.7128, "lon": -74.0060}'
   ```
   
   **Expected:** Works fine (started with fresh cache)

✅ **Pass Criteria:** Gracefully handles corrupted cache, doesn't crash

---

## Quick Verification Checklist

- [ ] Cache file created on first request
- [ ] Cache persists across backend restart
- [ ] Statistics endpoint returns accurate data
- [ ] Hit rate increases with duplicate requests
- [ ] Access count increments correctly
- [ ] LRU eviction works when cache is full
- [ ] Manual cache clearing works
- [ ] Debounced saves (not on every request)
- [ ] Graceful handling of missing/corrupted cache file
- [ ] No errors in backend logs during normal operation

---

## Expected Log Messages

**On Startup (with existing cache):**
```
CACHE_LOADED_FROM_DISK entries=27
```

**On Cache Hit:**
```
CACHE_HIT access_count=5
```

**On Cache Miss:**
```
CACHE_MISS - calling OSM API
REVERSE_GEOCODE_COMPLETE
```

**On Cache Save:**
```
CACHE_SAVED_TO_DISK entries=28
```

**On LRU Eviction:**
```
LRU_EVICTION
```

**On Cache Clear:**
```
CACHE_CLEARED entries_cleared=150
```

---

## Performance Benchmarks

**Expected Response Times:**
- **Cache Hit:** &lt; 5ms
- **Cache Miss (with API call):** 100-500ms
- **Statistics Endpoint:** &lt; 10ms
- **Cache Clear:** &lt; 20ms

**Expected Hit Rate (after warm-up):**
- For real-world usage patterns: **80-95%**

---

## Troubleshooting

### Cache file not created
- Check `../logs/` directory exists
- Check file permissions
- Look for I/O errors in logs

### Cache not loading on restart
- Check cache file is valid JSON
- Verify file path is correct
- Check backend logs for warnings

### Low hit rate
- Verify coordinates are being rounded correctly
- Check if requests use slightly different coordinates
- Inspect cache file to see what's stored

---

## Success Criteria Summary

All tests pass → **Task 61 fully verified** ✅

If any tests fail → Investigate logs and review implementation
