use std::collections::BTreeSet;

use crate::services::project::import_session::UploadSession;

pub fn validate_project_size(size_bytes: u64, max_bytes: u64) -> Result<usize, String> {
    if size_bytes == 0 {
        return Err("sizeBytes must be greater than zero".to_string());
    }
    if size_bytes > max_bytes {
        return Err(format!(
            "Project exceeds maximum supported size of {} bytes",
            max_bytes
        ));
    }
    usize::try_from(size_bytes)
        .map_err(|_| "Project size is too large for this platform".to_string())
}

pub fn validate_chunk_bounds(session: &UploadSession, chunk_index: usize) -> Result<(), String> {
    if chunk_index >= session.total_chunks {
        return Err(format!(
            "chunkIndex out of range: {} (total chunks: {})",
            chunk_index, session.total_chunks
        ));
    }
    Ok(())
}

pub fn validate_declared_chunk_size(
    declared_chunk_size: Option<usize>,
    payload_len: usize,
) -> Result<(), String> {
    if let Some(declared) = declared_chunk_size
        && declared != payload_len
    {
        return Err(format!(
            "Declared chunkByteLength {} does not match payload size {}",
            declared, payload_len
        ));
    }
    Ok(())
}

pub fn validate_chunk_payload_size(
    expected_chunk_size: usize,
    payload_len: usize,
    chunk_index: usize,
) -> Result<(), String> {
    if payload_len != expected_chunk_size {
        return Err(format!(
            "Chunk size mismatch at index {}: expected {}, received {}",
            chunk_index, expected_chunk_size, payload_len
        ));
    }
    Ok(())
}

pub fn missing_chunks(session: &UploadSession) -> Vec<usize> {
    (0..session.total_chunks)
        .filter(|idx| !session.received_chunks.contains(idx))
        .collect()
}

pub fn as_sorted_chunks(received_chunks: &BTreeSet<usize>) -> Vec<usize> {
    received_chunks.iter().copied().collect()
}
