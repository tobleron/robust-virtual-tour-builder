# Task 61: Add Geocoding Cache Persistence Layer

**Status:** Pending  
**Priority:** HIGH  
**Category:** Backend Performance  
**Estimated Effort:** 1-2 hours

---

## Objective

Enhance the geocoding cache (created in Task 59) with disk persistence to survive backend restarts and provide historical geocoding data for analytics.

---

## Context

**Current State (after Task 59):**
- In-memory cache using `HashMap`
- Cache lost on backend restart
- Limited to 1000 entries (simple eviction)

**Enhancement Goals:**
1. Persist cache to disk (JSON file)
2. Load cache on startup
3. Automatic save on new entries (debounced)
4. Implement LRU eviction policy
5. Add cache statistics endpoint

---

## Requirements

### Functional Requirements
1. Save cache to `logs/geocode_cache.json` periodically
2. Load cache on backend startup
3. Implement LRU (Least Recently Used) eviction
4. Add endpoint `GET /geocode-stats` for cache statistics
5. Support manual cache clear via `DELETE /geocode-cache`

### Technical Requirements
1. Use `serde_json` for serialization
2. Debounce writes (max 1 write per 5 seconds)
3. Handle file I/O errors gracefully
4. Track access times for LRU
5. Add metrics: hit rate, cache size, oldest entry age

---

## Implementation Steps

### Step 1: Update Cache Structure in `backend/src/handlers.rs`

Replace the simple cache with an LRU-aware structure:

```rust
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use std::time::SystemTime;
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct CachedGeocode {
    address: String,
    last_accessed: u64, // Unix timestamp
    access_count: u32,
}

type GeocodeKey = (i32, i32);

lazy_static! {
    static ref GEOCODE_CACHE: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>> = 
        Arc::new(RwLock::new(HashMap::new()));
    
    static ref CACHE_STATS: Arc<RwLock<CacheStats>> = 
        Arc::new(RwLock::new(CacheStats::default()));
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct CacheStats {
    hits: u64,
    misses: u64,
    evictions: u64,
    last_save: Option<u64>,
}

const CACHE_FILE_PATH: &str = "../logs/geocode_cache.json";
const MAX_CACHE_SIZE: usize = 5000;
const CACHE_SAVE_INTERVAL_MS: u64 = 5000; // 5 seconds
```

### Step 2: Implement Cache Persistence Functions

```rust
async fn save_cache_to_disk() -> std::io::Result<()> {
    let cache = GEOCODE_CACHE.read().await;
    let stats = CACHE_STATS.read().await;
    
    let data = serde_json::json!({
        "cache": *cache,
        "stats": *stats,
        "saved_at": SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_secs()
    });
    
    let json = serde_json::to_string_pretty(&data)?;
    tokio::fs::write(CACHE_FILE_PATH, json).await?;
    
    tracing::info!(
        module = "Geocoder",
        entries = cache.len(),
        "CACHE_SAVED_TO_DISK"
    );
    
    Ok(())
}

async fn load_cache_from_disk() -> std::io::Result<()> {
    match tokio::fs::read_to_string(CACHE_FILE_PATH).await {
        Ok(contents) => {
            let data: serde_json::Value = serde_json::from_str(&contents)?;
            
            if let Some(cache_obj) = data.get("cache") {
                let loaded_cache: HashMap<GeocodeKey, CachedGeocode> = 
                    serde_json::from_value(cache_obj.clone())?;
                
                let mut cache = GEOCODE_CACHE.write().await;
                *cache = loaded_cache;
                
                tracing::info!(
                    module = "Geocoder",
                    entries = cache.len(),
                    "CACHE_LOADED_FROM_DISK"
                );
            }
            
            if let Some(stats_obj) = data.get("stats") {
                let loaded_stats: CacheStats = 
                    serde_json::from_value(stats_obj.clone())?;
                
                let mut stats = CACHE_STATS.write().await;
                *stats = loaded_stats;
            }
            
            Ok(())
        },
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            tracing::info!(module = "Geocoder", "No cache file found - starting fresh");
            Ok(())
        },
        Err(e) => {
            tracing::warn!(module = "Geocoder", error = %e, "Failed to load cache");
            Ok(()) // Non-fatal - start with empty cache
        }
    }
}

fn get_current_timestamp() -> u64 {
    SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_secs()
}

async fn evict_lru_entry() {
    let mut cache = GEOCODE_CACHE.write().await;
    
    // Find oldest entry by last_accessed
    if let Some((&key, _)) = cache.iter()
        .min_by_key(|(_, v)| v.last_accessed) {
        
        cache.remove(&key);
        
        let mut stats = CACHE_STATS.write().await;
        stats.evictions += 1;
        
        tracing::debug!(module = "Geocoder", "LRU_EVICTION");
    }
}
```

