use actix_multipart::Multipart;
use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};

use crate::api::project_multipart;
use crate::api::utils::get_temp_path;
use crate::models::{AppError, User};
use crate::services::project;

use super::CleanupGuard;

#[tracing::instrument(skip(payload, req), name = "create_tour_package")]
pub(super) async fn create_tour_package(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    tracing::info!(module = "Exporter", user_id = %user.id, "CREATE_PACKAGE_START");

    let zip_path = get_temp_path("zip");
    let zip_path_clone = zip_path.clone();

    let timeout_duration = std::time::Duration::from_secs(600);

    let result: Result<Result<(), AppError>, tokio::time::error::Elapsed> =
        tokio::time::timeout(timeout_duration, async {
            let (image_files, fields) =
                project_multipart::parse_tour_package_multipart(payload).await?;
            let mut guard = CleanupGuard(Some(image_files));

            web::block(move || {
                let files = guard.0.take().unwrap_or_default();
                project::create_tour_package(files, fields, zip_path_clone)
            })
            .await
            .map_err(|error| AppError::InternalError(error.to_string()))?
            .map_err(AppError::InternalError)
        })
        .await;

    match result {
        Ok(Ok(())) => {
            let file_bytes = tokio::fs::read(&zip_path)
                .await
                .map_err(AppError::IoError)?;
            let _ = tokio::fs::remove_file(&zip_path).await;
            tracing::info!(module = "Exporter", user_id = %user.id, "CREATE_PACKAGE_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(file_bytes))
        }
        Ok(Err(error)) => {
            let _ = tokio::fs::remove_file(&zip_path).await;
            tracing::error!(module = "Exporter", user_id = %user.id, error = ?error, "CREATE_PACKAGE_FAILED");
            Err(error)
        }
        Err(_) => {
            let _ = tokio::fs::remove_file(&zip_path).await;
            tracing::error!(module = "Exporter", user_id = %user.id, "CREATE_PACKAGE_TIMEOUT");
            Err(AppError::InternalError(
                "Export timed out after 10 minutes".into(),
            ))
        }
    }
}
