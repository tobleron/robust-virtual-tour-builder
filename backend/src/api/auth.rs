use crate::auth::encode_token;
use crate::models::{AppError, User};
use actix_web::cookie::{Cookie, SameSite, time::Duration as CookieDuration};
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use argon2::Argon2;
use argon2::password_hash::rand_core::OsRng;
use argon2::password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString};
use chrono::{Duration, Utc};
use regex::Regex;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use sqlx::SqlitePool;
use uuid::Uuid;

const VERIFICATION_TOKEN_TTL_HOURS: i64 = 24;
const PASSWORD_RESET_TOKEN_TTL_HOURS: i64 = 2;
const OTP_TTL_MINUTES: i64 = 10;
const OTP_MAX_ATTEMPTS: i64 = 5;
const AUTH_COOKIE_NAME: &str = "auth_token";
const DEVICE_COOKIE_NAME: &str = "rvtb_device";
const OTP_RESEND_COOLDOWN_SECONDS_DEFAULT: i64 = 45;
const DEVICE_INACTIVITY_CHALLENGE_DAYS_DEFAULT: i64 = 7;
const DEVICE_TRUST_TTL_DAYS_DEFAULT: i64 = 30;
const STEP_UP_SESSION_HOURS_DEFAULT: i64 = 12;
const MAX_OTP_ISSUES_PER_HOUR_DEFAULT: i64 = 8;
const MAX_FAILED_LOGIN_BY_ACCOUNT_WINDOW_DEFAULT: i64 = 7;
const MAX_FAILED_LOGIN_BY_IP_WINDOW_DEFAULT: i64 = 15;
const FAILED_LOGIN_WINDOW_MINUTES: i64 = 15;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SignUpPayload {
    pub email: String,
    pub username: String,
    pub password: String,
    pub display_name: Option<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SignInPayload {
    pub email: String,
    pub password: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VerifyOtpPayload {
    pub challenge_id: String,
    pub otp_code: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ResendOtpPayload {
    pub challenge_id: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VerifyEmailPayload {
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct ResendVerificationPayload {
    pub email: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ForgotPasswordPayload {
    pub email: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ResetPasswordPayload {
    pub token: String,
    pub new_password: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthPublicUser {
    pub id: String,
    pub email: String,
    pub username: Option<String>,
    pub name: String,
    pub role: String,
    pub status: Option<String>,
    pub email_verified_at: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthSuccessResponse {
    pub token: String,
    pub user: AuthPublicUser,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthChallengeResponse {
    pub challenge_required: bool,
    pub challenge_id: String,
    pub message: String,
    pub expires_at: String,
    pub resend_available_at: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MeResponse {
    pub authenticated: bool,
    pub user: Option<AuthPublicUser>,
}

#[derive(Debug, Clone)]
struct LoginContext {
    ip_address: Option<String>,
    user_agent: Option<String>,
    user_agent_family: Option<String>,
    timezone: Option<String>,
    language: Option<String>,
    country: Option<String>,
    region: Option<String>,
    lat: Option<f64>,
    lon: Option<f64>,
}

#[derive(Debug, Clone)]
struct TrustedDeviceRecord {
    last_seen_at: chrono::DateTime<Utc>,
    trust_expires_at: chrono::DateTime<Utc>,
    user_agent_family: Option<String>,
    last_timezone: Option<String>,
    last_language: Option<String>,
}

#[derive(Debug)]
struct RiskDecision {
    score: i64,
    reasons: Vec<String>,
    hard_trigger: bool,
}

#[derive(Debug)]
enum IpReputation {
    Good,
    Bad(String),
    Unknown,
}

fn is_production() -> bool {
    crate::startup::is_production()
}

fn config_i64(var_name: &str, default_value: i64) -> i64 {
    std::env::var(var_name)
        .ok()
        .and_then(|v| v.parse::<i64>().ok())
        .unwrap_or(default_value)
}

fn normalize_email(input: &str) -> String {
    input.trim().to_lowercase()
}

fn normalize_username(input: &str) -> String {
    input.trim().to_lowercase()
}

fn validate_username(username: &str) -> Result<(), AppError> {
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
        .map_err(|e| AppError::InternalError(format!("Username regex build failed: {}", e)))?;
    if !regex.is_match(username) {
        return Err(AppError::ValidationError(
            "Username may only contain lowercase letters, numbers, and hyphens.".into(),
        ));
    }
    Ok(())
}

fn validate_password(password: &str) -> Result<(), AppError> {
    if password.len() < 8 {
        return Err(AppError::ValidationError(
            "Password must be at least 8 characters.".into(),
        ));
    }
    Ok(())
}

fn hash_password(password: &str) -> Result<String, AppError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|e| AppError::InternalError(format!("Password hashing failed: {}", e)))
}

fn verify_password(password: &str, password_hash: &str) -> Result<bool, AppError> {
    let parsed_hash = PasswordHash::new(password_hash)
        .map_err(|e| AppError::InternalError(format!("Password hash parse failed: {}", e)))?;
    let argon2 = Argon2::default();
    Ok(argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

fn hash_token(raw_token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(raw_token.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn make_device_token() -> String {
    format!("{}_{}", Uuid::new_v4(), Uuid::new_v4())
}

fn hash_otp(raw_otp: &str) -> String {
    let pepper = std::env::var("OTP_PEPPER").unwrap_or_else(|_| "dev-otp-pepper".to_string());
    hash_token(&format!("{}:{}", pepper, raw_otp))
}

fn generate_otp_code() -> String {
    let mut hasher = Sha256::new();
    hasher.update(Uuid::new_v4().to_string().as_bytes());
    let digest = hasher.finalize();
    let value = ((digest[0] as u32) << 16) | ((digest[1] as u32) << 8) | digest[2] as u32;
    let normalized = value % 900000 + 100000;
    normalized.to_string()
}

fn create_auth_cookie(token: &str) -> Cookie<'static> {
    Cookie::build(AUTH_COOKIE_NAME, token.to_string())
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(is_production())
        .max_age(CookieDuration::hours(24))
        .finish()
}

fn clear_auth_cookie() -> Cookie<'static> {
    Cookie::build(AUTH_COOKIE_NAME, "")
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(is_production())
        .max_age(CookieDuration::seconds(0))
        .finish()
}

fn create_device_cookie(token: &str) -> Cookie<'static> {
    let trust_ttl_days = config_i64("TRUSTED_DEVICE_TTL_DAYS", DEVICE_TRUST_TTL_DAYS_DEFAULT);
    Cookie::build(DEVICE_COOKIE_NAME, token.to_string())
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(is_production())
        .max_age(CookieDuration::days(trust_ttl_days))
        .finish()
}

fn public_user(user: &User) -> AuthPublicUser {
    AuthPublicUser {
        id: user.id.clone(),
        email: user.email.clone(),
        username: user.username.clone(),
        name: user.name.clone(),
        role: user.role.clone(),
        status: user.status.clone(),
        email_verified_at: user.email_verified_at.map(|ts| ts.to_rfc3339()),
    }
}

async fn send_email_or_log(to_email: &str, subject: &str, html_body: &str) -> Result<(), AppError> {
    let resend_api_key = std::env::var("RESEND_API_KEY").ok();
    let sender = std::env::var("EMAIL_FROM").unwrap_or_else(|_| "no-reply@robust-vtb.com".into());

    if let Some(api_key) = resend_api_key {
        let payload = serde_json::json!({
            "from": sender,
            "to": [to_email],
            "subject": subject,
            "html": html_body,
        });
        let client = reqwest::Client::new();
        let response = client
            .post("https://api.resend.com/emails")
            .header("Authorization", format!("Bearer {}", api_key))
            .header("Content-Type", "application/json")
            .json(&payload)
            .send()
            .await
            .map_err(|e| {
                AppError::InternalError(format!("Email provider request failed: {}", e))
            })?;

        if !response.status().is_success() {
            let body = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown email provider error".to_string());
            return Err(AppError::InternalError(format!(
                "Email provider rejected request: {}",
                body
            )));
        }
        Ok(())
    } else {
        tracing::warn!(
            module = "AuthApi",
            to = %to_email,
            subject = %subject,
            "RESEND_API_KEY missing; email not sent via provider (logged for dev fallback)"
        );
        tracing::info!(module = "AuthApi", body = %html_body, "EMAIL_DEV_FALLBACK_BODY");
        if is_production() {
            return Err(AppError::InternalError(
                "Email provider is not configured in production.".into(),
            ));
        }
        Ok(())
    }
}

fn app_base_url() -> String {
    std::env::var("APP_BASE_URL").unwrap_or_else(|_| "http://localhost:3000".to_string())
}

async fn issue_verification_email(pool: &SqlitePool, user_id: &str, email: &str) -> Result<(), AppError> {
    let now = Utc::now();
    sqlx::query(
        r#"
        UPDATE email_verification_tokens
        SET consumed_at = ?
        WHERE user_id = ? AND consumed_at IS NULL
        "#,
    )
    .bind(now)
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(|e| AppError::InternalError(format!("Verification token invalidate failed: {}", e)))?;

    let raw_token = format!("{}_{}", Uuid::new_v4(), Uuid::new_v4());
    let token_hash = hash_token(&raw_token);
    let expires_at = now + Duration::hours(VERIFICATION_TOKEN_TTL_HOURS);

    sqlx::query(
        r#"
        INSERT INTO email_verification_tokens (id, user_id, token_hash, expires_at)
        VALUES (?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(user_id)
    .bind(&token_hash)
    .bind(expires_at)
    .execute(pool)
    .await
    .map_err(|e| AppError::InternalError(format!("Verification token insert failed: {}", e)))?;

    let verify_url = format!("{}/verify-email?token={}", app_base_url(), raw_token);
    let email_body = format!(
        "<p>Welcome to Robust Virtual Tour Builder.</p><p>Verify your email: <a href=\"{0}\">{0}</a></p>",
        verify_url
    );
    send_email_or_log(email, "Verify your Robust account", &email_body).await
}

fn extract_login_context(req: &HttpRequest) -> LoginContext {
    let ip_address = req
        .connection_info()
        .realip_remote_addr()
        .map(|s| s.split(':').next().unwrap_or(s).to_string());
    let user_agent = req
        .headers()
        .get("User-Agent")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());
    let user_agent_family = user_agent.as_deref().and_then(parse_user_agent_family);
    let timezone = req
        .headers()
        .get("X-Client-Timezone")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());
    let language = req
        .headers()
        .get("Accept-Language")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.split(',').next().unwrap_or(s).trim().to_string());
    let country = req
        .headers()
        .get("X-Geo-Country")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());
    let region = req
        .headers()
        .get("X-Geo-Region")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());
    let lat = req
        .headers()
        .get("X-Geo-Lat")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.parse::<f64>().ok());
    let lon = req
        .headers()
        .get("X-Geo-Lon")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.parse::<f64>().ok());

    LoginContext {
        ip_address,
        user_agent,
        user_agent_family,
        timezone,
        language,
        country,
        region,
        lat,
        lon,
    }
}

fn empty_login_context() -> LoginContext {
    LoginContext {
        ip_address: None,
        user_agent: None,
        user_agent_family: None,
        timezone: None,
        language: None,
        country: None,
        region: None,
        lat: None,
        lon: None,
    }
}

fn parse_user_agent_family(ua: &str) -> Option<String> {
    let lowered = ua.to_lowercase();
    if lowered.contains("edg/") {
        return Some("edge".to_string());
    }
    if lowered.contains("chrome/") {
        return Some("chrome".to_string());
    }
    if lowered.contains("firefox/") {
        return Some("firefox".to_string());
    }
    if lowered.contains("safari/") && !lowered.contains("chrome/") {
        return Some("safari".to_string());
    }
    if lowered.contains("opera/") || lowered.contains("opr/") {
        return Some("opera".to_string());
    }
    None
}

fn evaluate_ip_reputation(req: &HttpRequest) -> IpReputation {
    let reputation = req
        .headers()
        .get("X-IP-Reputation")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_lowercase());
    match reputation.as_deref() {
        Some("bad") => IpReputation::Bad("ip_reputation_bad".to_string()),
        Some("proxy") => IpReputation::Bad("ip_proxy_detected".to_string()),
        Some("vpn") => IpReputation::Bad("ip_vpn_detected".to_string()),
        Some("tor") => IpReputation::Bad("ip_tor_detected".to_string()),
        Some("hosting") => IpReputation::Bad("ip_hosting_network".to_string()),
        Some("good") => IpReputation::Good,
        _ => IpReputation::Unknown,
    }
}

async fn log_auth_event(
    pool: &SqlitePool,
    user_id: Option<&str>,
    event_type: &str,
    decision: &str,
    risk_score: Option<i64>,
    reason: Option<&str>,
    context: &LoginContext,
    extra_json: Option<&str>,
) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT INTO auth_events (
            id, user_id, event_type, decision, risk_score, reason, ip_address, user_agent,
            country, region, lat, lon, timezone, language, extra_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(user_id)
    .bind(event_type)
    .bind(decision)
    .bind(risk_score)
    .bind(reason)
    .bind(context.ip_address.clone())
    .bind(context.user_agent.clone())
    .bind(context.country.clone())
    .bind(context.region.clone())
    .bind(context.lat)
    .bind(context.lon)
    .bind(context.timezone.clone())
    .bind(context.language.clone())
    .bind(extra_json)
    .execute(pool)
    .await
    .map_err(|e| AppError::InternalError(format!("Auth event insert failed: {}", e)))?;
    Ok(())
}

async fn log_login_attempt(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
    success: bool,
    failure_reason: Option<&str>,
) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT INTO login_attempts (id, user_id, email, ip_address, device_token_hash, success, failure_reason)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(user_id)
    .bind(email)
    .bind(context.ip_address.clone())
    .bind(device_token_hash)
    .bind(if success { 1 } else { 0 })
    .bind(failure_reason)
    .execute(pool)
    .await
    .map_err(|e| AppError::InternalError(format!("Login attempt insert failed: {}", e)))?;
    Ok(())
}

async fn find_trusted_device(
    pool: &SqlitePool,
    user_id: &str,
    raw_device_token: Option<&str>,
) -> Result<Option<TrustedDeviceRecord>, AppError> {
    let Some(raw_device_token) = raw_device_token else {
        return Ok(None);
    };
    let token_hash = hash_token(raw_device_token);
    let row = sqlx::query_as::<
        _,
        (
            chrono::DateTime<Utc>,
            chrono::DateTime<Utc>,
            Option<String>,
            Option<String>,
            Option<String>,
        ),
    >(
        r#"
        SELECT last_seen_at, trust_expires_at, user_agent_family, last_timezone, last_language
        FROM trusted_devices
        WHERE user_id = ? AND device_token_hash = ? AND revoked_at IS NULL
        "#,
    )
    .bind(user_id)
    .bind(token_hash)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::InternalError(format!("Trusted device lookup failed: {}", e)))?;

    Ok(row.map(
        |(last_seen_at, trust_expires_at, user_agent_family, last_timezone, last_language)| {
            TrustedDeviceRecord {
                last_seen_at,
                trust_expires_at,
                user_agent_family,
                last_timezone,
                last_language,
            }
        },
    ))
}

async fn load_last_success_login_context(
    pool: &SqlitePool,
    user_id: &str,
) -> Result<
    Option<(
        chrono::DateTime<Utc>,
        Option<String>,
        Option<String>,
        Option<f64>,
        Option<f64>,
    )>,
    AppError,
> {
    let row = sqlx::query_as::<
        _,
        (
            chrono::DateTime<Utc>,
            Option<String>,
            Option<String>,
            Option<f64>,
            Option<f64>,
        ),
    >(
        r#"
        SELECT created_at, country, region, lat, lon
        FROM auth_events
        WHERE user_id = ? AND event_type = 'signin_success'
        ORDER BY created_at DESC
        LIMIT 1
        "#,
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| {
        AppError::InternalError(format!("Last success auth event lookup failed: {}", e))
    })?;
    Ok(row)
}

async fn count_recent_failed_logins(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
) -> Result<(i64, i64), AppError> {
    let window_start = Utc::now() - Duration::minutes(FAILED_LOGIN_WINDOW_MINUTES);
    let account_failed = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM login_attempts
        WHERE success = 0
          AND email = ?
          AND created_at >= ?
        "#,
    )
    .bind(email)
    .bind(window_start)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        AppError::InternalError(format!("Recent failed login(account) query failed: {}", e))
    })?;

    let ip_failed = if let Some(ip) = context.ip_address.clone() {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE success = 0
              AND ip_address = ?
              AND created_at >= ?
            "#,
        )
        .bind(ip)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Recent failed login(ip) query failed: {}", e))
        })?
    } else {
        0
    };

    let device_failed = if let Some(device_hash) = device_token_hash {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE success = 0
              AND device_token_hash = ?
              AND created_at >= ?
            "#,
        )
        .bind(device_hash)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Recent failed login(device) query failed: {}", e))
        })?
    } else {
        0
    };

    if let Some(uid) = user_id {
        let user_failed = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE success = 0
              AND user_id = ?
              AND created_at >= ?
            "#,
        )
        .bind(uid)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Recent failed login(user) query failed: {}", e))
        })?;
        Ok((
            account_failed.max(user_failed).max(device_failed),
            ip_failed,
        ))
    } else {
        Ok((account_failed.max(device_failed), ip_failed))
    }
}

