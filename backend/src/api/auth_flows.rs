#[path = "auth_flows_account.rs"]
mod auth_flows_account;
#[path = "auth_flows_password.rs"]
mod auth_flows_password;
#[path = "auth_flows_session.rs"]
mod auth_flows_session;

use actix_web::{HttpRequest, HttpResponse, web};
use sqlx::SqlitePool;

use crate::models::{AppError, User};

use super::{
    ChangePasswordPayload, ForgotPasswordPayload, ResendVerificationPayload, ResetPasswordPayload, SignInPayload,
    SignUpPayload, VerifyEmailPayload,
};

pub(super) async fn signup(
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignUpPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_account::signup(pool, payload).await
}

pub(super) async fn resend_verification_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResendVerificationPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_account::resend_verification_email(pool, payload).await
}

pub(super) async fn verify_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<VerifyEmailPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_account::verify_email(pool, payload).await
}

pub(super) async fn signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignInPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_session::signin(req, pool, payload).await
}

#[allow(dead_code)]
pub(super) async fn ensure_dev_bootstrap_user(pool: &SqlitePool) -> Result<User, AppError> {
    auth_flows_session::ensure_dev_bootstrap_user(pool).await
}

pub(super) async fn dev_signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    auth_flows_session::dev_signin(req, pool).await
}

pub(super) fn signout() -> Result<HttpResponse, AppError> {
    auth_flows_session::signout()
}

pub(super) fn me(req: HttpRequest) -> Result<HttpResponse, AppError> {
    auth_flows_session::me(req)
}

pub(super) async fn forgot_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ForgotPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_password::forgot_password(pool, payload).await
}

pub(super) async fn reset_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResetPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_password::reset_password(pool, payload).await
}

pub(super) async fn change_password(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<ChangePasswordPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_password::change_password(req, pool, payload).await
}
