use crate::models::AppError;
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
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
        let token = encode_token(sub).unwrap();

        assert!(!token.is_empty());

        let claims = decode_token(&token).unwrap();
        assert_eq!(claims.sub, sub);
    }
}
