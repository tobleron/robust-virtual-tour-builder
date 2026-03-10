#[path = "auth_flows_session_signin.rs"]
mod auth_flows_session_signin;

use actix_web::{web, HttpRequest, HttpResponse};
use sqlx::SqlitePool;

use crate::models::AppError;

use super::super::SignInPayload;

pub(super) async fn signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignInPayload>,
) -> Result<HttpResponse, AppError> {
    auth_flows_session_signin::signin(req, pool, payload).await
}

pub(super) fn signout() -> Result<HttpResponse, AppError> {
    auth_flows_session_signin::signout()
}

pub(super) fn me(req: HttpRequest) -> Result<HttpResponse, AppError> {
    auth_flows_session_signin::me(req)
}
