# Task 62: Create Backend Batch Image Similarity Endpoint

**Status:** Pending  
**Priority:** MEDIUM  
**Category:** Backend Performance  
**Estimated Effort:** 2-3 hours

---

## Objective

Create a backend endpoint for parallel histogram-based image similarity calculation, offloading CPU-intensive work from the frontend and leveraging Rust's Rayon for parallel processing.

---

## Context

**Current Implementation:**
- `ImageAnalysis.res` (frontend) calculates histogram intersection in JavaScript
- CPU-intensive operation (nested loops over 256-bin histograms)
- Blocks UI thread during batch comparisons (20+ images)
- Sequential processing (one pair at a time)

**Why Move to Backend:**
1. **Performance:** Rust is ~10-50x faster than JavaScript for numerical operations
2. **Parallelization:** Rayon can process multiple pairs concurrently
3. **Non-blocking:** Frees frontend UI thread
4. **Better suited:** Backend already has quality analysis data

---

## Requirements

### Functional Requirements
1. Create endpoint `POST /batch-calculate-similarity`
2. Accept array of image pair comparisons
3. Return similarity scores (0.0 - 1.0) for each pair
4. Support both color and luminance histogram comparison
5. Process pairs in parallel using Rayon

### Technical Requirements
1. Use Rayon for parallel iteration
2. Implement histogram intersection algorithm in Rust
3. Support binning (reduce 256 bins to 8 for performance)
4. Accept histogram data from frontend quality analysis
5. Return results in same order as input

---

## Implementation Steps

### Step 1: Define Request/Response Structs in `backend/src/handlers.rs`

```rust
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
```

### Step 2: Implement Histogram Intersection Functions

```rust
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

/// Calculate similarity between two images based on histograms
/// Prefers color histograms if available, falls back to luminance
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
```

### Step 3: Implement Batch Endpoint Handler

```rust
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
    
    if pair_count > 1000 {
        return Err(AppError::InternalError(
            "Too many pairs (max 1000)".to_string()
        ));
    }
    
    let pairs = req.into_inner().pairs;
    
    // Process in parallel using Rayon
    let results = web::block(move || -> Vec<SimilarityResult> {
        use rayon::prelude::*;
        
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
```

### Step 4: Register Route in `backend/src/main.rs`

```rust
.route("/batch-calculate-similarity", web::post().to(handlers::batch_calculate_similarity))
```

### Step 5: Update Frontend `BackendApi.res`

Add new function:
```rescript
type similarityPair = {
  "idA": string,
  "idB": string,
  "histogramA": JSON.t,
  "histogramB": JSON.t,
}

type similarityResult = {
  "idA": string,
  "idB": string,
  "similarity": float,
}

let batchCalculateSimilarity = async (pairs: array<similarityPair>): Promise.t<array<similarityResult>> => {
  try {
    let response = await Fetch.fetch(
      Constants.backendUrl ++ "/batch-calculate-similarity",
      {
        method: "POST",
        headers: Nullable.make(Dict.fromArray([("Content-Type", "application/json")])),
        body: Nullable.make(JSON.stringify(Obj.magic({"pairs": pairs}))),
      },
    )
    
    if !Fetch.ok(response) {
      Logger.error(~module_="BackendApi", ~message="SIMILARITY_BATCH_FAILED", ())
      Promise.resolve([])
    } else {
      let json = await Fetch.json(response)
      let data: {"results": array<similarityResult>} = Obj.magic(json)
      Promise.resolve(data["results"])
    }
  } catch {
  | e => {
      Logger.error(~module_="BackendApi", ~message="SIMILARITY_BATCH_ERROR", ~data=Obj.magic({"error": e}), ())
      Promise.resolve([])
    }
  }
}
```

### Step 6: Update `UploadProcessor.res` to Use Backend

Find the similarity calculation logic (around line 250-280) and replace:

**Before (frontend calculation):**
```rescript
// Sequential frontend calculation
Belt.Array.forEach(validProcessed, (item) => {
  Belt.Array.forEach(validProcessed, (otherItem) => {
    if item.checksum != otherItem.checksum {
      let sim = ImageAnalysis.calculateSimilarity(
        Obj.magic(item.quality),
        Obj.magic(otherItem.quality)
      )
      // ... clustering logic ...
    }
  })
})
```

