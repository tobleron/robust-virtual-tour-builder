#[allow(dead_code)]
pub mod jwt {
    // @efficiency: infra-adapter
    use crate::models::AppError;
    use chrono::{Duration, Utc};
    use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
    use serde::{Deserialize, Serialize};
    use std::env;

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

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn test_encode_decode_token() {
            // Set env var for testing
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
}

use crate::models::AppError;
use oauth2::basic::BasicClient;
use oauth2::{AuthUrl, ClientId, ClientSecret, RedirectUrl, TokenUrl};
use std::env;

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
