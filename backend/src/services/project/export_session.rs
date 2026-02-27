use std::collections::BTreeSet;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

pub const DEFAULT_EXPORT_CHUNK_SIZE_BYTES: usize = 50 * 1024 * 1024; // 50MB
pub const MAX_EXPORT_CHUNK_SIZE_BYTES: usize = 100 * 1024 * 1024; // 100MB
pub const MIN_EXPORT_CHUNK_SIZE_BYTES: usize = 512 * 1024; // 512KB
pub const MAX_EXPORT_PAYLOAD_SIZE_BYTES: u64 = 10 * 1024 * 1024 * 1024; // 10GB

#[derive(Clone, Debug)]
pub(crate) struct ExportUploadSession {
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

impl ExportUploadSession {
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
    let candidate = requested_chunk_size.unwrap_or(DEFAULT_EXPORT_CHUNK_SIZE_BYTES);
    if candidate < MIN_EXPORT_CHUNK_SIZE_BYTES {
        return Err(format!(
            "chunkSizeBytes {} is below minimum {}",
            candidate, MIN_EXPORT_CHUNK_SIZE_BYTES
        ));
    }
    if candidate > MAX_EXPORT_CHUNK_SIZE_BYTES {
        return Err(format!(
            "chunkSizeBytes {} exceeds maximum {}",
            candidate, MAX_EXPORT_CHUNK_SIZE_BYTES
        ));
    }
    Ok(candidate)
}

pub fn as_sorted_chunks(chunks: &BTreeSet<usize>) -> Vec<usize> {
    chunks.iter().copied().collect()
}

pub fn missing_chunks(session: &ExportUploadSession) -> Vec<usize> {
    (0..session.total_chunks)
        .filter(|idx| !session.received_chunks.contains(idx))
        .collect()
}

pub fn to_epoch_ms(time: SystemTime) -> Result<u64, String> {
    let millis = time
        .duration_since(UNIX_EPOCH)
        .map_err(|_| "System clock drift detected while converting timestamp".to_string())?
        .as_millis();
    u64::try_from(millis).map_err(|_| "Timestamp overflow".to_string())
}