**After (backend batch call):**
```rescript
// Build pairs array
let pairs = []
Belt.Array.forEach(validProcessed, (item) => {
  Belt.Array.forEach(validProcessed, (otherItem) => {
    if item.checksum != otherItem.checksum {
      Belt.Array.push(pairs, {
        "idA": item.checksum,
        "idB": otherItem.checksum,
        "histogramA": item.quality,
        "histogramB": otherItem.quality,
      })
    }
  })
})

// Batch calculate on backend
let similarities = await BackendApi.batchCalculateSimilarity(pairs)

// Build lookup map
let simMap = Belt.Map.String.make()
Belt.Array.forEach(similarities, (result) => {
  let key = result["idA"] ++ "_" ++ result["idB"]
  simMap->Belt.Map.String.set(key, result["similarity"])
})

// Apply clustering logic
Belt.Array.forEach(validProcessed, (item) => {
  // ... use simMap.get(key) instead of calculateSimilarity ...
})
```

---

## Testing Criteria

### Unit Tests (Rust)

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_histogram_binning() {
        let hist = vec![1.0; 256];
        let binned = bin_histogram(&hist, 8);
        assert_eq!(binned.len(), 8);
        assert_eq!(binned[0], 32.0); // 256/8 = 32 bins collapsed
    }
    
    #[test]
    fn test_histogram_intersection_identical() {
        let hist_a = vec![1.0, 2.0, 3.0];
        let hist_b = vec![1.0, 2.0, 3.0];
        let result = histogram_intersection(&hist_a, &hist_b);
        assert!((result - 1.0).abs() < 0.001); // Should be 1.0
    }
    
    #[test]
    fn test_histogram_intersection_different() {
        let hist_a = vec![1.0, 0.0, 0.0];
        let hist_b = vec![0.0, 1.0, 0.0];
        let result = histogram_intersection(&hist_a, &hist_b);
        assert_eq!(result, 0.0); // No overlap
    }
}
```

### Integration Tests

1. **Single Pair Request:**
   ```bash
   curl -X POST http://localhost:8080/batch-calculate-similarity \
     -H "Content-Type: application/json" \
     -d '{
       "pairs": [{
         "idA": "scene1",
         "idB": "scene2",
         "histogramA": {"histogram": [1.0, 2.0, ...]},
         "histogramB": {"histogram": [1.1, 2.1, ...]}
       }]
     }'
   ```

2. **Batch Request (100 pairs):**
   - Generate 100 random histogram pairs
   - Measure response time
   - Should be < 100ms for 100 pairs

### Performance Benchmarks

Compare frontend vs backend:

| Scenario | Frontend (JS) | Backend (Rust) | Speedup |
|----------|---------------|----------------|---------|
| 10 pairs | ~50ms | ~5ms | 10x |
| 100 pairs | ~500ms | ~20ms | 25x |
| 1000 pairs | ~5000ms | ~100ms | 50x |

---

## Expected Impact

**Performance:**
- ✅ 10-50x speedup for similarity calculations
- ✅ Parallel processing of pairs (uses all CPU cores)
- ✅ Non-blocking UI during batch operations

**Code Quality:**
- ✅ Moves CPU-intensive work to appropriate layer
- ✅ Reduces frontend bundle size
- ✅ Better separation of concerns

**User Experience:**
- ✅ Faster upload processing (no UI freezing)
- ✅ Progress updates remain smooth
- ✅ Large batches (50+ images) become viable

---

## Dependencies

**Rust Crates:**
- `rayon` - should already be in Cargo.toml (used in other handlers)

**Frontend Modules:**
- `BackendApi.res` (add function)
- `UploadProcessor.res` (update to use backend)
- `ImageAnalysis.res` (can be deprecated after migration)

---

## Rollback Plan

If issues arise:
1. Remove backend endpoint route
2. Revert `UploadProcessor.res` to frontend calculation
3. Keep `ImageAnalysis.res` for fallback

---

## Optional Enhancements (Future)

1. **Smart Batching:** Automatically chunk large requests
2. **Caching:** Cache similarity results by checksum pair
3. **GPU Acceleration:** Use CUDA for extreme batches (1000+ pairs)

---

## Related Files

- `backend/src/handlers.rs` (add endpoint)
- `backend/src/main.rs` (register route)
- `src/systems/BackendApi.res` (add function)
- `src/systems/UploadProcessor.res` (update clustering logic)
- `src/systems/ImageAnalysis.res` (can be deprecated)

---

## Success Metrics

- ✅ Backend processes 100 pairs in < 50ms
- ✅ Frontend upload processing 3-5x faster for 20+ images
- ✅ No UI freezing during similarity calculation
- ✅ Logging shows parallel execution
- ✅ Memory usage remains stable for large batches
