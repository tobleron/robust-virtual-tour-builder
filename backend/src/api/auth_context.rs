use actix_web::HttpRequest;

use super::{IpReputation, LoginContext};

pub(super) fn extract_login_context(req: &HttpRequest) -> LoginContext {
    let ip_address = req
        .connection_info()
        .realip_remote_addr()
        .map(|value| value.split(':').next().unwrap_or(value).to_string());
    let user_agent = req
        .headers()
        .get("User-Agent")
        .and_then(|value| value.to_str().ok())
        .map(|value| value.to_string());
    let user_agent_family = user_agent
        .as_deref()
        .and_then(super::parse_user_agent_family);
    let timezone = req
        .headers()
        .get("X-Client-Timezone")
        .and_then(|value| value.to_str().ok())
        .map(|value| value.to_string());
    let language = req
        .headers()
        .get("Accept-Language")
        .and_then(|value| value.to_str().ok())
        .map(|value| value.split(',').next().unwrap_or(value).trim().to_string());
    let country = req
        .headers()
        .get("X-Geo-Country")
        .and_then(|value| value.to_str().ok())
        .map(|value| value.to_string());
    let region = req
        .headers()
        .get("X-Geo-Region")
        .and_then(|value| value.to_str().ok())
        .map(|value| value.to_string());
    let lat = req
        .headers()
        .get("X-Geo-Lat")
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.parse::<f64>().ok());
    let lon = req
        .headers()
        .get("X-Geo-Lon")
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.parse::<f64>().ok());

    LoginContext {
        ip_address,
        user_agent,
        user_agent_family,
        timezone,
        language,
        country,
        region,
        lat,
        lon,
    }
}

pub(super) fn empty_login_context() -> LoginContext {
    LoginContext {
        ip_address: None,
        user_agent: None,
        user_agent_family: None,
        timezone: None,
        language: None,
        country: None,
        region: None,
        lat: None,
        lon: None,
    }
}

pub(super) fn parse_user_agent_family(ua: &str) -> Option<String> {
    let lowered = ua.to_lowercase();
    if lowered.contains("edg/") {
        return Some("edge".to_string());
    }
    if lowered.contains("chrome/") {
        return Some("chrome".to_string());
    }
    if lowered.contains("firefox/") {
        return Some("firefox".to_string());
    }
    if lowered.contains("safari/") && !lowered.contains("chrome/") {
        return Some("safari".to_string());
    }
    if lowered.contains("opera/") || lowered.contains("opr/") {
        return Some("opera".to_string());
    }
    None
}

pub(super) fn evaluate_ip_reputation(req: &HttpRequest) -> IpReputation {
    let reputation = req
        .headers()
        .get("X-IP-Reputation")
        .and_then(|value| value.to_str().ok())
        .map(|value| value.to_lowercase());
    match reputation.as_deref() {
        Some("bad") => IpReputation::Bad("ip_reputation_bad".to_string()),
        Some("proxy") => IpReputation::Bad("ip_proxy_detected".to_string()),
        Some("vpn") => IpReputation::Bad("ip_vpn_detected".to_string()),
        Some("tor") => IpReputation::Bad("ip_tor_detected".to_string()),
        Some("hosting") => IpReputation::Bad("ip_hosting_network".to_string()),
        Some("good") => IpReputation::Good,
        _ => IpReputation::Unknown,
    }
}
