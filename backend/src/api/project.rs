/* backend/src/api/project.rs - Consolidated Project API */

use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use futures_util::TryStreamExt as _;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::PathBuf;
use uuid::Uuid;
use zip::write::FileOptions;

use crate::api::utils::{
    MAX_UPLOAD_SIZE, PROCESSED_IMAGE_WIDTH, WEBP_QUALITY, get_temp_path, sanitize_filename,
};
use crate::models::{AppError, User, ValidationReport};
use crate::pathfinder::PathRequest;
use crate::services::media::StorageManager;
use crate::services::project;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResponse {
    pub session_id: String,
    pub project_data: serde_json::Value,
}

// --- STORAGE HANDLERS ---

/// Saves the current project state into a ZIP file.
#[tracing::instrument(skip(payload, req), name = "save_project")]
pub async fn save_project(
    req: HttpRequest,
    mut payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    tracing::info!(module = "ProjectManager", user_id = %user.id, "SAVE_PROJECT_START");
    let start = std::time::Instant::now();
    let zip_path = get_temp_path("zip");

    let mut project_json: Option<String> = None;
    let mut session_id: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new();

    while let Some(mut field) = payload.try_next().await? {
        let name = field.name().unwrap_or("unknown").to_string();
        if name == "project_data" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            project_json = Some(String::from_utf8_lossy(&bytes).to_string());
        } else if name == "files" {
            let filename = field
                .content_disposition()
                .and_then(|cd| cd.get_filename())
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

    let json_content = project_json.ok_or_else(|| {
        AppError::MultipartError(actix_multipart::MultipartError::Incomplete.to_string())
    })?;
    let project_path = session_id
        .as_ref()
        .map(|pid| StorageManager::get_user_project_path(&user.id, pid));

    let (validated_json, _report, summary_content) = web::block({
        let temp_images = temp_images.clone();
        let project_path = project_path.clone();
        move || validate_project_full_sync(json_content, temp_images, project_path)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    let final_zip_path = zip_path.clone();
    let zip_creation_result = web::block({
        let validated_json = validated_json.clone();
        let project_path = project_path.clone();
        move || {
            create_project_zip_sync(
                final_zip_path,
                validated_json,
                summary_content,
                temp_images,
                project_path,
            )
        }
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match zip_creation_result {
        Ok(_) => {
            let file_bytes = fs::read(&zip_path).map_err(AppError::IoError)?;
            let _ = fs::remove_file(&zip_path);
            tracing::info!(
                module = "ProjectManager",
                duration_ms = duration,
                "SAVE_PROJECT_COMPLETE"
            );
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(file_bytes))
        }
        Err(e) => {
            let _ = fs::remove_file(&zip_path);
            Err(e.into())
        }
    }
}

/// Loads a project ZIP file into memory.
pub async fn load_project(
    req: HttpRequest,
    mut payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let _user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let mut temp_upload = tempfile::tempfile().map_err(AppError::IoError)?;
    let mut uploaded_size = 0;
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            uploaded_size += chunk.len();
            if uploaded_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
            temp_upload.write_all(&chunk).map_err(AppError::IoError)?;
        }
    }
    temp_upload
        .seek(SeekFrom::Start(0))
        .map_err(AppError::IoError)?;
    let result_zip_file = web::block(move || project::process_uploaded_project_zip(temp_upload))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))??;
    let file = result_zip_file.reopen().map_err(AppError::IoError)?;
    let named_file = actix_files::NamedFile::from_file(file, "project.zip")?;
    Ok(named_file.into_response(&req))
}

/// Imports a project ZIP and establishes a persistent project.
pub async fn import_project(
    req: HttpRequest,
    mut payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    while let Ok(Some(mut field)) = payload.try_next().await {
        if field.name() == Some("file") {
            let tmp_path = get_temp_path("zip");
            let mut f = fs::File::create(&tmp_path).map_err(AppError::IoError)?;
            while let Ok(Some(chunk)) = field.try_next().await {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }
            let (project_id, project_data) = {
                let file = fs::File::open(&tmp_path).map_err(AppError::IoError)?;
                let mut archive =
                    zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;
                let mut json_file = archive
                    .by_name("project.json")
                    .map_err(|_| AppError::InternalError("project.json missing".into()))?;
                let mut json_str = String::new();
                json_file
                    .read_to_string(&mut json_str)
                    .map_err(AppError::IoError)?;
                let data: serde_json::Value = serde_json::from_str(&json_str)
                    .map_err(|e| AppError::InternalError(e.to_string()))?;
                let id = data
                    .get("id")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| Uuid::new_v4().to_string());
                (id, data)
            };
            let project_dir = StorageManager::ensure_project_dir(&user.id, &project_id)
                .map_err(AppError::IoError)?;
            let file = fs::File::open(&tmp_path).map_err(AppError::IoError)?;
            let mut archive =
                zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;
            for i in 0..archive.len() {
                let mut file = archive
                    .by_index(i)
                    .map_err(|e| AppError::ZipError(e.to_string()))?;
                let outpath = match file.enclosed_name() {
                    Some(path) => project_dir.join(path),
                    None => continue,
                };
                if file.name().ends_with('/') {
                    fs::create_dir_all(&outpath).map_err(AppError::IoError)?;
                } else {
                    if let Some(p) = outpath.parent() {
                        if !p.exists() {
                            fs::create_dir_all(p).map_err(AppError::IoError)?;
                        }
                    }
                    let mut outfile = fs::File::create(&outpath).map_err(AppError::IoError)?;
                    std::io::copy(&mut file, &mut outfile).map_err(AppError::IoError)?;
                }
            }
            let _ = fs::remove_file(&tmp_path);
            return Ok(HttpResponse::Ok().json(ImportResponse {
                session_id: project_id,
                project_data,
            }));
        }
    }
    Err(AppError::MultipartError(
        actix_multipart::MultipartError::Incomplete.to_string(),
    ))
}

