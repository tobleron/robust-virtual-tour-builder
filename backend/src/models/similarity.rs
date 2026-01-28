// @efficiency: data-model
use serde::{Deserialize, Serialize};

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
    pub histogram: Option<Vec<f32>>,        // Luminance histogram
    pub color_hist: Option<ColorHistogram>, // RGB histograms
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityPair {
    pub id_a: String, // Scene ID for tracking
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
