fn format_address_from_json(json: &serde_json::Value) -> Option<String> {
    let address_obj = json.get("address")?;
    let mut parts = Vec::new();

    let get_val = |keys: &[&str]| -> Option<String> {
        for key in keys {
            if let Some(val) = address_obj.get(key).and_then(|v| v.as_str()) {
                if !val.is_empty() {
                    return Some(val.to_string());
                }
            }
        }
        None
    };

    if let Some(v) = get_val(&["road"]) {
        parts.push(v);
    }
    if let Some(v) = get_val(&["suburb", "neighbourhood"]) {
        parts.push(v);
    }
    if let Some(v) = get_val(&["city", "town", "village"]) {
        parts.push(v);
    }
    if let Some(v) = get_val(&["state", "province"]) {
        parts.push(v);
    }
    if let Some(v) = get_val(&["country"]) {
        parts.push(v);
    }

    if !parts.is_empty() {
        Some(parts.join(", "))
    } else {
        None
    }
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

    if let Some(error) = json.get("error") {
        return Err(format!("OSM API error: {}", error));
    }

    if let Some(formatted) = format_address_from_json(&json) {
        return Ok(formatted);
    }

    json.get("display_name")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .ok_or_else(|| "No address found in response".to_string())
}
