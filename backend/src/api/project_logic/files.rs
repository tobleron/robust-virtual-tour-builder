use std::collections::HashSet;
use std::fs;
use std::path::Path;

pub fn list_available_files(project_path: &Path) -> HashSet<String> {
    let mut available_files = HashSet::new();
    // Check images subdirectory
    if let Ok(entries) = fs::read_dir(project_path.join("images")) {
        for entry in entries.flatten() {
            if let Ok(name) = entry.file_name().into_string() {
                available_files.insert(name);
            }
        }
    }
    // Check root directory (fallback/legacy)
    if let Ok(entries) = fs::read_dir(project_path) {
        for entry in entries.flatten() {
            if let Ok(name) = entry.file_name().into_string() {
                available_files.insert(name);
            }
        }
    }
    available_files
}