async fn enforce_failed_login_rate_limit(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
) -> Result<(), AppError> {
    let (account_failed, ip_failed) =
        count_recent_failed_logins(pool, user_id, email, context, device_token_hash).await?;
    let account_limit = config_i64(
        "MAX_FAILED_LOGIN_BY_ACCOUNT_WINDOW",
        MAX_FAILED_LOGIN_BY_ACCOUNT_WINDOW_DEFAULT,
    );
    let ip_limit = config_i64(
        "MAX_FAILED_LOGIN_BY_IP_WINDOW",
        MAX_FAILED_LOGIN_BY_IP_WINDOW_DEFAULT,
    );
    if account_failed >= account_limit || ip_failed >= ip_limit {
        return Err(AppError::Unauthorized(
            "Too many recent failed login attempts. Please wait and try again.".into(),
        ));
    }
    Ok(())
}

fn haversine_km(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    let r = 6371.0_f64;
    let dlat = (lat2 - lat1).to_radians();
    let dlon = (lon2 - lon1).to_radians();
    let a = (dlat / 2.0).sin() * (dlat / 2.0).sin()
        + lat1.to_radians().cos()
            * lat2.to_radians().cos()
            * (dlon / 2.0).sin()
            * (dlon / 2.0).sin();
    let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());
    r * c
}