### Step 3: Update Reverse Geocode Handler

Modify the existing handler to track access times and stats:

```rust
#[tracing::instrument(skip(req), name = "reverse_geocode")]
pub async fn reverse_geocode(req: web::Json<GeocodeRequest>) -> Result<HttpResponse, AppError> {
    let lat = req.lat;
    let lon = req.lon;
    let cache_key = round_coords(lat, lon);
    let current_time = get_current_timestamp();
    
    // Check cache first
    {
        let mut cache = GEOCODE_CACHE.write().await;
        if let Some(entry) = cache.get_mut(&cache_key) {
            // Update access time and count
            entry.last_accessed = current_time;
            entry.access_count += 1;
            
            let mut stats = CACHE_STATS.write().await;
            stats.hits += 1;
            
            tracing::info!(
                module = "Geocoder",
                access_count = entry.access_count,
                "CACHE_HIT"
            );
            
            return Ok(HttpResponse::Ok().json(GeocodeResponse {
                address: entry.address.clone(),
            }));
        }
    }
    
    // Cache miss
    {
        let mut stats = CACHE_STATS.write().await;
        stats.misses += 1;
    }
    
    tracing::debug!(module = "Geocoder", "CACHE_MISS");
    
    // Call OSM API (existing code)
    let address = web::block(move || -> Result<String, String> {
        // ... existing call_osm_nominatim logic ...
    }).await.map_err(|e| AppError::InternalError(e.to_string()))??;
    
    // Store in cache with timestamp
    {
        let mut cache = GEOCODE_CACHE.write().await;
        
        // Evict if at capacity
        if cache.len() >= MAX_CACHE_SIZE {
            evict_lru_entry().await;
        }
        
        cache.insert(cache_key, CachedGeocode {
            address: address.clone(),
            last_accessed: current_time,
            access_count: 1,
        });
    }
    
    // Trigger async save (debounced)
    tokio::spawn(async move {
        tokio::time::sleep(tokio::time::Duration::from_millis(CACHE_SAVE_INTERVAL_MS)).await;
        let _ = save_cache_to_disk().await;
    });
    
    Ok(HttpResponse::Ok().json(GeocodeResponse { address }))
}
```

### Step 4: Add Cache Statistics Endpoint

```rust
#[derive(Serialize)]
struct GeocodeStatsResponse {
    cache_size: usize,
    max_cache_size: usize,
    hit_rate: f64,
    total_requests: u64,
    hits: u64,
    misses: u64,
    evictions: u64,
    last_save: Option<String>,
}

#[tracing::instrument(name = "geocode_stats")]
pub async fn geocode_stats() -> impl actix_web::Responder {
    let cache = GEOCODE_CACHE.read().await;
    let stats = CACHE_STATS.read().await;
    
    let total_requests = stats.hits + stats.misses;
    let hit_rate = if total_requests > 0 {
        (stats.hits as f64 / total_requests as f64) * 100.0
    } else {
        0.0
    };
    
    let last_save_time = stats.last_save.map(|ts| {
        chrono::DateTime::<chrono::Utc>::from_timestamp(ts as i64, 0)
            .map(|dt| dt.to_rfc3339())
            .unwrap_or_else(|| "Unknown".to_string())
    });
    
    HttpResponse::Ok().json(GeocodeStatsResponse {
        cache_size: cache.len(),
        max_cache_size: MAX_CACHE_SIZE,
        hit_rate,
        total_requests,
        hits: stats.hits,
        misses: stats.misses,
        evictions: stats.evictions,
        last_save: last_save_time,
    })
}
```

