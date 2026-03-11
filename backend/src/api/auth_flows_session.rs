#[path = "auth_flows_session_dev.rs"]
mod auth_flows_session_dev;
#[path = "auth_flows_session_signin.rs"]
mod auth_flows_session_signin;

use actix_web::{HttpRequest, HttpResponse, web};
use sqlx::SqlitePool;

use crate::models::{AppError, User};

use super::super::SignInPayload;

pub(super) async fn signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignInPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_session_signin::signin(req, pool, payload).await
}

pub(super) async fn ensure_dev_bootstrap_user(pool: &SqlitePool) -> Result<User, AppError> {
    auth_flows_session_dev::ensure_dev_bootstrap_user(pool).await
}

pub(super) async fn dev_signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    auth_flows_session_dev::dev_signin(req, pool).await
}

pub(super) fn signout() -> Result<HttpResponse, AppError> {
    auth_flows_session_signin::signout()
}

pub(super) fn me(req: HttpRequest) -> Result<HttpResponse, AppError> {
    auth_flows_session_signin::me(req)
}
