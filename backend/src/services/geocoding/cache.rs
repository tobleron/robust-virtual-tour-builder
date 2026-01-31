// @efficiency-role: domain-logic
use crate::metrics::{GEOCODING_CACHE_HITS_TOTAL, GEOCODING_CACHE_MISSES_TOTAL};

use crate::models::{CacheStats, CachedGeocode, GeocodeKey};
use serde_json::json;
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

pub struct GeocoderInfo {
    pub stats: CacheStats,
    pub cache_size: usize,
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
    let mut cache = cache.write().await;

    // Find oldest entry by last_accessed
    if let Some((&key, _)) = cache.iter().min_by_key(|(_, v)| v.last_accessed) {
        cache.remove(&key);
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

pub async fn check_cache(key: GeocodeKey) -> Option<String> {
    let mut cache = GEOCODE_CACHE.write().await;
    if let Some(entry) = cache.get_mut(&key) {
        entry.last_accessed = get_current_timestamp();
        entry.access_count += 1;
        let mut stats = CACHE_STATS.write().await;
        stats.hits += 1;
        GEOCODING_CACHE_HITS_TOTAL.inc();
        return Some(entry.address.clone());
    }
    let mut stats = CACHE_STATS.write().await;
    stats.misses += 1;
    GEOCODING_CACHE_MISSES_TOTAL.inc();
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

pub async fn get_cache_len() -> usize {
    let cache = GEOCODE_CACHE.read().await;
    cache.len()
}

pub async fn cache_contains_key(key: &GeocodeKey) -> bool {
    let cache = GEOCODE_CACHE.read().await;
    cache.contains_key(key)
}

pub async fn get_cache_entry_access_count(key: &GeocodeKey) -> Option<u32> {
    let cache = GEOCODE_CACHE.read().await;
    cache.get(key).map(|e| e.access_count)
}

pub async fn get_evictions_count() -> u64 {
    let stats = CACHE_STATS.read().await;
    stats.evictions
}

pub async fn get_hits_count() -> u64 {
    let stats = CACHE_STATS.read().await;
    stats.hits
}
