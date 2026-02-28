// @efficiency-role: domain-logic
use crate::metrics::{GEOCODING_CACHE_HITS_TOTAL, GEOCODING_CACHE_MISSES_TOTAL};

use crate::models::{CacheStats, CachedGeocode, GeocodeKey};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub const MAX_CACHE_SIZE: usize = 5000;

lazy_static::lazy_static! {
    static ref GEOCODE_CACHE: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>> =
        Arc::new(RwLock::new(HashMap::new()));

    static ref CACHE_STATS: Arc<RwLock<CacheStats>> =
        Arc::new(RwLock::new(CacheStats::default()));
}

#[cfg(test)]
lazy_static::lazy_static! {
    pub(crate) static ref GEOCODING_TEST_MUTEX: std::sync::Mutex<()> =
        std::sync::Mutex::new(());
}

pub struct GeocoderInfo {
    pub stats: CacheStats,
    pub cache_size: usize,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct PersistedCacheEntry {
    lat: i32,
    lon: i32,
    address: String,
    last_accessed: u64,
    access_count: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct PersistedCachePayload {
    entries: Vec<PersistedCacheEntry>,
    stats: CacheStats,
    saved_at: u64,
}

fn decode_cache_payload(
    data: &serde_json::Value,
) -> (
    Option<HashMap<GeocodeKey, CachedGeocode>>,
    Option<CacheStats>,
    bool,
) {
    // Preferred format: explicit entries array.
    if let Some(entries_value) = data.get("entries") {
        match serde_json::from_value::<Vec<PersistedCacheEntry>>(entries_value.clone()) {
            Ok(entries) => {
                let mut loaded_cache: HashMap<GeocodeKey, CachedGeocode> = HashMap::new();
                for entry in entries {
                    loaded_cache.insert(
                        (entry.lat, entry.lon),
                        CachedGeocode {
                            address: entry.address,
                            last_accessed: entry.last_accessed,
                            access_count: entry.access_count,
                        },
                    );
                }
                let stats = data.get("stats").and_then(|stats_obj| {
                    serde_json::from_value::<CacheStats>(stats_obj.clone()).ok()
                });
                return (Some(loaded_cache), stats, false);
            }
            Err(_) => return (None, None, true),
        }
    }

    // Backward compatibility for legacy payloads.
    if let Some(cache_obj) = data.get("cache") {
        match serde_json::from_value::<HashMap<GeocodeKey, CachedGeocode>>(cache_obj.clone()) {
            Ok(loaded_cache) => {
                let stats = data.get("stats").and_then(|stats_obj| {
                    serde_json::from_value::<CacheStats>(stats_obj.clone()).ok()
                });
                return (Some(loaded_cache), stats, false);
            }
            Err(_) => return (None, None, true),
        }
    }

    (None, None, false)
}

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

pub async fn evict_lru_entry(
    cache: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>>,
    stats: Arc<RwLock<crate::models::CacheStats>>,
) {
    let removed = {
        let mut cache = cache.write().await;

        // Find oldest entry by last_accessed
        let key_to_remove = cache
            .iter()
            .min_by_key(|(_, v)| v.last_accessed)
            .map(|(&key, _)| key);

        if let Some(key) = key_to_remove {
            cache.remove(&key);
            true
        } else {
            false
        }
    }; // cache lock dropped here

    if removed {
        let mut stats = stats.write().await;
        stats.evictions += 1;
        tracing::debug!(module = "Geocoder", "LRU_EVICTION");
    }
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
        tokio::fs::create_dir_all(parent)
            .await
            .map_err(|e| format!("Failed to create cache directory: {}", e))?;
    }

    let current_time = get_current_timestamp();
    let entries: Vec<PersistedCacheEntry> = cache
        .iter()
        .map(|((lat, lon), value)| PersistedCacheEntry {
            lat: *lat,
            lon: *lon,
            address: value.address.clone(),
            last_accessed: value.last_accessed,
            access_count: value.access_count,
        })
        .collect();

    let data = PersistedCachePayload {
        entries,
        stats: stats.clone(),
        saved_at: current_time,
    };

    let json = serde_json::to_string_pretty(&data)
        .map_err(|e| format!("Failed to serialize cache: {}", e))?;

    tokio::fs::write(&cache_file, json)
        .await
        .map_err(|e| format!("Failed to write cache file: {}", e))?;

    stats.last_save = Some(current_time);
    tracing::info!(module = "Geocoder", entries = cache.len(), file = %cache_file, "CACHE_SAVED_TO_DISK");
    Ok(())
}

pub async fn load_cache_from_disk() -> std::io::Result<()> {
    let cache_file = get_cache_file_path();

    match tokio::fs::read_to_string(&cache_file).await {
        Ok(contents) => {
            let data: serde_json::Value = match serde_json::from_str(&contents) {
                Ok(v) => v,
                Err(e) => {
                    tracing::warn!(module = "Geocoder", error = %e, "Invalid cache JSON; starting fresh");
                    return Ok(());
                }
            };

            let (cache_opt, stats_opt, had_decode_error) = decode_cache_payload(&data);
            if had_decode_error {
                tracing::warn!(module = "Geocoder", "Invalid cache payload; starting fresh");
            }

            if let Some(loaded_cache) = cache_opt {
                let mut cache = GEOCODE_CACHE.write().await;
                let loaded_entries = loaded_cache.len();
                *cache = loaded_cache;
                tracing::info!(
                    module = "Geocoder",
                    entries = loaded_entries,
                    "CACHE_LOADED_FROM_DISK"
                );
            }

            if let Some(loaded_stats) = stats_opt {
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

pub async fn check_cache(key: GeocodeKey) -> Option<String> {
    let mut cache = GEOCODE_CACHE.write().await;
    if let Some(entry) = cache.get_mut(&key) {
        entry.last_accessed = get_current_timestamp();
        entry.access_count += 1;
        let mut stats = CACHE_STATS.write().await;
        stats.hits += 1;
        if let Some(m) = &*GEOCODING_CACHE_HITS_TOTAL {
            m.inc();
        }
        return Some(entry.address.clone());
    }
    let mut stats = CACHE_STATS.write().await;
    stats.misses += 1;
    if let Some(m) = &*GEOCODING_CACHE_MISSES_TOTAL {
        m.inc();
    }
    None
}

pub async fn update_cache(key: GeocodeKey, address: String) {
    let current_time = get_current_timestamp();
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
            address,
            last_accessed: current_time,
            access_count: 1,
        },
    );
}

// For tests
#[allow(dead_code)]
pub async fn manual_insert(
    key: GeocodeKey,
    address: String,
    last_accessed: u64,
    access_count: u32,
) {
    let mut cache = GEOCODE_CACHE.write().await;
    cache.insert(
        key,
        CachedGeocode {
            address,
            last_accessed,
            access_count,
        },
    );
}

#[allow(dead_code)]
pub async fn get_cache_len() -> usize {
    let cache = GEOCODE_CACHE.read().await;
    cache.len()
}

#[allow(dead_code)]
pub async fn cache_contains_key(key: &GeocodeKey) -> bool {
    let cache = GEOCODE_CACHE.read().await;
    cache.contains_key(key)
}

#[allow(dead_code)]
pub async fn get_cache_entry_access_count(key: &GeocodeKey) -> Option<u32> {
    let cache = GEOCODE_CACHE.read().await;
    cache.get(key).map(|e| e.access_count)
}

#[allow(dead_code)]
pub async fn get_evictions_count() -> u64 {
    let stats = CACHE_STATS.read().await;
    stats.evictions
}

#[allow(dead_code)]
pub async fn get_hits_count() -> u64 {
    let stats = CACHE_STATS.read().await;
    stats.hits
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decode_cache_payload_handles_invalid_legacy_cache_shape() {
        let payload = serde_json::json!({
            "cache": {"bad": {"address": "x", "last_accessed": 1, "access_count": 1}},
            "stats": {"hits": 0, "misses": 0, "evictions": 0, "last_save": null}
        });

        let (cache_opt, stats_opt, had_decode_error) = decode_cache_payload(&payload);
        assert!(cache_opt.is_none());
        assert!(stats_opt.is_none());
        assert!(had_decode_error);
    }

    #[test]
    fn decode_cache_payload_reads_entries_format() {
        let payload = serde_json::json!({
            "entries": [{
                "lat": 10,
                "lon": 20,
                "address": "Example",
                "last_accessed": 7,
                "access_count": 3
            }],
            "stats": {"hits": 1, "misses": 2, "evictions": 3, "last_save": 4},
            "saved_at": 123
        });

        let (cache_opt, stats_opt, had_decode_error) = decode_cache_payload(&payload);
        assert!(!had_decode_error);
        let cache = cache_opt.expect("cache should decode");
        assert_eq!(cache.len(), 1);
        let entry = cache.get(&(10, 20)).expect("entry should exist");
        assert_eq!(entry.address, "Example");
        assert_eq!(entry.last_accessed, 7);
        assert_eq!(entry.access_count, 3);

        let stats = stats_opt.expect("stats should decode");
        assert_eq!(stats.hits, 1);
        assert_eq!(stats.misses, 2);
    }
}
