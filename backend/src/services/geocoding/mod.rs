/* backend/src/services/geocoding/mod.rs - Facade for Geocoding Service */
// @efficiency-role: infra-adapter

pub mod cache;
pub mod osm;

// use crate::models::{CachedGeocode, GeocodeKey};

pub use cache::{MAX_CACHE_SIZE, clear_cache, get_info, load_cache_from_disk, save_cache_to_disk};

pub async fn reverse_geocode(lat: f64, lon: f64) -> Result<String, String> {
    tracing::info!(lat = lat, lon = lon, "REVERSE_GEOCODE_COORD_RECEIVED");
    let key = cache::round_coords(lat, lon);

    if let Some(address) = cache::check_cache(key).await {
        return Ok(address);
    }

    match osm::call_osm_nominatim(lat, lon).await {
        Ok(address) => {
            cache::update_cache(key, address.clone()).await;
            tracing::info!(address = %address, "REVERSE_GEOCODE_RESOLVED");
            Ok(address)
        }
        Err(e) => Err(e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_geocoder_suite_sequential() {
        let _guard = cache::GEOCODING_TEST_MUTEX.lock().expect("test mutex poisoned");
        test_coordinate_rounding_internal();
        test_reverse_geocode_with_cache_internal().await;
        test_clear_cache_internal().await;
        test_lru_eviction_internal().await;
    }

    async fn test_reverse_geocode_with_cache_internal() {
        clear_cache().await; // Ensure a clean state for the test
        let lat = 40.7128;
        let lon = -74.0060;
        let address = "New York, NY, USA".to_string();

        cache::update_cache(cache::round_coords(lat, lon), address.clone()).await;

        let result = reverse_geocode(lat, lon)
            .await
            .expect("Failed to reverse geocode");
        assert_eq!(result, address);

        let info = get_info().await;
        assert!(info.cache_size >= 1);
    }

    async fn test_lru_eviction_internal() {
        clear_cache().await;
        {
            for i in 0..MAX_CACHE_SIZE {
                let key = (i as i32, 0);
                cache::manual_insert(key, format!("Address {}", i), i as u64, 1).await;
            }
        }

        let key_new = (MAX_CACHE_SIZE as i32, 0);
        cache::update_cache(key_new, "New Address".to_string()).await;

        let len = cache::get_cache_len().await;
        assert_eq!(len, MAX_CACHE_SIZE);

        assert!(!cache::cache_contains_key(&(0, 0)).await); // Oldest should be gone
        assert!(cache::cache_contains_key(&(1, 0)).await);

        let evictions = cache::get_evictions_count().await;
        assert_eq!(evictions, 1);
    }

    fn test_coordinate_rounding_internal() {
        let k1 = cache::round_coords(37.77491, -122.41941);
        let k2 = cache::round_coords(37.77494, -122.41944);
        let k3 = cache::round_coords(37.7750, -122.4200);
        assert_eq!(k1, k2);
        assert_ne!(k1, k3);
    }

    async fn test_clear_cache_internal() {
        {
            cache::manual_insert((1, 1), "foo".to_string(), 0, 0).await;
        }
        clear_cache().await;
        let len = cache::get_cache_len().await;
        assert_eq!(len, 0);
        let hits = cache::get_hits_count().await;
        assert_eq!(hits, 0);
    }
}
