use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use serde::Deserialize;

use crate::api::project_logic;
use crate::models::{AppError, User};
use crate::pathfinder::PathRequest;
use crate::services::media::StorageManager;
use crate::services::project;

#[derive(Deserialize)]
pub struct ValidatePayload {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    pub data: serde_json::Value,
}

pub(super) async fn calculate_path(
    payload: web::Json<PathRequest>,
) -> Result<HttpResponse, AppError> {
    let request = payload.into_inner();
    let result = web::block(move || crate::pathfinder::calculate_path(request))
        .await
        .map_err(|error| AppError::InternalError(error.to_string()))?;
    match result {
        Ok(steps) => Ok(HttpResponse::Ok().json(steps)),
        Err(error) => Err(AppError::InternalError(error)),
    }
}

pub(super) async fn validate_project(
    req: HttpRequest,
    payload: web::Json<ValidatePayload>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let payload = payload.into_inner();
    let project_path = StorageManager::get_user_project_path(&user.id, &payload.session_id)
        .map_err(AppError::IoError)?;

    let result = web::block(move || {
        let available_files = project_logic::list_available_files(&project_path);
        project::validate_and_clean_project(payload.data, &available_files)
    })
    .await
    .map_err(|error| AppError::InternalError(error.to_string()))??;

    Ok(HttpResponse::Ok().json(result.1))
}
