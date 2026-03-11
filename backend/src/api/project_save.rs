use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};

use crate::api::project_logic;
use crate::api::project_multipart;
use crate::api::utils::get_temp_path;
use crate::models::{AppError, User};
use crate::services::media::StorageManager;

use super::{TempImagesCleanupGuard, ZipCleanupGuard};

#[tracing::instrument(skip(payload, req), name = "save_project")]
pub(super) async fn save_project(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    tracing::info!(module = "ProjectManager", user_id = %user.id, "SAVE_PROJECT_START");
    let start = std::time::Instant::now();
    let zip_path = get_temp_path("zip");

    let (project_json, session_id, temp_images) =
        project_multipart::parse_save_project_multipart(payload).await?;

    let _temp_images_guard = TempImagesCleanupGuard {
        paths: temp_images.iter().map(|(_, path)| path.clone()).collect(),
    };
    let mut zip_cleanup_guard = ZipCleanupGuard::new(zip_path.clone());

    let json_content = project_json.ok_or_else(|| {
        AppError::MultipartError(actix_multipart::MultipartError::Incomplete.to_string())
    })?;
    let project_path = match &session_id {
        Some(pid) => {
            Some(StorageManager::get_user_project_path(&user.id, pid).map_err(AppError::IoError)?)
        }
        None => None,
    };

    let (validated_json, _report, summary_content) = web::block({
        let temp_images = temp_images.clone();
        let project_path = project_path.clone();
        move || project_logic::validate_project_full_sync(json_content, temp_images, project_path)
    })
    .await
    .map_err(|error| AppError::InternalError(error.to_string()))??;

    let final_zip_path = zip_path.clone();
    let zip_creation_result = web::block({
        let validated_json = validated_json.clone();
        let project_path = project_path.clone();
        move || {
            project_logic::create_project_zip_sync(
                final_zip_path,
                validated_json,
                summary_content,
                temp_images,
                project_path,
            )
        }
    })
    .await
    .map_err(|error| AppError::InternalError(error.to_string()))?;

    let duration = start.elapsed().as_millis();
    match zip_creation_result {
        Ok(_) => {
            let file_bytes = tokio::fs::read(&zip_path)
                .await
                .map_err(AppError::IoError)?;
            zip_cleanup_guard.keep();
            let _ = std::fs::remove_file(&zip_path);
            tracing::info!(
                module = "ProjectManager",
                duration_ms = duration,
                "SAVE_PROJECT_COMPLETE"
            );
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(file_bytes))
        }
        Err(error) => Err(error.into()),
    }
}
