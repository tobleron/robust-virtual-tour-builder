// @efficiency-role: service-orchestrator
use crate::models::AppError;
use actix_web::{HttpResponse, web};
use oauth2::basic::BasicClient;
use oauth2::{
    AuthUrl, ClientId, ClientSecret, CsrfToken, PkceCodeChallenge, RedirectUrl, Scope, TokenUrl,
};
use serde::Deserialize;
use std::env;

pub mod jwt;
pub mod middleware;

pub use middleware::AuthMiddleware;

// ==========================================
// Service
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

// ==========================================
// Handlers
// ==========================================

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

    // In a real app, store state/pkce in a secure cookie or session
    Ok(HttpResponse::Found()
        .append_header(("Location", auth_url.to_string()))
        .finish())
}

#[allow(dead_code)]
pub async fn google_callback(
    _params: web::Query<AuthCallbackParams>,
    _auth_service: web::Data<AuthService>,
) -> Result<HttpResponse, AppError> {
    // 1. Exchange code for token
    // 2. Fetch user profile from Google
    // 3. Upsert user in SQLite
    // 4. Generate JWT
    // 5. Redirect to frontend with token
    Ok(HttpResponse::NotImplemented().finish())
}