fn evaluate_geo_anomaly(
    last_success: Option<&(
        chrono::DateTime<Utc>,
        Option<String>,
        Option<String>,
        Option<f64>,
        Option<f64>,
    )>,
    context: &LoginContext,
) -> bool {
    let Some((last_at, last_country, last_region, last_lat, last_lon)) = last_success else {
        return false;
    };
    if let (Some(lat1), Some(lon1), Some(lat2), Some(lon2)) =
        (*last_lat, *last_lon, context.lat, context.lon)
    {
        let distance_km = haversine_km(lat1, lon1, lat2, lon2);
        let hours = (Utc::now() - *last_at).num_minutes() as f64 / 60.0;
        if hours > 0.0 && distance_km > 1200.0 && hours < 4.0 {
            return true;
        }
    }
    let country_changed = match (last_country.as_deref(), context.country.as_deref()) {
        (Some(prev), Some(now)) => prev != now,
        _ => false,
    };
    let region_changed = match (last_region.as_deref(), context.region.as_deref()) {
        (Some(prev), Some(now)) => prev != now,
        _ => false,
    };
    country_changed && region_changed
}

fn evaluate_context_mismatch(
    trusted_device: Option<&TrustedDeviceRecord>,
    context: &LoginContext,
    risk_reasons_count_before: usize,
) -> bool {
    let Some(device) = trusted_device else {
        return false;
    };
    let ua_jump = match (
        device.user_agent_family.as_deref(),
        context.user_agent_family.as_deref(),
    ) {
        (Some(prev), Some(now)) => prev != now,
        _ => false,
    };
    let tz_jump = match (device.last_timezone.as_deref(), context.timezone.as_deref()) {
        (Some(prev), Some(now)) => prev != now,
        _ => false,
    };
    let lang_jump = match (device.last_language.as_deref(), context.language.as_deref()) {
        (Some(prev), Some(now)) => prev != now,
        _ => false,
    };
    let has_secondary_signal = risk_reasons_count_before > 0;
    (ua_jump || (tz_jump && lang_jump)) && has_secondary_signal
}

