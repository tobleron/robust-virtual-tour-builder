// @efficiency-role: infra-adapter
#[path = "rate_limiter_config.rs"]
mod rate_limiter_config;
#[path = "rate_limiter_response.rs"]
mod rate_limiter_response;

use actix_governor::{
    GovernorConfig, KeyExtractor, SimpleKeyExtractionError, governor::middleware::NoOpMiddleware,
};
use actix_web::{
    Error,
    body::{BoxBody, EitherBody, MessageBody},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
};
use futures_util::future::LocalBoxFuture;
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
        rate_limiter_config::is_critical_path(req)
    }

    fn extract_ip(req: &ServiceRequest) -> String {
        rate_limiter_config::extract_ip(req)
    }

    fn extract_session(req: &ServiceRequest) -> String {
        rate_limiter_config::extract_session(req)
    }
}

impl KeyExtractor for SessionAwareKeyExtractor {
    type Key = SessionAwareKey;
    type KeyExtractionError = SimpleKeyExtractionError<&'static str>;

    fn extract(&self, req: &ServiceRequest) -> Result<Self::Key, Self::KeyExtractionError> {
        if Self::is_critical_path(req) {
            return Ok(rate_limiter_config::whitelisted_key(&self.scope));
        }

        Ok(SessionAwareKey {
            ip: Self::extract_ip(req),
            session: Self::extract_session(req),
        })
    }

    fn whitelisted_keys(&self) -> Vec<Self::Key> {
        vec![rate_limiter_config::whitelisted_key(&self.scope)]
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
        rate_limiter_config::create_config(class)
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
        rate_limiter_response::call(self.service.clone(), self.scope.clone(), req)
    }
}
