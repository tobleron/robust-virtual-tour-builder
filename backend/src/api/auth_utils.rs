use crate::models::{AppError, User};
use actix_web::cookie::{Cookie, SameSite, time::Duration as CookieDuration};
use argon2::Argon2;
use argon2::password_hash::rand_core::OsRng;
use argon2::password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString};
use regex::Regex;
use sha2::{Digest, Sha256};
use uuid::Uuid;

use super::{AUTH_COOKIE_NAME, AuthPublicUser, DEVICE_COOKIE_NAME, DEVICE_TRUST_TTL_DAYS_DEFAULT};

pub(super) fn is_production() -> bool {
    crate::startup::is_production()
}

pub(super) fn config_i64(var_name: &str, default_value: i64) -> i64 {
    std::env::var(var_name)
        .ok()
        .and_then(|value| value.parse::<i64>().ok())
        .unwrap_or(default_value)
}

pub(super) fn normalize_email(input: &str) -> String {
    input.trim().to_lowercase()
}

pub(super) fn normalize_username(input: &str) -> String {
    input.trim().to_lowercase()
}

pub(super) fn validate_username(username: &str) -> Result<(), AppError> {
    let reserved = [
        "admin",
        "api",
        "auth",
        "builder",
        "dashboard",
        "home",
        "pricing",
        "signin",
        "signup",
        "account",
        "support",
        "about",
        "root",
        "system",
        "www",
    ];
    if reserved.contains(&username) {
        return Err(AppError::ValidationError(
            "Username is reserved. Choose another username.".into(),
        ));
    }
    if username.len() < 3 || username.len() > 30 {
        return Err(AppError::ValidationError(
            "Username must be between 3 and 30 characters.".into(),
        ));
    }
    let regex = Regex::new(r"^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$")
        .map_err(|error| AppError::InternalError(format!("Username regex build failed: {}", error)))?;
    if !regex.is_match(username) {
        return Err(AppError::ValidationError(
            "Username may only contain lowercase letters, numbers, and hyphens.".into(),
        ));
    }
    Ok(())
}

pub(super) fn validate_password(password: &str) -> Result<(), AppError> {
    if password.len() < 8 {
        return Err(AppError::ValidationError(
            "Password must be at least 8 characters.".into(),
        ));
    }
    Ok(())
}

pub(super) fn hash_password(password: &str) -> Result<String, AppError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|error| AppError::InternalError(format!("Password hashing failed: {}", error)))
}

pub(super) fn verify_password(password: &str, password_hash: &str) -> Result<bool, AppError> {
    let parsed_hash = PasswordHash::new(password_hash)
        .map_err(|error| AppError::InternalError(format!("Password hash parse failed: {}", error)))?;
    let argon2 = Argon2::default();
    Ok(argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

pub(super) fn hash_token(raw_token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(raw_token.as_bytes());
    format!("{:x}", hasher.finalize())
}

pub(super) fn make_device_token() -> String {
    format!("{}_{}", Uuid::new_v4(), Uuid::new_v4())
}

pub(super) fn hash_otp(raw_otp: &str) -> String {
    let pepper = std::env::var("OTP_PEPPER").unwrap_or_else(|_| "dev-otp-pepper".to_string());
    hash_token(&format!("{}:{}", pepper, raw_otp))
}

pub(super) fn generate_otp_code() -> String {
    let mut hasher = Sha256::new();
    hasher.update(Uuid::new_v4().to_string().as_bytes());
    let digest = hasher.finalize();
    let value = ((digest[0] as u32) << 16) | ((digest[1] as u32) << 8) | digest[2] as u32;
    let normalized = value % 900000 + 100000;
    normalized.to_string()
}

pub(super) fn create_auth_cookie(token: &str) -> Cookie<'static> {
    Cookie::build(AUTH_COOKIE_NAME, token.to_string())
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(super::is_production())
        .max_age(CookieDuration::hours(24))
        .finish()
}

pub(super) fn clear_auth_cookie() -> Cookie<'static> {
    Cookie::build(AUTH_COOKIE_NAME, "")
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(super::is_production())
        .max_age(CookieDuration::seconds(0))
        .finish()
}

pub(super) fn create_device_cookie(token: &str) -> Cookie<'static> {
    let trust_ttl_days = super::config_i64(
        "TRUSTED_DEVICE_TTL_DAYS",
        DEVICE_TRUST_TTL_DAYS_DEFAULT,
    );
    Cookie::build(DEVICE_COOKIE_NAME, token.to_string())
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(super::is_production())
        .max_age(CookieDuration::days(trust_ttl_days))
        .finish()
}

pub(super) fn public_user(user: &User) -> AuthPublicUser {
    AuthPublicUser {
        id: user.id.clone(),
        email: user.email.clone(),
        username: user.username.clone(),
        name: user.name.clone(),
        role: user.role.clone(),
        status: user.status.clone(),
        email_verified_at: user.email_verified_at.map(|timestamp| timestamp.to_rfc3339()),
    }
}
