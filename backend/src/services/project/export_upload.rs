#[path = "export_upload_runtime.rs"]
mod export_upload_runtime;

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

use tokio::sync::RwLock;

use crate::services::project::export_session::ExportUploadSession;

const DEFAULT_UPLOAD_TTL_SECS: u64 = 30 * 60;

#[derive(Clone, Debug)]
pub struct ExportInitSession {
    pub upload_id: String,
    pub chunk_size_bytes: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Clone, Debug)]
pub struct ExportChunkAck {
    pub accepted: bool,
    pub next_expected_chunk: usize,
    pub received_count: usize,
}

#[derive(Clone, Debug)]
pub struct ExportUploadStatus {
    pub received_chunks: Vec<usize>,
    pub next_expected_chunk: usize,
    pub total_chunks: usize,
    pub expires_at_epoch_ms: u64,
}

#[derive(Clone, Debug)]
pub struct ChunkedProjectExportUploadManager {
    pub(crate) root_dir: PathBuf,
    pub(crate) ttl: Duration,
    pub(crate) sessions: Arc<RwLock<HashMap<String, ExportUploadSession>>>,
}

impl ChunkedProjectExportUploadManager {
    pub fn new() -> std::io::Result<Self> {
        Self::with_ttl(Duration::from_secs(DEFAULT_UPLOAD_TTL_SECS))
    }

    pub fn with_ttl(ttl: Duration) -> std::io::Result<Self> {
        let mut root_dir = std::env::var("TEMP_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from(crate::api::utils::TEMP_DIR));
        root_dir.push("project_export_chunks");
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
    ) -> Result<ExportInitSession, String> {
        export_upload_runtime::init_session(
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
        declared_sha256: &str,
    ) -> Result<ExportChunkAck, String> {
        export_upload_runtime::save_chunk(
            self,
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
        &self,
        user_id: &str,
        upload_id: &str,
    ) -> Result<ExportUploadStatus, String> {
        export_upload_runtime::status(self, user_id, upload_id).await
    }

    pub async fn complete_session(
        &self,
        user_id: &str,
        upload_id: &str,
        filename: &str,
        size_bytes: u64,
        total_chunks: usize,
    ) -> Result<PathBuf, String> {
        export_upload_runtime::complete_session(
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
        export_upload_runtime::remove_session(self, upload_id, user_id).await
    }

    async fn cleanup_expired(&self) {
        export_upload_runtime::cleanup_expired(self).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sha2::{Digest, Sha256};

    fn sha_hex(data: &[u8]) -> String {
        let mut hasher = Sha256::new();
        hasher.update(data);
        format!("{:x}", hasher.finalize())
    }

    #[tokio::test]
    async fn completes_chunked_payload_and_reassembles_in_order() {
        let manager = ChunkedProjectExportUploadManager::new().expect("manager should initialize");
        let chunk_size = 512 * 1024_usize;
        let total_size = (chunk_size * 2) as u64;
        let init = manager
            .init_session("user-a", "export_payload.bin", total_size, Some(chunk_size))
            .await
            .expect("init should succeed");

        let chunk0 = vec![b'a'; chunk_size];
        let chunk1 = vec![b'b'; chunk_size];
        manager
            .save_chunk(
                "user-a",
                &init.upload_id,
                0,
                chunk0.clone(),
                Some(chunk0.len()),
                &sha_hex(&chunk0),
            )
            .await
            .expect("chunk 0 should succeed");
        manager
            .save_chunk(
                "user-a",
                &init.upload_id,
                1,
                chunk1.clone(),
                Some(chunk1.len()),
                &sha_hex(&chunk1),
            )
            .await
            .expect("chunk 1 should succeed");

        let assembled = manager
            .complete_session("user-a", &init.upload_id, "export_payload.bin", total_size, 2)
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
        let _ = tokio::fs::remove_file(assembled).await;
    }

    #[tokio::test]
    async fn rejects_checksum_mismatch() {
        let manager = ChunkedProjectExportUploadManager::new().expect("manager should initialize");
        let chunk_size = 512 * 1024_usize;
        let total_size = chunk_size as u64;
        let init = manager
            .init_session("user-a", "export_payload.bin", total_size, Some(chunk_size))
            .await
            .expect("init should succeed");

        let chunk0 = vec![b'a'; chunk_size];
        let err = manager
            .save_chunk(
                "user-a",
                &init.upload_id,
                0,
                chunk0.clone(),
                Some(chunk0.len()),
                "deadbeef",
            )
            .await
            .expect_err("checksum mismatch should fail");
        assert!(err.contains("checksum mismatch"));
    }
}
