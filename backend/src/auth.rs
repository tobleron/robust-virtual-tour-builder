// @efficiency-role: functional-service
#[path = "auth_handlers.rs"]
mod auth_handlers;
#[path = "auth_requests.rs"]
mod auth_requests;

use crate::models::AppError;
use actix_web::{
    Error, HttpRequest, HttpResponse,
    body::{BoxBody, EitherBody},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
    web,
};
use futures_util::future::LocalBoxFuture;
use oauth2::basic::BasicClient;
use serde::{Deserialize, Serialize};
use std::future::{Ready, ready};
use std::rc::Rc;

// ==========================================
// Handlers & Client
// ==========================================

#[allow(dead_code)]
pub struct AuthService {
    pub google_client: BasicClient,
}

#[allow(dead_code)]
impl AuthService {
    pub fn new() -> Result<Self, AppError> {
        auth_handlers::new_auth_service()
    }
}

#[allow(dead_code)]
#[derive(Deserialize)]
pub struct AuthCallbackParams {
    pub code: String,
    pub state: String,
}

#[allow(dead_code)]
pub async fn google_login(auth_service: web::Data<AuthService>) -> Result<HttpResponse, AppError> {
    auth_handlers::google_login(auth_service).await
}

#[allow(dead_code)]
pub async fn google_callback(
    params: web::Query<AuthCallbackParams>,
    auth_service: web::Data<AuthService>,
) -> Result<HttpResponse, AppError> {
    auth_handlers::google_callback(params, auth_service).await
}

// ==========================================
// JWT Logic
// ==========================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String,
    pub exp: usize,
    pub iat: usize,
    pub step_up_verified_until: Option<usize>,
}

#[cfg_attr(not(test), allow(dead_code))]
pub fn encode_token(sub: &str, step_up_verified_until: Option<usize>) -> Result<String, AppError> {
    auth_handlers::encode_token(sub, step_up_verified_until)
}

pub fn decode_token(token: &str) -> Result<Claims, AppError> {
    auth_handlers::decode_token(token)
}

pub fn is_step_up_verified(req: &HttpRequest) -> bool {
    auth_handlers::is_step_up_verified(req)
}

#[allow(dead_code)]
pub fn require_step_up_verified(req: &HttpRequest) -> Result<(), AppError> {
    auth_handlers::require_step_up_verified(req)
}

// ==========================================
// Auth Middleware
// ==========================================

pub struct AuthMiddleware;

impl<S, B> Transform<S, ServiceRequest> for AuthMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type InitError = ();
    type Transform = AuthMiddlewareMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(AuthMiddlewareMiddleware {
            service: Rc::new(service),
        }))
    }
}

pub struct StepUpMiddleware;

impl<S, B> Transform<S, ServiceRequest> for StepUpMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type InitError = ();
    type Transform = StepUpMiddlewareMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(StepUpMiddlewareMiddleware {
            service: Rc::new(service),
        }))
    }
}

pub struct StepUpMiddlewareMiddleware<S> {
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for StepUpMiddlewareMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = self.service.clone();
        Box::pin(async move {
            if let Err(response) = process_authentication(&req).await {
                return Ok(req
                    .into_response(response)
                    .map_body(|_, b| EitherBody::Right { body: b }));
            }
            let allowed = {
                let http_req = req.request();
                is_step_up_verified(http_req)
            };
            if !allowed {
                let response = HttpResponse::Unauthorized().json(serde_json::json!({
                    "error": "Step-up verification required"
                }));
                return Ok(req
                    .into_response(response)
                    .map_body(|_, b| EitherBody::Right { body: b }));
            }

            let res = service.call(req).await?;
            Ok(res.map_body(|_, b| EitherBody::Left { body: b }))
        })
    }
}

pub struct AuthMiddlewareMiddleware<S> {
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for AuthMiddlewareMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = self.service.clone();

        Box::pin(async move {
            if let Err(response) = process_authentication(&req).await {
                return Ok(req
                    .into_response(response)
                    .map_body(|_, b| EitherBody::Right { body: b }));
            }

            let res = service.call(req).await?;
            Ok(res.map_body(|_, b| EitherBody::Left { body: b }))
        })
    }
}

#[allow(dead_code)]
fn extract_token(req: &ServiceRequest) -> Option<String> {
    auth_requests::extract_token(req)
}

#[allow(dead_code)]
async fn attach_user_to_request(req: &ServiceRequest, user_id: &str) -> Result<(), HttpResponse> {
    auth_requests::attach_user_to_request(req, user_id).await
}

#[allow(dead_code)]
fn headless_token() -> Option<String> {
    auth_requests::headless_token()
}

#[allow(dead_code)]
fn headless_user_metadata() -> (String, String, String, String) {
    auth_requests::headless_user_metadata()
}

#[allow(dead_code)]
fn is_headless_token(token: &str) -> bool {
    auth_requests::is_headless_token(token)
}

#[allow(dead_code)]
async fn attach_headless_user(req: &ServiceRequest) -> Result<(), HttpResponse> {
    auth_requests::attach_headless_user(req).await
}

async fn process_authentication(req: &ServiceRequest) -> Result<(), HttpResponse> {
    auth_requests::process_authentication(req).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_token_encode_decode() -> Result<(), Box<dyn std::error::Error>> {
        if std::env::var("JWT_SECRET").is_err() {
            unsafe {
                std::env::set_var("JWT_SECRET", "test_secret_for_unit_tests_only");
            }
        }
        let sub = "user123";
        let token = encode_token(sub, None)?;
        let claims = decode_token(&token)?;
        assert_eq!(claims.sub, sub);
        Ok(())
    }
}
