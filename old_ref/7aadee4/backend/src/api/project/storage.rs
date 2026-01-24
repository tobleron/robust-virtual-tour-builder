use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use futures_util::TryStreamExt as _;
use serde::Serialize;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use uuid::Uuid;
use zip::write::FileOptions;

use crate::api::utils::{
    MAX_UPLOAD_SIZE, PROCESSED_IMAGE_WIDTH, SESSIONS_DIR, TEMP_DIR, WEBP_QUALITY, get_session_path,
    get_temp_path, sanitize_filename,
};
use crate::models::{AppError, ValidationReport};
use crate::services::project;

/// Saves the current project state into a ZIP file.
///
/// This handler streams uploaded images to temporary storage to minimize memory usage,
/// validates the project structure, and produces a ZIP containing `project.json`
/// and the uploaded images.
///
/// # Arguments
/// * `payload` - Multipart form data containing "project_data" and "files".
///
/// # Returns
/// A response containing the project ZIP file.
///
/// # Errors
/// * `IoError` if temporary file creation fails.
/// * `MultipartError` if the required fields are missing.
/// * `ValidationError` if the project structure is invalid.
#[tracing::instrument(skip(payload), name = "save_project")]
pub async fn save_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "ProjectManager", "SAVE_PROJECT_START");
    let start = std::time::Instant::now();
    // 1. Prepare Zip Writer
    // We stream directly to a file in TEMP_DIR to avoid memory issues with huge projects
    let zip_path = get_temp_path("zip"); // returns full path with .zip extension

    // We use a block to scope the ZipWriter
    let mut project_json: Option<String> = None;
    let mut session_id: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new(); // (filename, temp_path)

    // 2. Iterate Multipart Stream
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field
            .content_disposition()
            .ok_or_else(|| AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition
            .get_name()
            .unwrap_or("unknown")
            .to_string();

        if name == "project_data" {
            // Read JSON into memory (it's small)
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            project_json = Some(String::from_utf8_lossy(&bytes).to_string());
        } else if name == "files" {
            // This is an image file. Stream it to a temp file first to keep RAM low.
            let filename = content_disposition
                .get_filename()
                .map(|f| f.to_string())
                .unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized_name = sanitize_filename(&filename)
                .unwrap_or_else(|_| format!("img_{}.webp", Uuid::new_v4()));

            let temp_img_path = get_temp_path("tmp");
            let mut f = fs::File::create(&temp_img_path).map_err(AppError::IoError)?;

            while let Some(chunk) = field.try_next().await? {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }
            temp_images.push((sanitized_name, temp_img_path));
        } else if name == "session_id" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            session_id = Some(String::from_utf8_lossy(&bytes).to_string());
        }
    }

    // 3. Create ZIP
    // We do this in a blocking thread to avoid blocking async runtime
    let final_zip_path = zip_path.clone();
    let json_content = project_json
        .ok_or_else(|| AppError::MultipartError(actix_multipart::MultipartError::Incomplete))?;

    // Run validation and summary generation before saving
    let temp_images_for_validation = temp_images.clone();
    let session_id_for_validation = session_id.clone();
    let (validated_json, _report, summary_content) = web::block(
        move || -> Result<(String, ValidationReport, String), String> {
            let project_data: serde_json::Value = serde_json::from_str(&json_content)
                .map_err(|e| format!("Invalid project JSON: {}", e))?;

            // 1. Core Metadata
            let tour_name = project_data["tourName"]
                .as_str()
                .unwrap_or("Untitled Tour")
                .to_string();
            let scenes = project_data["scenes"]
                .as_array()
                .ok_or("Missing 'scenes' array")?;
            let scene_count = scenes.len();

            // 2. Stats Collection
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

                // Extract quality stats if available
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
                let a_int = a.parse::<i32>().unwrap_or(-1);
                let b_int = b.parse::<i32>().unwrap_or(-1);
                a_int.cmp(&b_int)
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

            // 3. Generate Human Readable Summary
            let now = chrono::Local::now();
            let summary = format!(
                "====================================================\n\
                 VIRTUAL TOUR - PROJECT SUMMARY\n\
                 ====================================================\n\n\
                 Project Name:      {}
\
                 Generated On:      {}
\
                 Application:       Robust Virtual Tour Builder v4.4.7\n\n\
                 --- SCENE ANALYSIS ---
\
                 Total Scenes:      {}
\
                 Total Hotspots:    {}
\
                 Visual Groups:     {} (Identified via similarity clustering)
\
{}
\
                 --- QUALITY METRICS ---
\
                 Avg Quality Score: {:.1}/10.0
\
                 Avg Luminance:     {} (Balanced range: 100-180)
\
\
                 Technical Checks Performed:
\
                 - Luminance Analysis: Ensuring balanced exposure
\
                 - Sharpness Variance: Detecting blur or soft focus
\
                 - Clipping Detection: Checking for lost detail in highlights/shadows
\
\
                 --- IMAGE SPECIFICATIONS ---
\
                 Standard Format:   WebP (Lossy)
\
                 WebP Quality:      {:.1}%
\
                 Max Resolution:    {}x{} px
\
\
                 --- VALIDATION ---
\
                 Status:            COMPLETED
\
\
                 ====================================================\n",
                tour_name,
                now.format("%Y-%m-%d %H:%M:%S"),
                scene_count,
                total_hotspots,
                group_counts.len(),
                group_summary,
                avg_score * 10.0,
                avg_lum,
                WEBP_QUALITY,
                PROCESSED_IMAGE_WIDTH,
                PROCESSED_IMAGE_WIDTH,
            );

            // For save-project, available files are the ones being uploaded + already in session
            let mut available_files = HashSet::new();
            for (name, _) in &temp_images_for_validation {
                available_files.insert(name.clone());
            }

            if let Some(sid) = &session_id_for_validation {
                let session_path = get_session_path(sid);

                // Check "images" subdir
                let img_dir = session_path.join("images");
                if let Ok(entries) = fs::read_dir(img_dir) {
                    for entry in entries.flatten() {
                        if let Ok(name) = entry.file_name().into_string() {
                            available_files.insert(name);
                        }
                    }
                }

                // Check root session dir
                if let Ok(entries) = fs::read_dir(session_path) {
                    for entry in entries.flatten() {
                        if let Ok(name) = entry.file_name().into_string() {
                            available_files.insert(name);
                        }
                    }
                }
            }

            let (mut validated_project, report) =
                project::validate_and_clean_project(project_data, &available_files)?;

            // Embed report
            validated_project["validationReport"] = serde_json::to_value(&report)
                .map_err(|e| format!("Failed to serialize report: {}", e))?;

            let updated_json =
                serde_json::to_string_pretty(&validated_project).map_err(|e| e.to_string())?;

            Ok((updated_json, report, summary))
        },
    )
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    let zip_creation_result = web::block(move || -> Result<(), std::io::Error> {
        let file = fs::File::create(&final_zip_path)?;
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored) // Already compressed WebPs
            .unix_permissions(0o755);

        // Write JSON
        zip.start_file("project.json", options)?;
        zip.write_all(validated_json.as_bytes())?;

        // Write Summary
        zip.start_file("summary.txt", options)?;
        zip.write_all(summary_content.as_bytes())?;

        // Track what we've written from temp_images
        let mut written_files = HashSet::new();

        // 1. Write Images from multipart (newly uploaded)
        for (filename, path) in temp_images {
            zip.start_file(format!("images/{}", filename), options)?;
            let mut f = fs::File::open(&path)?;
            std::io::copy(&mut f, &mut zip)?;
            written_files.insert(filename);

            // Allow OS to clean up temp file (best effort)
            let _ = fs::remove_file(path);
        }

        // 2. Write remaining images from session (if any scenes need them)
        if let Some(sid) = session_id {
            let session_path = get_session_path(&sid);
            let project_val: serde_json::Value =
                serde_json::from_str(&validated_json).unwrap_or(serde_json::Value::Null);

            if let Some(scenes) = project_val["scenes"].as_array() {
                for scene in scenes {
                    if let Some(name) = scene["name"].as_str() {
                        if !written_files.contains(name) {
                            // Try to find in session dir
                            let img_subdir = session_path.join("images").join(name);
                            let root_path = session_path.join(name);

                            let source_path = if img_subdir.exists() {
                                Some(img_subdir)
                            } else if root_path.exists() {
                                Some(root_path)
                            } else {
                                None
                            };

                            if let Some(path) = source_path {
                                zip.start_file(format!("images/{}", name), options)?;
                                let mut f = fs::File::open(path)?;
                                std::io::copy(&mut f, &mut zip)?;
                                written_files.insert(name.to_string());
                            }
                        }
                    }
                }
            }
        }

        zip.finish()?;
        Ok(())
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    // 4. Stream Back the ZIP
    let duration = start.elapsed().as_millis();
    match zip_creation_result {
        Ok(_) => {
            let zip_file = fs::File::open(&zip_path).map_err(AppError::IoError)?;
            let metadata = zip_file.metadata().map_err(AppError::IoError)?;

            let mut buffer = Vec::with_capacity(metadata.len() as usize);
            let mut reader = std::io::BufReader::new(zip_file);
            std::io::copy(&mut reader, &mut buffer).map_err(AppError::IoError)?;

            // Clean up
            let _ = fs::remove_file(&zip_path);

            tracing::info!(
                module = "ProjectManager",
                duration_ms = duration,
                "SAVE_PROJECT_COMPLETE"
            );

            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(buffer))
        }
        Err(e) => {
            let _ = fs::remove_file(&zip_path); // Clean up on error too
            tracing::error!(module = "ProjectManager", duration_ms = duration, error = %e, "SAVE_PROJECT_FAILED");
            Err(e.into())
        }
    }
}

