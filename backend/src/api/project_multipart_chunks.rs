// @efficiency-role: infra-adapter
use actix_multipart::Multipart;
use futures_util::TryStreamExt as _;

use crate::api::project_multipart::{ExportChunkMultipartData, ImportChunkMultipartData};
use crate::models::AppError;
use crate::services::project::MAX_IMPORT_CHUNK_SIZE_BYTES;

pub(super) async fn parse_import_chunk_multipart(
    payload: &mut Multipart,
) -> Result<ImportChunkMultipartData, AppError> {
    let mut upload_id: Option<String> = None;
    let mut chunk_index: Option<usize> = None;
    let mut chunk_byte_length: Option<usize> = None;
    let mut chunk_data: Option<Vec<u8>> = None;

    while let Some(mut field) = payload.try_next().await? {
        match field.name().unwrap_or("") {
            "uploadId" | "upload_id" => {
                upload_id = Some(super::read_string_field(&mut field).await?);
            }
            "chunkIndex" | "chunk_index" => {
                let raw = super::read_string_field(&mut field).await?;
                chunk_index = Some(raw.trim().parse::<usize>().map_err(|_| {
                    AppError::ValidationError("Invalid chunkIndex provided".to_string())
                })?);
            }
            "chunkByteLength" | "chunk_byte_length" => {
                let raw = super::read_string_field(&mut field).await?;
                chunk_byte_length = Some(raw.trim().parse::<usize>().map_err(|_| {
                    AppError::ValidationError("Invalid chunkByteLength provided".to_string())
                })?);
            }
            "chunk" | "file" => {
                let mut bytes = Vec::new();
                while let Some(chunk) = field.try_next().await? {
                    bytes.extend_from_slice(&chunk);
                    if bytes.len() > MAX_IMPORT_CHUNK_SIZE_BYTES {
                        return Err(AppError::ValidationError(format!(
                            "Chunk exceeds maximum size of {} bytes",
                            MAX_IMPORT_CHUNK_SIZE_BYTES
                        )));
                    }
                }
                chunk_data = Some(bytes);
            }
            _ => {
                let _ = super::read_string_field(&mut field).await?;
            }
        }
    }

    let upload_id = upload_id.ok_or_else(|| {
        AppError::MultipartError("Missing uploadId field in chunk payload".to_string())
    })?;
    let chunk_index = chunk_index.ok_or_else(|| {
        AppError::MultipartError("Missing chunkIndex field in chunk payload".to_string())
    })?;
    let chunk_data = chunk_data.ok_or_else(|| {
        AppError::MultipartError("Missing chunk data in chunk payload".to_string())
    })?;

    Ok(ImportChunkMultipartData {
        upload_id,
        chunk_index,
        chunk_byte_length,
        chunk_data,
    })
}

pub(super) async fn parse_export_chunk_multipart(
    payload: &mut Multipart,
) -> Result<ExportChunkMultipartData, AppError> {
    let mut upload_id: Option<String> = None;
    let mut chunk_index: Option<usize> = None;
    let mut chunk_byte_length: Option<usize> = None;
    let mut chunk_sha256: Option<String> = None;
    let mut chunk_data: Option<Vec<u8>> = None;

    while let Some(mut field) = payload.try_next().await? {
        match field.name().unwrap_or("unknown") {
            "uploadId" => {
                upload_id = Some(super::read_string_field(&mut field).await?);
            }
            "chunkIndex" => {
                let raw = super::read_string_field(&mut field).await?;
                chunk_index = Some(raw.parse::<usize>().map_err(|_| {
                    AppError::MultipartError(format!("Invalid chunkIndex value: {raw}"))
                })?);
            }
            "chunkByteLength" => {
                let raw = super::read_string_field(&mut field).await?;
                chunk_byte_length = Some(raw.parse::<usize>().map_err(|_| {
                    AppError::MultipartError(format!("Invalid chunkByteLength value: {raw}"))
                })?);
            }
            "chunkSha256" => {
                chunk_sha256 = Some(super::read_string_field(&mut field).await?);
            }
            "chunk" => {
                let mut bytes = Vec::new();
                while let Some(chunk) = field.try_next().await? {
                    bytes.extend_from_slice(&chunk);
                }
                chunk_data = Some(bytes);
            }
            _ => {}
        }
    }

    let upload_id = upload_id.ok_or_else(|| {
        AppError::MultipartError("Missing uploadId field in chunk payload".to_string())
    })?;
    let chunk_index = chunk_index.ok_or_else(|| {
        AppError::MultipartError("Missing chunkIndex field in chunk payload".to_string())
    })?;
    let chunk_sha256 = chunk_sha256.ok_or_else(|| {
        AppError::MultipartError("Missing chunkSha256 field in chunk payload".to_string())
    })?;
    let chunk_data = chunk_data.ok_or_else(|| {
        AppError::MultipartError("Missing chunk data in chunk payload".to_string())
    })?;

    Ok(ExportChunkMultipartData {
        upload_id,
        chunk_index,
        chunk_byte_length,
        chunk_sha256,
        chunk_data,
    })
}
