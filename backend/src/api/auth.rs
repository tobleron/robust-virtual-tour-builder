#[path = "auth_context.rs"]
mod auth_context;
#[path = "auth_events.rs"]
mod auth_events;
#[path = "auth_flows.rs"]
mod auth_flows;
#[path = "auth_mail.rs"]
mod auth_mail;
#[path = "auth_risk.rs"]
mod auth_risk;
#[path = "auth_step_up.rs"]
mod auth_step_up;
#[path = "auth_types.rs"]
mod auth_types;
#[path = "auth_utils.rs"]
mod auth_utils;

use crate::models::{AppError, User};
use actix_web::cookie::Cookie;
use actix_web::{HttpRequest, HttpResponse, web};
use chrono::Utc;
use sqlx::SqlitePool;

pub use auth_types::{
    AuthChallengeResponse, AuthPublicUser, AuthSuccessResponse, ChangePasswordPayload,
    ForgotPasswordPayload, MeResponse, ResendOtpPayload, ResendVerificationPayload,
    ResetPasswordPayload, SignInPayload, SignUpPayload, VerifyEmailPayload, VerifyOtpPayload,
};
use auth_types::{IpReputation, LoginContext, RiskDecision, TrustedDeviceRecord};

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

#[rustfmt::skip]
fn is_production() -> bool { auth_utils::is_production() }
#[rustfmt::skip]
fn config_i64(var_name: &str, default_value: i64) -> i64 { auth_utils::config_i64(var_name, default_value) }
#[rustfmt::skip]
fn config_bool(var_name: &str, default_value: bool) -> bool { auth_utils::config_bool(var_name, default_value) }
#[rustfmt::skip]
fn normalize_email(input: &str) -> String { auth_utils::normalize_email(input) }
#[rustfmt::skip]
fn normalize_username(input: &str) -> String { auth_utils::normalize_username(input) }
#[rustfmt::skip]
fn validate_username(username: &str) -> Result<(), AppError> { auth_utils::validate_username(username) }
#[rustfmt::skip]
fn validate_password(password: &str) -> Result<(), AppError> { auth_utils::validate_password(password) }
#[rustfmt::skip]
fn hash_password(password: &str) -> Result<String, AppError> { auth_utils::hash_password(password) }
#[rustfmt::skip]
fn verify_password(password: &str, password_hash: &str) -> Result<bool, AppError> { auth_utils::verify_password(password, password_hash) }
#[rustfmt::skip]
fn hash_token(raw_token: &str) -> String { auth_utils::hash_token(raw_token) }
#[rustfmt::skip]
fn make_device_token() -> String { auth_utils::make_device_token() }
#[rustfmt::skip]
fn hash_otp(raw_otp: &str) -> String { auth_utils::hash_otp(raw_otp) }
#[rustfmt::skip]
fn generate_otp_code() -> String { auth_utils::generate_otp_code() }
#[rustfmt::skip]
fn create_auth_cookie(token: &str) -> Cookie<'static> { auth_utils::create_auth_cookie(token) }
#[rustfmt::skip]
fn clear_auth_cookie() -> Cookie<'static> { auth_utils::clear_auth_cookie() }
#[rustfmt::skip]
fn create_device_cookie(token: &str) -> Cookie<'static> { auth_utils::create_device_cookie(token) }
#[rustfmt::skip]
fn public_user(user: &User) -> AuthPublicUser { auth_utils::public_user(user) }
#[rustfmt::skip]
async fn send_email_or_log(to_email: &str, subject: &str, html_body: &str) -> Result<(), AppError> { auth_mail::send_email_or_log(to_email, subject, html_body).await }
#[rustfmt::skip]
fn app_base_url() -> String { auth_mail::app_base_url() }
#[rustfmt::skip]
async fn issue_verification_email(pool: &SqlitePool, user_id: &str, email: &str) -> Result<(), AppError> { auth_mail::issue_verification_email(pool, user_id, email).await }
#[rustfmt::skip]
fn extract_login_context(req: &HttpRequest) -> LoginContext { auth_context::extract_login_context(req) }
#[rustfmt::skip]
fn empty_login_context() -> LoginContext { auth_context::empty_login_context() }
#[rustfmt::skip]
fn parse_user_agent_family(ua: &str) -> Option<String> { auth_context::parse_user_agent_family(ua) }
#[rustfmt::skip]
fn is_local_request_host(value: &str) -> bool { auth_context::is_local_request_host(value) }
#[rustfmt::skip]
fn is_local_dev_request(req: &HttpRequest) -> bool { auth_context::is_local_dev_request(req) }
#[rustfmt::skip]
fn dev_auth_bootstrap_enabled() -> bool { auth_context::dev_auth_bootstrap_enabled() }
#[rustfmt::skip]
fn dev_auth_email() -> String { auth_context::dev_auth_email() }
#[rustfmt::skip]
fn dev_auth_username() -> String { auth_context::dev_auth_username() }
#[rustfmt::skip]
fn dev_auth_name() -> String { auth_context::dev_auth_name() }
#[rustfmt::skip]
fn dev_auth_password() -> String { auth_context::dev_auth_password() }
#[rustfmt::skip]
fn evaluate_ip_reputation(req: &HttpRequest) -> IpReputation { auth_context::evaluate_ip_reputation(req) }

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
    auth_events::log_auth_event(
        pool, user_id, event_type, decision, risk_score, reason, context, extra_json,
    )
    .await
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
    auth_events::log_login_attempt(
        pool,
        user_id,
        email,
        context,
        device_token_hash,
        success,
        failure_reason,
    )
    .await
}

