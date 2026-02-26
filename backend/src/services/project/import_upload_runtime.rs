// @efficiency-role: domain-logic

use std::path::PathBuf;
use std::time::SystemTime;

use crate::services::project::import_session::{
    UploadSession, assemble_chunks, normalize_chunk_size, to_epoch_ms,
};
use crate::services::project::import_upload::{
    ChunkedProjectImportManager, ImportChunkAck, ImportInitSession, ImportUploadStatus,
    MAX_IMPORT_PROJECT_SIZE_BYTES,
};
use crate::services::project::import_upload_logic;
use uuid::Uuid;

pub async fn init_session(
    manager: &ChunkedProjectImportManager,
    user_id: &str,
    filename: &str,
    size_bytes: u64,
    requested_chunk_size_bytes: Option<usize>,
) -> Result<ImportInitSession, String> {
    cleanup_expired(manager).await;

    let size_bytes_usize =
        import_upload_logic::validate_project_size(size_bytes, MAX_IMPORT_PROJECT_SIZE_BYTES)?;
    let filename = crate::api::utils::sanitize_filename(filename)
        .map_err(|e| format!("Invalid filename: {e}"))?;

    let chunk_size_bytes = normalize_chunk_size(requested_chunk_size_bytes)?;
    let total_chunks = (size_bytes_usize + chunk_size_bytes - 1) / chunk_size_bytes;
    if total_chunks == 0 {
        return Err("Could not determine chunk count".to_string());
    }

    let upload_id = Uuid::new_v4().to_string();
    let session_dir = manager.root_dir.join(&upload_id);
    tokio::fs::create_dir_all(&session_dir)
        .await
        .map_err(|e| format!("Failed to initialize upload session: {e}"))?;

    let expires_at = SystemTime::now() + manager.ttl;
    let session = UploadSession {
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

    let expires_at_epoch_ms = to_epoch_ms(expires_at)?;
    manager
        .sessions
        .write()
        .await
        .insert(upload_id.clone(), session);

    Ok(ImportInitSession {
        upload_id,
        chunk_size_bytes,
        total_chunks,
        expires_at_epoch_ms,
    })
}

pub async fn save_chunk(
    manager: &ChunkedProjectImportManager,
    user_id: &str,
    upload_id: &str,
    chunk_index: usize,
    chunk_data: Vec<u8>,
    declared_chunk_size: Option<usize>,
) -> Result<ImportChunkAck, String> {
    cleanup_expired(manager).await;
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

    import_upload_logic::validate_chunk_bounds(&session, chunk_index)?;
    let expected_chunk_size = session
        .expected_chunk_size(chunk_index)
        .ok_or_else(|| "Unable to resolve expected chunk size".to_string())?;
    import_upload_logic::validate_declared_chunk_size(declared_chunk_size, chunk_data.len())?;
    import_upload_logic::validate_chunk_payload_size(
        expected_chunk_size,
        chunk_data.len(),
        chunk_index,
    )?;

    let chunk_path = session.chunk_path(chunk_index);
    if let Ok(metadata) = tokio::fs::metadata(&chunk_path).await {
        if metadata.len() as usize != chunk_data.len() {
            return Err(format!(
                "Chunk {} already exists with a different byte size",
                chunk_index
            ));
        }
    } else {
        tokio::fs::write(&chunk_path, &chunk_data)
            .await
            .map_err(|e| format!("Failed to persist chunk {}: {}", chunk_index, e))?;
    }

    let mut sessions = manager.sessions.write().await;
    let active_session = sessions
        .get_mut(upload_id)
        .ok_or_else(|| "Upload session was removed before chunk commit".to_string())?;
    if active_session.user_id != user_id {
        return Err("Upload session does not belong to authenticated user".to_string());
    }

    active_session.received_chunks.insert(chunk_index);
    Ok(ImportChunkAck {
        accepted: true,
        next_expected_chunk: active_session.next_expected_chunk(),
        received_count: active_session.received_chunks.len(),
    })
}

pub async fn status(
    manager: &ChunkedProjectImportManager,
    user_id: &str,
    upload_id: &str,
) -> Result<ImportUploadStatus, String> {
    cleanup_expired(manager).await;

    let sessions = manager.sessions.read().await;
    let session = sessions
        .get(upload_id)
        .ok_or_else(|| "Upload session not found or expired".to_string())?;
    if session.user_id != user_id {
        return Err("Upload session does not belong to authenticated user".to_string());
    }

    Ok(ImportUploadStatus {
        received_chunks: import_upload_logic::as_sorted_chunks(&session.received_chunks),
        next_expected_chunk: session.next_expected_chunk(),
        total_chunks: session.total_chunks,
        expires_at_epoch_ms: to_epoch_ms(session.expires_at)?,
    })
}

pub async fn complete_session(
    manager: &ChunkedProjectImportManager,
    user_id: &str,
    upload_id: &str,
    filename: &str,
    size_bytes: u64,
    total_chunks: usize,
) -> Result<PathBuf, String> {
    cleanup_expired(manager).await;

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

        let missing = import_upload_logic::missing_chunks(session);
        if !missing.is_empty() {
            return Err(format!(
                "Cannot complete upload. Missing chunks: {:?}",
                missing
            ));
        }

        session.clone()
    };

    let assembled_path = crate::api::utils::get_temp_path("zip");
    assemble_chunks(&session, &assembled_path).await?;

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

    let _ = remove_session(manager, upload_id, user_id).await;
    Ok(assembled_path)
}

pub async fn remove_session(
    manager: &ChunkedProjectImportManager,
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

pub async fn cleanup_expired(manager: &ChunkedProjectImportManager) {
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
