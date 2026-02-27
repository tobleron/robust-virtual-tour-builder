use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use serde::{Deserialize, Serialize};

use crate::api::project_multipart;
use crate::models::{AppError, User};
use crate::services::project::ChunkedProjectExportUploadManager;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportInitRequest {
    pub filename: String,
    pub size_bytes: u64,
    pub chunk_size_bytes: Option<usize>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportInitResponse {
    pub upload_id: String,
    pub chunk_size_bytes: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportChunkResponse {
    pub accepted: bool,
    pub next_expected_chunk: usize,
    pub received_count: usize,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportStatusResponse {
    pub received_chunks: Vec<usize>,
    pub next_expected_chunk: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportCompleteRequest {
    pub upload_id: String,
    pub filename: String,
    pub size_bytes: u64,
    pub total_chunks: usize,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportCompleteResponse {
    pub staged: bool,
    pub staged_upload_id: String,
    pub assembled_size_bytes: u64,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportAbortRequest {
    pub upload_id: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportAbortResponse {
    pub aborted: bool,
}

pub async fn export_init(
    req: HttpRequest,
    payload: web::Json<ExportInitRequest>,
    upload_manager: web::Data<ChunkedProjectExportUploadManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let payload = payload.into_inner();

    let init = upload_manager
        .init_session(
            &user.id,
            &payload.filename,
            payload.size_bytes,
            payload.chunk_size_bytes,
        )
        .await
        .map_err(AppError::ValidationError)?;

    Ok(HttpResponse::Ok().json(ExportInitResponse {
        upload_id: init.upload_id,
        chunk_size_bytes: init.chunk_size_bytes,
        total_chunks: init.total_chunks,
        expires_at_epoch_ms: init.expires_at_epoch_ms,
    }))
}

pub async fn export_chunk(
    req: HttpRequest,
    payload: Multipart,
    upload_manager: web::Data<ChunkedProjectExportUploadManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let multipart = project_multipart::parse_export_chunk_multipart(payload).await?;

    let ack = upload_manager
        .save_chunk(
            &user.id,
            &multipart.upload_id,
            multipart.chunk_index,
            multipart.chunk_data,
            multipart.chunk_byte_length,
            &multipart.chunk_sha256,
        )
        .await
        .map_err(AppError::ValidationError)?;

    Ok(HttpResponse::Ok().json(ExportChunkResponse {
        accepted: ack.accepted,
        next_expected_chunk: ack.next_expected_chunk,
        received_count: ack.received_count,
    }))
}

pub async fn export_status(
    req: HttpRequest,
    upload_id: web::Path<String>,
    upload_manager: web::Data<ChunkedProjectExportUploadManager>,
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

    Ok(HttpResponse::Ok().json(ExportStatusResponse {
        received_chunks: status.received_chunks,
        next_expected_chunk: status.next_expected_chunk,
        total_chunks: status.total_chunks,
        expires_at_epoch_ms: status.expires_at_epoch_ms,
    }))
}

pub async fn export_complete(
    req: HttpRequest,
    payload: web::Json<ExportCompleteRequest>,
    upload_manager: web::Data<ChunkedProjectExportUploadManager>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let payload = payload.into_inner();

    let assembled_path = upload_manager
        .complete_session(
            &user.id,
            &payload.upload_id,
            &payload.filename,
            payload.size_bytes,
            payload.total_chunks,
        )
        .await
        .map_err(AppError::ValidationError)?;

    let assembled_size = tokio::fs::metadata(&assembled_path)
        .await
        .map_err(AppError::IoError)?
        .len();
    let _ = tokio::fs::remove_file(assembled_path).await;

    Ok(HttpResponse::Ok().json(ExportCompleteResponse {
        staged: true,
        staged_upload_id: payload.upload_id,
        assembled_size_bytes: assembled_size,
    }))
}

pub async fn export_abort(
    req: HttpRequest,
    payload: web::Json<ExportAbortRequest>,
    upload_manager: web::Data<ChunkedProjectExportUploadManager>,
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

    Ok(HttpResponse::Ok().json(ExportAbortResponse { aborted }))
}
