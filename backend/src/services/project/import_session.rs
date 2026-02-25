// @efficiency-role: service-orchestrator
/* backend/src/services/project/import_session.rs - Project Import Session Logic */

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::io::AsyncWriteExt;

pub const DEFAULT_IMPORT_CHUNK_SIZE_BYTES: usize = 5 * 1024 * 1024; // 5MB
pub const MAX_IMPORT_CHUNK_SIZE_BYTES: usize = 10 * 1024 * 1024; // 10MB hard cap
pub const MIN_IMPORT_CHUNK_SIZE_BYTES: usize = 256 * 1024; // 256KB

#[derive(Clone, Debug)]
pub(crate) struct UploadSession {
    pub user_id: String,
    pub filename: String,
    pub size_bytes: u64,
    pub size_bytes_usize: usize,
    pub chunk_size_bytes: usize,
    pub total_chunks: usize,
    pub received_chunks: BTreeSet<usize>,
    pub session_dir: PathBuf,
    pub expires_at: SystemTime,
}

impl UploadSession {
    pub fn chunk_path(&self, index: usize) -> PathBuf {
        self.session_dir.join(format!("chunk_{index:08}.part"))
    }

    pub fn expected_chunk_size(&self, index: usize) -> Option<usize> {
        if index >= self.total_chunks {
            return None;
        }

        let start = index.saturating_mul(self.chunk_size_bytes);
        let remaining = self.size_bytes_usize.saturating_sub(start);
        Some(remaining.min(self.chunk_size_bytes))
    }

    pub fn next_expected_chunk(&self) -> usize {
        (0..self.total_chunks)
            .find(|idx| !self.received_chunks.contains(idx))
            .unwrap_or(self.total_chunks)
    }
}

pub fn normalize_chunk_size(requested_chunk_size: Option<usize>) -> Result<usize, String> {
    let candidate = requested_chunk_size.unwrap_or(DEFAULT_IMPORT_CHUNK_SIZE_BYTES);
    if candidate < MIN_IMPORT_CHUNK_SIZE_BYTES {
        return Err(format!(
            "chunkSizeBytes {} is below minimum {}",
            candidate, MIN_IMPORT_CHUNK_SIZE_BYTES
        ));
    }
    if candidate > MAX_IMPORT_CHUNK_SIZE_BYTES {
        return Err(format!(
            "chunkSizeBytes {} exceeds maximum {}",
            candidate, MAX_IMPORT_CHUNK_SIZE_BYTES
        ));
    }
    Ok(candidate)
}

pub async fn assemble_chunks(session: &UploadSession, output_path: &Path) -> Result<(), String> {
    let file = tokio::fs::File::create(output_path)
        .await
        .map_err(|e| format!("Failed to create assembled upload file: {e}"))?;
    let mut writer = tokio::io::BufWriter::new(file);

    for idx in 0..session.total_chunks {
        let chunk_path = session.chunk_path(idx);
        let chunk_bytes = tokio::fs::read(&chunk_path)
            .await
            .map_err(|e| format!("Failed to read chunk {}: {}", idx, e))?;
        writer
            .write_all(&chunk_bytes)
            .await
            .map_err(|e| format!("Failed to write chunk {}: {}", idx, e))?;
    }

    writer
        .flush()
        .await
        .map_err(|e| format!("Failed to flush assembled upload file: {e}"))?;

    Ok(())
}

pub fn to_epoch_ms(time: SystemTime) -> Result<u64, String> {
    let millis = time
        .duration_since(UNIX_EPOCH)
        .map_err(|_| "System clock drift detected while converting timestamp".to_string())?
        .as_millis();
    u64::try_from(millis).map_err(|_| "Timestamp overflow".to_string())
}