### Step 5: Add Cache Clear Endpoint

```rust
#[tracing::instrument(name = "clear_geocode_cache")]
pub async fn clear_geocode_cache() -> impl actix_web::Responder {
    {
        let mut cache = GEOCODE_CACHE.write().await;
        let size = cache.len();
        cache.clear();
        
        tracing::info!(
            module = "Geocoder",
            entries_cleared = size,
            "CACHE_CLEARED"
        );
    }
    
    // Reset stats
    {
        let mut stats = CACHE_STATS.write().await;
        *stats = CacheStats::default();
    }
    
    // Save empty cache
    let _ = save_cache_to_disk().await;
    
    HttpResponse::Ok().json(serde_json::json!({
        "success": true,
        "message": "Cache cleared"
    }))
}
```

### Step 6: Register Routes in `backend/src/main.rs`

Add to route configuration:
```rust
.route("/geocode-stats", web::get().to(handlers::geocode_stats))
.route("/geocode-cache", web::delete().to(handlers::clear_geocode_cache))
```

### Step 7: Initialize Cache on Startup

In `main.rs`, add after logger initialization:
```rust
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // ... existing logger setup ...
    
    // Load geocoding cache
    if let Err(e) = handlers::load_cache_from_disk().await {
        tracing::warn!("Failed to load geocoding cache: {}", e);
    }
    
    // ... rest of server setup ...
}
```

---

## Testing Criteria

### Unit Tests
1. ✅ Test LRU eviction (fill cache to max, verify oldest removed)
2. ✅ Test save/load cycle (save cache, restart, verify loaded)
3. ✅ Test access time updates
4. ✅ Test statistics calculation

### Integration Tests
1. ✅ Make 10 geocoding requests
2. ✅ Check `/geocode-stats` shows 100% hit rate after duplicates
3. ✅ Restart backend, verify cache persists
4. ✅ Call `DELETE /geocode-cache`, verify stats reset

### Manual Testing
1. Generate 100+ geocoding requests
2. Check `logs/geocode_cache.json` file created
3. Restart backend, verify cache loaded
4. View `/geocode-stats` in browser

---

## Expected Impact

**Performance:**
- ✅ Cache survives backend restarts (no cold start penalty)
- ✅ 5000 entry capacity (10x increase)
- ✅ LRU eviction keeps most-used entries

**Observability:**
- ✅ Hit rate metrics for monitoring
- ✅ Eviction stats show cache pressure
- ✅ Historical data in cache file

**Reliability:**
- ✅ Degrades gracefully on I/O errors
- ✅ Manual cache clear for troubleshooting

---

## Dependencies

**Requires:**
- Task 59 (Backend Reverse Geocoding Endpoint) - MUST be completed first

**Rust Crates:**
- `chrono` (for timestamp formatting) - add to Cargo.toml if not present

---

## Rollback Plan

If issues arise:
1. Remove cache persistence code
2. Revert to in-memory-only cache from Task 59
3. Delete `logs/geocode_cache.json`

---

## Related Files

- `backend/src/handlers.rs` (update cache logic)
- `backend/src/main.rs` (register routes, load cache)
- `backend/Cargo.toml` (add chrono if needed)
- `logs/geocode_cache.json` (created at runtime)

---

## Success Metrics

- ✅ Cache persists across backend restarts
- ✅ Hit rate > 80% after warm-up period
- ✅ No I/O errors in logs
- ✅ `/geocode-stats` shows accurate metrics
- ✅ LRU eviction working (evictions counter increases when cache full)
