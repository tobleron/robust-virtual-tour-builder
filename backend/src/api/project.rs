use actix_multipart::Multipart;
use actix_web::{web, HttpResponse};
use futures_util::TryStreamExt as _;
use std::fs;
use std::io::{Write};
use std::path::PathBuf;
use uuid::Uuid;
use serde::Serialize;
use zip::write::FileOptions;
use std::collections::{HashMap, HashSet};

use crate::services::project;
use crate::models::{AppError, ValidationReport};
use super::utils::{get_temp_path, sanitize_filename, MAX_UPLOAD_SIZE, SESSIONS_DIR, TEMP_DIR};

/// Creates a final tour package ZIP containing the tour application and all assets.
///
/// This function collects images and field data from a multipart request and packages
/// them into a downloadable ZIP file that can be hosted on any static web server.
///
/// # Arguments
/// * `payload` - Multipart form data containing "project_data" (JSON) and asset files.
///
/// # Returns
/// A response containing the ZIP file as binary data.
///
/// # Errors
/// * `ImageError` if the total upload size exceeds `MAX_UPLOAD_SIZE`.
/// * `InternalError` for path sanitization or processing failures.
#[tracing::instrument(skip(payload), name = "create_tour_package")]
pub async fn create_tour_package(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Exporter", "EXPORT_START");
    let start = std::time::Instant::now();
    let mut fields: HashMap<String, String> = HashMap::new();
    let mut image_files: Vec<(String, Vec<u8>)> = Vec::new();

    let mut current_total_size = 0;

    // 1. Parse Multipart into Memory
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition()
            .cloned()
            .ok_or(AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition.get_name().unwrap_or("unknown").to_string();
        let filename = content_disposition.get_filename().map(|f| f.to_string());

        let mut data = Vec::new();
        while let Some(chunk) = field.try_next().await? {
            current_total_size += chunk.len();
            if current_total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(
                    format!("Total upload size exceeds maximum of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                ));
            }
            data.extend_from_slice(&chunk);
        }

        if let Some(fname) = filename {
            // Use secure sanitization to prevent path traversal
            let sanitized_name = sanitize_filename(&fname)
                .map_err(|e| AppError::InternalError(format!("Invalid filename '{}': {}", fname, e)))?;
            image_files.push((sanitized_name, data));
        } else {
            let value_str = String::from_utf8_lossy(&data).to_string();
            fields.insert(name, value_str);
        }
    }

    let result_zip = web::block(move || {
        project::create_tour_package(image_files, fields)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(module = "Exporter", duration_ms = duration, size = zip_bytes.len(), "EXPORT_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => {
            tracing::error!(module = "Exporter", duration_ms = duration, error = %e, "EXPORT_FAILED");
            Err(AppError::ZipError(e))
        },
    }
}

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
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new(); // (filename, temp_path)
    
    // 2. Iterate Multipart Stream
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition()
            .cloned()
            .ok_or(AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition.get_name().unwrap_or("unknown").to_string();
        
        if name == "project_data" {
            // Read JSON into memory (it's small)
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            project_json = Some(String::from_utf8_lossy(&bytes).to_string());
        } else if name == "files" {
            // This is an image file. Stream it to a temp file first to keep RAM low.
            let filename = content_disposition.get_filename().map(|f| f.to_string()).unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized_name = sanitize_filename(&filename).unwrap_or_else(|_| format!("img_{}.webp", Uuid::new_v4()));
            
            let temp_img_path = get_temp_path("tmp");
            let mut f = fs::File::create(&temp_img_path).map_err(AppError::IoError)?;
            
            while let Some(chunk) = field.try_next().await? {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }
            temp_images.push((sanitized_name, temp_img_path));
        }
    }
    
    // 3. Create ZIP
    // We do this in a blocking thread to avoid blocking async runtime
    let final_zip_path = zip_path.clone();
    let json_content = project_json.ok_or_else(|| AppError::MultipartError(actix_multipart::MultipartError::Incomplete))?;
    
    // Run validation before saving
    let temp_images_for_validation = temp_images.clone();
    let (validated_json, _report) = web::block(move || -> Result<(String, ValidationReport), String> {
        let project_data: serde_json::Value = serde_json::from_str(&json_content)
            .map_err(|e| format!("Invalid project JSON: {}", e))?;
        
        // For save-project, available files are the ones being uploaded
        let mut available_files = HashSet::new();
        for (name, _) in &temp_images_for_validation {
            available_files.insert(name.clone());
        }
        
        let (mut validated_project, report) = project::validate_and_clean_project(project_data, &available_files)?;
        
        // Embed report
        validated_project["validationReport"] = serde_json::to_value(&report)
            .map_err(|e| format!("Failed to serialize report: {}", e))?;
            
        let updated_json = serde_json::to_string_pretty(&validated_project)
            .map_err(|e| e.to_string())?;
            
        Ok((updated_json, report))
    }).await.map_err(|e| AppError::InternalError(e.to_string()))??;

    let zip_creation_result = web::block(move || -> Result<(), std::io::Error> {
        let file = fs::File::create(&final_zip_path)?;
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored) // Already compressed WebPs
            .unix_permissions(0o755);
            
        // Write JSON
        zip.start_file("project.json", options)?;
        zip.write_all(validated_json.as_bytes())?;
        
        // Write Images
        for (filename, path) in temp_images {
            zip.start_file(format!("images/{}", filename), options)?;
            let mut f = fs::File::open(&path)?;
            std::io::copy(&mut f, &mut zip)?;
            
            // Allow OS to clean up temp file (best effort)
            let _ = fs::remove_file(path);
        }
        
        zip.finish()?;
        Ok(())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
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

            tracing::info!(module = "ProjectManager", duration_ms = duration, "SAVE_PROJECT_COMPLETE");

            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(buffer))
        },
        Err(e) => {
            let _ = fs::remove_file(&zip_path); // Clean up on error too
            tracing::error!(module = "ProjectManager", duration_ms = duration, error = %e, "SAVE_PROJECT_FAILED");
            Err(e.into())
        }
    }
}

