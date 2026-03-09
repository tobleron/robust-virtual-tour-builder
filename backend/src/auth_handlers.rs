// @efficiency-role: service-orchestrator
use crate::auth::{AuthCallbackParams, AuthService, Claims};
use crate::models::AppError;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use chrono::{Duration, Utc};
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
use oauth2::basic::BasicClient;
use oauth2::{
    AuthUrl, ClientId, ClientSecret, CsrfToken, PkceCodeChallenge, RedirectUrl, Scope, TokenUrl,
};
use std::env;

pub(super) fn new_auth_service() -> Result<AuthService, AppError> {
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

    let client =
        BasicClient::new(client_id, Some(client_secret), auth_url, Some(token_url))
            .set_redirect_uri(
                RedirectUrl::new(env::var("GOOGLE_REDIRECT_URL").unwrap_or_else(|_| {
                    "http://localhost:8080/api/auth/google/callback".to_string()
                }))
                .map_err(|e| AppError::InternalError(format!("Invalid Redirect URL: {}", e)))?,
            );

    Ok(AuthService {
        google_client: client,
    })
}

pub(super) async fn google_login(
    auth_service: web::Data<AuthService>,
) -> Result<HttpResponse, AppError> {
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

pub(super) async fn google_callback(
    _params: web::Query<AuthCallbackParams>,
    _auth_service: web::Data<AuthService>,
) -> Result<HttpResponse, AppError> {
    Ok(HttpResponse::NotImplemented().finish())
}

pub(super) fn encode_token(
    sub: &str,
    step_up_verified_until: Option<usize>,
) -> Result<String, AppError> {
    let secret = env::var("JWT_SECRET")
        .map_err(|_| AppError::InternalError("JWT_SECRET must be set".to_string()))?;
    let expiration = Utc::now()
        .checked_add_signed(Duration::hours(24))
        .ok_or_else(|| AppError::InternalError("Timestamp overflow".to_string()))?
        .timestamp();

    let claims = Claims {
        sub: sub.to_owned(),
        iat: Utc::now().timestamp() as usize,
        exp: expiration as usize,
        step_up_verified_until,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::InternalError(format!("Token creation failed: {}", e)))
}

pub(super) fn decode_token(token: &str) -> Result<Claims, AppError> {
    let secret = env::var("JWT_SECRET")
        .map_err(|_| AppError::InternalError("JWT_SECRET must be set".to_string()))?;
    let validation = Validation::default();

    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )
    .map(|data| data.claims)
    .map_err(|e| AppError::Unauthorized(format!("Invalid token: {}", e)))
}

pub(super) fn is_step_up_verified(req: &HttpRequest) -> bool {
    if let Some(claims) = req.extensions().get::<Claims>() {
        if let Some(until_ts) = claims.step_up_verified_until {
            return (Utc::now().timestamp() as usize) <= until_ts;
        }
    }
    false
}

pub(super) fn require_step_up_verified(req: &HttpRequest) -> Result<(), AppError> {
    if is_step_up_verified(req) {
        Ok(())
    } else {
        Err(AppError::Unauthorized(
            "Step-up verification is required for this action.".into(),
        ))
    }
}
