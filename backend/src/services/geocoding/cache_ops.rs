// @efficiency-role: domain-logic
use crate::metrics::{GEOCODING_CACHE_HITS_TOTAL, GEOCODING_CACHE_MISSES_TOTAL};
use crate::models::{CacheStats, CachedGeocode, GeocodeKey};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

use super::{CACHE_STATS, GEOCODE_CACHE, GeocoderInfo, MAX_CACHE_SIZE};

pub(super) fn round_coords(lat: f64, lon: f64) -> GeocodeKey {
    let lat_rounded = (lat * 10000.0).round() as i32;
    let lon_rounded = (lon * 10000.0).round() as i32;
    (lat_rounded, lon_rounded)
}

pub(super) fn get_current_timestamp() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::SystemTime::UNIX_EPOCH)
        .unwrap_or(std::time::Duration::from_secs(0))
        .as_secs()
}

pub(super) async fn evict_lru_entry(
    cache: Arc<RwLock<HashMap<GeocodeKey, CachedGeocode>>>,
    stats: Arc<RwLock<crate::models::CacheStats>>,
) {
    let removed = {
        let mut cache = cache.write().await;
        let key_to_remove = cache
            .iter()
            .min_by_key(|(_, value)| value.last_accessed)
            .map(|(&key, _)| key);

        if let Some(key) = key_to_remove {
            cache.remove(&key);
            true
        } else {
            false
        }
    };

    if removed {
        let mut stats = stats.write().await;
        stats.evictions += 1;
        tracing::debug!(module = "Geocoder", "LRU_EVICTION");
    }
}

pub(super) async fn get_info() -> GeocoderInfo {
    let cache = GEOCODE_CACHE.read().await;
    let stats = CACHE_STATS.read().await;
    GeocoderInfo {
        stats: stats.clone(),
        cache_size: cache.len(),
    }
}

pub(super) async fn clear_cache() {
    let mut cache = GEOCODE_CACHE.write().await;
    cache.clear();
    let mut stats = CACHE_STATS.write().await;
    *stats = CacheStats::default();
    tracing::info!(module = "Geocoder", "CACHE_CLEARED");
}

pub(super) async fn check_cache(key: GeocodeKey) -> Option<String> {
    let mut cache = GEOCODE_CACHE.write().await;
    if let Some(entry) = cache.get_mut(&key) {
        entry.last_accessed = get_current_timestamp();
        entry.access_count += 1;
        let mut stats = CACHE_STATS.write().await;
        stats.hits += 1;
        if let Some(metric) = &*GEOCODING_CACHE_HITS_TOTAL {
            metric.inc();
        }
        return Some(entry.address.clone());
    }

    let mut stats = CACHE_STATS.write().await;
    stats.misses += 1;
    if let Some(metric) = &*GEOCODING_CACHE_MISSES_TOTAL {
        metric.inc();
    }
    None
}

pub(super) async fn update_cache(key: GeocodeKey, address: String) {
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

pub(super) async fn manual_insert(
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

pub(super) async fn get_cache_len() -> usize {
    let cache = GEOCODE_CACHE.read().await;
    cache.len()
}

pub(super) async fn cache_contains_key(key: &GeocodeKey) -> bool {
    let cache = GEOCODE_CACHE.read().await;
    cache.contains_key(key)
}

pub(super) async fn get_cache_entry_access_count(key: &GeocodeKey) -> Option<u32> {
    let cache = GEOCODE_CACHE.read().await;
    cache.get(key).map(|entry| entry.access_count)
}

pub(super) async fn get_evictions_count() -> u64 {
    let stats = CACHE_STATS.read().await;
    stats.evictions
}

pub(super) async fn get_hits_count() -> u64 {
    let stats = CACHE_STATS.read().await;
    stats.hits
}
