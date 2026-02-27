// @efficiency-role: domain-logic

#[path = "import_upload_runtime.rs"]
mod import_upload_runtime;

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

use tokio::sync::RwLock;

use crate::services::project::import_session::UploadSession;

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
    pub(crate) root_dir: PathBuf,
    pub(crate) ttl: Duration,
    pub(crate) sessions: Arc<RwLock<HashMap<String, UploadSession>>>,
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
        import_upload_runtime::init_session(
            self,
            user_id,
            filename,
            size_bytes,
            requested_chunk_size_bytes,
        )
        .await
    }

    pub async fn save_chunk(
        &self,
        user_id: &str,
        upload_id: &str,
        chunk_index: usize,
        chunk_data: Vec<u8>,
        declared_chunk_size: Option<usize>,
    ) -> Result<ImportChunkAck, String> {
        import_upload_runtime::save_chunk(
            self,
            user_id,
            upload_id,
            chunk_index,
            chunk_data,
            declared_chunk_size,
        )
        .await
    }

    pub async fn status(
        &self,
        user_id: &str,
        upload_id: &str,
    ) -> Result<ImportUploadStatus, String> {
        import_upload_runtime::status(self, user_id, upload_id).await
    }

    pub async fn complete_session(
        &self,
        user_id: &str,
        upload_id: &str,
        filename: &str,
        size_bytes: u64,
        total_chunks: usize,
    ) -> Result<PathBuf, String> {
        import_upload_runtime::complete_session(
            self,
            user_id,
            upload_id,
            filename,
            size_bytes,
            total_chunks,
        )
        .await
    }

    pub async fn abort_session(&self, user_id: &str, upload_id: &str) -> Result<bool, String> {
        self.cleanup_expired().await;
        self.remove_session(upload_id, user_id).await
    }

    async fn remove_session(&self, upload_id: &str, user_id: &str) -> Result<bool, String> {
        import_upload_runtime::remove_session(self, upload_id, user_id).await
    }

    async fn cleanup_expired(&self) {
        import_upload_runtime::cleanup_expired(self).await
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
