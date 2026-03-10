// @efficiency-role: service-orchestrator
use std::path::PathBuf;
use std::time::SystemTime;

use uuid::Uuid;

use crate::services::project::export_session::{
    ExportUploadSession, MAX_EXPORT_PAYLOAD_SIZE_BYTES, as_sorted_chunks, missing_chunks,
    normalize_chunk_size, to_epoch_ms,
};
use crate::services::project::export_upload::{
    ChunkedProjectExportUploadManager, ExportChunkAck, ExportInitSession, ExportUploadStatus,
};

pub(super) async fn assemble_chunks(
    session: &ExportUploadSession,
    output_path: &PathBuf,
) -> Result<(), String> {
    let file = tokio::fs::File::create(output_path)
        .await
        .map_err(|e| format!("Failed to create assembled upload file: {e}"))?;
    let mut writer = tokio::io::BufWriter::new(file);

    for idx in 0..session.total_chunks {
        let chunk_path = session.chunk_path(idx);
        let chunk_bytes = tokio::fs::read(&chunk_path)
            .await
            .map_err(|e| format!("Failed to read chunk {}: {}", idx, e))?;
        tokio::io::AsyncWriteExt::write_all(&mut writer, &chunk_bytes)
            .await
            .map_err(|e| format!("Failed to write chunk {}: {}", idx, e))?;
    }

    tokio::io::AsyncWriteExt::flush(&mut writer)
        .await
        .map_err(|e| format!("Failed to flush assembled upload file: {e}"))?;

    Ok(())
}

pub(super) async fn init_session(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    filename: &str,
    size_bytes: u64,
    requested_chunk_size_bytes: Option<usize>,
) -> Result<ExportInitSession, String> {
    super::cleanup_expired(manager).await;

    let size_bytes_usize = super::validate_payload_size(size_bytes, MAX_EXPORT_PAYLOAD_SIZE_BYTES)?;
    let filename = crate::api::utils::sanitize_filename(filename)
        .map_err(|e| format!("Invalid filename: {e}"))?;
    let chunk_size_bytes = normalize_chunk_size(requested_chunk_size_bytes)?;
    let total_chunks = size_bytes_usize.div_ceil(chunk_size_bytes);
    if total_chunks == 0 {
        return Err("Could not determine chunk count".to_string());
    }

    let upload_id = Uuid::new_v4().to_string();
    let session_dir = manager.root_dir.join(&upload_id);
    tokio::fs::create_dir_all(&session_dir)
        .await
        .map_err(|e| format!("Failed to initialize export upload session: {e}"))?;

    let expires_at = SystemTime::now() + manager.ttl;
    let expires_at_epoch_ms = to_epoch_ms(expires_at)?;
    let session = ExportUploadSession {
        user_id: user_id.to_string(),
        filename,
        size_bytes,
        size_bytes_usize,
        chunk_size_bytes,
        total_chunks,
        received_chunks: Default::default(),
        session_dir,
        expires_at,
    };

    manager
        .sessions
        .write()
        .await
        .insert(upload_id.clone(), session);

    Ok(ExportInitSession {
        upload_id,
        chunk_size_bytes,
        total_chunks,
        expires_at_epoch_ms,
    })
}

pub(super) async fn save_chunk(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    upload_id: &str,
    chunk_index: usize,
    chunk_data: Vec<u8>,
    declared_chunk_size: Option<usize>,
    declared_sha256: &str,
) -> Result<ExportChunkAck, String> {
    super::cleanup_expired(manager).await;
    let session = {
        let sessions = manager.sessions.read().await;
        let session = sessions
            .get(upload_id)
            .ok_or_else(|| "Upload session not found or expired".to_string())?;
        if session.user_id != user_id {
            return Err("Upload session does not belong to authenticated user".to_string());
        }
        session.clone()
    };

    super::validate_chunk_bounds(&session, chunk_index)?;
    let expected_chunk_size = session
        .expected_chunk_size(chunk_index)
        .ok_or_else(|| "Unable to resolve expected chunk size".to_string())?;
    super::validate_declared_chunk_size(declared_chunk_size, chunk_data.len())?;
    if expected_chunk_size != chunk_data.len() {
        return Err(format!(
            "Chunk {} size mismatch: expected {}, got {}",
            chunk_index,
            expected_chunk_size,
            chunk_data.len()
        ));
    }

    let computed_sha = super::sha256_hex(&chunk_data);
    if !declared_sha256.eq_ignore_ascii_case(&computed_sha) {
        return Err(format!(
            "Chunk {} checksum mismatch: expected {}, got {}",
            chunk_index, declared_sha256, computed_sha
        ));
    }

    let chunk_path = session.chunk_path(chunk_index);
    tokio::fs::write(&chunk_path, &chunk_data)
        .await
        .map_err(|e| format!("Failed to persist chunk {}: {}", chunk_index, e))?;

    let mut sessions = manager.sessions.write().await;
    let active_session = sessions
        .get_mut(upload_id)
        .ok_or_else(|| "Upload session was removed before chunk commit".to_string())?;
    if active_session.user_id != user_id {
        return Err("Upload session does not belong to authenticated user".to_string());
    }
    active_session.received_chunks.insert(chunk_index);
    Ok(ExportChunkAck {
        accepted: true,
        next_expected_chunk: active_session.next_expected_chunk(),
        received_count: active_session.received_chunks.len(),
    })
}

