// @efficiency: data-model
use serde::{Deserialize, Serialize};

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
pub type GeocodeKey = (i32, i32);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CachedGeocode {
    pub address: String,
    pub last_accessed: u64, // Unix timestamp
    pub access_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct CacheStats {
    pub hits: u64,
    pub misses: u64,
    pub evictions: u64,
    pub last_save: Option<u64>,
}