async fn compute_risk_decision(
    pool: &SqlitePool,
    user: &User,
    email: &str,
    context: &LoginContext,
    trusted_device: Option<&TrustedDeviceRecord>,
    req: &HttpRequest,
    force_new_device_hard_trigger: bool,
) -> Result<RiskDecision, AppError> {
    let mut score = 0_i64;
    let mut reasons: Vec<String> = Vec::new();
    let mut hard_trigger = force_new_device_hard_trigger;

    if force_new_device_hard_trigger {
        score += 50;
        reasons.push("new_device".to_string());
    }

    let inactivity_days = config_i64(
        "STEP_UP_INACTIVITY_DAYS",
        DEVICE_INACTIVITY_CHALLENGE_DAYS_DEFAULT,
    );
    if let Some(device) = trusted_device {
        if Utc::now() > device.trust_expires_at
            || Utc::now() - device.last_seen_at >= Duration::days(inactivity_days)
        {
            score += 25;
            reasons.push("long_inactivity".to_string());
        }
    }

    let last_success = load_last_success_login_context(pool, &user.id).await?;
    if evaluate_geo_anomaly(last_success.as_ref(), context) {
        score += 40;
        reasons.push("geo_anomaly".to_string());
    }

    if let IpReputation::Bad(reason) = evaluate_ip_reputation(req) {
        score += 40;
        reasons.push(reason);
    }

    let (failed_account_or_user, failed_ip) =
        count_recent_failed_logins(pool, Some(&user.id), email, context, None).await?;
    if failed_account_or_user >= 3 || failed_ip >= 5 {
        score += 30;
        reasons.push("recent_failed_attempts".to_string());
    }

    if evaluate_context_mismatch(trusted_device, context, reasons.len()) {
        score += 20;
        reasons.push("context_mismatch".to_string());
    }

    if let Some(force_until) = user.force_step_up_until {
        if Utc::now() <= force_until {
            score += 60;
            hard_trigger = true;
            reasons.push(
                user.force_step_up_reason
                    .clone()
                    .unwrap_or_else(|| "forced_step_up".to_string()),
            );
        }
    }

    Ok(RiskDecision {
        score,
        reasons,
        hard_trigger,
    })
}

async fn issue_or_refresh_step_up_challenge(
    pool: &SqlitePool,
    user: &User,
    context: &LoginContext,
    risk: &RiskDecision,
    device_token_hash: Option<&str>,
) -> Result<(String, String, chrono::DateTime<Utc>, chrono::DateTime<Utc>), AppError> {
    let user_id = &user.id;
    let cooldown_secs = config_i64(
        "OTP_RESEND_COOLDOWN_SECONDS",
        OTP_RESEND_COOLDOWN_SECONDS_DEFAULT,
    );
    let now = Utc::now();

    sqlx::query(
        r#"
        UPDATE otp_challenges
        SET status = 'invalidated', consumed_at = ?
        WHERE user_id = ? AND status = 'pending'
        "#,
    )
    .bind(now)
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(|e| AppError::InternalError(format!("OTP challenge invalidation failed: {}", e)))?;

    let challenge_id = Uuid::new_v4().to_string();
    let otp_code = generate_otp_code();
    let otp_hash = hash_otp(&otp_code);
    let otp_expires_at = now + Duration::minutes(OTP_TTL_MINUTES);
    let resend_available_at = now + Duration::seconds(cooldown_secs);
    let reasons_json = serde_json::to_string(&risk.reasons).map_err(|e| {
        AppError::InternalError(format!("Risk reasons serialization failed: {}", e))
    })?;

    sqlx::query(
        r#"
        INSERT INTO otp_challenges (
            id, user_id, challenge_type, status, risk_score, risk_reasons_json, otp_hash,
            otp_expires_at, attempts_used, max_attempts, resend_available_at, resend_count,
            ip_address, user_agent, device_token_hash
        ) VALUES (?, ?, 'email_step_up', 'pending', ?, ?, ?, ?, 0, ?, ?, 0, ?, ?, ?)
        "#,
    )
    .bind(&challenge_id)
    .bind(user_id)
    .bind(risk.score)
    .bind(reasons_json)
    .bind(otp_hash)
    .bind(otp_expires_at)
    .bind(OTP_MAX_ATTEMPTS)
    .bind(resend_available_at)
    .bind(context.ip_address.clone())
    .bind(context.user_agent.clone())
    .bind(device_token_hash)
    .execute(pool)
    .await
    .map_err(|e| AppError::InternalError(format!("OTP challenge insert failed: {}", e)))?;

    Ok((challenge_id, otp_code, otp_expires_at, resend_available_at))
}

async fn enforce_otp_issue_rate_limit(
    pool: &SqlitePool,
    user_id: &str,
    context: &LoginContext,
) -> Result<(), AppError> {
    let max_per_hour = config_i64("MAX_OTP_ISSUES_PER_HOUR", MAX_OTP_ISSUES_PER_HOUR_DEFAULT);
    let window_start = Utc::now() - Duration::hours(1);
    let issued_by_user = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM otp_challenges WHERE user_id = ? AND issued_at >= ?",
    )
    .bind(user_id)
    .bind(window_start)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        AppError::InternalError(format!("OTP issue rate-limit(user) query failed: {}", e))
    })?;
    if issued_by_user >= max_per_hour {
        return Err(AppError::Unauthorized(
            "Too many verification code requests. Please try again later.".into(),
        ));
    }
    if let Some(ip) = context.ip_address.clone() {
        let issued_by_ip = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM otp_challenges WHERE ip_address = ? AND issued_at >= ?",
        )
        .bind(ip)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|e| {
            AppError::InternalError(format!("OTP issue rate-limit(ip) query failed: {}", e))
        })?;
        if issued_by_ip >= max_per_hour {
            return Err(AppError::Unauthorized(
                "Too many verification code requests. Please try again later.".into(),
            ));
        }
    }
    Ok(())
}

