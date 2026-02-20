/* backend/src/api/project_import.rs - Project Import API */

use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use serde::{Deserialize, Serialize};

use crate::api::{project_logic, project_multipart};
use crate::models::{AppError, User};
use crate::services::media::StorageManager;
use crate::services::project::{self, ChunkedProjectImportManager};

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResponse {
    pub session_id: String,
    pub project_data: serde_json::Value,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportInitRequest {
    pub filename: String,
    pub size_bytes: u64,
    pub chunk_size_bytes: Option<usize>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportInitResponse {
    pub upload_id: String,
    pub chunk_size_bytes: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportChunkResponse {
    pub accepted: bool,
    pub next_expected_chunk: usize,
    pub received_count: usize,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportStatusResponse {
    pub received_chunks: Vec<usize>,
    pub next_expected_chunk: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportCompleteRequest {
    pub upload_id: String,
    pub filename: String,
    pub size_bytes: u64,
    pub total_chunks: usize,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportAbortRequest {
    pub upload_id: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportAbortResponse {
    pub aborted: bool,
}

pub(crate) async fn import_project_from_zip_path(
    user: &User,
    tmp_path: &std::path::PathBuf,
) -> Result<ImportResponse, AppError> {
    // Extract metadata
    let tmp_path_clone = tmp_path.clone();
    let (project_id, project_data) =
        web::block(move || project_logic::extract_project_metadata_from_zip(&tmp_path_clone))
            .await
            .map_err(|e| AppError::InternalError(e.to_string()))??;

    let project_dir =
        StorageManager::ensure_project_dir(&user.id, &project_id).map_err(AppError::IoError)?;

    // Use shared logic for extraction
    let tmp_path_clone = tmp_path.clone();
    let project_dir_clone = project_dir.clone();
    web::block(move || {
        project_logic::extract_zip_to_project_dir(&tmp_path_clone, &project_dir_clone)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?
    .map_err(AppError::InternalError)?;

    let validated_project = web::block({
        let project_dir = project_dir.clone();
        let project_data = project_data.clone();
        move || -> Result<serde_json::Value, AppError> {
            let available_files = project_logic::list_available_files(&project_dir);
            let (mut cleaned_project, report) =
                project::validate_and_clean_project(project_data, &available_files)
                    .map_err(AppError::InternalError)?;

            cleaned_project["validationReport"] = serde_json::to_value(&report)
                .map_err(|e| AppError::InternalError(e.to_string()))?;

            let persisted = serde_json::to_string_pretty(&cleaned_project)
                .map_err(|e| AppError::InternalError(e.to_string()))?;
            std::fs::write(project_dir.join("project.json"), persisted)
                .map_err(AppError::IoError)?;

            Ok(cleaned_project)
        }
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    Ok(ImportResponse {
        session_id: project_id,
        project_data: validated_project,
    })
}

/// Imports a project ZIP and establishes a persistent project.
pub async fn import_project(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    tracing::info!(module = "ProjectManager", user_id = %user.id, "IMPORT_PROJECT_START");

    // Extract file from payload
    let tmp_path = project_multipart::extract_file_from_multipart(payload, "zip").await?;
    struct TempUploadCleanupGuard {
        path: std::path::PathBuf,
    }
    impl Drop for TempUploadCleanupGuard {
        fn drop(&mut self) {
            let _ = std::fs::remove_file(&self.path);
        }
    }
    let _tmp_upload_cleanup = TempUploadCleanupGuard {
        path: tmp_path.clone(),
    };

    let response = import_project_from_zip_path(&user, &tmp_path).await?;

    tracing::info!(
        module = "ProjectManager",
        user_id = %user.id,
        session_id = %response.session_id,
        "IMPORT_PROJECT_COMPLETE"
    );

    Ok(HttpResponse::Ok().json(response))
}

/// Starts a chunked project import session.
pub async fn import_project_init(
    req: HttpRequest,
    payload: web::Json<ImportInitRequest>,
    upload_manager: web::Data<ChunkedProjectImportManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    let payload = payload.into_inner();
    tracing::info!(
        module = "ProjectManager",
        user_id = %user.id,
        size_bytes = payload.size_bytes,
        "IMPORT_PROJECT_CHUNK_INIT_START"
    );

    let init = upload_manager
        .init_session(
            &user.id,
            &payload.filename,
            payload.size_bytes,
            payload.chunk_size_bytes,
        )
        .await
        .map_err(AppError::ValidationError)?;

    tracing::info!(
        module = "ProjectManager",
        user_id = %user.id,
        upload_id = %init.upload_id,
        total_chunks = init.total_chunks,
        "IMPORT_PROJECT_CHUNK_INIT_COMPLETE"
    );

    Ok(HttpResponse::Ok().json(ImportInitResponse {
        upload_id: init.upload_id,
        chunk_size_bytes: init.chunk_size_bytes,
        total_chunks: init.total_chunks,
        expires_at_epoch_ms: init.expires_at_epoch_ms,
    }))
}

/// Accepts one chunk for an active chunked import session.
pub async fn import_project_chunk(
    req: HttpRequest,
    payload: Multipart,
    upload_manager: web::Data<ChunkedProjectImportManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    let multipart = project_multipart::parse_import_chunk_multipart(payload).await?;

    let ack = upload_manager
        .save_chunk(
            &user.id,
            &multipart.upload_id,
            multipart.chunk_index,
            multipart.chunk_data,
            multipart.chunk_byte_length,
        )
        .await
        .map_err(AppError::ValidationError)?;

    Ok(HttpResponse::Ok().json(ImportChunkResponse {
        accepted: ack.accepted,
        next_expected_chunk: ack.next_expected_chunk,
        received_count: ack.received_count,
    }))
}

/// Returns chunk session status so the frontend can resume interrupted uploads.
pub async fn import_project_status(
    req: HttpRequest,
    upload_id: web::Path<String>,
    upload_manager: web::Data<ChunkedProjectImportManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let upload_id = upload_id.into_inner();

    let status = upload_manager
        .status(&user.id, &upload_id)
        .await
        .map_err(AppError::ValidationError)?;

    Ok(HttpResponse::Ok().json(ImportStatusResponse {
        received_chunks: status.received_chunks,
        next_expected_chunk: status.next_expected_chunk,
        total_chunks: status.total_chunks,
        expires_at_epoch_ms: status.expires_at_epoch_ms,
    }))
}

/// Completes a chunked upload and imports the assembled ZIP.
pub async fn import_project_complete(
    req: HttpRequest,
    payload: web::Json<ImportCompleteRequest>,
    upload_manager: web::Data<ChunkedProjectImportManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let payload = payload.into_inner();

    let assembled_zip = upload_manager
        .complete_session(
            &user.id,
            &payload.upload_id,
            &payload.filename,
            payload.size_bytes,
            payload.total_chunks,
        )
        .await
        .map_err(AppError::ValidationError)?;

    struct TempUploadCleanupGuard {
        path: std::path::PathBuf,
    }
    impl Drop for TempUploadCleanupGuard {
        fn drop(&mut self) {
            let _ = std::fs::remove_file(&self.path);
        }
    }
    let _cleanup = TempUploadCleanupGuard {
        path: assembled_zip.clone(),
    };

    let response = import_project_from_zip_path(&user, &assembled_zip).await?;
    tracing::info!(
        module = "ProjectManager",
        user_id = %user.id,
        upload_id = %payload.upload_id,
        session_id = %response.session_id,
        "IMPORT_PROJECT_CHUNK_COMPLETE"
    );

    Ok(HttpResponse::Ok().json(response))
}

/// Aborts a chunked upload session and deletes temporary chunks.
pub async fn import_project_abort(
    req: HttpRequest,
    payload: web::Json<ImportAbortRequest>,
    upload_manager: web::Data<ChunkedProjectImportManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let payload = payload.into_inner();

    let aborted = upload_manager
        .abort_session(&user.id, &payload.upload_id)
        .await
        .map_err(AppError::ValidationError)?;

    Ok(HttpResponse::Ok().json(ImportAbortResponse { aborted }))
}
