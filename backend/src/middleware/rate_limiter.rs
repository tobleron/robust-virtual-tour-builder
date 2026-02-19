use crate::startup;
use actix_governor::{GovernorConfig, GovernorConfigBuilder, PeerIpKeyExtractor};
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
use std::rc::Rc;

pub type RateLimitConfig =
    GovernorConfig<PeerIpKeyExtractor, actix_governor::governor::middleware::NoOpMiddleware>;

#[derive(Clone)]
pub struct RateLimiters {
    pub health: RateLimitConfig,
    pub read: RateLimitConfig,
    pub write: RateLimitConfig,
    pub admin: RateLimitConfig,
}

impl RateLimiters {
    pub fn new() -> Self {
        Self {
            health: Self::create_config("health"),
            read: Self::create_config("read"),
            write: Self::create_config("write"),
            admin: Self::create_config("admin"),
        }
    }

    fn create_config(class: &str) -> RateLimitConfig {
        let (rps, burst) = startup::rate_limit_settings_for_class(class);

        GovernorConfigBuilder::default()
            .per_second(rps)
            .burst_size(burst)
            .key_extractor(PeerIpKeyExtractor)
            .finish()
            .expect("Failed to create rate limit config")
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

                if let Some(rid) = request_id {
                    if let Some(obj) = msg.as_object_mut() {
                        obj.insert("requestId".to_string(), json!(rid));
                    }
                }

                let new_body = serde_json::to_string(&msg).unwrap();

                let mut res = res.map_body(|_, _| EitherBody::Right {
                    body: BoxBody::new(new_body),
                });

                res.headers_mut()
                    .insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));

                if retry_after > 0 {
                    // Make sure x-ratelimit-after is present as well
                    if !res.headers().contains_key("x-ratelimit-after") {
                        res.headers_mut().insert(
                            actix_web::http::header::HeaderName::from_static("x-ratelimit-after"),
                            actix_web::http::header::HeaderValue::from_str(
                                &retry_after.to_string(),
                            )
                            .unwrap(),
                        );
                    }
                }

                Ok(res)
            } else {
                Ok(res.map_body(|_, b| EitherBody::Left { body: b }))
            }
        })
    }
}