async fn upsert_trusted_device(
    pool: &SqlitePool,
    user_id: &str,
    raw_device_token: &str,
    context: &LoginContext,
) -> Result<(), AppError> {
    let trust_ttl_days = config_i64("TRUSTED_DEVICE_TTL_DAYS", DEVICE_TRUST_TTL_DAYS_DEFAULT);
    let token_hash = hash_token(raw_device_token);
    let now = Utc::now();
    let trust_expires_at = now + Duration::days(trust_ttl_days);

    let existing = sqlx::query_scalar::<_, String>(
        "SELECT id FROM trusted_devices WHERE user_id = ? AND device_token_hash = ?",
    )
    .bind(user_id)
    .bind(token_hash.clone())
    .fetch_optional(pool)
    .await
    .map_err(|e| {
        AppError::InternalError(format!("Trusted device pre-upsert lookup failed: {}", e))
    })?;

    if let Some(device_id) = existing {
        sqlx::query(
            r#"
            UPDATE trusted_devices
            SET user_agent = ?, user_agent_family = ?, last_ip = ?, last_country = ?, last_region = ?,
                last_lat = ?, last_lon = ?, last_timezone = ?, last_language = ?, last_seen_at = ?,
                trust_expires_at = ?, revoked_at = NULL
            WHERE id = ?
            "#,
        )
        .bind(context.user_agent.clone())
        .bind(context.user_agent_family.clone())
        .bind(context.ip_address.clone())
        .bind(context.country.clone())
        .bind(context.region.clone())
        .bind(context.lat)
        .bind(context.lon)
        .bind(context.timezone.clone())
        .bind(context.language.clone())
        .bind(now)
        .bind(trust_expires_at)
        .bind(device_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::InternalError(format!("Trusted device update failed: {}", e)))?;
    } else {
        sqlx::query(
            r#"
            INSERT INTO trusted_devices (
                id, user_id, device_token_hash, user_agent, user_agent_family, last_ip, last_country, last_region,
                last_lat, last_lon, last_timezone, last_language, first_seen_at, last_seen_at, trust_expires_at, revoked_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
            "#,
        )
        .bind(Uuid::new_v4().to_string())
        .bind(user_id)
        .bind(token_hash)
        .bind(context.user_agent.clone())
        .bind(context.user_agent_family.clone())
        .bind(context.ip_address.clone())
        .bind(context.country.clone())
        .bind(context.region.clone())
        .bind(context.lat)
        .bind(context.lon)
        .bind(context.timezone.clone())
        .bind(context.language.clone())
        .bind(now)
        .bind(now)
        .bind(trust_expires_at)
        .execute(pool)
        .await
        .map_err(|e| AppError::InternalError(format!("Trusted device insert failed: {}", e)))?;
    }

    Ok(())
}

pub async fn signup(
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignUpPayload>,
) -> Result<HttpResponse, AppError> {
    let payload = payload.into_inner();
    let email = normalize_email(&payload.email);
    let username = normalize_username(&payload.username);
    let password = payload.password.trim().to_string();
    let display_name = payload
        .display_name
        .unwrap_or_else(|| "Robust User".to_string())
        .trim()
        .to_string();

    validate_username(&username)?;
    validate_password(&password)?;

    let existing_email = sqlx::query_scalar::<_, String>("SELECT id FROM users WHERE email = ?")
        .bind(&email)
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("Signup email lookup failed: {}", e)))?;
    if existing_email.is_some() {
        return Err(AppError::ValidationError(
            "Email already registered.".into(),
        ));
    }

    let existing_username =
        sqlx::query_scalar::<_, String>("SELECT id FROM users WHERE username = ?")
            .bind(&username)
            .fetch_optional(pool.get_ref())
            .await
            .map_err(|e| {
                AppError::InternalError(format!("Signup username lookup failed: {}", e))
            })?;
    if existing_username.is_some() {
        return Err(AppError::ValidationError("Username already taken.".into()));
    }

    let password_hash = hash_password(&password)?;
    let user_id = Uuid::new_v4().to_string();

    sqlx::query(
        r#"
        INSERT INTO users (id, email, username, password_hash, name, role, status)
        VALUES (?, ?, ?, ?, ?, 'user', 'pending_verification')
        "#,
    )
    .bind(&user_id)
    .bind(&email)
    .bind(&username)
    .bind(&password_hash)
    .bind(&display_name)
    .execute(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("Signup user insert failed: {}", e)))?;

    issue_verification_email(pool.get_ref(), &user_id, &email).await?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "Account created. Please verify your email before signing in."
    })))
}

pub async fn resend_verification_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResendVerificationPayload>,
) -> Result<HttpResponse, AppError> {
    let email = normalize_email(&payload.email);
    let row = sqlx::query_as::<_, (String, Option<chrono::DateTime<Utc>>)>(
        r#"
        SELECT id, email_verified_at
        FROM users
        WHERE email = ?
        "#,
    )
    .bind(&email)
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("Resend verification user lookup failed: {}", e)))?;

    if let Some((user_id, email_verified_at)) = row {
        if email_verified_at.is_none() {
            issue_verification_email(pool.get_ref(), &user_id, &email).await?;
        }
    }

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "If this account exists and is not verified, a verification email has been sent."
    })))
}

pub async fn verify_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<VerifyEmailPayload>,
) -> Result<HttpResponse, AppError> {
    let token_hash = hash_token(payload.token.trim());
    let row = sqlx::query_as::<_, (String, chrono::DateTime<Utc>, Option<chrono::DateTime<Utc>>)>(
        r#"
        SELECT user_id, expires_at, consumed_at
        FROM email_verification_tokens
        WHERE token_hash = ?
        "#,
    )
    .bind(token_hash)
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("Verification token lookup failed: {}", e)))?;

    let (user_id, expires_at, consumed_at) = row.ok_or_else(|| {
        AppError::ValidationError("Verification token is invalid or expired.".into())
    })?;

    if consumed_at.is_some() || Utc::now() > expires_at {
        return Err(AppError::ValidationError(
            "Verification token is invalid or expired.".into(),
        ));
    }

    let now = Utc::now();
    sqlx::query("UPDATE users SET email_verified_at = ?, status = 'active' WHERE id = ?")
        .bind(now)
        .bind(&user_id)
        .execute(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("User verification update failed: {}", e)))?;

    sqlx::query("UPDATE email_verification_tokens SET consumed_at = ? WHERE token_hash = ?")
        .bind(now)
        .bind(hash_token(payload.token.trim()))
        .execute(pool.get_ref())
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Verification token consume failed: {}", e))
        })?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "Email verified successfully. You can now sign in."
    })))
}

