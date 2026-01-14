pub mod errors;
pub use errors::*;

use serde::{Serialize, Deserialize};

// --- Metadata Structs ---

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GpsData {
    pub lat: f64,
    pub lon: f64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ExifMetadata {
    pub make: Option<String>,
    pub model: Option<String>,
    pub date_time: Option<String>,
    pub gps: Option<GpsData>,
    pub width: u32,
    pub height: u32,
    pub focal_length: Option<f32>,
    pub aperture: Option<f32>,
    pub iso: Option<u32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct QualityStats {
    pub avg_luminance: u32,
    pub black_clipping: f32,
    pub white_clipping: f32,
    pub sharpness_variance: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ColorHist {
    pub r: Vec<u32>,
    pub g: Vec<u32>,
    pub b: Vec<u32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct QualityAnalysis {
    pub score: f32,
    pub histogram: Vec<u32>,
    pub color_hist: ColorHist,
    pub stats: QualityStats,
    pub is_blurry: bool,
    pub is_soft: bool,
    pub is_severely_dark: bool,
    pub is_dim: bool,
    pub has_black_clipping: bool,
    pub has_white_clipping: bool,
    pub issues: u32,
    pub warnings: u32,
    pub analysis: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct MetadataResponse {
    pub exif: ExifMetadata,
    pub quality: QualityAnalysis,
    pub is_optimized: bool,
    pub checksum: String, // SHA-256 hash in format: {hex}_{filesize}
    pub suggested_name: Option<String>, // Logic moved from frontend
}

// --- GEOCODING SYSTEM ---

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

// --- SIMILARITY SYSTEM ---

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ColorHistogram {
    pub r: Vec<f32>,
    pub g: Vec<f32>,
    pub b: Vec<f32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct HistogramData {
    pub histogram: Option<Vec<f32>>,          // Luminance histogram
    pub color_hist: Option<ColorHistogram>,   // RGB histograms
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityPair {
    pub id_a: String,        // Scene ID for tracking
    pub id_b: String,
    pub histogram_a: HistogramData,
    pub histogram_b: HistogramData,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityRequest {
    pub pairs: Vec<SimilarityPair>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityResult {
    pub id_a: String,
    pub id_b: String,
    pub similarity: f32,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityResponse {
    pub results: Vec<SimilarityResult>,
    pub duration_ms: u128,
}

// --- VALIDATION SYSTEM ---

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ValidationReport {
    pub broken_links_removed: u32,
    pub orphaned_scenes: Vec<String>, // Scenes with no incoming links
    pub unused_files: Vec<String>,    // Files in ZIP not used by project
    pub warnings: Vec<String>,
    pub errors: Vec<String>,
}

impl ValidationReport {
    pub fn new() -> Self {
        ValidationReport {
            broken_links_removed: 0,
            orphaned_scenes: Vec::new(),
            unused_files: Vec::new(),
            warnings: Vec::new(),
            errors: Vec::new(),
        }
    }
    
    pub fn has_issues(&self) -> bool {
        self.broken_links_removed > 0 
            || !self.orphaned_scenes.is_empty() 
            || !self.unused_files.is_empty()
            || !self.errors.is_empty()
    }
}

// --- TELEMETRY ---

#[derive(Debug, Serialize, Deserialize)]
pub struct TelemetryEntry {
    pub level: String,
    pub module: String,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub timestamp: String,
}
