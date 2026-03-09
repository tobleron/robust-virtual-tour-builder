// @efficiency-role: infra-adapter
use crate::models::{CacheStats, CachedGeocode, GeocodeKey};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::{CACHE_STATS, GEOCODE_CACHE, cache_ops};

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

pub(super) fn decode_cache_payload(
    data: &serde_json::Value,
) -> (
    Option<HashMap<GeocodeKey, CachedGeocode>>,
    Option<CacheStats>,
    bool,
) {
    if let Some(entries_value) = data.get("entries") {
        match serde_json::from_value::<Vec<PersistedCacheEntry>>(entries_value.clone()) {
            Ok(entries) => {
                let mut loaded_cache = HashMap::new();
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

pub(super) fn get_cache_file_path() -> String {
    std::env::var("GEOCODING_CACHE_FILE").unwrap_or_else(|_| "../cache/geocoding.json".to_string())
}

pub(super) async fn save_cache_to_disk() -> Result<(), String> {
    let cache = GEOCODE_CACHE.read().await;
    let mut stats = CACHE_STATS.write().await;
    let cache_file = get_cache_file_path();

    if let Some(parent) = std::path::Path::new(&cache_file).parent() {
        tokio::fs::create_dir_all(parent)
            .await
            .map_err(|e| format!("Failed to create cache directory: {}", e))?;
    }

    let current_time = cache_ops::get_current_timestamp();
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

pub(super) async fn load_cache_from_disk() -> std::io::Result<()> {
    let cache_file = get_cache_file_path();

    match tokio::fs::read_to_string(&cache_file).await {
        Ok(contents) => {
            let data: serde_json::Value = match serde_json::from_str(&contents) {
                Ok(value) => value,
                Err(error) => {
                    tracing::warn!(module = "Geocoder", error = %error, "Invalid cache JSON; starting fresh");
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
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            tracing::info!(module = "Geocoder", "No cache file found - starting fresh");
            Ok(())
        }
        Err(error) => {
            tracing::warn!(module = "Geocoder", error = %error, "Failed to load cache");
            Ok(())
        }
    }
}
