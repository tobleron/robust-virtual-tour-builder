use crate::models::AppError;
use crate::services::auth::AuthService;
use actix_web::{HttpResponse, web};
use oauth2::{CsrfToken, PkceCodeChallenge, Scope};
use serde::Deserialize;

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