/// Validates a project ZIP file without fully loading its images.
///
/// This handler inspects the `project.json` within the ZIP and cross-references
/// it with the files present in the archive to find broken links or orphaned scenes.
///
/// # Arguments
/// * `payload` - Multipart form data containing the project ZIP "file".
///
/// # Returns
/// A `ValidationReport` containing errors and warnings.
///
/// # Errors
/// * `ImageError` if the project size exceeds limits.
/// * `InternalError` if validation fails.
#[tracing::instrument(skip(payload), name = "validate_project")]
pub async fn validate_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Validator", "VALIDATE_PROJECT_START");
    let start = std::time::Instant::now();
    let mut zip_data = Vec::new();
    
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            zip_data.extend_from_slice(&chunk);
            if zip_data.len() > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
        }
    }
    
    let report = web::block(move || {
        project::validate_project_zip(zip_data)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
    let duration = start.elapsed().as_millis();
    match report {
        Ok(validation_report) => {
            tracing::info!(module = "Validator", duration_ms = duration, "VALIDATE_PROJECT_COMPLETE");
            Ok(HttpResponse::Ok().json(validation_report))
        },
        Err(e) => {
            tracing::error!(module = "Validator", duration_ms = duration, error = %e, "VALIDATE_PROJECT_FAILED");
            Err(AppError::InternalError(e))
        },
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

    tracing::info!(module = "ProjectManager", size_bytes = zip_data.len(), "PROJECT_ZIP_RECEIVED");
    
    // 2. Process in blocking thread - create response ZIP with project.json + all images
    let result_zip = web::block(move || {
        project::process_uploaded_project_zip(zip_data)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(module = "ProjectManager", duration_ms = duration, "LOAD_PROJECT_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => {
            tracing::error!(module = "ProjectManager", duration_ms = duration, error = %e, "LOAD_PROJECT_FAILED");
            Err(e.into())
        },
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
        
        let name = field.content_disposition().and_then(|cd| cd.get_name()).unwrap_or("unknown");

        if name == "file" {
            let tmp_path = format!("{}/{}_upload.zip", TEMP_DIR, session_id);
             fs::create_dir_all(TEMP_DIR).map_err(AppError::IoError)?; // Ensure temp dir exists
             
             let mut f = fs::File::create(&tmp_path).map_err(AppError::IoError)?;
             while let Ok(Some(chunk)) = field.try_next().await {
                 f.write_all(&chunk).map_err(AppError::IoError)?;
             }
             
             // Unzip
             let file = fs::File::open(&tmp_path).map_err(AppError::IoError)?;
             let mut archive = zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;
             
             for i in 0..archive.len() {
                 let mut file = archive.by_index(i).map_err(|e| AppError::ZipError(e.to_string()))?;
                 let outpath = match file.enclosed_name() {
                    Some(path) => session_dir.join(path),
                    None => continue,
                 };
                 
                 if file.name().ends_with('/') {
                    fs::create_dir_all(&outpath).map_err(AppError::IoError)?;
                 } else {
                    if let Some(p) = outpath.parent() {
                        if !p.exists() {
                            fs::create_dir_all(&p).map_err(AppError::IoError)?;
                        }
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
                  return Err(AppError::InternalError("project.json not found in archive".into()));
             }
             
             let json_str = fs::read_to_string(project_json_path).map_err(AppError::IoError)?;
             let project_data: serde_json::Value = serde_json::from_str(&json_str).map_err(|e| AppError::InternalError(e.to_string()))?;
             
             tracing::info!(module = "ProjectManager", session_id = %session_id, "IMPORT_PROJECT_SUCCESS");

             return Ok(HttpResponse::Ok().json(ImportResponse {
                 session_id: session_id,
                 project_data: project_data
             }));
        }
    }
    
    Err(AppError::MultipartError(actix_multipart::MultipartError::Incomplete)) 
}

/// Calculates the optimal navigation path between scenes.
///
/// Supports both "Walk" (exploratory) and "Timeline" (guided) navigation modes.
/// It uses the pathfinder logic to determine camera rotations and transition
/// targets between multiple spherical panoramas.
///
/// # Arguments
/// * `req` - A JSON payload containing the `PathRequest` (Walk or Timeline).
///
/// # Returns
/// A JSON array of `Step` objects representing the calculated path.
///
/// # Errors
/// * `ValidationError` if the requested path involves non-existent scenes or broken links.
pub async fn calculate_path(
    req: web::Json<crate::pathfinder::PathRequest>,
) -> Result<HttpResponse, AppError> {
    let result = match req.into_inner() {
        crate::pathfinder::PathRequest::Walk { scenes, skip_auto_forward } => {
            crate::pathfinder::calculate_walk_path(scenes, skip_auto_forward)
        }
        crate::pathfinder::PathRequest::Timeline { scenes, timeline, skip_auto_forward } => {
            crate::pathfinder::calculate_timeline_path(scenes, timeline, skip_auto_forward)
        }
    }.map_err(AppError::ValidationError)?;
    Ok(HttpResponse::Ok().json(result))
}
