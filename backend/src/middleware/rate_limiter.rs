// @efficiency-role: infra-adapter

use crate::startup;
use actix_governor::{
    GovernorConfig, GovernorConfigBuilder, KeyExtractor, SimpleKeyExtractionError,
    governor::middleware::NoOpMiddleware,
};
use actix_web::{
    Error,
    body::{BoxBody, EitherBody, MessageBody},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
    http::{
        StatusCode,
        header::{CONTENT_TYPE, HeaderValue},
    },
};
use futures_util::future::LocalBoxFuture;
use serde_json::json;
use std::future::{Ready, ready};
use std::hash::{Hash, Hasher};
use std::rc::Rc;

#[derive(Clone, Eq)]
pub struct SessionAwareKey {
    ip: String,
    session: String,
}

impl PartialEq for SessionAwareKey {
    fn eq(&self, other: &Self) -> bool {
        self.ip == other.ip && self.session == other.session
    }
}

impl Hash for SessionAwareKey {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.ip.hash(state);
        self.session.hash(state);
    }
}

#[derive(Clone)]
pub struct SessionAwareKeyExtractor {
    scope: String,
}

impl SessionAwareKeyExtractor {
    pub fn new(scope: &str) -> Self {
        Self {
            scope: scope.to_string(),
        }
    }

    fn is_critical_path(req: &ServiceRequest) -> bool {
        let path = req.path();
        path == "/health"
            || path == "/api/health"
            || path.starts_with("/api/project/")
                && path.contains("/file/")
                && req.method() == actix_web::http::Method::GET
    }

    fn extract_ip(req: &ServiceRequest) -> String {
        req.connection_info()
            .realip_remote_addr()
            .unwrap_or("unknown")
            .split(':')
            .next()
            .unwrap_or("unknown")
            .to_string()
    }

    fn extract_session(req: &ServiceRequest) -> String {
        req.headers()
            .get("x-session-id")
            .and_then(|v| v.to_str().ok())
            .filter(|v| !v.is_empty())
            .map(|v| v.to_string())
            .or_else(|| req.cookie("id").map(|c| c.value().to_string()))
            .unwrap_or_else(|| "anon".to_string())
    }
}

impl KeyExtractor for SessionAwareKeyExtractor {
    type Key = SessionAwareKey;
    type KeyExtractionError = SimpleKeyExtractionError<&'static str>;

    fn extract(&self, req: &ServiceRequest) -> Result<Self::Key, Self::KeyExtractionError> {
        if Self::is_critical_path(req) {
            return Ok(SessionAwareKey {
                ip: "critical".to_string(),
                session: format!("critical:{}", self.scope),
            });
        }

        Ok(SessionAwareKey {
            ip: Self::extract_ip(req),
            session: Self::extract_session(req),
        })
    }

    fn whitelisted_keys(&self) -> Vec<Self::Key> {
        vec![SessionAwareKey {
            ip: "critical".to_string(),
            session: format!("critical:{}", self.scope),
        }]
    }
}

pub type RateLimitConfig = GovernorConfig<SessionAwareKeyExtractor, NoOpMiddleware>;

#[derive(Clone)]
pub struct RateLimiters {
    pub health: RateLimitConfig,
    pub read: RateLimitConfig,
    pub write: RateLimitConfig,
    pub media_heavy: RateLimitConfig,
    pub admin: RateLimitConfig,
}

impl RateLimiters {
    pub fn new() -> Self {
        Self {
            health: Self::create_config("health"),
            read: Self::create_config("read"),
            write: Self::create_config("write"),
            media_heavy: Self::create_config("media_heavy"),
            admin: Self::create_config("admin"),
        }
    }

    fn create_config(class: &str) -> RateLimitConfig {
        let (rps, mut burst) = startup::rate_limit_settings_for_class(class);
        let burst_multiplier = match class {
            "media_heavy" => std::env::var("RATE_LIMIT_MEDIA_HEAVY_BURST_MULTIPLIER")
                .ok()
                .and_then(|v| v.parse::<u32>().ok())
                .unwrap_or(3),
            "read" => std::env::var("RATE_LIMIT_READ_BURST_MULTIPLIER")
                .ok()
                .and_then(|v| v.parse::<u32>().ok())
                .unwrap_or(5),
            _ => 1,
        };
        burst = burst.saturating_mul(burst_multiplier).max(1);

        let mut builder =
            GovernorConfigBuilder::default().key_extractor(SessionAwareKeyExtractor::new(class));
        builder.per_second(rps).burst_size(burst);

        match builder.finish() {
            Some(cfg) => cfg,
            None => GovernorConfigBuilder::default()
                .per_second(1)
                .burst_size(1)
                .key_extractor(SessionAwareKeyExtractor::new(class))
                .finish()
                .expect("fallback rate limiter config must be valid"),
        }
    }
}

// ==========================================
// RateLimitResponseTransformer
// ==========================================