async fn find_trusted_device(
    pool: &SqlitePool,
    user_id: &str,
    raw_device_token: Option<&str>,
) -> Result<Option<TrustedDeviceRecord>, AppError> {
    auth_events::find_trusted_device(pool, user_id, raw_device_token).await
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
    auth_events::load_last_success_login_context(pool, user_id).await
}

async fn count_recent_failed_logins(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
) -> Result<(i64, i64), AppError> {
    auth_events::count_recent_failed_logins(pool, user_id, email, context, device_token_hash).await
}

async fn enforce_failed_login_rate_limit(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
) -> Result<(), AppError> {
    auth_risk::enforce_failed_login_rate_limit(pool, user_id, email, context, device_token_hash)
        .await
}

fn haversine_km(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    auth_risk::haversine_km(lat1, lon1, lat2, lon2)
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
    auth_risk::evaluate_geo_anomaly(last_success, context)
}

fn evaluate_context_mismatch(
    trusted_device: Option<&TrustedDeviceRecord>,
    context: &LoginContext,
    risk_reasons_count_before: usize,
) -> bool {
    auth_risk::evaluate_context_mismatch(trusted_device, context, risk_reasons_count_before)
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
    auth_risk::compute_risk_decision(
        pool,
        user,
        email,
        context,
        trusted_device,
        req,
        force_new_device_hard_trigger,
    )
    .await
}

async fn issue_or_refresh_step_up_challenge(
    pool: &SqlitePool,
    user: &User,
    context: &LoginContext,
    risk: &RiskDecision,
    device_token_hash: Option<&str>,
) -> Result<(String, String, chrono::DateTime<Utc>, chrono::DateTime<Utc>), AppError> {
    auth_step_up::issue_or_refresh_step_up_challenge(pool, user, context, risk, device_token_hash)
        .await
}

async fn enforce_otp_issue_rate_limit(
    pool: &SqlitePool,
    user_id: &str,
    context: &LoginContext,
) -> Result<(), AppError> {
    auth_risk::enforce_otp_issue_rate_limit(pool, user_id, context).await
}

async fn upsert_trusted_device(
    pool: &SqlitePool,
    user_id: &str,
    raw_device_token: &str,
    context: &LoginContext,
) -> Result<(), AppError> {
    auth_step_up::upsert_trusted_device(pool, user_id, raw_device_token, context).await
}

pub async fn signup(
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignUpPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows::signup(pool, payload).await
}

pub async fn resend_verification_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResendVerificationPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows::resend_verification_email(pool, payload).await
}

pub async fn verify_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<VerifyEmailPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows::verify_email(pool, payload).await
}

pub async fn signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignInPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows::signin(req, pool, payload).await
}

#[allow(dead_code)]
async fn ensure_dev_bootstrap_user(pool: &SqlitePool) -> Result<User, AppError> {
    auth_flows::ensure_dev_bootstrap_user(pool).await
}

pub async fn dev_signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    auth_flows::dev_signin(req, pool).await
}

pub async fn signout() -> Result<HttpResponse, AppError> {
    auth_flows::signout()
}

pub async fn me(req: HttpRequest) -> Result<HttpResponse, AppError> {
    auth_flows::me(req)
}

pub async fn forgot_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ForgotPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows::forgot_password(pool, payload).await
}

pub async fn reset_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResetPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows::reset_password(pool, payload).await
}

pub async fn change_password(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<ChangePasswordPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows::change_password(req, pool, payload).await
}

pub async fn verify_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<VerifyOtpPayload>,
) -> Result<HttpResponse, AppError> {
    let payload = payload.into_inner();
    auth_step_up::verify_step_up_otp(
        req,
        pool,
        payload.challenge_id.trim(),
        payload.otp_code.trim(),
    )
    .await
}

pub async fn resend_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResendOtpPayload>,
) -> Result<HttpResponse, AppError> {
    let challenge_id = payload.into_inner().challenge_id.trim().to_string();
    auth_step_up::resend_step_up_otp(req, pool, challenge_id).await
}

pub async fn revoke_all_trusted_devices(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    auth_step_up::revoke_all_trusted_devices(req, pool).await
}

#[cfg(test)]
#[path = "auth_tests.rs"]
mod tests;

#[cfg(test)]
mod tests_surface {
    use super::tests;

    #[test]
    fn username_validation_accepts_expected_slug() {
        tests::username_validation_accepts_expected_slug();
    }
    #[test]
    fn username_validation_rejects_reserved() {
        tests::username_validation_rejects_reserved();
    }
    #[test]
    fn password_min_length_enforced() {
        tests::password_min_length_enforced();
    }
    #[test]
    fn token_hash_is_deterministic() {
        tests::token_hash_is_deterministic();
    }
    #[test]
    fn otp_is_six_digits() {
        tests::otp_is_six_digits();
    }
    #[test]
    fn user_agent_family_parse_works() {
        tests::user_agent_family_parse_works();
    }
}
