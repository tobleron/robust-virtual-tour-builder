// @efficiency-role: domain-logic

use std::collections::{BTreeSet, HashMap};
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{Duration, SystemTime};

use tokio::sync::RwLock;
use uuid::Uuid;

use crate::services::project::import_session::{
    UploadSession, assemble_chunks, normalize_chunk_size, to_epoch_ms,
};

pub use crate::services::project::import_session::MAX_IMPORT_CHUNK_SIZE_BYTES;

pub const MAX_IMPORT_PROJECT_SIZE_BYTES: u64 = 500 * 1024 * 1024; // 500MB
const DEFAULT_UPLOAD_TTL_SECS: u64 = 30 * 60;

#[derive(Clone, Debug)]
pub struct ImportInitSession {
    pub upload_id: String,
    pub chunk_size_bytes: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Clone, Debug)]
pub struct ImportChunkAck {
    pub accepted: bool,
    pub next_expected_chunk: usize,
    pub received_count: usize,
}

#[derive(Clone, Debug)]
pub struct ImportUploadStatus {
    pub received_chunks: Vec<usize>,
    pub next_expected_chunk: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Clone, Debug)]
pub struct ChunkedProjectImportManager {
    root_dir: PathBuf,
    ttl: Duration,
    sessions: Arc<RwLock<HashMap<String, UploadSession>>>,
}

impl ChunkedProjectImportManager {
    pub fn new() -> std::io::Result<Self> {
        Self::with_ttl(Duration::from_secs(DEFAULT_UPLOAD_TTL_SECS))
    }

