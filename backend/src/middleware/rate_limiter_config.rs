// @efficiency-role: infra-adapter
use crate::startup;
use actix_governor::{GovernorConfig, GovernorConfigBuilder, governor::middleware::NoOpMiddleware};
use actix_web::dev::ServiceRequest;

use super::{SessionAwareKey, SessionAwareKeyExtractor};

pub(super) fn is_critical_path(req: &ServiceRequest) -> bool {
    let path = req.path();
    path == "/health"
        || path == "/api/health"
        || path.starts_with("/api/project/")
            && path.contains("/file/")
            && req.method() == actix_web::http::Method::GET
}

pub(super) fn extract_ip(req: &ServiceRequest) -> String {
    req.connection_info()
        .realip_remote_addr()
        .unwrap_or("unknown")
        .split(':')
        .next()
        .unwrap_or("unknown")
        .to_string()
}

pub(super) fn extract_session(req: &ServiceRequest) -> String {
    req.headers()
        .get("x-session-id")
        .and_then(|value| value.to_str().ok())
        .filter(|value| !value.is_empty())
        .map(|value| value.to_string())
        .or_else(|| req.cookie("id").map(|cookie| cookie.value().to_string()))
        .unwrap_or_else(|| "anon".to_string())
}

pub(super) fn whitelisted_key(scope: &str) -> SessionAwareKey {
    SessionAwareKey {
        ip: "critical".to_string(),
        session: format!("critical:{scope}"),
    }
}

pub(super) fn create_config(
    class: &str,
) -> GovernorConfig<SessionAwareKeyExtractor, NoOpMiddleware> {
    let (rps, burst) = startup::rate_limit_settings_for_class(class);
    let burst = burst.saturating_mul(burst_multiplier(class)).max(1);

    let mut builder =
        GovernorConfigBuilder::default().key_extractor(SessionAwareKeyExtractor::new(class));
    builder.per_second(rps).burst_size(burst);

    builder.finish().unwrap_or_else(|| fallback_config(class))
}

fn burst_multiplier(class: &str) -> u32 {
    match class {
        "media_heavy" => std::env::var("RATE_LIMIT_MEDIA_HEAVY_BURST_MULTIPLIER")
            .ok()
            .and_then(|value| value.parse::<u32>().ok())
            .unwrap_or(3),
        "read" => std::env::var("RATE_LIMIT_READ_BURST_MULTIPLIER")
            .ok()
            .and_then(|value| value.parse::<u32>().ok())
            .unwrap_or(5),
        _ => 1,
    }
}

fn fallback_config(class: &str) -> GovernorConfig<SessionAwareKeyExtractor, NoOpMiddleware> {
    GovernorConfigBuilder::default()
        .per_second(1)
        .burst_size(1)
        .key_extractor(SessionAwareKeyExtractor::new(class))
        .finish()
        .expect("fallback rate limiter config must be valid")
}
