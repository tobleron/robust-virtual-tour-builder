/* backend/src/services/media/naming.rs */

use once_cell::sync::Lazy;
use regex::Regex;
use std::path::Path;

static FILENAME_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"_(\d{6})_\d{2}_(\d{3})").expect("Invalid regex pattern in source code")
});

/// Extracts a suggested human-readable name from a camera-generated filename.
pub fn get_suggested_name(original: &str) -> String {
    let base_name = Path::new(original)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or(original);

    if let Some(caps) = FILENAME_REGEX.captures(base_name)
        && caps.len() >= 3
    {
        return format!("{}_{}", &caps[1], &caps[2]);
    }

    base_name.to_string()
}

/// Sanitizes an asset path to prevent Zip Slip and directory traversal attacks.
///
/// # Rules:
/// 1. Strips all directory components (parent `..`, current `.`, root `/`).
/// 2. Returns only the filename component.
/// 3. If the filename is empty, returns a safe default.
pub fn sanitize_asset_path(path: &str) -> String {
    let path_obj = Path::new(path);
    
    // Extract just the filename component, ignoring all directory traversal attempts
    match path_obj.file_name() {
        Some(name) => name.to_string_lossy().into_owned(),
        None => "unknown_asset".to_string(),
    }
}

/// Normalizes a project file entry to ensure it lives in the correct location.
///
/// * `project.json` stays at root.
/// * Images (.webp, .jpg, .png) are forced into `images/`.
/// * Everything else is considered invalid/unsafe for now (or ignored by the caller).
pub fn normalize_project_entry_path(filename: &str) -> Option<String> {
    let sanitized_name = sanitize_asset_path(filename);
    
    if sanitized_name == "project.json" {
        return Some("project.json".to_string());
    }
    
    if sanitized_name.ends_with(".webp")
        || sanitized_name.ends_with(".jpg")
        || sanitized_name.ends_with(".jpeg")
        || sanitized_name.ends_with(".png") 
    {
        return Some(format!("images/{}", sanitized_name));
    }
    
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_asset_path_removes_traversal() {
        assert_eq!(sanitize_asset_path("../../etc/passwd"), "passwd");
        assert_eq!(sanitize_asset_path("images/../hidden/secret.jpg"), "secret.jpg");
        assert_eq!(sanitize_asset_path("/absolute/path/to/file.png"), "file.png");
        assert_eq!(sanitize_asset_path("normal.webp"), "normal.webp");
    }

    #[test]
    fn test_normalize_project_entry_path() {
        assert_eq!(normalize_project_entry_path("project.json"), Some("project.json".to_string()));
        assert_eq!(normalize_project_entry_path("../../project.json"), Some("project.json".to_string()));
        
        assert_eq!(normalize_project_entry_path("scene1.webp"), Some("images/scene1.webp".to_string()));
        assert_eq!(normalize_project_entry_path("nested/folder/scene2.jpg"), Some("images/scene2.jpg".to_string()));
        
        // Non-image files should be ignored (None)
        assert_eq!(normalize_project_entry_path("script.sh"), None);
        assert_eq!(normalize_project_entry_path("malicious.exe"), None);
    }
}
