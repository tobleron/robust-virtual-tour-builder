use percent_encoding::percent_decode_str;
use serde_json::Value;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use uuid::Uuid;
use zip::write::FileOptions;

use crate::api::utils::{PROCESSED_IMAGE_WIDTH, WEBP_QUALITY};
use crate::models::{AppError, ValidationReport};
use crate::services::project;

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

pub fn generate_project_summary(project_data: &Value) -> Result<String, String> {
    let tour_name = project_data["tourName"]
        .as_str()
        .unwrap_or("Untitled Tour")
        .to_string();
    let scenes = project_data["scenes"]
        .as_array()
        .ok_or("Missing 'scenes' array")?;
    let mut total_hotspots = 0;
    let mut total_score = 0.0;
    let mut total_luminance = 0;
    let mut group_counts: HashMap<String, u32> = HashMap::new();
    let mut score_count = 0;
    for scene in scenes {
        if let Some(hss) = scene["hotspots"].as_array() {
            total_hotspots += hss.len();
        }
        if let Some(group) = scene["colorGroup"].as_str() {
            *group_counts.entry(group.to_string()).or_insert(0) += 1;
        }
        if let Some(quality) = scene["quality"].as_object() {
            if let Some(score) = quality.get("score").and_then(|v| v.as_f64()) {
                total_score += score;
                score_count += 1;
            }
            if let Some(stats) = quality.get("stats").and_then(|v| v.as_object()) {
                if let Some(lum) = stats.get("avgLuminance").and_then(|v| v.as_u64()) {
                    total_luminance += lum;
                }
            }
        }
    }
    let mut group_summary = String::new();
    let mut group_ids: Vec<_> = group_counts.keys().collect();
    group_ids.sort_by(|a, b| {
        a.parse::<i32>()
            .unwrap_or(-1)
            .cmp(&b.parse::<i32>().unwrap_or(-1))
    });
    for id in group_ids {
        group_summary.push_str(&format!(
            "  - Visual Group {}: {} scene(s)\n",
            id, group_counts[id]
        ));
    }

    let avg_score = if score_count > 0 {
        total_score / score_count as f64
    } else {
        0.0
    };
    let avg_lum = if score_count > 0 {
        total_luminance / score_count as u64
    } else {
        0
    };

    Ok(format!(
        "====================================================\nVIRTUAL TOUR - PROJECT SUMMARY\n====================================================\n\n\
        Project Name:      {}\nGenerated On:      {}\nApplication:       Robust Virtual Tour Builder v4.4.7\n\n--- SCENE ANALYSIS ---\n\
        Total Scenes:      {}\nTotal Hotspots:    {}\nVisual Groups:     {} (Identified via similarity clustering)\n{}\n--- QUALITY METRICS ---\n\
        Avg Quality Score: {:.1}/10.0\nAvg Luminance:     {} (Balanced range: 100-180)\n\n\
        Technical Checks Performed:\n- Luminance Analysis: Ensuring balanced exposure\n- Sharpness Variance: Detecting blur or soft focus\n\
        - Clipping Detection: Checking for lost detail in highlights/shadows\n\n--- IMAGE SPECIFICATIONS ---\nStandard Format:   WebP (Lossy)\n\
        WebP Quality:      {:.1}%\nMax Resolution:    {}x{} px\n\n--- VALIDATION ---\nStatus:            COMPLETED\n\n\
        ====================================================\n",
        tour_name,
        chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
        scenes.len(),
        total_hotspots,
        group_counts.len(),
        group_summary,
        avg_score * 10.0,
        avg_lum,
        WEBP_QUALITY,
        PROCESSED_IMAGE_WIDTH,
        PROCESSED_IMAGE_WIDTH
    ))
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
        let project_val: Value = serde_json::from_str(&project_json).unwrap_or(Value::Null);
        if let Some(scenes) = project_val["scenes"].as_array() {
            for scene in scenes {
                if let Some(_name) = scene["name"].as_str() {
                    // Collect all possible file references in a scene
                    let file_props = ["file", "tinyFile", "originalFile"];
                    for prop in file_props {
                        if let Some(file_url) = scene[prop].as_str() {
                            if file_url.contains("/file/") {
                                if let Some(filename_segment) = file_url
                                    .split("/file/")
                                    .nth(1)
                                    .and_then(|s| s.split('?').next())
                                {
                                    if let Ok(decoded_filename) =
                                        percent_decode_str(filename_segment).decode_utf8()
                                    {
                                        let decoded_filename = decoded_filename.to_string();
                                        if let Ok(safe_filename) =
                                            crate::api::utils::sanitize_filename(&decoded_filename)
                                        {
                                            if !written_files.contains(&safe_filename) {
                                                let img_subdir = session_path
                                                    .join("images")
                                                    .join(&safe_filename);
                                                let root_path = session_path.join(&safe_filename);
                                                let source_path = if img_subdir.exists() {
                                                    Some(img_subdir)
                                                } else if root_path.exists() {
                                                    Some(root_path)
                                                } else {
                                                    None
                                                };

                                                if let Some(path) = source_path {
                                                    zip.start_file(
                                                        format!("images/{}", safe_filename),
                                                        options,
                                                    )?;
                                                    let mut f = fs::File::open(path)?;
                                                    std::io::copy(&mut f, &mut zip)?;
                                                    written_files.insert(safe_filename);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    zip.finish()?;
    Ok(())
}

pub fn validate_project_full_sync(
    json_content: String,
    temp_images: Vec<(String, PathBuf)>,
    project_path: Option<PathBuf>,
) -> Result<(String, ValidationReport, String), String> {
    let project_data: Value =
        serde_json::from_str(&json_content).map_err(|e| format!("Invalid project JSON: {}", e))?;
    let summary = generate_project_summary(&project_data)?;

    let mut available_files = HashSet::new();
    for (name, _) in &temp_images {
        available_files.insert(name.clone());
    }

    if let Some(session_path) = &project_path {
        let existing_files = list_available_files(session_path);
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::tempdir;

    #[test]
    fn test_extract_zip_path_traversal() {
        let tmp = tempdir().unwrap();
        let zip_path = tmp.path().join("malicious.zip");
        let project_dir = tmp.path().join("project");
        fs::create_dir_all(&project_dir).unwrap();

        // Create malicious ZIP
        let file = fs::File::create(&zip_path).unwrap();
        let mut zip = zip::ZipWriter::new(file);
        let options = zip::write::FileOptions::default();

        // This name is malicious
        zip.start_file("../outside.txt", options).unwrap();
        zip.write_all(b"malicious").unwrap();
        zip.finish().unwrap();

        // Extractions should ignore outside.txt or sanitize it to project/outside.txt
        // enclosed_name() actually returns None for "..", so it's skipped.
        extract_zip_to_project_dir(&zip_path, &project_dir).unwrap();

        assert!(!tmp.path().join("outside.txt").exists());
        // Since it's skipped by enclosed_name, it shouldn't even exist in project_dir
        assert!(!project_dir.join("outside.txt").exists());
    }

    #[test]
    fn test_extract_zip_sanitizes_components() {
        let tmp = tempdir().unwrap();
        let zip_path = tmp.path().join("dodgy.zip");
        let project_dir = tmp.path().join("project");
        fs::create_dir_all(&project_dir).unwrap();

        let file = fs::File::create(&zip_path).unwrap();
        let mut zip = zip::ZipWriter::new(file);
        let options = zip::write::FileOptions::default();

        zip.start_file("images/safe.webp", options).unwrap();
        zip.write_all(b"safe").unwrap();

        // Use backslash which sanitize_filename replaces on all platforms
        zip.start_file("images/dodgy\\file.webp", options).unwrap();
        zip.write_all(b"dodgy").unwrap();

        zip.finish().unwrap();

        extract_zip_to_project_dir(&zip_path, &project_dir).unwrap();

        assert!(project_dir.join("images").is_dir());
        assert!(project_dir.join("images").join("safe.webp").exists());

        let dodgy_path = project_dir.join("images").join("dodgy_file.webp");
        assert!(
            dodgy_path.exists(),
            "Sanitized dodgy path should exist at {:?}",
            dodgy_path
        );
    }
}
