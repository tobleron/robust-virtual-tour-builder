use actix_web::{web, HttpResponse};
use rayon::prelude::*;
use std::time::Instant;

use crate::models::{AppError, HistogramData, SimilarityRequest, SimilarityResponse, SimilarityResult};

// --- SIMILARITY HELPERS ---

/// Bin a 256-element histogram into fewer bins for faster comparison
fn bin_histogram(hist: &[f32], num_bins: usize) -> Vec<f32> {
    let bin_size = 256.0 / num_bins as f32;
    let mut binned = vec![0.0; num_bins];
    
    for (i, &value) in hist.iter().enumerate().take(256) {
        let bin_idx = ((i as f32) / bin_size) as usize;
        if bin_idx < num_bins {
            binned[bin_idx] += value;
        }
    }
    
    binned
}

/// Calculate histogram intersection (similarity metric)
/// Returns value between 0.0 (no overlap) and 1.0 (identical)
fn histogram_intersection(hist_a: &[f32], hist_b: &[f32]) -> f32 {
    let num_bins = hist_a.len().min(hist_b.len());
    
    let mut intersection = 0.0;
    let mut sum_a = 0.0;
    
    for i in 0..num_bins {
        let val_a = hist_a.get(i).copied().unwrap_or(0.0);
        let val_b = hist_b.get(i).copied().unwrap_or(0.0);
        
        intersection += val_a.min(val_b);
        sum_a += val_a;
    }
    
    if sum_a > 0.0 {
        intersection / sum_a
    } else {
        0.0
    }
}

/// Calculates the similarity between two images based on their histograms.
///
/// This function prefers color histograms (RGB) for higher accuracy but
/// falls back to luminance histograms if color data is unavailable.
///
/// # Arguments
/// * `hist_a` - Histogram data for the first image.
/// * `hist_b` - Histogram data for the second image.
///
/// # Returns
/// A similarity score between 0.0 (totally different) and 1.0 (identical).
fn calculate_similarity(
    hist_a: &HistogramData,
    hist_b: &HistogramData,
) -> f32 {
    // Try color histograms first (RGB channels)
    if let (Some(color_a), Some(color_b)) = (&hist_a.color_hist, &hist_b.color_hist) {
        // Bin to 8 bins for faster comparison
        let r_a = bin_histogram(&color_a.r, 8);
        let r_b = bin_histogram(&color_b.r, 8);
        let g_a = bin_histogram(&color_a.g, 8);
        let g_b = bin_histogram(&color_b.g, 8);
        let b_a = bin_histogram(&color_a.b, 8);
        let b_b = bin_histogram(&color_b.b, 8);
        
        let r_sim = histogram_intersection(&r_a, &r_b);
        let g_sim = histogram_intersection(&g_a, &g_b);
        let b_sim = histogram_intersection(&b_a, &b_b);
        
        // Average across channels
        return (r_sim + g_sim + b_sim) / 3.0;
    }
    
    // Fallback to luminance histogram
    if let (Some(luma_a), Some(luma_b)) = (&hist_a.histogram, &hist_b.histogram) {
        let binned_a = bin_histogram(luma_a, 8);
        let binned_b = bin_histogram(luma_b, 8);
        return histogram_intersection(&binned_a, &binned_b);
    }
    
    // No histogram data available
    0.0
}

/// Calculates similarity scores for a batch of image pairs.
///
/// This handler processes multiple pairs in parallel using Rayon, which
/// significantly improves performance when identifying near-duplicate images
/// in large virtual tours.
///
/// # Arguments
/// * `req` - A JSON payload containing a list of image histogram pairs.
///
/// # Returns
/// A `SimilarityResponse` containing the similarity scores for all pairs.
///
/// # Errors
/// * `InternalError` if the batch size exceeds 10,000 pairs.
#[tracing::instrument(skip(req), name = "batch_calculate_similarity")]
pub async fn batch_calculate_similarity(
    req: web::Json<SimilarityRequest>,
) -> Result<HttpResponse, AppError> {
    let start = Instant::now();
    let pair_count = req.pairs.len();
    
    tracing::info!(
        module = "Similarity",
        pair_count = pair_count,
        "SIMILARITY_BATCH_START"
    );
    
    if pair_count == 0 {
        return Ok(HttpResponse::Ok().json(SimilarityResponse {
            results: vec![],
            duration_ms: 0,
        }));
    }
    
    if pair_count > 10000 {
        return Err(AppError::InternalError(
            "Too many pairs (max 10000)".to_string()
        ));
    }
    
    let pairs = req.into_inner().pairs;
    
    // Process in parallel using Rayon
    let results = web::block(move || -> Vec<SimilarityResult> {
        pairs.par_iter()
            .map(|pair| {
                let similarity = calculate_similarity(
                    &pair.histogram_a,
                    &pair.histogram_b,
                );
                
                SimilarityResult {
                    id_a: pair.id_a.clone(),
                    id_b: pair.id_b.clone(),
                    similarity,
                }
            })
            .collect()
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
    let duration = start.elapsed().as_millis();
    
    tracing::info!(
        module = "Similarity",
        pair_count = pair_count,
        duration_ms = duration,
        avg_ms_per_pair = (duration as f64 / pair_count as f64),
        "SIMILARITY_BATCH_COMPLETE"
    );
    
    Ok(HttpResponse::Ok().json(SimilarityResponse {
        results,
        duration_ms: duration,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_histogram_binning() {
        let input = vec![10.0; 256]; // Uniform
        let binned = bin_histogram(&input, 4);
        
        assert_eq!(binned.len(), 4);
        // Each bin should sum 64 items of value 10.0 = 640.0
        for val in binned {
            assert_eq!(val, 640.0);
        }
    }

    #[test]
    fn test_histogram_intersection_identical() {
        let h1 = vec![1.0, 2.0, 3.0, 4.0];
        let h2 = vec![1.0, 2.0, 3.0, 4.0];
        
        assert!((histogram_intersection(&h1, &h2) - 1.0).abs() < 1e-6);
    }
    
    #[test]
    fn test_histogram_intersection_different() {
        let h1 = vec![10.0, 0.0];
        let h2 = vec![0.0, 10.0];
        
        assert_eq!(histogram_intersection(&h1, &h2), 0.0);
    }
}
