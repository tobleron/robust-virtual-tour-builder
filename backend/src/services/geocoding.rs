/* backend/src/services/geocoding.rs - Facade for Geocoding Service */
// @efficiency-role: infra-adapter

use crate::metrics::{GEOCODING_CACHE_HITS_TOTAL, GEOCODING_CACHE_MISSES_TOTAL};
use crate::models::{CacheStats, CachedGeocode, GeocodeKey};
use serde_json::json;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub const MAX_CACHE_SIZE: usize = 5000;

pub fn round_coords(lat: f64, lon: f64) -> GeocodeKey {
    // Round to 4 decimal places (~11 meter precision)
    let lat_rounded = (lat * 10000.0).round() as i32;
    let lon_rounded = (lon * 10000.0).round() as i32;
    (lat_rounded, lon_rounded)
}

pub fn get_current_timestamp() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::SystemTime::UNIX_EPOCH)
        .unwrap_or(std::time::Duration::from_secs(0))
        .as_secs()
}

fn get_cache_file_path() -> String {
    std::env::var("GEOCODING_CACHE_FILE").unwrap_or_else(|_| "../cache/geocoding.json".to_string())
}

fn format_address_from_json(json: &serde_json::Value) -> Option<String> {
    let address_obj = json.get("address")?;
    let mut parts = Vec::new();

    let push_if_present = |parts: &mut Vec<String>, key: &str| {
        if let Some(val) = address_obj.get(key).and_then(|v| v.as_str()) {
            if !val.is_empty() {
                parts.push(val.to_string());
            }
        }
    };

    push_if_present(&mut parts, "road");

    // Suburb/Neighbourhood
    let suburb = address_obj
        .get("suburb")
        .or_else(|| address_obj.get("neighbourhood"))
        .and_then(|v| v.as_str());
    if let Some(s) = suburb {
        if !s.is_empty() {
            parts.push(s.to_string());
        }
    }

    // City/Town/Village
    let city = address_obj
        .get("city")
        .or_else(|| address_obj.get("town"))
        .or_else(|| address_obj.get("village"))
        .and_then(|v| v.as_str());
    if let Some(c) = city {
        if !c.is_empty() {
            parts.push(c.to_string());
        }
    }

    // State/Province
    let state = address_obj
        .get("state")
        .or_else(|| address_obj.get("province"))
        .and_then(|v| v.as_str());
    if let Some(s) = state {
        if !s.is_empty() {
            parts.push(s.to_string());
        }
    }

    push_if_present(&mut parts, "country");

    if !parts.is_empty() {
        Some(parts.join(", "))
    } else {
        None
    }
}

pub async fn call_osm_nominatim(lat: f64, lon: f64) -> Result<String, String> {
    let url = format!(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat={}&lon={}&zoom=18&addressdetails=1&accept-language=en",
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
    if let Some(formatted) = format_address_from_json(&json) {
        return Ok(formatted);
    }

    // Fallback to display_name
    json.get("display_name")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .ok_or_else(|| "No address found in response".to_string())
}

pub async fn evict_lru_entry(
    cache: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>>,
    stats: Arc<RwLock<crate::models::CacheStats>>,
) {
    let mut cache = cache.write().await;

    // Find oldest entry by last_accessed
    if let Some((&key, _)) = cache.iter().min_by_key(|(_, v)| v.last_accessed) {
        cache.remove(&key);
        let mut stats = stats.write().await;
        stats.evictions += 1;
        tracing::debug!(module = "Geocoder", "LRU_EVICTION");
    }
}

lazy_static::lazy_static! {
    static ref GEOCODE_CACHE: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>> =
        Arc::new(RwLock::new(HashMap::new()));

    static ref CACHE_STATS: Arc<RwLock<CacheStats>> =
        Arc::new(RwLock::new(CacheStats::default()));
}

pub struct GeocoderInfo {
    pub stats: CacheStats,
    pub cache_size: usize,
}

pub async fn get_info() -> GeocoderInfo {
    let cache = GEOCODE_CACHE.read().await;
    let stats = CACHE_STATS.read().await;
    GeocoderInfo {
        stats: stats.clone(),
        cache_size: cache.len(),
    }
}

pub async fn save_cache_to_disk() -> Result<(), String> {
    let cache = GEOCODE_CACHE.read().await;
    let mut stats = CACHE_STATS.write().await;

    let cache_file = get_cache_file_path();

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
    tracing::info!(module = "Geocoder", entries = cache.len(), file = %cache_file, "CACHE_SAVED_TO_DISK");
    Ok(())
}

pub async fn load_cache_from_disk() -> std::io::Result<()> {
    let cache_file = get_cache_file_path();

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
            Ok(())
        }
    }
}

pub async fn clear_cache() {
    let mut cache = GEOCODE_CACHE.write().await;
    cache.clear();
    let mut stats = CACHE_STATS.write().await;
    *stats = CacheStats::default();
    tracing::info!(module = "Geocoder", "CACHE_CLEARED");
}

pub async fn reverse_geocode(lat: f64, lon: f64) -> Result<String, String> {
    tracing::info!(lat = lat, lon = lon, "REVERSE_GEOCODE_COORD_RECEIVED");
    let key = round_coords(lat, lon);
    let current_time = get_current_timestamp();

    {
        let mut cache = GEOCODE_CACHE.write().await;
        if let Some(entry) = cache.get_mut(&key) {
            entry.last_accessed = current_time;
            entry.access_count += 1;
            let mut stats = CACHE_STATS.write().await;
            stats.hits += 1;
            GEOCODING_CACHE_HITS_TOTAL.inc();
            return Ok(entry.address.clone());
        }
        let mut stats = CACHE_STATS.write().await;
        stats.misses += 1;
        GEOCODING_CACHE_MISSES_TOTAL.inc();
    }

    match call_osm_nominatim(lat, lon).await {
        Ok(address) => {
            let cache_len = {
                let cache = GEOCODE_CACHE.read().await;
                cache.len()
            };

            if cache_len >= MAX_CACHE_SIZE {
                evict_lru_entry(GEOCODE_CACHE.clone(), CACHE_STATS.clone()).await;
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
            tracing::info!(address = %address, "REVERSE_GEOCODE_RESOLVED");
            Ok(address)
        }
        Err(e) => Err(e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_geocoder_suite_sequential() {
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
        let result = reverse_geocode(lat, lon)
            .await
            .expect("Reverse geocode failed");
        assert_eq!(result, address);
        let info = get_info().await;
        assert_eq!(info.stats.hits, 1);
        let cache = GEOCODE_CACHE.read().await;
        let entry = cache.get(&key).expect("Cache entry missing");
        assert_eq!(entry.access_count, 2);
    }

    async fn test_lru_eviction_internal() {
        clear_cache().await;
        {
            let mut cache = GEOCODE_CACHE.write().await;
            for i in 0..MAX_CACHE_SIZE {
                let key = (i as i32, 0);
                cache.insert(
                    key,
                    CachedGeocode {
                        address: format!("Address {}", i),
                        last_accessed: i as u64,
                        access_count: 1,
                    },
                );
            }
        }
        evict_lru_entry(GEOCODE_CACHE.clone(), CACHE_STATS.clone()).await;
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
