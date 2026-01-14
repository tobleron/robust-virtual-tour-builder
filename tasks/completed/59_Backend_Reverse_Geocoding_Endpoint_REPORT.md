# Report 59: Create Backend Reverse Geocoding Endpoint

**Status:** Pending  
**Priority:** HIGH  
**Category:** Backend Enhancement  
**Estimated Effort:** 2-3 hours

---

## Objective (Completed)

Create a `/reverse-geocode` backend endpoint to proxy OpenStreetMap geocoding requests, improving privacy, enabling rate limiting, and adding caching for better performance.

---

## Context

**Current Implementation:**
- `ExifParser.res` directly calls OpenStreetMap's Nominatim API from the frontend
- Exposes user IP addresses to external service
- No rate limiting or caching
- Slower due to external API latency
- Unreliable (depends on OSM availability)

**Why This Matters:**
1. **Privacy:** User IP addresses are exposed to OpenStreetMap
2. **Performance:** External API calls are slow, especially for repeated coordinates
3. **Reliability:** No caching means repeated lookups for same location
4. **Rate Limiting:** OSM has strict rate limits that could affect multiple users

---

## Requirements

### Functional Requirements
1. Create a new backend endpoint `POST /reverse-geocode`
2. Accept latitude and longitude as input
3. Call OpenStreetMap Nominatim API from backend
4. Return formatted address string
5. Implement in-memory caching layer
6. Add proper error handling for API failures
7. Log all geocoding requests

### Technical Requirements
1. Use Rust's `reqwest` crate for HTTP calls
2. Implement `lazy_static!` for cache initialization
3. Use `Arc<RwLock<HashMap>>` for thread-safe cache
4. Round coordinates to 4 decimal places for cache keys (~11m precision)
5. Follow existing error handling patterns (AppError)
6. Add tracing instrumentation

---

## Implementation Details

### Step 1: Add Dependencies to `backend/Cargo.toml`
```toml
[dependencies]
reqwest = { version = "0.11", features = ["json"] }
lazy_static = "1.4"
```

### Step 2: Create Geocoding Structs in `backend/src/handlers.rs`

Add after the existing metadata structs:

```rust
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GeocodeRequest {
    pub lat: f64,
    pub lon: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GeocodeResponse {
    pub address: String,
}

// Cache key: rounded coordinates for ~11m precision
type GeocodeKey = (i32, i32);

lazy_static! {
    static ref GEOCODE_CACHE: Arc<RwLock<HashMap<GeocodeKey, String>>> = 
        Arc::new(RwLock::new(HashMap::new()));
}
```

### Step 3: Implement Helper Function

```rust
fn round_coords(lat: f64, lon: f64) -> GeocodeKey {
    // Round to 4 decimal places (~11 meter precision)
    let lat_rounded = (lat * 10000.0).round() as i32;
    let lon_rounded = (lon * 10000.0).round() as i32;
    (lat_rounded, lon_rounded)
}

async fn call_osm_nominatim(lat: f64, lon: f64) -> Result<String, String> {
    let url = format!(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat={}&lon={}&zoom=18&addressdetails=1",
        lat, lon
    );
    
    let client = reqwest::Client::builder()
        .user_agent("RobustVirtualTourBuilder/1.0")
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
    
    let response = client.get(&url)
        .send()
        .await
        .map_err(|e| format!("Geocoding request failed: {}", e))?;
    
    if !response.status().is_success() {
        return Err(format!("OSM API returned status: {}", response.status()));
    }
    
    let json: serde_json::Value = response.json()
        .await
        .map_err(|e| format!("Failed to parse OSM response: {}", e))?;
    
    // Check for error in response
    if let Some(error) = json.get("error") {
        return Err(format!("OSM API error: {}", error));
    }
    
    // Extract and format address
    if let Some(address_obj) = json.get("address") {
        let mut parts = Vec::new();
        
        // Extract address components
        if let Some(road) = address_obj.get("road").and_then(|v| v.as_str()) {
            if !road.is_empty() {
                parts.push(road.to_string());
            }
        }
        
        // Suburb/neighborhood
        let suburb = address_obj.get("suburb")
            .or_else(|| address_obj.get("neighbourhood"))
            .and_then(|v| v.as_str());
        if let Some(s) = suburb {
            if !s.is_empty() {
                parts.push(s.to_string());
            }
        }
        
        // City/town/village
        let city = address_obj.get("city")
            .or_else(|| address_obj.get("town"))
            .or_else(|| address_obj.get("village"))
            .and_then(|v| v.as_str());
        if let Some(c) = city {
            if !c.is_empty() {
                parts.push(c.to_string());
            }
        }
        
        // State/province
        let state = address_obj.get("state")
            .or_else(|| address_obj.get("province"))
            .and_then(|v| v.as_str());
        if let Some(s) = state {
            if !s.is_empty() {
                parts.push(s.to_string());
            }
        }
        
        // Country
        if let Some(country) = address_obj.get("country").and_then(|v| v.as_str()) {
            if !country.is_empty() {
                parts.push(country.to_string());
            }
        }
        
        if !parts.is_empty() {
            return Ok(parts.join(", "));
        }
    }
    
    // Fallback to display_name
    json.get("display_name")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .ok_or_else(|| "No address found in response".to_string())
}
```

### Step 4: Implement Endpoint Handler

