/* backend/src/services/geocoding/logic.rs */

use crate::models::{CachedGeocode, GeocodeKey};
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
    if let Some(address_obj) = json.get("address") {
        let mut parts = Vec::new();

        // Extract address components
        if let Some(road) = address_obj.get("road").and_then(|v| v.as_str())
            && !road.is_empty()
        {
            parts.push(road.to_string());
        }

        let suburb = address_obj
            .get("suburb")
            .or_else(|| address_obj.get("neighbourhood"))
            .and_then(|v| v.as_str());
        if let Some(s) = suburb
            && !s.is_empty()
        {
            parts.push(s.to_string());
        }

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

        let state = address_obj
            .get("state")
            .or_else(|| address_obj.get("province"))
            .and_then(|v| v.as_str());
        if let Some(s) = state
            && !s.is_empty()
        {
            parts.push(s.to_string());
        }

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
