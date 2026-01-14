# Task 81: Expand Backend Test Coverage

## Priority: 🟡 IMPORTANT

## Context
The backend currently has 7 unit tests:
- pathfinder::tests::test_auto_forward_chain
- pathfinder::tests::test_auto_forward_loop
- pathfinder::tests::test_broken_link_stops_chain
- api::media::similarity::tests::test_histogram_intersection_different
- api::media::similarity::tests::test_histogram_intersection_identical
- api::media::similarity::tests::test_histogram_binning
- api::media::image::tests::test_quality_analysis_serialization

Critical services like validation, geocoding cache, and media processing lack tests.

## Tests to Add

### 1. services/project.rs Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_validate_project_finds_broken_links() {
        // Create project with scene A linking to non-existent scene B
        // Verify validation report shows broken link
    }
    
    #[test]
    fn test_validate_project_finds_orphaned_scenes() {
        // Create project where scene C has no incoming links
        // Verify orphaned_scenes includes "C"
    }
    
    #[test]
    fn test_validate_project_clean_project() {
        // Create well-formed project
        // Verify report.has_issues() == false
    }
}
```

### 2. services/geocoding.rs Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_cache_hit_increments_counter() {
        // Add entry to cache
        // Access it
        // Verify access_count increased
    }
    
    #[tokio::test]
    async fn test_lru_eviction() {
        // Fill cache to MAX_CACHE_SIZE
        // Add one more
        // Verify oldest entry was evicted
    }
    
    #[test]
    fn test_coordinate_rounding() {
        // Verify coordinates are rounded to ~11m precision
        // 37.7749, -122.4194 and 37.7750, -122.4194 should map to same key
    }
}
```

### 3. services/media.rs Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_quality_score_calculation() {
        // Create known histogram
        // Verify score is within expected range
    }
    
    #[test]
    fn test_blur_detection() {
        // Create image with known low variance
        // Verify is_blurry == true
    }
    
    #[test]
    fn test_checksum_format() {
        // Generate checksum
        // Verify format is {hex}_{filesize}
    }
}
```

### 4. models/errors.rs Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_app_error_response_format() {
        // Create AppError::BadRequest
        // Verify JSON response has "error" and "details" fields
    }
}
```

### 5. API Integration Tests (Optional, More Complex)
```rust
#[cfg(test)]
mod integration_tests {
    use actix_web::test;
    use super::*;
    
    #[actix_web::test]
    async fn test_health_endpoint() {
        let app = test::init_service(App::new().route("/health", web::get().to(health_check))).await;
        let req = test::TestRequest::get().uri("/health").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }
}
```

## Target Coverage

| Module | Current Tests | Target Tests |
|--------|---------------|--------------|
| pathfinder.rs | 3 | 5+ |
| similarity.rs | 3 | 5 |
| image.rs | 1 | 5 |
| project.rs (service) | 0 | 4 |
| geocoding.rs (service) | 0 | 4 |
| media.rs (service) | 0 | 4 |
| **Total** | **7** | **27+** |

## Acceptance Criteria
- [ ] At least 20 total tests
- [ ] `cargo test` passes all tests
- [ ] Key services (project, geocoding, media) have coverage
- [ ] Tests document expected behavior

## Files to Modify
- `backend/src/services/project.rs` - add tests mod
- `backend/src/services/geocoding.rs` - add tests mod
- `backend/src/services/media.rs` - add tests mod
- `backend/src/models/errors.rs` - add tests mod

## Testing
```bash
cd backend
cargo test -- --nocapture  # See output
cargo test --test-threads=1  # Run sequentially if needed
```
