// @efficiency-role: domain-logic
use sha2::{Digest, Sha256};

use crate::services::project::export_session::ExportUploadSession;

pub(super) fn validate_payload_size(size_bytes: u64, max_size_bytes: u64) -> Result<usize, String> {
    if size_bytes == 0 {
        return Err("sizeBytes must be greater than zero".to_string());
    }
    if size_bytes > max_size_bytes {
        return Err(format!(
            "sizeBytes {} exceeds maximum {}",
            size_bytes, max_size_bytes
        ));
    }
    usize::try_from(size_bytes).map_err(|_| "sizeBytes exceeds platform capacity".to_string())
}

pub(super) fn validate_chunk_bounds(
    session: &ExportUploadSession,
    chunk_index: usize,
) -> Result<(), String> {
    if chunk_index >= session.total_chunks {
        return Err(format!(
            "Chunk index {} out of bounds for totalChunks {}",
            chunk_index, session.total_chunks
        ));
    }
    Ok(())
}

pub(super) fn validate_declared_chunk_size(
    declared_chunk_size: Option<usize>,
    actual_chunk_size: usize,
) -> Result<(), String> {
    if let Some(declared) = declared_chunk_size
        && declared != actual_chunk_size
    {
        return Err(format!(
            "Chunk size mismatch: declared {}, actual {}",
            declared, actual_chunk_size
        ));
    }
    Ok(())
}

pub(super) fn sha256_hex(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}
