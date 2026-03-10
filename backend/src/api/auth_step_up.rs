#[path = "auth_step_up_challenges.rs"]
mod auth_step_up_challenges;
#[path = "auth_step_up_devices.rs"]
mod auth_step_up_devices;

use actix_web::{web, HttpRequest, HttpResponse};
use chrono::Utc;
use sqlx::SqlitePool;

use crate::models::{AppError, User};

use super::{LoginContext, RiskDecision};

pub(super) async fn issue_or_refresh_step_up_challenge(
    pool: &SqlitePool,
    user: &User,
    context: &LoginContext,
    risk: &RiskDecision,
    device_token_hash: Option<&str>,
) -> Result<(String, String, chrono::DateTime<Utc>, chrono::DateTime<Utc>), AppError> {
    auth_step_up_challenges::issue_or_refresh_step_up_challenge(
        pool,
        user,
        context,
        risk,
        device_token_hash,
    )
    .await
}

pub(super) async fn upsert_trusted_device(
    pool: &SqlitePool,
    user_id: &str,
    raw_device_token: &str,
    context: &LoginContext,
) -> Result<(), AppError> {
    auth_step_up_devices::upsert_trusted_device(pool, user_id, raw_device_token, context).await
}

pub(super) async fn verify_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    challenge_id: &str,
    otp_code: &str,
) -> Result<HttpResponse, AppError> {
    auth_step_up_challenges::verify_step_up_otp(req, pool, challenge_id, otp_code).await
}

pub(super) async fn resend_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    challenge_id: String,
) -> Result<HttpResponse, AppError> {
    auth_step_up_challenges::resend_step_up_otp(req, pool, challenge_id).await
}

pub(super) async fn revoke_all_trusted_devices(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    auth_step_up_devices::revoke_all_trusted_devices(req, pool).await
}
