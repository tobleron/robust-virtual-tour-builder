use super::validate::validate_and_clean_project;
use crate::models::ValidationReport;
use std::collections::HashSet;
use std::io::{Read, Write};
use zip::write::FileOptions;

/// Processes an uploaded project ZIP and returns a normalized version.
///
/// It extract the `project.json`, validates it, ensures all image paths are
/// consistent (moving them to the `images/` directory), and repacks it.
///
/// # Arguments
/// * `zip_data` - The binary content of the uploaded ZIP file.
///
/// # Returns
/// The binary content of the normalized ZIP file.
///
/// # Errors
/// * Returns a `String` error if the ZIP is malformed or missing `project.json`.
pub fn process_uploaded_project_zip(
    zip_file: std::fs::File,
) -> Result<tempfile::NamedTempFile, String> {
    // Open uploaded ZIP archive
    let mut archive =
        zip::ZipArchive::new(zip_file).map_err(|e| format!("Failed to read ZIP: {}", e))?;

    // 1. Collect list of files in ZIP for validation
    let mut available_files = HashSet::new();
    for i in 0..archive.len() {
        if let Ok(file) = archive.by_index(i) {
            available_files.insert(file.name().to_string());
        }
    }

    // 2. Extract project.json
    let mut project_file = archive
        .by_name("project.json")
        .map_err(|e| format!("Missing project.json: {}", e))?;
    let mut project_json = String::new();
    project_file
        .read_to_string(&mut project_json)
        .map_err(|e| format!("Failed to read project.json: {}", e))?;
    drop(project_file);

    let project_data: serde_json::Value =
        serde_json::from_str(&project_json).map_err(|e| format!("Invalid project.json: {}", e))?;

    // 3. Validate and clean project
    let (mut validated_project, validation_report) =
        validate_and_clean_project(project_data, &available_files)?;

    // Log validation results
    if validation_report.has_issues() {
        tracing::warn!(
            "Project validation found issues: {} broken links removed",
            validation_report.broken_links_removed
        );
    }

    // Add validation report to project data
    validated_project["validationReport"] = serde_json::to_value(&validation_report)
        .map_err(|e| format!("Failed to serialize validation report: {}", e))?;

    // 4. Create response ZIP containing validated project.json + all images normalized in images/
    let output_file =
        tempfile::NamedTempFile::new().map_err(|e| format!("Failed to create temp file: {}", e))?;
    let mut zip_writer = zip::ZipWriter::new(output_file);
    let options = FileOptions::default()
        .compression_method(zip::CompressionMethod::Stored)
        .unix_permissions(0o755);

    // Add validated project.json
    zip_writer
        .start_file("project.json", options)
        .map_err(|e| e.to_string())?;
    let updated_json =
        serde_json::to_string_pretty(&validated_project).map_err(|e| e.to_string())?;
    zip_writer
        .write_all(updated_json.as_bytes())
        .map_err(|e| e.to_string())?;

    // Copy all image files, normalizing to images/ folder
    for i in 0..archive.len() {
        let mut file = archive
            .by_index(i)
            .map_err(|e| format!("Failed to read file {}: {}", i, e))?;

        let filename = file.name().to_string();

        // Use hardened sanitization logic
        if let Some(normalized_path) =
            crate::services::media::naming::normalize_project_entry_path(&filename)
        {
            // We already wrote the fresh project.json manually, so skip the original
            if normalized_path == "project.json" {
                continue;
            }

            zip_writer
                .start_file(&normalized_path, options)
                .map_err(|e| e.to_string())?;

            std::io::copy(&mut file, &mut zip_writer).map_err(|e| e.to_string())?;
        }
    }

    let mut result_file = zip_writer.finish().map_err(|e| e.to_string())?;

    // Rewind file to beginning for reading by caller
    use std::io::Seek;
    result_file
        .rewind()
        .map_err(|e| format!("Failed to rewind output file: {}", e))?;

    Ok(result_file)
}

/// Validates a project ZIP's internal consistency without modifying its content.
///
/// # Arguments
/// * `zip_data` - The binary content of the ZIP file to validate.
///
/// # Returns
/// A `ValidationReport` detailing any issues found.
///
/// # Errors
/// * Returns a `String` error if the ZIP cannot be read or is missing `project.json`.
pub fn validate_project_zip(zip_file: std::fs::File) -> Result<ValidationReport, String> {
    let mut archive =
        zip::ZipArchive::new(zip_file).map_err(|e| format!("Failed to read ZIP: {}", e))?;

    // Collect list of files in ZIP for validation
    let mut available_files = HashSet::new();
    for i in 0..archive.len() {
        if let Ok(file) = archive.by_index(i) {
            available_files.insert(file.name().to_string());
        }
    }

    let mut project_file = archive
        .by_name("project.json")
        .map_err(|e| format!("Missing project.json: {}", e))?;
    let mut project_json = String::new();
    project_file
        .read_to_string(&mut project_json)
        .map_err(|e| format!("Failed to read project.json: {}", e))?;
    drop(project_file);

    let project_data: serde_json::Value =
        serde_json::from_str(&project_json).map_err(|e| format!("Invalid project.json: {}", e))?;

    let (_validated_project, report) = validate_and_clean_project(project_data, &available_files)?;
    Ok(report)
}