// --- NAVIGATION HANDLERS ---

/// Calculates a traversal path based on the requested strategy.
#[tracing::instrument(skip(payload), name = "calculate_path")]
pub async fn calculate_path(payload: web::Json<PathRequest>) -> Result<HttpResponse, AppError> {
    let request = payload.into_inner();
    let result = web::block(move || crate::pathfinder::calculate_path(request))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    match result {
        Ok(steps) => Ok(HttpResponse::Ok().json(steps)),
        Err(e) => Err(AppError::InternalError(e)),
    }
}

// --- VALIDATION HANDLERS ---

#[derive(Deserialize)]
pub struct ValidatePayload {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    pub data: serde_json::Value,
}

/// Validates project data and available scenes.
pub async fn validate_project(
    req: HttpRequest,
    payload: web::Json<ValidatePayload>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let payload = payload.into_inner();
    let project_path = StorageManager::get_user_project_path(&user.id, &payload.session_id);

    let result = web::block(move || {
        let mut available_files = HashSet::new();
        if let Ok(entries) = fs::read_dir(project_path.join("images")) {
            for entry in entries.flatten() {
                if let Ok(name) = entry.file_name().into_string() {
                    available_files.insert(name);
                }
            }
        }
        project::validate_and_clean_project(payload.data, &available_files)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    Ok(HttpResponse::Ok().json(result.1))
}

// --- EXPORT HANDLERS ---

/// Packages the project into a deployment-ready static structure.
#[tracing::instrument(skip(payload), name = "create_tour_package")]
pub async fn create_tour_package(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Exporter", "CREATE_PACKAGE_START");
    let mut image_files = Vec::new();
    let mut fields = HashMap::new();

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field
            .content_disposition()
            .ok_or_else(|| AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition
            .get_name()
            .unwrap_or("unknown")
            .to_string();

        if name == "html_4k"
            || name == "html_2k"
            || name == "html_hd"
            || name == "html_index"
            || name == "embed_codes"
        {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            fields.insert(name, String::from_utf8_lossy(&bytes).to_string());
        } else {
            // Assume it's a file (library, logo, or scene)
            let filename = content_disposition
                .get_filename()
                .map(|f| f.to_string())
                .unwrap_or_else(|| name.clone());
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            image_files.push((filename, bytes));
        }
    }

    let result = web::block(move || project::create_tour_package(image_files, fields))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))??;

    Ok(HttpResponse::Ok()
        .content_type("application/zip")
        .body(result))
}

// --- INTERNAL SYNC LOGIC ---

pub fn generate_project_summary(project_data: &serde_json::Value) -> Result<String, String> {
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
        let project_val: serde_json::Value =
            serde_json::from_str(&project_json).unwrap_or(serde_json::Value::Null);
        if let Some(scenes) = project_val["scenes"].as_array() {
            for scene in scenes {
                if let Some(name) = scene["name"].as_str() {
                    if !written_files.contains(name) {
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
}

pub fn validate_project_full_sync(
    json_content: String,
    temp_images: Vec<(String, PathBuf)>,
    project_path: Option<PathBuf>,
) -> Result<(String, ValidationReport, String), String> {
    let project_data: serde_json::Value =
        serde_json::from_str(&json_content).map_err(|e| format!("Invalid project JSON: {}", e))?;
    let summary = generate_project_summary(&project_data)?;
    let mut available_files = HashSet::new();
    for (name, _) in &temp_images {
        available_files.insert(name.clone());
    }
    if let Some(session_path) = &project_path {
        if let Ok(entries) = fs::read_dir(session_path.join("images")) {
            for entry in entries.flatten() {
                if let Ok(name) = entry.file_name().into_string() {
                    available_files.insert(name);
                }
            }
        }
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
    validated_project["validationReport"] =
        serde_json::to_value(&report).map_err(|e| format!("Failed to serialize report: {}", e))?;
    let updated_json =
        serde_json::to_string_pretty(&validated_project).map_err(|e| e.to_string())?;
    Ok((updated_json, report, summary))
}