/// Loads a project ZIP file into memory and processes its content.
///
/// This handler accepts a previously saved project ZIP, validates it, and returns
/// a normalized ZIP file that ensures all files are correctly located and structured.
///
/// # Arguments
/// * `payload` - Multipart form data containing the project ZIP "file".
///
/// # Returns
/// A response containing the processed project ZIP file.
///
/// # Errors
/// * `ImageError` if the project size exceeds limits.
/// * `ProcessingError` if the ZIP cannot be parsed or normalized.
#[tracing::instrument(skip(payload), name = "load_project")]
pub async fn load_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "ProjectManager", "LOAD_PROJECT_START");
    let start = std::time::Instant::now();
    let mut zip_data = Vec::new();

    // 1. Read ZIP Upload into memory
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            zip_data.extend_from_slice(&chunk);
            if zip_data.len() > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
        }
    }

    tracing::info!(
        module = "ProjectManager",
        size_bytes = zip_data.len(),
        "PROJECT_ZIP_RECEIVED"
    );

    // 2. Process in blocking thread - create response ZIP with project.json + all images
    let result_zip = web::block(move || project::process_uploaded_project_zip(zip_data))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(
                module = "ProjectManager",
                duration_ms = duration,
                "LOAD_PROJECT_COMPLETE"
            );
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        }
        Err(e) => {
            tracing::error!(module = "ProjectManager", duration_ms = duration, error = %e, "LOAD_PROJECT_FAILED");
            Err(e.into())
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResponse {
    pub session_id: String,
    pub project_data: serde_json::Value,
}

/// Imports a project ZIP and establishes a server-side session.
///
/// Unlike `load_project`, this function extracts the project contents into a
/// dedicated session directory on the server, allowing for subsequent incremental
/// edits and faster access during the editing session.
///
/// # Arguments
/// * `payload` - Multipart form data containing the project ZIP "file".
///
/// # Returns
/// An `ImportResponse` containing the `session_id` and the `project_data` (JSON).
///
/// # Errors
/// * `IoError` if session directory creation fails.
/// * `ZipError` if the archive is malformed.
/// * `InternalError` if `project.json` is missing from the archive.
pub async fn import_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // 1. Generate Session ID
    let session_id = Uuid::new_v4().to_string();
    let session_dir = PathBuf::from(format!("{}/{}", SESSIONS_DIR, session_id));
    fs::create_dir_all(&session_dir).map_err(AppError::IoError)?;

    tracing::info!(module = "ProjectManager", session_id = %session_id, "IMPORT_PROJECT_START");

    while let Ok(Some(mut field)) = payload.try_next().await {
        let name = field
            .content_disposition()
            .and_then(|cd| cd.get_name())
            .unwrap_or("unknown");

        if name == "file" {
            let tmp_path = format!("{}/{}_upload.zip", TEMP_DIR, session_id);
            fs::create_dir_all(TEMP_DIR).map_err(AppError::IoError)?; // Ensure temp dir exists

            let mut f = fs::File::create(&tmp_path).map_err(AppError::IoError)?;
            while let Ok(Some(chunk)) = field.try_next().await {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }

            // Unzip
            let file = fs::File::open(&tmp_path).map_err(AppError::IoError)?;
            let mut archive =
                zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;

            for i in 0..archive.len() {
                let mut file = archive
                    .by_index(i)
                    .map_err(|e| AppError::ZipError(e.to_string()))?;
                let outpath = match file.enclosed_name() {
                    Some(path) => session_dir.join(path),
                    None => continue,
                };

                if file.name().ends_with('/') {
                    fs::create_dir_all(&outpath).map_err(AppError::IoError)?;
                } else {
                    if let Some(p) = outpath.parent()
                        && !p.exists()
                    {
                        fs::create_dir_all(p).map_err(AppError::IoError)?;
                    }
                    let mut outfile = fs::File::create(&outpath).map_err(AppError::IoError)?;
                    std::io::copy(&mut file, &mut outfile).map_err(AppError::IoError)?;
                }
            }

            // Clean temp zip
            let _ = fs::remove_file(&tmp_path);

            // Read project.json
            let project_json_path = session_dir.join("project.json");
            if !project_json_path.exists() {
                return Err(AppError::InternalError(
                    "project.json not found in archive".into(),
                ));
            }

            let json_str = fs::read_to_string(project_json_path).map_err(AppError::IoError)?;
            let project_data: serde_json::Value = serde_json::from_str(&json_str)
                .map_err(|e| AppError::InternalError(e.to_string()))?;

            tracing::info!(module = "ProjectManager", session_id = %session_id, "IMPORT_PROJECT_SUCCESS");

            return Ok(HttpResponse::Ok().json(ImportResponse {
                session_id,
                project_data,
            }));
        }
    }

    Err(AppError::MultipartError(
        actix_multipart::MultipartError::Incomplete,
    ))
}
