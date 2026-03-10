// @efficiency-role: domain-logic
#[path = "cache_ops.rs"]
mod cache_ops;
#[path = "cache_persistence.rs"]
mod cache_persistence;

use crate::models::{CacheStats, CachedGeocode, GeocodeKey};
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

#[allow(dead_code)]
fn decode_cache_payload(
    data: &serde_json::Value,
) -> (
    Option<HashMap<GeocodeKey, CachedGeocode>>,
    Option<CacheStats>,
    bool,
) {
    cache_persistence::decode_cache_payload(data)
}

pub fn round_coords(lat: f64, lon: f64) -> GeocodeKey {
    cache_ops::round_coords(lat, lon)
}

#[allow(dead_code)]
pub fn get_current_timestamp() -> u64 {
    cache_ops::get_current_timestamp()
}

#[allow(dead_code)]
fn get_cache_file_path() -> String {
    cache_persistence::get_cache_file_path()
}

#[allow(dead_code)]
pub async fn evict_lru_entry(
    cache: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>>,
    stats: Arc<RwLock<crate::models::CacheStats>>,
) {
    cache_ops::evict_lru_entry(cache, stats).await
}

pub async fn get_info() -> GeocoderInfo {
    cache_ops::get_info().await
}

pub async fn save_cache_to_disk() -> Result<(), String> {
    cache_persistence::save_cache_to_disk().await
}

pub async fn load_cache_from_disk() -> std::io::Result<()> {
    cache_persistence::load_cache_from_disk().await
}

pub async fn clear_cache() {
    cache_ops::clear_cache().await
}

pub async fn check_cache(key: GeocodeKey) -> Option<String> {
    cache_ops::check_cache(key).await
}

pub async fn update_cache(key: GeocodeKey, address: String) {
    cache_ops::update_cache(key, address).await
}

// For tests
#[allow(dead_code)]
pub async fn manual_insert(
    key: GeocodeKey,
    address: String,
    last_accessed: u64,
    access_count: u32,
) {
    cache_ops::manual_insert(key, address, last_accessed, access_count).await
}

#[allow(dead_code)]
pub async fn get_cache_len() -> usize {
    cache_ops::get_cache_len().await
}

#[allow(dead_code)]
pub async fn cache_contains_key(key: &GeocodeKey) -> bool {
    cache_ops::cache_contains_key(key).await
}

#[allow(dead_code)]
pub async fn get_cache_entry_access_count(key: &GeocodeKey) -> Option<u32> {
    cache_ops::get_cache_entry_access_count(key).await
}

#[allow(dead_code)]
pub async fn get_evictions_count() -> u64 {
    cache_ops::get_evictions_count().await
}

#[allow(dead_code)]
pub async fn get_hits_count() -> u64 {
    cache_ops::get_hits_count().await
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
