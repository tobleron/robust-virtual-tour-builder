use super::jwt;
use crate::models::User;
use actix_web::{
    Error, HttpMessage, HttpResponse,
    body::{BoxBody, EitherBody},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
    http::header,
    web,
};
use futures_util::future::LocalBoxFuture;
use sqlx::SqlitePool;
use std::future::{Ready, ready};
use std::rc::Rc;

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

            // Continue request
            let res = service.call(req).await?;
            Ok(res.map_body(|_, b| EitherBody::Left { body: b }))
        })
    }
}

fn extract_token(req: &ServiceRequest) -> Option<String> {
    // Check Authorization header
    if let Some(header) = req.headers().get(header::AUTHORIZATION) {
        if let Ok(header_str) = header.to_str() {
            if let Some(token) = header_str.strip_prefix("Bearer ") {
                return Some(token.to_string());
            }
        }
    }

    // Try query param
    req.query_string().split('&').find_map(|pair| {
        let (key, value) = pair.split_once('=')?;
        if key == "token" {
            Some(value.to_string())
        } else {
            None
        }
    })
}

async fn attach_user_to_request(req: &ServiceRequest, user_id: &str) -> Result<(), HttpResponse> {
    let pool = req.app_data::<web::Data<SqlitePool>>().ok_or_else(|| {
        tracing::error!("Database pool not found in app_data");
        HttpResponse::InternalServerError().finish()
    })?;

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
        .bind(user_id)
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|e| {
            tracing::error!("Database error during auth: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Database error"}))
        })?
        .ok_or_else(|| {
            HttpResponse::Unauthorized().json(serde_json::json!({"error": "User not found"}))
        })?;

    req.extensions_mut().insert(user);
    Ok(())
}

async fn process_authentication(req: &ServiceRequest) -> Result<(), HttpResponse> {
    let token = extract_token(req).ok_or_else(|| {
        HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "Missing Authorization header or token param"
        }))
    })?;

    // Professional bypass for local development/debug environments
    // Automatically enabled in debug builds, or via explicit env var in release
    let dev_mode = cfg!(debug_assertions)
        || std::env::var("BYPASS_AUTH")
            .map(|v| v == "true")
            .unwrap_or(false);

    if dev_mode && token.trim() == "dev-token" {
        tracing::warn!("⚠️  Using DEV_TOKEN bypass for authentication");
        // Use a fixed development user ID
        return attach_user_to_request(req, "dev_user_id").await;
    }

    // Use jwt module defined in this file (via super)
    let claims = jwt::decode_token(&token).map_err(|e| {
        HttpResponse::Unauthorized().json(serde_json::json!({
            "error": e.to_string()
        }))
    })?;

    attach_user_to_request(req, &claims.sub).await
}
