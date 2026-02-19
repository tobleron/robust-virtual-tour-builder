use serde_json::Value;
use std::collections::HashSet;
use std::path::PathBuf;

use crate::models::ValidationReport;
use crate::services::project;

pub fn validate_project_full_sync(
    json_content: String,
    temp_images: Vec<(String, PathBuf)>,
    project_path: Option<PathBuf>,
) -> Result<(String, ValidationReport, String), String> {
    let project_data: Value =
        serde_json::from_str(&json_content).map_err(|e| format!("Invalid project JSON: {}", e))?;
    let summary = super::summary::generate_project_summary(&project_data)?;

    let mut available_files = HashSet::new();
    for (name, _) in &temp_images {
        available_files.insert(name.clone());
    }

    if let Some(session_path) = &project_path {
        let existing_files = super::files::list_available_files(session_path);
        available_files.extend(existing_files);
    }

    let (mut validated_project, report) =
        project::validate_and_clean_project(project_data, &available_files)?;
    validated_project["validationReport"] =
        serde_json::to_value(&report).map_err(|e| format!("Failed to serialize report: {}", e))?;
    let updated_json =
        serde_json::to_string_pretty(&validated_project).map_err(|e| e.to_string())?;
    Ok((updated_json, report, summary))
}