    pub fn with_ttl(ttl: Duration) -> std::io::Result<Self> {
        let mut root_dir = std::env::var("TEMP_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from(crate::api::utils::TEMP_DIR));
        root_dir.push("project_import_chunks");
        std::fs::create_dir_all(&root_dir)?;

        Ok(Self {
            root_dir,
            ttl,
            sessions: Arc::new(RwLock::new(HashMap::new())),
        })
    }

    pub async fn init_session(
        &self,
        user_id: &str,
        filename: &str,
        size_bytes: u64,
        requested_chunk_size_bytes: Option<usize>,
    ) -> Result<ImportInitSession, String> {
        self.cleanup_expired().await;

        if size_bytes == 0 {
            return Err("sizeBytes must be greater than zero".to_string());
        }
        if size_bytes > MAX_IMPORT_PROJECT_SIZE_BYTES {
            return Err(format!(
                "Project exceeds maximum supported size of {} bytes",
                MAX_IMPORT_PROJECT_SIZE_BYTES
            ));
        }

        let size_bytes_usize = usize::try_from(size_bytes)
            .map_err(|_| "Project size is too large for this platform".to_string())?;
        let filename = crate::api::utils::sanitize_filename(filename)
            .map_err(|e| format!("Invalid filename: {e}"))?;

        let chunk_size_bytes = normalize_chunk_size(requested_chunk_size_bytes)?;
        let total_chunks = (size_bytes_usize + chunk_size_bytes - 1) / chunk_size_bytes;
        if total_chunks == 0 {
            return Err("Could not determine chunk count".to_string());
        }

        let upload_id = Uuid::new_v4().to_string();
        let session_dir = self.root_dir.join(&upload_id);
        tokio::fs::create_dir_all(&session_dir)
            .await
            .map_err(|e| format!("Failed to initialize upload session: {e}"))?;

        let expires_at = SystemTime::now() + self.ttl;

        let session = UploadSession {
            user_id: user_id.to_string(),
            filename,
            size_bytes,
            size_bytes_usize,
            chunk_size_bytes,
            total_chunks,
            received_chunks: BTreeSet::new(),
            session_dir,
            expires_at,
        };

        let expires_at_epoch_ms = to_epoch_ms(expires_at)?;

        self.sessions
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
        &self,
        user_id: &str,
        upload_id: &str,
        chunk_index: usize,
        chunk_data: Vec<u8>,
        declared_chunk_size: Option<usize>,
    ) -> Result<ImportChunkAck, String> {
        self.cleanup_expired().await;

        let session = {
            let sessions = self.sessions.read().await;
            let session = sessions
                .get(upload_id)
                .ok_or_else(|| "Upload session not found or expired".to_string())?;

            if session.user_id != user_id {
                return Err("Upload session does not belong to authenticated user".to_string());
            }

            session.clone()
        };

        if chunk_index >= session.total_chunks {
            return Err(format!(
                "chunkIndex out of range: {} (total chunks: {})",
                chunk_index, session.total_chunks
            ));
        }

        let expected_chunk_size = session
            .expected_chunk_size(chunk_index)
            .ok_or_else(|| "Unable to resolve expected chunk size".to_string())?;

        if let Some(declared) = declared_chunk_size {
            if declared != chunk_data.len() {
                return Err(format!(
                    "Declared chunkByteLength {} does not match payload size {}",
                    declared,
                    chunk_data.len()
                ));
            }
        }

        if chunk_data.len() != expected_chunk_size {
            return Err(format!(
                "Chunk size mismatch at index {}: expected {}, received {}",
                chunk_index,
                expected_chunk_size,
                chunk_data.len()
            ));
        }

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

        let mut sessions = self.sessions.write().await;
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
        &self,
        user_id: &str,
        upload_id: &str,
    ) -> Result<ImportUploadStatus, String> {
        self.cleanup_expired().await;

        let sessions = self.sessions.read().await;
        let session = sessions
            .get(upload_id)
            .ok_or_else(|| "Upload session not found or expired".to_string())?;

        if session.user_id != user_id {
            return Err("Upload session does not belong to authenticated user".to_string());
        }

        Ok(ImportUploadStatus {
            received_chunks: session.received_chunks.iter().copied().collect(),
            next_expected_chunk: session.next_expected_chunk(),
            total_chunks: session.total_chunks,
            expires_at_epoch_ms: to_epoch_ms(session.expires_at)?,
        })
    }

    pub async fn complete_session(
        &self,
        user_id: &str,
        upload_id: &str,
        filename: &str,
        size_bytes: u64,
        total_chunks: usize,
    ) -> Result<PathBuf, String> {
        self.cleanup_expired().await;

        let session = {
            let sessions = self.sessions.read().await;
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

            let missing: Vec<usize> = (0..session.total_chunks)
                .filter(|idx| !session.received_chunks.contains(idx))
                .collect();
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

        let _ = self.remove_session(upload_id, user_id).await;

        Ok(assembled_path)
    }

    pub async fn abort_session(&self, user_id: &str, upload_id: &str) -> Result<bool, String> {
        self.cleanup_expired().await;
        self.remove_session(upload_id, user_id).await
    }

    async fn remove_session(&self, upload_id: &str, user_id: &str) -> Result<bool, String> {
        let removed = {
            let mut sessions = self.sessions.write().await;
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

    async fn cleanup_expired(&self) {
        let now = SystemTime::now();
        let expired = {
            let mut sessions = self.sessions.write().await;
            let expired_ids: Vec<String> = sessions
                .iter()
                .filter_map(|(id, session)| {
                    if session.expires_at <= now {
                        Some(id.clone())
                    } else {
                        None
                    }
                })
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
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::project::import_session::MIN_IMPORT_CHUNK_SIZE_BYTES;

    #[tokio::test]
    async fn completes_chunked_payload_and_reassembles_in_order() {
        let manager = ChunkedProjectImportManager::new().expect("manager should initialize");
        let chunk_size = MIN_IMPORT_CHUNK_SIZE_BYTES;
        let total_size = (chunk_size * 2 + 2) as u64;
        let init = manager
            .init_session("user-a", "project.zip", total_size, Some(chunk_size))
            .await
            .expect("init should succeed");

        manager
            .save_chunk(
                "user-a",
                &init.upload_id,
                0,
                vec![b'a'; chunk_size],
                Some(chunk_size),
            )
            .await
            .expect("chunk 0 should be accepted");
        manager
            .save_chunk("user-a", &init.upload_id, 2, vec![b'c'; 2], Some(2))
            .await
            .expect("chunk 2 should be accepted");

        let status = manager
            .status("user-a", &init.upload_id)
            .await
            .expect("status should succeed");
        assert_eq!(status.next_expected_chunk, 1);
        assert_eq!(status.total_chunks, 3);
        assert_eq!(status.received_chunks, vec![0, 2]);

        manager
            .save_chunk(
                "user-a",
                &init.upload_id,
                1,
                vec![b'b'; chunk_size],
                Some(chunk_size),
            )
            .await
            .expect("chunk 1 should be accepted");

        let assembled = manager
            .complete_session("user-a", &init.upload_id, "project.zip", total_size, 3)
            .await
            .expect("complete should succeed");

        let bytes = tokio::fs::read(&assembled)
            .await
            .expect("assembled bytes should be readable");
        assert_eq!(bytes.len(), total_size as usize);
        assert_eq!(bytes[0], b'a');
        assert_eq!(bytes[chunk_size - 1], b'a');
        assert_eq!(bytes[chunk_size], b'b');
        assert_eq!(bytes[(chunk_size * 2) - 1], b'b');
        assert_eq!(bytes[chunk_size * 2], b'c');
        assert_eq!(bytes[(chunk_size * 2) + 1], b'c');

        let _ = tokio::fs::remove_file(assembled).await;
    }

    #[tokio::test]
    async fn rejects_invalid_chunk_byte_size() {
        let manager = ChunkedProjectImportManager::new().expect("manager should initialize");
        let chunk_size = MIN_IMPORT_CHUNK_SIZE_BYTES;
        let total_size = (chunk_size * 2) as u64;
        let init = manager
            .init_session("user-a", "project.zip", total_size, Some(chunk_size))
            .await
            .expect("init should succeed");

        let err = manager
            .save_chunk(
                "user-a",
                &init.upload_id,
                0,
                vec![0_u8; chunk_size - 1],
                Some(chunk_size - 1),
            )
            .await
            .expect_err("chunk must be rejected due to expected size mismatch");
        assert!(err.contains("Chunk size mismatch"));

        let _ = manager
            .abort_session("user-a", &init.upload_id)
            .await
            .expect("abort should succeed");
    }
}