pub async fn signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignInPayload>,
) -> Result<HttpResponse, AppError> {
    let payload = payload.into_inner();
    let email = normalize_email(&payload.email);
    let context = extract_login_context(&req);
    let incoming_device_token = req
        .cookie(DEVICE_COOKIE_NAME)
        .map(|c| c.value().to_string());
    let incoming_device_hash = incoming_device_token.as_deref().map(hash_token);

    enforce_failed_login_rate_limit(
        pool.get_ref(),
        None,
        &email,
        &context,
        incoming_device_hash.as_deref(),
    )
    .await?;
    let user_opt = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
        .bind(email.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("Signin user lookup failed: {}", e)))?;
    let user = if let Some(user) = user_opt {
        user
    } else {
        log_login_attempt(
            pool.get_ref(),
            None,
            &email,
            &context,
            incoming_device_hash.as_deref(),
            false,
            Some("user_not_found"),
        )
        .await?;
        return Err(AppError::Unauthorized("Invalid credentials".into()));
    };

    enforce_failed_login_rate_limit(
        pool.get_ref(),
        Some(&user.id),
        &email,
        &context,
        incoming_device_hash.as_deref(),
    )
    .await?;
    let is_valid = verify_password(payload.password.trim(), &user.password_hash)?;
    if !is_valid {
        log_login_attempt(
            pool.get_ref(),
            Some(&user.id),
            &email,
            &context,
            incoming_device_hash.as_deref(),
            false,
            Some("password_mismatch"),
        )
        .await?;
        log_auth_event(
            pool.get_ref(),
            Some(&user.id),
            "signin_failed",
            "denied",
            None,
            Some("invalid_password"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::Unauthorized("Invalid credentials".into()));
    }

    if user.email_verified_at.is_none() {
        log_login_attempt(
            pool.get_ref(),
            Some(&user.id),
            &email,
            &context,
            incoming_device_hash.as_deref(),
            false,
            Some("email_not_verified"),
        )
        .await?;
        return Err(AppError::Unauthorized(
            "Email is not verified yet. Please verify before signing in.".into(),
        ));
    }

    let trusted_device =
        find_trusted_device(pool.get_ref(), &user.id, incoming_device_token.as_deref()).await?;
    let force_new_device_hard_trigger = trusted_device.is_none();
    let risk = compute_risk_decision(
        pool.get_ref(),
        &user,
        &email,
        &context,
        trusted_device.as_ref(),
        &req,
        force_new_device_hard_trigger,
    )
    .await?;

    let should_challenge = risk.hard_trigger || risk.score >= 50;
    if should_challenge {
        enforce_otp_issue_rate_limit(pool.get_ref(), &user.id, &context).await?;
        let (challenge_id, otp_code, otp_expires_at, resend_available_at) =
            issue_or_refresh_step_up_challenge(
                pool.get_ref(),
                &user,
                &context,
                &risk,
                incoming_device_hash.as_deref(),
            )
            .await?;
        let subject = "Your Robust sign-in verification code";
        let body = format!(
            "<p>We sent this code because we detected a risky sign-in.</p><p><strong>{}</strong></p><p>This code expires in 10 minutes.</p>",
            otp_code
        );
        send_email_or_log(&user.email, subject, &body).await?;

        log_login_attempt(
            pool.get_ref(),
            Some(&user.id),
            &email,
            &context,
            incoming_device_hash.as_deref(),
            true,
            Some("password_ok_challenge_required"),
        )
        .await?;
        let reasons_json = serde_json::to_string(&risk.reasons).map_err(|e| {
            AppError::InternalError(format!("Risk reasons serialization failed: {}", e))
        })?;
        log_auth_event(
            pool.get_ref(),
            Some(&user.id),
            "step_up_otp_issued",
            "challenge",
            Some(risk.score),
            Some("risk_threshold_or_hard_trigger"),
            &context,
            Some(&reasons_json),
        )
        .await?;

        return Ok(HttpResponse::Accepted().json(AuthChallengeResponse {
            challenge_required: true,
            challenge_id,
            message: "We sent a verification code to your email.".to_string(),
            expires_at: otp_expires_at.to_rfc3339(),
            resend_available_at: resend_available_at.to_rfc3339(),
        }));
    }

    let current_device_token = incoming_device_token.unwrap_or_else(make_device_token);
    upsert_trusted_device(pool.get_ref(), &user.id, &current_device_token, &context).await?;
    let device_cookie = create_device_cookie(&current_device_token);
    let step_up_hours = config_i64("STEP_UP_SESSION_HOURS", STEP_UP_SESSION_HOURS_DEFAULT);
    let step_up_until = Some((Utc::now() + Duration::hours(step_up_hours)).timestamp() as usize);
    let token = encode_token(&user.id, step_up_until)?;
    let auth_cookie = create_auth_cookie(&token);
    log_login_attempt(
        pool.get_ref(),
        Some(&user.id),
        &email,
        &context,
        Some(&hash_token(&current_device_token)),
        true,
        None,
    )
    .await?;
    log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "signin_success",
        "allow",
        Some(risk.score),
        Some("trusted_login_no_step_up"),
        &context,
        None,
    )
    .await?;

    Ok(HttpResponse::Ok()
        .cookie(auth_cookie)
        .cookie(device_cookie)
        .json(AuthSuccessResponse {
            token,
            user: public_user(&user),
        }))
}

pub async fn signout() -> Result<HttpResponse, AppError> {
    let cookie = clear_auth_cookie();
    Ok(HttpResponse::Ok().cookie(cookie).json(serde_json::json!({
        "ok": true
    })))
}

pub async fn me(req: HttpRequest) -> Result<HttpResponse, AppError> {
    let user_opt = req.extensions().get::<User>().cloned();
    match user_opt {
        Some(user) => Ok(HttpResponse::Ok().json(MeResponse {
            authenticated: true,
            user: Some(public_user(&user)),
        })),
        None => Ok(HttpResponse::Unauthorized().json(MeResponse {
            authenticated: false,
            user: None,
        })),
    }
}

pub async fn forgot_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ForgotPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    let email = normalize_email(&payload.email);
    let user_opt = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
        .bind(email.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Forgot-password user lookup failed: {}", e))
        })?;

    if let Some(user) = user_opt {
        let raw_token = format!("{}_{}", Uuid::new_v4(), Uuid::new_v4());
        let token_hash = hash_token(&raw_token);
        let expires_at = Utc::now() + Duration::hours(PASSWORD_RESET_TOKEN_TTL_HOURS);

        sqlx::query(
            r#"
            INSERT INTO password_reset_tokens (id, user_id, token_hash, expires_at)
            VALUES (?, ?, ?, ?)
            "#,
        )
        .bind(Uuid::new_v4().to_string())
        .bind(user.id)
        .bind(token_hash)
        .bind(expires_at)
        .execute(pool.get_ref())
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Password reset token insert failed: {}", e))
        })?;

        let reset_url = format!("{}/reset-password?token={}", app_base_url(), raw_token);
        let email_body = format!(
            "<p>You requested a password reset.</p><p>Reset link: <a href=\"{0}\">{0}</a></p>",
            reset_url
        );
        send_email_or_log(&email, "Reset your Robust password", &email_body).await?;
    }

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "If the email exists, a password reset link has been sent."
    })))
}

