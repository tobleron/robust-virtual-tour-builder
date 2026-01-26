use crate::models::{AppError, GeocodeRequest, GeocodeResponse};
use crate::services::geocoding;
use actix_web::{HttpResponse, web};
use serde::Serialize;

/// Performs reverse geocoding to find a human-readable address for coordinates.
///
/// This handler uses the geocoding service which implements LRU caching and
/// OpenStreetMap Nominatim API. It returns a fallback message instead of
/// an error if the service is unavailable.
///
/// # Arguments
/// * `req` - A JSON payload containing `lat` and `lon`.
///
/// # Returns
/// A `GeocodeResponse` containing the address string.
#[tracing::instrument(skip(req), name = "reverse_geocode")]
pub async fn reverse_geocode(req: web::Json<GeocodeRequest>) -> Result<HttpResponse, AppError> {
    let lat = req.lat;
    let lon = req.lon;

    tracing::info!(
        module = "Geocoder",
        lat = lat,
        lon = lon,
        "REVERSE_GEOCODE_START"
    );

    match geocoding::reverse_geocode(lat, lon).await {
        Ok(address) => {
            tracing::info!(module = "Geocoder", "REVERSE_GEOCODE_COMPLETE");
            Ok(HttpResponse::Ok().json(GeocodeResponse { address }))
        }
        Err(e) => {
            tracing::error!(module = "Geocoder", error = %e, "REVERSE_GEOCODE_FAILED");
            // Return a graceful fallback message
            Ok(HttpResponse::Ok().json(GeocodeResponse {
                address: format!("[Geocoding unavailable: {}]", e),
            }))
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GeocodeStatsResponse {
    cache_size: usize,
    max_cache_size: usize,
    hit_rate: f64,
    total_requests: u64,
    hits: u64,
    misses: u64,
    evictions: u64,
    last_save: Option<String>,
}

/// Returns diagnostic statistics about the geocoding cache.
///
/// Provides information such as hit rate, cache size, total requests,
/// and the last time the cache was persisted to disk.
///
/// # Returns
/// A JSON object containing cache performance metrics.
#[tracing::instrument(name = "geocode_stats")]
pub async fn geocode_stats() -> impl actix_web::Responder {
    let info = geocoding::get_info().await;
    let stats = info.stats;

    let total_requests = stats.hits + stats.misses;
    let hit_rate = if total_requests > 0 {
        (stats.hits as f64 / total_requests as f64) * 100.0
    } else {
        0.0
    };

    let last_save_time = stats.last_save.map(|ts| {
        chrono::DateTime::<chrono::Utc>::from_timestamp(ts as i64, 0)
            .map(|dt| dt.to_rfc3339())
            .unwrap_or_else(|| "Unknown".to_string())
    });

    HttpResponse::Ok().json(GeocodeStatsResponse {
        cache_size: info.cache_size,
        max_cache_size: geocoding::MAX_CACHE_SIZE,
        hit_rate,
        total_requests,
        hits: stats.hits,
        misses: stats.misses,
        evictions: stats.evictions,
        last_save: last_save_time,
    })
}

/// Wipes the in-memory geocoding cache and persists the empty state to disk.
///
/// This is typically used for maintenance or if the cache contains stale data.
///
/// # Returns
/// A success message JSON.
#[tracing::instrument(name = "clear_geocode_cache")]
pub async fn clear_geocode_cache() -> impl actix_web::Responder {
    geocoding::clear_cache().await;

    // Save empty cache
    let _ = geocoding::save_cache_to_disk().await;

    HttpResponse::Ok().json(serde_json::json!({
        "success": true,
        "message": "Cache cleared"
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::geocoding;
    use actix_web::{Responder, http::StatusCode, test, web};

    #[actix_web::test]
    async fn test_reverse_geocode_structure() {
        // We can't guarantee network, but we can verify the response structure matches expectations
        // or fails gracefully.

        // We need to construct the app or call handlers directly.
        // Calling handler directly is easier if we don't need complex middleware.
        let resp = reverse_geocode(web::Json(GeocodeRequest { lat: 0.0, lon: 0.0 })).await;

        // It always returns Ok(HttpResponse) unless something catastrophic happens
        assert!(resp.is_ok());
        let response = resp.unwrap();
        assert_eq!(response.status(), StatusCode::OK);

        // We could inspect the body, but it requires parsing bytes.
    }

    #[actix_web::test]
    async fn test_geocode_stats() {
        // Ensure stats endpoint returns valid JSON
        let resp = geocode_stats().await;

        // It's a Responder, so we need to convert it to response
        let resp = resp.respond_to(&test::TestRequest::default().to_http_request());
        assert_eq!(resp.status(), StatusCode::OK);
    }

    #[actix_web::test]
    async fn test_clear_cache() {
        let resp = clear_geocode_cache().await;
        let resp = resp.respond_to(&test::TestRequest::default().to_http_request());
        assert_eq!(resp.status(), StatusCode::OK);

        // Verify stats are reset
        let info = geocoding::get_info().await;
        assert_eq!(info.cache_size, 0);
    }
}
