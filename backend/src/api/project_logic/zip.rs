use serde_json::Value;
use std::collections::HashSet;
use std::fs;
use std::io::{Read, Write};
use std::path::PathBuf;
use uuid::Uuid;
use zip::write::FileOptions;

use crate::models::AppError;

pub fn extract_project_metadata_from_zip(
    path: &PathBuf,
) -> Result<(String, serde_json::Value), AppError> {
    let file = fs::File::open(path).map_err(AppError::IoError)?;
    let mut archive = zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;
    let mut json_file = archive
        .by_name("project.json")
        .map_err(|_| AppError::InternalError("project.json missing".into()))?;
    let mut json_str = String::new();
    json_file
        .read_to_string(&mut json_str)
        .map_err(AppError::IoError)?;
    let data: serde_json::Value =
        serde_json::from_str(&json_str).map_err(|e| AppError::InternalError(e.to_string()))?;
    let id_raw = data
        .get("id")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| Uuid::new_v4().to_string());

    let id = crate::api::utils::sanitize_id(&id_raw)
        .map_err(|e| AppError::ValidationError(format!("Invalid project ID in ZIP: {}", e)))?;

    Ok((id, data))
}

pub fn extract_zip_to_project_dir(zip_path: &PathBuf, project_dir: &PathBuf) -> Result<(), String> {
    let file = fs::File::open(zip_path).map_err(|e| e.to_string())?;
    let mut archive = zip::ZipArchive::new(file).map_err(|e| e.to_string())?;

    for i in 0..archive.len() {
        let mut file = archive.by_index(i).map_err(|e| e.to_string())?;
        let outpath = match file.enclosed_name() {
            Some(path) => {
                let mut safe_path = project_dir.clone();
                for component in path.components() {
                    match component {
                        std::path::Component::Normal(name) => {
                            if let Some(name_str) = name.to_str() {
                                let sanitized = crate::api::utils::sanitize_filename(name_str)
                                    .map_err(|e| format!("Invalid path component: {}", e))?;
                                safe_path.push(sanitized);
                            }
                        }
                        _ => {} // enclosed_name already handles .. and root
                    }
                }
                safe_path
            }
            None => continue,
        };

        if file.name().ends_with('/') {
            fs::create_dir_all(&outpath).map_err(|e| e.to_string())?;
        } else {
            if let Some(p) = outpath.parent() {
                if !p.exists() {
                    fs::create_dir_all(p).map_err(|e| e.to_string())?;
                }
            }
            let mut outfile = fs::File::create(&outpath).map_err(|e| e.to_string())?;
            std::io::copy(&mut file, &mut outfile).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

pub fn create_project_zip_sync(
    zip_path: PathBuf,
    project_json: String,
    summary_content: String,
    temp_images: Vec<(String, PathBuf)>,
    project_path: Option<PathBuf>,
) -> Result<(), std::io::Error> {
    let file = fs::File::create(&zip_path)?;
    let mut zip = zip::ZipWriter::new(file);
    let options = FileOptions::default()
        .compression_method(zip::CompressionMethod::Stored)
        .unix_permissions(0o755);
    zip.start_file("project.json", options)?;
    zip.write_all(project_json.as_bytes())?;
    zip.start_file("summary.txt", options)?;
    zip.write_all(summary_content.as_bytes())?;
    let mut written_files = HashSet::new();
    for (filename, path) in temp_images {
        zip.start_file(format!("images/{}", filename), options)?;
        let mut f = fs::File::open(&path)?;
        std::io::copy(&mut f, &mut zip)?;
        written_files.insert(filename);
        let _ = fs::remove_file(path);
    }
    if let Some(session_path) = project_path {
        let project_val: Value = serde_json::from_str(&project_json).map_err(|e| {
            std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                format!("Invalid project JSON while packaging zip: {}", e),
            )
        })?;

        let referenced_files = super::reference::collect_referenced_project_files(&project_val);
        for safe_filename in referenced_files {
            if written_files.contains(&safe_filename) {
                continue;
            }

            let img_subdir = session_path.join("images").join(&safe_filename);
            let root_path = session_path.join(&safe_filename);
            let source_path = if img_subdir.exists() {
                Some(img_subdir)
            } else if root_path.exists() {
                Some(root_path)
            } else {
                None
            };

            if let Some(path) = source_path {
                zip.start_file(format!("images/{}", safe_filename), options)?;
                let mut f = fs::File::open(path)?;
                std::io::copy(&mut f, &mut zip)?;
                written_files.insert(safe_filename);
            }
        }
    }
    zip.finish()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::io::Write;
    use tempfile::tempdir;

    #[test]
    fn test_extract_zip_path_traversal() {
        let tmp = tempdir().expect("failed to create temp directory");
        let zip_path = tmp.path().join("malicious.zip");
        let project_dir = tmp.path().join("project");
        fs::create_dir_all(&project_dir).expect("failed to create project directory");

        // Create malicious ZIP
        let file = fs::File::create(&zip_path).expect("failed to create zip file");
        let mut zip = zip::ZipWriter::new(file);
        let options = zip::write::FileOptions::default();

        // This name is malicious
        zip.start_file("../outside.txt", options)
            .expect("failed to start zip file");
        zip.write_all(b"malicious").expect("failed to write to zip");
        zip.finish().expect("failed to finish zip writing");

        // Extractions should ignore outside.txt or sanitize it to project/outside.txt
        // enclosed_name() actually returns None for "..", so it's skipped.
        extract_zip_to_project_dir(&zip_path, &project_dir).expect("failed to extract zip");

        assert!(!tmp.path().join("outside.txt").exists());
        // Since it's skipped by enclosed_name, it shouldn't even exist in project_dir
        assert!(!project_dir.join("outside.txt").exists());
    }

    #[test]
    fn test_extract_zip_sanitizes_components() {
        let tmp = tempdir().expect("failed to create temp directory");
        let zip_path = tmp.path().join("dodgy.zip");
        let project_dir = tmp.path().join("project");
        fs::create_dir_all(&project_dir).expect("failed to create project directory");

        let file = fs::File::create(&zip_path).expect("failed to create zip file");
        let mut zip = zip::ZipWriter::new(file);
        let options = zip::write::FileOptions::default();

        zip.start_file("images/safe.webp", options)
            .expect("failed to start zip file");
        zip.write_all(b"safe").expect("failed to write to zip");

        // Use backslash which sanitize_filename replaces on all platforms
        zip.start_file("images/dodgy\\file.webp", options)
            .expect("failed to start zip file");
        zip.write_all(b"dodgy").expect("failed to write to zip");

        zip.finish().expect("failed to finish zip writing");

        extract_zip_to_project_dir(&zip_path, &project_dir).expect("failed to extract zip");

        assert!(project_dir.join("images").is_dir());
        assert!(project_dir.join("images").join("safe.webp").exists());

        let dodgy_path = project_dir.join("images").join("dodgy_file.webp");
        assert!(
            dodgy_path.exists(),
            "Sanitized dodgy path should exist at {:?}",
            dodgy_path
        );
    }

    #[test]
    fn test_create_project_zip_sync_includes_inventory_active_scene_files() {
        let tmp = tempdir().expect("failed to create temp directory");
        let zip_path = tmp.path().join("saved.vt.zip");
        let session_path = tmp.path().join("session-a");
        let images_path = session_path.join("images");
        fs::create_dir_all(&images_path).expect("failed to create images directory");

        fs::write(images_path.join("001.webp"), b"scene-001").expect("failed to write first image");
        fs::write(images_path.join("002.webp"), b"scene-002")
            .expect("failed to write second image");

        // Simulate backend-validated JSON where legacy scenes[] lost one scene,
        // while inventory still has both active entries (frontend load path relies on inventory+order).
        let project_json = json!({
            "tourName": "Test",
            "scenes": [
                {
                    "id": "s1",
                    "name": "001.webp",
                    "file": "/api/project/old/file/001.webp"
                }
            ],
            "inventory": [
                {
                    "id": "s1",
                    "entry": {
                        "scene": {
                            "id": "s1",
                            "name": "001.webp",
                            "file": "/api/project/old/file/001.webp"
                        },
                        "status": "Active"
                    }
                },
                {
                    "id": "s2",
                    "entry": {
                        "scene": {
                            "id": "s2",
                            "name": "002.webp",
                            "file": "/api/project/old/file/002.webp"
                        },
                        "status": "Active"
                    }
                }
            ],
            "sceneOrder": ["s1", "s2"]
        });

        create_project_zip_sync(
            zip_path.clone(),
            serde_json::to_string(&project_json).expect("failed to serialize project json"),
            "summary".to_string(),
            vec![],
            Some(session_path),
        )
        .expect("failed to create project zip");

        let file = fs::File::open(zip_path).expect("failed to open output zip");
        let mut archive = zip::ZipArchive::new(file).expect("failed to parse output zip");
        let mut entries = HashSet::new();
        for i in 0..archive.len() {
            let entry = archive.by_index(i).expect("failed to read zip entry");
            entries.insert(entry.name().to_string());
        }

        assert!(entries.contains("images/001.webp"));
        assert!(entries.contains("images/002.webp"));
    }
}