pub async fn reset_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResetPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    validate_password(payload.new_password.trim())?;
    let hashed_lookup = hash_token(payload.token.trim());
    let row = sqlx::query_as::<_, (String, chrono::DateTime<Utc>, Option<chrono::DateTime<Utc>>)>(
        r#"
        SELECT user_id, expires_at, consumed_at
        FROM password_reset_tokens
        WHERE token_hash = ?
        "#,
    )
    .bind(hashed_lookup.clone())
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("Reset token lookup failed: {}", e)))?;

    let (user_id, expires_at, consumed_at) =
        row.ok_or_else(|| AppError::ValidationError("Reset token is invalid or expired.".into()))?;
    if consumed_at.is_some() || Utc::now() > expires_at {
        return Err(AppError::ValidationError(
            "Reset token is invalid or expired.".into(),
        ));
    }

    let new_hash = hash_password(payload.new_password.trim())?;
    sqlx::query("UPDATE users SET password_hash = ? WHERE id = ?")
        .bind(new_hash)
        .bind(user_id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("Password update failed: {}", e)))?;

    let forced_until = Utc::now() + Duration::days(3);
    sqlx::query(
        "UPDATE users SET force_step_up_reason = 'password_reset_flow', force_step_up_until = ? WHERE id = ?",
    )
    .bind(forced_until)
    .bind(user_id.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("Forced step-up set failed: {}", e)))?;

    sqlx::query("UPDATE trusted_devices SET revoked_at = ? WHERE user_id = ?")
        .bind(Utc::now())
        .bind(user_id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Trusted device revocation on reset failed: {}", e))
        })?;

    let context = empty_login_context();
    log_auth_event(
        pool.get_ref(),
        Some(&user_id),
        "password_reset_completed",
        "challenge_required_next_login",
        Some(60),
        Some("password_reset_flow"),
        &context,
        None,
    )
    .await?;

    sqlx::query("UPDATE password_reset_tokens SET consumed_at = ? WHERE token_hash = ?")
        .bind(Utc::now())
        .bind(hashed_lookup)
        .execute(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("Reset token consume failed: {}", e)))?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "Password reset successful. Please sign in."
    })))
}

pub async fn verify_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<VerifyOtpPayload>,
) -> Result<HttpResponse, AppError> {
    let context = extract_login_context(&req);
    let challenge_id = payload.challenge_id.trim();
    let otp_code = payload.otp_code.trim();
    if otp_code.len() < 6 {
        return Err(AppError::ValidationError(
            "Verification code must be at least 6 characters.".into(),
        ));
    }

    let challenge = sqlx::query_as::<
        _,
        (
            String,
            String,
            String,
            chrono::DateTime<Utc>,
            i64,
            i64,
            i64,
            Option<String>,
            Option<String>,
        ),
    >(
        r#"
        SELECT id, user_id, otp_hash, otp_expires_at, attempts_used, max_attempts, risk_score, status, device_token_hash
        FROM otp_challenges
        WHERE id = ?
        "#,
    )
    .bind(challenge_id)
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("OTP challenge lookup failed: {}", e)))?
    .ok_or_else(|| AppError::ValidationError("Verification challenge not found.".into()))?;

    let (
        challenge_id_db,
        user_id,
        otp_hash_db,
        otp_expires_at,
        attempts_used,
        max_attempts,
        risk_score,
        status,
        challenge_device_hash,
    ) = challenge;

    if status.as_deref() != Some("pending") {
        return Err(AppError::ValidationError(
            "Verification challenge is no longer active.".into(),
        ));
    }

    if Utc::now() > otp_expires_at {
        sqlx::query("UPDATE otp_challenges SET status = 'expired', consumed_at = ? WHERE id = ?")
            .bind(Utc::now())
            .bind(challenge_id_db.clone())
            .execute(pool.get_ref())
            .await
            .map_err(|e| AppError::InternalError(format!("OTP expiration update failed: {}", e)))?;
        log_auth_event(
            pool.get_ref(),
            Some(&user_id),
            "step_up_otp_expired",
            "denied",
            Some(risk_score),
            Some("otp_expired"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::ValidationError(
            "Verification code expired.".into(),
        ));
    }

    if attempts_used >= max_attempts {
        sqlx::query("UPDATE otp_challenges SET status = 'locked', consumed_at = ? WHERE id = ?")
            .bind(Utc::now())
            .bind(challenge_id_db.clone())
            .execute(pool.get_ref())
            .await
            .map_err(|e| AppError::InternalError(format!("OTP lock update failed: {}", e)))?;
        log_auth_event(
            pool.get_ref(),
            Some(&user_id),
            "step_up_otp_lockout",
            "denied",
            Some(risk_score),
            Some("max_attempts_reached"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::Unauthorized(
            "Too many verification attempts. Please sign in again.".into(),
        ));
    }

    let submitted_hash = hash_otp(otp_code);
    if submitted_hash != otp_hash_db {
        let next_attempts = attempts_used + 1;
        let next_status = if next_attempts >= max_attempts {
            "locked"
        } else {
            "pending"
        };
        sqlx::query("UPDATE otp_challenges SET attempts_used = ?, status = ? WHERE id = ?")
            .bind(next_attempts)
            .bind(next_status)
            .bind(challenge_id_db.clone())
            .execute(pool.get_ref())
            .await
            .map_err(|e| AppError::InternalError(format!("OTP attempts update failed: {}", e)))?;
        log_auth_event(
            pool.get_ref(),
            Some(&user_id),
            "step_up_otp_failed",
            "denied",
            Some(risk_score),
            Some("invalid_otp"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::Unauthorized("Invalid verification code.".into()));
    }

    sqlx::query(
        "UPDATE otp_challenges SET status = 'verified', verified_at = ?, consumed_at = ? WHERE id = ?",
    )
    .bind(Utc::now())
    .bind(Utc::now())
    .bind(challenge_id_db.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("OTP verify update failed: {}", e)))?;

    sqlx::query(
        "UPDATE otp_challenges SET status = 'invalidated', consumed_at = ? WHERE user_id = ? AND status = 'pending' AND id != ?",
    )
    .bind(Utc::now())
    .bind(user_id.clone())
    .bind(challenge_id_db.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("OTP pending invalidation failed: {}", e)))?;

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
        .bind(user_id.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("OTP user lookup failed: {}", e)))?
        .ok_or_else(|| AppError::Unauthorized("User not found.".into()))?;

    let raw_device_token = req
        .cookie(DEVICE_COOKIE_NAME)
        .map(|c| c.value().to_string())
        .unwrap_or_else(make_device_token);
    upsert_trusted_device(pool.get_ref(), &user.id, &raw_device_token, &context).await?;
    let device_cookie = create_device_cookie(&raw_device_token);

    if user.force_step_up_until.is_some() {
        sqlx::query(
            "UPDATE users SET force_step_up_reason = NULL, force_step_up_until = NULL WHERE id = ?",
        )
        .bind(user.id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|e| {
            AppError::InternalError(format!("Clear forced step-up flags failed: {}", e))
        })?;
    }

    let step_up_hours = config_i64("STEP_UP_SESSION_HOURS", STEP_UP_SESSION_HOURS_DEFAULT);
    let step_up_until = Some((Utc::now() + Duration::hours(step_up_hours)).timestamp() as usize);
    let token = encode_token(&user.id, step_up_until)?;
    let auth_cookie = create_auth_cookie(&token);

    log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "step_up_otp_success",
        "allow",
        Some(risk_score),
        Some("otp_verified"),
        &context,
        None,
    )
    .await?;

    if let Some(hash) = challenge_device_hash {
        let extra = serde_json::json!({ "challengeDeviceTokenHash": hash }).to_string();
        log_auth_event(
            pool.get_ref(),
            Some(&user.id),
            "step_up_session_established",
            "allow",
            Some(risk_score),
            Some("session_rotated_after_step_up"),
            &context,
            Some(&extra),
        )
        .await?;
    }

    Ok(HttpResponse::Ok()
        .cookie(auth_cookie)
        .cookie(device_cookie)
        .json(AuthSuccessResponse {
            token,
            user: public_user(&user),
        }))
}

