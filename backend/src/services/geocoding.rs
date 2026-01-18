use crate::metrics::{GEOCODING_CACHE_HITS_TOTAL, GEOCODING_CACHE_MISSES_TOTAL};
use crate::models::{CacheStats, CachedGeocode, GeocodeKey};
use serde_json::json;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

lazy_static::lazy_static! {
    static ref GEOCODE_CACHE: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>> =
        Arc::new(RwLock::new(HashMap::new()));

    static ref CACHE_STATS: Arc<RwLock<CacheStats>> =
        Arc::new(RwLock::new(CacheStats::default()));
}

pub const MAX_CACHE_SIZE: usize = 5000;

pub struct GeocoderInfo {
    pub stats: CacheStats,
    pub cache_size: usize,
}

/// Retrieves the current status and statistics of the geocoder service.
///
/// # Returns
/// A `GeocoderInfo` struct containing cache stats and current size.
pub async fn get_info() -> GeocoderInfo {
    let stats = CACHE_STATS.read().await;
    let cache = GEOCODE_CACHE.read().await;
    GeocoderInfo {
        stats: stats.clone(),
        cache_size: cache.len(),
    }
}

fn round_coords(lat: f64, lon: f64) -> GeocodeKey {
    // Round to 4 decimal places (~11 meter precision)
    let lat_rounded = (lat * 10000.0).round() as i32;
    let lon_rounded = (lon * 10000.0).round() as i32;
    (lat_rounded, lon_rounded)
}

fn get_current_timestamp() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::SystemTime::UNIX_EPOCH)
        .unwrap_or(std::time::Duration::from_secs(0))
        .as_secs()
}

async fn evict_lru_entry() {
    let mut cache = GEOCODE_CACHE.write().await;

    // Find oldest entry by last_accessed
    if let Some((&key, _)) = cache.iter().min_by_key(|(_, v)| v.last_accessed) {
        cache.remove(&key);

        let mut stats = CACHE_STATS.write().await;
        stats.evictions += 1;

        tracing::debug!(module = "Geocoder", "LRU_EVICTION");
    }
}

/// Persists the geocoding cache and statistics to a JSON file.
///
/// This allows the cache to survive server restarts.
///
/// # Returns
/// `std::io::Result<()>` indicating success or failure.
pub async fn save_cache_to_disk() -> Result<(), String> {
    let cache = GEOCODE_CACHE.read().await;
    let mut stats = CACHE_STATS.write().await;

    let cache_file = std::env::var("GEOCODING_CACHE_FILE")
        .unwrap_or_else(|_| "../cache/geocoding.json".to_string());

    // Ensure cache directory exists
    if let Some(parent) = std::path::Path::new(&cache_file).parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create cache directory: {}", e))?;
    }

    let current_time = get_current_timestamp();

    let data = json!({
        "cache": *cache,
        "stats": *stats,
        "saved_at": current_time
    });

    let json = serde_json::to_string_pretty(&data)
        .map_err(|e| format!("Failed to serialize cache: {}", e))?;

    std::fs::write(&cache_file, json).map_err(|e| format!("Failed to write cache file: {}", e))?;

    stats.last_save = Some(current_time);

    tracing::info!(
        module = "Geocoder",
        entries = cache.len(),
        file = %cache_file,
        "CACHE_SAVED_TO_DISK"
    );

    Ok(())
}

/// Loads the geocoding cache and statistics from the persistence file.
///
/// If the file does not exist, it starts with an empty cache.
///
/// # Returns
/// `std::io::Result<()>` indicating success or failure.
pub async fn load_cache_from_disk() -> std::io::Result<()> {
    let cache_file = std::env::var("GEOCODING_CACHE_FILE")
        .unwrap_or_else(|_| "../cache/geocoding.json".to_string());

    match tokio::fs::read_to_string(&cache_file).await {
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
                let loaded_stats: CacheStats = serde_json::from_value(stats_obj.clone())?;

                let mut stats = CACHE_STATS.write().await;
                *stats = loaded_stats;
            }

            Ok(())
        }
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            tracing::info!(module = "Geocoder", "No cache file found - starting fresh");
            Ok(())
        }
        Err(e) => {
            tracing::warn!(module = "Geocoder", error = %e, "Failed to load cache");
            Ok(()) // Non-fatal - start with empty cache
        }
    }
}

/// Clears all entries from the in-memory geocoding cache and resets statistics.
pub async fn clear_cache() {
    let mut cache = GEOCODE_CACHE.write().await;
    cache.clear();
    let mut stats = CACHE_STATS.write().await;
    *stats = CacheStats::default();
    tracing::info!(module = "Geocoder", "CACHE_CLEARED");
}

