#[path = "project_multipart_chunks.rs"]
mod project_multipart_chunks;
#[path = "project_multipart_files.rs"]
mod project_multipart_files;

use actix_multipart::Multipart;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use crate::models::AppError;

/// Reads a string field from multipart.
pub async fn read_string_field(field: &mut actix_multipart::Field) -> Result<String, AppError> {
    project_multipart_files::read_string_field(field).await
}

/// Helper to save field content to a file asynchronously
async fn save_field_to_file(
    field: &mut actix_multipart::Field,
    path: &Path,
) -> Result<(), AppError> {
    project_multipart_files::save_field_to_file(field, path).await
}

/// Saves a file field to a temporary file.
pub async fn save_temp_file_field(
    field: &mut actix_multipart::Field,
) -> Result<(String, PathBuf), AppError> {
    project_multipart_files::save_temp_file_field(field).await
}

/// Parsed multipart payload for a chunk upload request.
pub struct ImportChunkMultipartData {
    pub upload_id: String,
    pub chunk_index: usize,
    pub chunk_byte_length: Option<usize>,
    pub chunk_data: Vec<u8>,
}

pub struct ExportChunkMultipartData {
    pub upload_id: String,
    pub chunk_index: usize,
    pub chunk_byte_length: Option<usize>,
    pub chunk_sha256: String,
    pub chunk_data: Vec<u8>,
}

/// Parses the multipart payload for saving a project.
pub async fn parse_save_project_multipart(
    mut payload: Multipart,
) -> Result<(Option<String>, Option<String>, Vec<(String, PathBuf)>), AppError> {
    project_multipart_files::parse_save_project_multipart(&mut payload).await
}

/// Extracts a single file from multipart payload based on extension logic (creates temp path).
pub async fn extract_file_from_multipart(
    mut payload: Multipart,
    ext: &str,
) -> Result<PathBuf, AppError> {
    project_multipart_files::extract_file_from_multipart(&mut payload, ext).await
}

/// Parses the multipart payload for project import chunk upload.
pub async fn parse_import_chunk_multipart(
    mut payload: Multipart,
) -> Result<ImportChunkMultipartData, AppError> {
    project_multipart_chunks::parse_import_chunk_multipart(&mut payload).await
}

pub async fn parse_export_chunk_multipart(
    mut payload: Multipart,
) -> Result<ExportChunkMultipartData, AppError> {
    project_multipart_chunks::parse_export_chunk_multipart(&mut payload).await
}

/// Parses the multipart payload for creating a tour package.
pub async fn parse_tour_package_multipart(
    mut payload: Multipart,
) -> Result<(Vec<(String, PathBuf)>, HashMap<String, String>), AppError> {
    project_multipart_files::parse_tour_package_multipart(&mut payload).await
}

/// Saves the entire multipart payload to a temporary file (used for loading project zip).
pub async fn save_multipart_to_tempfile(mut payload: Multipart) -> Result<fs::File, AppError> {
    project_multipart_files::save_multipart_to_tempfile(&mut payload).await
}
