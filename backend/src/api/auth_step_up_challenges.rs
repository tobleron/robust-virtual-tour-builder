#[path = "auth_step_up_challenges_issue.rs"]
mod auth_step_up_challenges_issue;
#[path = "auth_step_up_challenges_verify.rs"]
mod auth_step_up_challenges_verify;

use actix_web::{HttpRequest, HttpResponse, web};
use chrono::Utc;
use sqlx::SqlitePool;

use crate::models::{AppError, User};

use super::super::{LoginContext, RiskDecision};

pub(super) async fn issue_or_refresh_step_up_challenge(
    pool: &SqlitePool,
    user: &User,
    context: &LoginContext,
    risk: &RiskDecision,
    device_token_hash: Option<&str>,
) -> Result<(String, String, chrono::DateTime<Utc>, chrono::DateTime<Utc>), AppError> {
    auth_step_up_challenges_issue::issue_or_refresh_step_up_challenge(
        pool,
        user,
        context,
        risk,
        device_token_hash,
    )
    .await
}

pub(super) async fn verify_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    challenge_id: &str,
    otp_code: &str,
) -> Result<HttpResponse, AppError> {
    auth_step_up_challenges_verify::verify_step_up_otp(req, pool, challenge_id, otp_code).await
}

pub(super) async fn resend_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    challenge_id: String,
) -> Result<HttpResponse, AppError> {
    auth_step_up_challenges_issue::resend_step_up_otp(req, pool, challenge_id).await
}