pub struct RateLimitResponseTransformer {
    pub scope: String,
}

impl RateLimitResponseTransformer {
    pub fn new(scope: &str) -> Self {
        Self {
            scope: scope.to_string(),
        }
    }
}

impl<S, B> Transform<S, ServiceRequest> for RateLimitResponseTransformer
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: MessageBody + 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type InitError = ();
    type Transform = RateLimitResponseTransformerMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(RateLimitResponseTransformerMiddleware {
            service: Rc::new(service),
            scope: Rc::new(self.scope.clone()),
        }))
    }
}

pub struct RateLimitResponseTransformerMiddleware<S> {
    service: Rc<S>,
    scope: Rc<String>,
}

impl<S, B> Service<ServiceRequest> for RateLimitResponseTransformerMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: MessageBody + 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = self.service.clone();
        let scope = self.scope.clone();

        // Capture Request ID if present
        let request_id = req
            .headers()
            .get("X-Request-ID")
            .and_then(|h| h.to_str().ok())
            .map(|s| s.to_string());

        Box::pin(async move {
            let res = service.call(req).await?;
            let (_scope_rps, scope_burst) = startup::rate_limit_settings_for_class(scope.as_str());

            if res.status() == StatusCode::TOO_MANY_REQUESTS {
                let retry_after = res
                    .headers()
                    .get("Retry-After")
                    .and_then(|h| h.to_str().ok())
                    .and_then(|s| s.parse::<u64>().ok())
                    .unwrap_or(0);

                let mut msg = json!({
                    "code": "RATE_LIMITED",
                    "reason": "rate_limit_exceeded",
                    "retryAfterSec": retry_after,
                    "scope": scope.as_str(),
                    "message": "Too many requests. Please try again later."
                });

                if let Some(ref rid) = request_id {
                    if let Some(obj) = msg.as_object_mut() {
                        obj.insert("requestId".to_string(), json!(rid));
                    }
                }
                let session_id = res
                    .request()
                    .headers()
                    .get("x-session-id")
                    .and_then(|h| h.to_str().ok())
                    .map(|v| v.to_string())
                    .or_else(|| res.request().cookie("id").map(|c| c.value().to_string()))
                    .unwrap_or_else(|| "anon".to_string());

                tracing::warn!(
                    module = "RateLimiter",
                    scope = scope.as_str(),
                    retry_after,
                    session_id = %session_id,
                    request_id = ?request_id,
                    "RATE_LIMIT_EXCEEDED"
                );

                let new_body = serde_json::to_string(&msg).unwrap_or_else(|_| "{}".to_string());

                let mut res = res.map_body(|_, _| EitherBody::Right {
                    body: BoxBody::new(new_body),
                });

                res.headers_mut()
                    .insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));

                if retry_after > 0 {
                    // Make sure x-ratelimit-after is present as well
                    if !res.headers().contains_key("x-ratelimit-after") {
                        if let Ok(hv) =
                            actix_web::http::header::HeaderValue::from_str(&retry_after.to_string())
                        {
                            res.headers_mut().insert(
                                actix_web::http::header::HeaderName::from_static(
                                    "x-ratelimit-after",
                                ),
                                hv,
                            );
                        }
                    }
                }

                if let Ok(hv) = HeaderValue::from_str(scope.as_str()) {
                    res.headers_mut().insert(
                        actix_web::http::header::HeaderName::from_static("x-ratelimit-scope"),
                        hv,
                    );
                }
                if let Ok(hv) = HeaderValue::from_str(&scope_burst.to_string()) {
                    res.headers_mut().insert(
                        actix_web::http::header::HeaderName::from_static("x-ratelimit-limit"),
                        hv.clone(),
                    );
                    res.headers_mut().insert(
                        actix_web::http::header::HeaderName::from_static("x-ratelimit-remaining"),
                        HeaderValue::from_static("0"),
                    );
                }
                if let Ok(hv) = HeaderValue::from_str(&retry_after.to_string()) {
                    res.headers_mut().insert(
                        actix_web::http::header::HeaderName::from_static(
                            "x-ratelimit-class-retry-after",
                        ),
                        hv,
                    );
                }

                Ok(res)
            } else {
                let mut res = res.map_body(|_, b| EitherBody::Left { body: b });
                if let Ok(hv) = HeaderValue::from_str(&scope_burst.to_string()) {
                    res.headers_mut().insert(
                        actix_web::http::header::HeaderName::from_static("x-ratelimit-limit"),
                        hv.clone(),
                    );
                    res.headers_mut().insert(
                        actix_web::http::header::HeaderName::from_static("x-ratelimit-remaining"),
                        hv,
                    );
                }
                if let Ok(hv) = HeaderValue::from_str(scope.as_str()) {
                    res.headers_mut().insert(
                        actix_web::http::header::HeaderName::from_static("x-ratelimit-scope"),
                        hv,
                    );
                }
                Ok(res)
            }
        })
    }
}
