// @efficiency-role: functional-service
use crate::models::{AppError, User};
use actix_web::{
    Error, HttpMessage, HttpResponse,
    body::{BoxBody, EitherBody},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
    http::header,
    web,
};
use chrono::{Duration, Utc};
use futures_util::future::LocalBoxFuture;
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
use oauth2::basic::BasicClient;
use oauth2::{
    AuthUrl, ClientId, ClientSecret, CsrfToken, PkceCodeChallenge, RedirectUrl, Scope, TokenUrl,
};
use serde::{Deserialize, Serialize};
use sqlx::SqlitePool;
use std::env;
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
        let client_id = ClientId::new(
            env::var("GOOGLE_CLIENT_ID")
                .map_err(|_| AppError::InternalError("GOOGLE_CLIENT_ID not set".into()))?,
        );
        let client_secret = ClientSecret::new(
            env::var("GOOGLE_CLIENT_SECRET")
                .map_err(|_| AppError::InternalError("GOOGLE_CLIENT_SECRET not set".into()))?,
        );
        let auth_url = AuthUrl::new("https://accounts.google.com/o/oauth2/v2/auth".to_string())
            .map_err(|e| AppError::InternalError(format!("Invalid Auth URL: {}", e)))?;
        let token_url = TokenUrl::new("https://www.googleapis.com/oauth2/v3/token".to_string())
            .map_err(|e| AppError::InternalError(format!("Invalid Token URL: {}", e)))?;

        let client = BasicClient::new(client_id, Some(client_secret), auth_url, Some(token_url))
            .set_redirect_uri(
                RedirectUrl::new(env::var("GOOGLE_REDIRECT_URL").unwrap_or_else(|_| {
                    "http://localhost:8080/api/auth/google/callback".to_string()
                }))
                .map_err(|e| AppError::InternalError(format!("Invalid Redirect URL: {}", e)))?,
            );

        Ok(Self {
            google_client: client,
        })
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
    let (pkce_challenge, _pkce_verifier) = PkceCodeChallenge::new_random_sha256();

    let (auth_url, _csrf_token) = auth_service
        .google_client
        .authorize_url(CsrfToken::new_random)
        .add_scope(Scope::new(
            "https://www.googleapis.com/auth/userinfo.email".to_string(),
        ))
        .add_scope(Scope::new(
            "https://www.googleapis.com/auth/userinfo.profile".to_string(),
        ))
        .set_pkce_challenge(pkce_challenge)
        .url();

    Ok(HttpResponse::Found()
        .append_header(("Location", auth_url.to_string()))
        .finish())
}

#[allow(dead_code)]
pub async fn google_callback(
    _params: web::Query<AuthCallbackParams>,
    _auth_service: web::Data<AuthService>,
) -> Result<HttpResponse, AppError> {
    Ok(HttpResponse::NotImplemented().finish())
}

// ==========================================
// JWT Logic
// ==========================================

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub exp: usize,
    pub iat: usize,
}

pub fn encode_token(sub: &str) -> Result<String, AppError> {
    let secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    let expiration = Utc::now()
        .checked_add_signed(Duration::hours(24))
        .expect("valid timestamp")
        .timestamp();

    let claims = Claims {
        sub: sub.to_owned(),
        iat: Utc::now().timestamp() as usize,
        exp: expiration as usize,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::InternalError(format!("Token creation failed: {}", e)))
}

pub fn decode_token(token: &str) -> Result<Claims, AppError> {
    let secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    let validation = Validation::default();

    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )
    .map(|data| data.claims)
    .map_err(|e| AppError::Unauthorized(format!("Invalid token: {}", e)))
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

fn extract_token(req: &ServiceRequest) -> Option<String> {
    if let Some(header) = req.headers().get(header::AUTHORIZATION) {
        if let Ok(header_str) = header.to_str() {
            if let Some(token) = header_str.strip_prefix("Bearer ") {
                return Some(token.to_string());
            }
        }
    }

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

    let dev_mode = cfg!(debug_assertions)
        || std::env::var("BYPASS_AUTH")
            .map(|v| v == "true")
            .unwrap_or(false);

    if dev_mode && token.trim() == "dev-token" {
        tracing::warn!("⚠️  Using DEV_TOKEN bypass for authentication");
        return attach_user_to_request(req, "dev_user_id").await;
    }

    let claims = decode_token(&token).map_err(|e| {
        HttpResponse::Unauthorized().json(serde_json::json!({
            "error": e.to_string()
        }))
    })?;

    attach_user_to_request(req, &claims.sub).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encode_decode_token() {
        unsafe {
            std::env::set_var("JWT_SECRET", "test_secret");
        }

        let sub = "test_user_id";
        let token = encode_token(sub).expect("Token encoding failed");

        assert!(!token.is_empty());

        let claims = decode_token(&token).expect("Token decoding failed");
        assert_eq!(claims.sub, sub);
    }
}
