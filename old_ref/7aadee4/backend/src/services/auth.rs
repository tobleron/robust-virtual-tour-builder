use crate::models::AppError;
use oauth2::basic::BasicClient;
use oauth2::{AuthUrl, ClientId, ClientSecret, RedirectUrl, TokenUrl};
use std::env;

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
        let auth_url =
            AuthUrl::new("https://accounts.google.com/o/oauth2/v2/auth".to_string()).unwrap();
        let token_url =
            TokenUrl::new("https://www.googleapis.com/oauth2/v3/token".to_string()).unwrap();

        let client = BasicClient::new(client_id, Some(client_secret), auth_url, Some(token_url))
            .set_redirect_uri(
                RedirectUrl::new(env::var("GOOGLE_REDIRECT_URL").unwrap_or_else(|_| {
                    "http://localhost:8080/api/auth/google/callback".to_string()
                }))
                .unwrap(),
            );

        Ok(Self {
            google_client: client,
        })
    }
}