/// Resolves latitude and longitude to a human-readable address.
///
/// Implementation details:
/// 1. Rounds coordinates to 4 decimal places for efficient caching.
/// 2. Checks the LRU cache for an existing result.
/// 3. Falls back to the OpenStreetMap Nominatim API if not cached.
/// 4. Updates the cache with the new result and performs eviction if necessary.
///
/// # Arguments
/// * `lat` - Latitude coordinate.
/// * `lon` - Longitude coordinate.
///
/// # Returns
/// A result containing the address string or an error message.
pub async fn reverse_geocode(lat: f64, lon: f64) -> Result<String, String> {
    let key = round_coords(lat, lon);
    let current_time = get_current_timestamp();

    // 1. Check Cache
    {
        let mut cache = GEOCODE_CACHE.write().await;
        if let Some(entry) = cache.get_mut(&key) {
            entry.last_accessed = current_time;
            entry.access_count += 1;

            let mut stats = CACHE_STATS.write().await;
            stats.hits += 1;

            // Metrics
            GEOCODING_CACHE_HITS_TOTAL.inc();

            return Ok(entry.address.clone());
        }

        let mut stats = CACHE_STATS.write().await;
        stats.misses += 1;

        // Metrics
        GEOCODING_CACHE_MISSES_TOTAL.inc();
    } // Drop locks

    // 2. Call OSM
    match call_osm_nominatim(lat, lon).await {
        Ok(address) => {
            // 3. Update Cache
            // We need to check size before inserting, but we can't hold lock while waiting for eviction if eviction is async and takes lock.
            // But evict_lru_entry takes lock.

            let cache_len = {
                let cache = GEOCODE_CACHE.read().await;
                cache.len()
            };

            if cache_len >= MAX_CACHE_SIZE {
                evict_lru_entry().await;
            }

            let mut cache = GEOCODE_CACHE.write().await;
            cache.insert(
                key,
                CachedGeocode {
                    address: address.clone(),
                    last_accessed: current_time,
                    access_count: 1,
                },
            );

            // Trigger save to disk might be handled by caller or periodic task
            Ok(address)
        }
        Err(e) => Err(e),
    }
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

    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("Geocoding request failed: {}", e))?;

    if !response.status().is_success() {
        return Err(format!("OSM API returned status: {}", response.status()));
    }

    let json: serde_json::Value = response
        .json()
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
        if let Some(road) = address_obj.get("road").and_then(|v| v.as_str())
            && !road.is_empty()
        {
            parts.push(road.to_string());
        }

        // Suburb/neighborhood
        let suburb = address_obj
            .get("suburb")
            .or_else(|| address_obj.get("neighbourhood"))
            .and_then(|v| v.as_str());
        if let Some(s) = suburb
            && !s.is_empty()
        {
            parts.push(s.to_string());
        }

        // City/town/village
        let city = address_obj
            .get("city")
            .or_else(|| address_obj.get("town"))
            .or_else(|| address_obj.get("village"))
            .and_then(|v| v.as_str());
        if let Some(c) = city
            && !c.is_empty()
        {
            parts.push(c.to_string());
        }

        // State/province
        let state = address_obj
            .get("state")
            .or_else(|| address_obj.get("province"))
            .and_then(|v| v.as_str());
        if let Some(s) = state
            && !s.is_empty()
        {
            parts.push(s.to_string());
        }

        // Country
        if let Some(country) = address_obj.get("country").and_then(|v| v.as_str())
            && !country.is_empty()
        {
            parts.push(country.to_string());
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

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_geocoder_suite_sequential() {
        // Run all tests that touch global state sequentially
        test_coordinate_rounding_internal();
        test_cache_hit_increments_counter_internal().await;
        test_clear_cache_internal().await;
        test_lru_eviction_internal().await;
    }

    async fn test_cache_hit_increments_counter_internal() {
        clear_cache().await;
        let lat = 37.7749;
        let lon = -122.4194;
        let address = "San Francisco, CA".to_string();

        // Manually insert into cache
        let key = round_coords(lat, lon);
        {
            let mut cache = GEOCODE_CACHE.write().await;
            cache.insert(
                key,
                CachedGeocode {
                    address: address.clone(),
                    last_accessed: get_current_timestamp(),
                    access_count: 1,
                },
            );
        }

        // Access it via reverse_geocode (should hit cache)
        let result = reverse_geocode(lat, lon)
            .await
            .expect("Reverse geocode failed");
        assert_eq!(result, address);

        // Verify stats
        let info = get_info().await;
        assert_eq!(info.stats.hits, 1);

        // Verify access count
        let cache = GEOCODE_CACHE.read().await;
        let entry = cache.get(&key).expect("Cache entry missing");
        assert_eq!(entry.access_count, 2);
    }

    async fn test_lru_eviction_internal() {
        clear_cache().await;

        // Fill cache up to MAX_CACHE_SIZE
        {
            let mut cache = GEOCODE_CACHE.write().await;
            for i in 0..MAX_CACHE_SIZE {
                let key = (i as i32, 0);
                cache.insert(
                    key,
                    CachedGeocode {
                        address: format!("Address {}", i),
                        last_accessed: i as u64, // Oldest first
                        access_count: 1,
                    },
                );
            }
        }

        // Evict one
        evict_lru_entry().await;

        // Verify oldest (i=0) was evicted
        let cache = GEOCODE_CACHE.read().await;
        assert_eq!(cache.len(), MAX_CACHE_SIZE - 1);
        assert!(!cache.contains_key(&(0, 0)));
        assert!(cache.contains_key(&(1, 0)));

        let stats = CACHE_STATS.read().await;
        assert_eq!(stats.evictions, 1);
    }

    fn test_coordinate_rounding_internal() {
        let k1 = round_coords(37.77491, -122.41941);
        let k2 = round_coords(37.77494, -122.41944);
        let k3 = round_coords(37.7750, -122.4200);

        assert_eq!(k1, k2);
        assert_ne!(k1, k3);
    }

    async fn test_clear_cache_internal() {
        // Insert something
        {
            let mut cache = GEOCODE_CACHE.write().await;
            cache.insert(
                (1, 1),
                CachedGeocode {
                    address: "foo".to_string(),
                    last_accessed: 0,
                    access_count: 0,
                },
            );
        }

        clear_cache().await;

        let cache = GEOCODE_CACHE.read().await;
        assert!(cache.is_empty());
        let stats = CACHE_STATS.read().await;
        assert_eq!(stats.hits, 0);
    }
}