pub(super) async fn status(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    upload_id: &str,
) -> Result<ExportUploadStatus, String> {
    super::cleanup_expired(manager).await;
    let sessions = manager.sessions.read().await;
    let session = sessions
        .get(upload_id)
        .ok_or_else(|| "Upload session not found or expired".to_string())?;
    if session.user_id != user_id {
        return Err("Upload session does not belong to authenticated user".to_string());
    }
    Ok(ExportUploadStatus {
        received_chunks: as_sorted_chunks(&session.received_chunks),
        next_expected_chunk: session.next_expected_chunk(),
        total_chunks: session.total_chunks,
        expires_at_epoch_ms: to_epoch_ms(session.expires_at)?,
    })
}

pub(super) async fn complete_session(
    manager: &ChunkedProjectExportUploadManager,
    user_id: &str,
    upload_id: &str,
    filename: &str,
    size_bytes: u64,
    total_chunks: usize,
) -> Result<PathBuf, String> {
    super::cleanup_expired(manager).await;
    let session = {
        let sessions = manager.sessions.read().await;
        let session = sessions
            .get(upload_id)
            .ok_or_else(|| "Upload session not found or expired".to_string())?;
        if session.user_id != user_id {
            return Err("Upload session does not belong to authenticated user".to_string());
        }
        let safe_filename = crate::api::utils::sanitize_filename(filename)
            .map_err(|e| format!("Invalid filename: {e}"))?;
        if safe_filename != session.filename {
            return Err("Completion metadata mismatch for filename".to_string());
        }
        if size_bytes != session.size_bytes {
            return Err("Completion metadata mismatch for sizeBytes".to_string());
        }
        if total_chunks != session.total_chunks {
            return Err("Completion metadata mismatch for totalChunks".to_string());
        }
        let missing = missing_chunks(session);
        if !missing.is_empty() {
            return Err(format!(
                "Cannot complete export upload. Missing chunks: {:?}",
                missing
            ));
        }
        session.clone()
    };

    let assembled_path = crate::api::utils::get_temp_path("bin");
    super::assemble_chunks(&session, &assembled_path).await?;

    let actual_size = tokio::fs::metadata(&assembled_path)
        .await
        .map_err(|e| format!("Failed to inspect assembled upload: {e}"))?
        .len();
    if actual_size != session.size_bytes {
        let _ = tokio::fs::remove_file(&assembled_path).await;
        return Err(format!(
            "Assembled upload size mismatch: expected {}, got {}",
            session.size_bytes, actual_size
        ));
    }

    let _ = super::remove_session(manager, upload_id, user_id).await;
    Ok(assembled_path)
}

pub(super) async fn remove_session(
    manager: &ChunkedProjectExportUploadManager,
    upload_id: &str,
    user_id: &str,
) -> Result<bool, String> {
    let removed = {
        let mut sessions = manager.sessions.write().await;
        let session = sessions
            .get(upload_id)
            .ok_or_else(|| "Upload session not found or expired".to_string())?;
        if session.user_id != user_id {
            return Err("Upload session does not belong to authenticated user".to_string());
        }
        sessions.remove(upload_id)
    };

    if let Some(session) = removed {
        let _ = tokio::fs::remove_dir_all(&session.session_dir).await;
        Ok(true)
    } else {
        Ok(false)
    }
}

pub(super) async fn cleanup_expired(manager: &ChunkedProjectExportUploadManager) {
    let now = SystemTime::now();
    let expired = {
        let mut sessions = manager.sessions.write().await;
        let expired_ids: Vec<String> = sessions
            .iter()
            .filter_map(|(id, session)| (session.expires_at <= now).then_some(id.clone()))
            .collect();

        let mut removed = Vec::with_capacity(expired_ids.len());
        for id in expired_ids {
            if let Some(session) = sessions.remove(&id) {
                removed.push(session);
            }
        }
        removed
    };

    for session in expired {
        let _ = tokio::fs::remove_dir_all(&session.session_dir).await;
    }
}