```rust
#[tracing::instrument(skip(req), name = "reverse_geocode")]
pub async fn reverse_geocode(req: web::Json<GeocodeRequest>) -> Result<HttpResponse, AppError> {
    let lat = req.lat;
    let lon = req.lon;
    
    tracing::info!(
        module = "Geocoder", 
        lat = lat, 
        lon = lon, 
        "REVERSE_GEOCODE_START"
    );
    
    let cache_key = round_coords(lat, lon);
    
    // Check cache first
    {
        let cache = GEOCODE_CACHE.read().await;
        if let Some(cached_address) = cache.get(&cache_key) {
            tracing::info!(
                module = "Geocoder", 
                "CACHE_HIT"
            );
            return Ok(HttpResponse::Ok().json(GeocodeResponse {
                address: cached_address.clone(),
            }));
        }
    }
    
    // Cache miss - call API
    tracing::debug!(module = "Geocoder", "CACHE_MISS - calling OSM API");
    
    let result = web::block(move || -> Result<String, String> {
        call_osm_nominatim(lat, lon).await
    }).await.map_err(|e| AppError::InternalError(e.to_string()))??;
    
    match result {
        Ok(address) => {
            // Store in cache
            {
                let mut cache = GEOCODE_CACHE.write().await;
                cache.insert(cache_key, address.clone());
                
                // Limit cache size to 1000 entries
                if cache.len() > 1000 {
                    // Remove oldest entry (simple eviction)
                    if let Some(first_key) = cache.keys().next().cloned() {
                        cache.remove(&first_key);
                    }
                }
            }
            
            tracing::info!(module = "Geocoder", "REVERSE_GEOCODE_COMPLETE");
            Ok(HttpResponse::Ok().json(GeocodeResponse { address }))
        },
        Err(e) => {
            tracing::error!(module = "Geocoder", error = %e, "REVERSE_GEOCODE_FAILED");
            // Return a graceful fallback message
            Ok(HttpResponse::Ok().json(GeocodeResponse {
                address: format!("[Geocoding unavailable: {}]", e),
            }))
        }
    }
}
```

### Step 5: Register Route in `backend/src/main.rs`

Add to the route configuration:
```rust
.route("/reverse-geocode", web::post().to(handlers::reverse_geocode))
```

### Step 6: Update Frontend `BackendApi.res`

Add new function:
```rescript
let reverseGeocode = async (lat: float, lon: float): Promise.t<string> => {
  try {
    let response = await Fetch.fetch(
      Constants.backendUrl ++ "/reverse-geocode",
      {
        method: "POST",
        headers: Nullable.make(Dict.fromArray([("Content-Type", "application/json")])),
        body: Nullable.make(JSON.stringify(Obj.magic({
          "lat": lat,
          "lon": lon,
        }))),
      },
    )
    
    if !Fetch.ok(response) {
      Promise.resolve("[Geocoding service unavailable]")
    } else {
      let json = await Fetch.json(response)
      let data: {"address": string} = Obj.magic(json)
      Promise.resolve(data["address"])
    }
  } catch {
  | _ => Promise.resolve("[Geocoding failed]")
  }
}
```

### Step 7: Update `ExifParser.res`

Replace the `reverseGeocode` function:
```rescript
/* reverseGeocode - NOW PROXIED THROUGH BACKEND */
let reverseGeocode = (lat, lon) => {
  BackendApi.reverseGeocode(lat, lon)
}
```

Remove the old direct OSM implementation (lines 162-269).

---

## Testing Criteria

### Unit Tests
1. ✅ Test coordinate rounding (various precision levels)
2. ✅ Test cache hit/miss logic
3. ✅ Test address formatting from OSM response

### Integration Tests
1. ✅ Call endpoint with valid coordinates → returns address
2. ✅ Call endpoint twice with same coordinates → second call is cache hit
3. ✅ Call endpoint with invalid coordinates → returns graceful error
4. ✅ Frontend calls `BackendApi.reverseGeocode` → receives formatted address

### Manual Testing
1. Upload images with GPS coordinates
2. Verify "Detected Location" shows formatted address
3. Check backend logs for cache hits
4. Test with airplane mode (should fail gracefully)

---

## Expected Impact

**Performance:**
- ✅ ~100x speedup for cached coordinates (instant vs 500ms+)
- ✅ Reduced external API calls by ~80% (for typical projects with nearby scenes)

**Privacy:**
- ✅ User IP addresses no longer exposed to OpenStreetMap
- ✅ Backend can implement its own rate limiting

**Reliability:**
- ✅ Cached addresses remain available even if OSM is down
- ✅ Graceful degradation with fallback messages

---

## Dependencies

**Rust Crates:**
- `reqwest` (HTTP client)
- `lazy_static` (static cache initialization)
- `tokio` (async runtime) - already present

**Frontend Modules:**
- `BackendApi.res` (add new function)
- `ExifParser.res` (replace direct OSM calls)

---

## Rollback Plan

If issues arise:
1. Revert `ExifParser.res` to direct OSM calls
2. Comment out backend route registration
3. Frontend will function as before

---

## Related Files

- `backend/src/handlers.rs` (add endpoint)
- `backend/src/main.rs` (register route)
- `backend/Cargo.toml` (add dependencies)
- `src/systems/BackendApi.res` (add function)
- `src/systems/ExifParser.res` (update to use backend)

---

## Success Metrics

- ✅ 0 direct calls to OSM from frontend
- ✅ Cache hit rate > 70% for typical projects
- ✅ Geocoding response time < 50ms for cached entries
- ✅ No exposed user IPs in OSM logs