pub async fn resend_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResendOtpPayload>,
) -> Result<HttpResponse, AppError> {
    let context = extract_login_context(&req);
    let challenge_id = payload.challenge_id.trim().to_string();
    let now = Utc::now();
    let challenge = sqlx::query_as::<
        _,
        (
            String,
            String,
            String,
            chrono::DateTime<Utc>,
            chrono::DateTime<Utc>,
            i64,
            Option<String>,
            Option<String>,
            i64,
        ),
    >(
        r#"
        SELECT id, user_id, status, otp_expires_at, resend_available_at, risk_score, risk_reasons_json, device_token_hash, resend_count
        FROM otp_challenges
        WHERE id = ?
        "#,
    )
    .bind(challenge_id.clone())
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("Resend OTP challenge lookup failed: {}", e)))?
    .ok_or_else(|| AppError::ValidationError("Verification challenge not found.".into()))?;

    let (
        id,
        user_id,
        status,
        otp_expires_at,
        resend_available_at,
        risk_score,
        risk_reasons_json,
        challenge_device_hash,
        resend_count,
    ) = challenge;

    if status != "pending" {
        return Err(AppError::ValidationError(
            "Verification challenge is no longer active.".into(),
        ));
    }
    if now > otp_expires_at {
        return Err(AppError::ValidationError(
            "Verification code expired.".into(),
        ));
    }
    if now < resend_available_at {
        return Err(AppError::ValidationError(
            "Please wait before requesting another code.".into(),
        ));
    }

    enforce_otp_issue_rate_limit(pool.get_ref(), &user_id, &context).await?;

    let new_code = generate_otp_code();
    let new_hash = hash_otp(&new_code);
    let cooldown_secs = config_i64(
        "OTP_RESEND_COOLDOWN_SECONDS",
        OTP_RESEND_COOLDOWN_SECONDS_DEFAULT,
    );
    let next_resend_at = now + Duration::seconds(cooldown_secs);
    let next_expires_at = now + Duration::minutes(OTP_TTL_MINUTES);
    sqlx::query(
        r#"
        UPDATE otp_challenges
        SET otp_hash = ?, otp_expires_at = ?, attempts_used = 0,
            resend_available_at = ?, resend_count = ?
        WHERE id = ?
        "#,
    )
    .bind(new_hash)
    .bind(next_expires_at)
    .bind(next_resend_at)
    .bind(resend_count + 1)
    .bind(id.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|e| AppError::InternalError(format!("Resend OTP update failed: {}", e)))?;

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
        .bind(user_id.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("Resend OTP user lookup failed: {}", e)))?
        .ok_or_else(|| AppError::Unauthorized("User not found.".into()))?;

    let subject = "Your updated Robust verification code";
    let body = format!(
        "<p>Use this new verification code:</p><p><strong>{}</strong></p><p>This code expires in 10 minutes.</p>",
        new_code
    );
    send_email_or_log(&user.email, subject, &body).await?;

    let reason = if challenge_device_hash.is_some() {
        "otp_resent_with_device_context"
    } else {
        "otp_resent"
    };
    log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "step_up_otp_resent",
        "challenge",
        Some(risk_score),
        Some(reason),
        &context,
        risk_reasons_json.as_deref(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "challengeId": id,
        "message": "We sent a new verification code to your email.",
        "expiresAt": next_expires_at.to_rfc3339(),
        "resendAvailableAt": next_resend_at.to_rfc3339()
    })))
}

pub async fn revoke_all_trusted_devices(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    let context = extract_login_context(&req);
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or_else(|| AppError::Unauthorized("Not authenticated.".into()))?;
    sqlx::query("UPDATE trusted_devices SET revoked_at = ? WHERE user_id = ?")
        .bind(Utc::now())
        .bind(user.id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|e| AppError::InternalError(format!("Trusted devices revoke failed: {}", e)))?;
    log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "trusted_devices_revoked",
        "allow",
        None,
        Some("user_requested"),
        &context,
        None,
    )
    .await?;
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "All trusted devices were revoked."
    })))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn username_validation_accepts_expected_slug() {
        assert!(validate_username("layan-team").is_ok());
    }

    #[test]
    fn username_validation_rejects_reserved() {
        assert!(validate_username("admin").is_err());
    }

    #[test]
    fn password_min_length_enforced() {
        assert!(validate_password("1234567").is_err());
        assert!(validate_password("12345678").is_ok());
    }

    #[test]
    fn token_hash_is_deterministic() {
        assert_eq!(hash_token("abc"), hash_token("abc"));
    }

    #[test]
    fn otp_is_six_digits() {
        let otp = generate_otp_code();
        assert_eq!(otp.len(), 6);
        assert!(otp.chars().all(|c| c.is_ascii_digit()));
    }

    #[test]
    fn user_agent_family_parse_works() {
        assert_eq!(
            parse_user_agent_family("Mozilla/5.0 Chrome/130.0"),
            Some("chrome".to_string())
        );
        assert_eq!(
            parse_user_agent_family("Mozilla/5.0 Firefox/128.0"),
            Some("firefox".to_string())
        );
    }
}
