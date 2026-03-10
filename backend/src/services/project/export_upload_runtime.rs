// @efficiency-role: domain-logic
#[path = "export_upload_runtime_session.rs"]
mod export_upload_runtime_session;
#[path = "export_upload_runtime_validation.rs"]
mod export_upload_runtime_validation;

use std::path::PathBuf;

use crate::services::project::export_session::ExportUploadSession;
use crate::services::project::export_upload::{
    ChunkedProjectExportUploadManager, ExportChunkAck, ExportInitSession, ExportUploadStatus,
};

fn validate_payload_size(size_bytes: u64, max_size_bytes: u64) -> Result<usize, String> {
    export_upload_runtime_validation::validate_payload_size(size_bytes, max_size_bytes)
}

fn validate_chunk_bounds(session: &ExportUploadSession, chunk_index: usize) -> Result<(), String> {
    export_upload_runtime_validation::validate_chunk_bounds(session, chunk_index)
}

fn validate_declared_chunk_size(
    declared_chunk_size: Option<usize>,
    actual_chunk_size: usize,
) -> Result<(), String> {
    export_upload_runtime_validation::validate_declared_chunk_size(
        declared_chunk_size,
        actual_chunk_size,
    )
}

fn sha256_hex(data: &[u8]) -> String {
    export_upload_runtime_validation::sha256_hex(data)
}

async fn assemble_chunks(
    session: &ExportUploadSession,
    output_path: &PathBuf,
) -> Result<(), String> {
    export_upload_runtime_session::assemble_chunks(session, output_path).await
}

pub async fn init_session(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    filename: &str,
    size_bytes: u64,
    requested_chunk_size_bytes: Option<usize>,
) -> Result<ExportInitSession, String> {
    export_upload_runtime_session::init_session(
        manager,
        user_id,
        filename,
        size_bytes,
        requested_chunk_size_bytes,
    )
    .await
}

pub async fn save_chunk(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    upload_id: &str,
    chunk_index: usize,
    chunk_data: Vec<u8>,
    declared_chunk_size: Option<usize>,
    declared_sha256: &str,
) -> Result<ExportChunkAck, String> {
    export_upload_runtime_session::save_chunk(
        manager,
        user_id,
        upload_id,
        chunk_index,
        chunk_data,
        declared_chunk_size,
        declared_sha256,
    )
    .await
}

pub async fn status(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    upload_id: &str,
) -> Result<ExportUploadStatus, String> {
    export_upload_runtime_session::status(manager, user_id, upload_id).await
}

pub async fn complete_session(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    upload_id: &str,
    filename: &str,
    size_bytes: u64,
    total_chunks: usize,
) -> Result<PathBuf, String> {
    export_upload_runtime_session::complete_session(
        manager,
        user_id,
        upload_id,
        filename,
        size_bytes,
        total_chunks,
    )
    .await
}

pub async fn remove_session(
    manager: &ChunkedProjectExportUploadManager,
    upload_id: &str,
    user_id: &str,
) -> Result<bool, String> {
    export_upload_runtime_session::remove_session(manager, upload_id, user_id).await
}

pub async fn cleanup_expired(manager: &ChunkedProjectExportUploadManager) {
    export_upload_runtime_session::cleanup_expired(manager).await
}
