use actix_multipart::Multipart;
use actix_web::{web, HttpResponse};
use futures_util::TryStreamExt as _;
use headless_chrome::{Browser, LaunchOptions};
use std::fs;
use std::io::Write;
use std::process::Command;
use std::path::PathBuf;
use std::time::Duration;
use uuid::Uuid;

use crate::models::AppError;
use crate::api::utils::{get_temp_path, get_session_path, sanitize_filename, MAX_UPLOAD_SIZE};

#[tracing::instrument(skip(payload), name = "transcode_video")]
pub async fn transcode_video(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let input_path = get_temp_path("webm");
    
    let mut total_size = 0;

    // Save upload to disk
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition().ok_or_else(|| AppError::InternalError("Missing content disposition".to_string()))?;
        
        // Only process the 'file' field as video
        if content_disposition.get_name() == Some("file") {
            let mut f = fs::File::create(&input_path)?;
            while let Some(chunk) = field.try_next().await? {
                total_size += chunk.len();
                if total_size > MAX_UPLOAD_SIZE {
                    let _ = fs::remove_file(&input_path);
                    return Err(AppError::ImageError(
                        format!("Video upload exceeds maximum size of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                    ));
                }
                f.write_all(&chunk)?;
            }
        }
    }

    let output_path = get_temp_path("mp4");
    let input_str = input_path.to_str()
        .ok_or(AppError::InternalError("Invalid input path encoding".into()))?
        .to_string();
    let output_str = output_path.to_str()
        .ok_or(AppError::InternalError("Invalid output path encoding".into()))?
        .to_string();

    tracing::info!(module = "VideoEncoder", input = %input_str, output = %output_str, "TRANSCODE_START");

    let result = web::block(move || -> Result<PathBuf, String> {
        let local_ffmpeg = PathBuf::from("./bin/ffmpeg");
        let ffmpeg_cmd = if local_ffmpeg.exists() {
            local_ffmpeg.to_str()
                .ok_or("Invalid ffmpeg path encoding".to_string())?
                .to_string()
            
        } else {
            "ffmpeg".to_string()
        };

        let output = Command::new(&ffmpeg_cmd)
            .args(&[
                "-y",
                "-i", &input_str,
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "23",
                "-c:a", "aac",
                &output_str
            ])
            .output()
            .map_err(|e| format!("Failed to spawn ffmpeg (path: {}): {}", ffmpeg_cmd, e))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(format!("FFmpeg exited with code {}: {}", 
                output.status.code().unwrap_or(-1), 
                stderr
            ));
        }

        let _ = fs::remove_file(&input_str);
        Ok::<PathBuf, String>(PathBuf::from(output_str))
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    match result {
        Ok(path) => {
            tracing::info!(module = "VideoEncoder", "TRANSCODE_COMPLETE");
            let file_bytes = fs::read(&path)?;
            let _ = fs::remove_file(path);
            Ok(HttpResponse::Ok()
                .content_type("video/mp4")
                .body(file_bytes))
        },
        Err(e) => {
            let _ = fs::remove_file(&input_path);
            Err(AppError::FFmpegError(e))
        },
    }
}

#[tracing::instrument(skip(payload), name = "generate_teaser")]
pub async fn generate_teaser(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // 1. Create a transient session ID for this generation request
    let session_id = Uuid::new_v4().to_string();
    let session_path = get_session_path(&session_id);
    fs::create_dir_all(&session_path).map_err(AppError::IoError)?;
    
    tracing::info!(module = "TeaserGenerator", session_id = %session_id, "TEASER_GENERATION_START");

    let mut project_data_value: Option<serde_json::Value> = None;
    let mut width = 1920;
    let mut height = 1080;
    let duration_limit = 120; // Default limit

    // 2. Parse Multipart
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition()
            .cloned()
            .ok_or(AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition.get_name().unwrap_or("").to_string();

        if name == "project_data" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? { bytes.extend_from_slice(&chunk); }
            project_data_value = serde_json::from_slice(&bytes).ok();
        } else if name == "width" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? { bytes.extend_from_slice(&chunk); }
            if let Ok(s) = String::from_utf8(bytes) {
                if let Ok(val) = s.parse::<u32>() { width = val; }
            }
        } else if name == "height" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? { bytes.extend_from_slice(&chunk); }
             if let Ok(s) = String::from_utf8(bytes) {
                if let Ok(val) = s.parse::<u32>() { height = val; }
            }
        } else if name == "files" {
            let filename = content_disposition.get_filename().map(|f| f.to_string()).unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized = sanitize_filename(&filename).unwrap_or(filename);
            let file_path = session_path.join(&sanitized);
            let mut f = fs::File::create(file_path).map_err(AppError::IoError)?;
             while let Some(chunk) = field.try_next().await? { f.write_all(&chunk).map_err(AppError::IoError)?; }
        }
    }

    let project_data = project_data_value.ok_or_else(|| AppError::InternalError("Missing project_data JSON".into()))?;

    let output_path = get_temp_path("mp4");
    let output_str = output_path.to_str()
        .ok_or(AppError::InternalError("Invalid output path encoding".into()))?
        .to_string();
    
    // session_id must be moved into the closure
    let session_id_clone = session_id.clone();
    let _session_path_clone = session_path.clone();

    // Run blocking browser automation
    let result = web::block(move || -> Result<(), String> {
        // 1. Launch Browser
        let browser = Browser::new(LaunchOptions {
            headless: true,
            window_size: Some((width, height)),
            args: vec![
                std::ffi::OsStr::new("--force-device-scale-factor=1.0"), 
                std::ffi::OsStr::new("--enable-webgl"), 
                std::ffi::OsStr::new("--ignore-gpu-blacklist")
            ], 
            ..LaunchOptions::default()
        }).map_err(|e| format!("Failed to launch browser: {}", e))?;

        let tab = browser.new_tab().map_err(|e| format!("Failed to create tab: {}", e))?;

        // 2. Navigate to Frontend
        // Ensure this URL is reachable from the backend process
        // Note: Make sure the frontend is running!
        tab.navigate_to("http://localhost:8080").map_err(|e| format!("Nav failed: {}", e))?;
        tab.wait_until_navigated().map_err(|e| format!("Nav timeout: {}", e))?;

        // 3. Inject Project Data & Loader Script
        let json_str = serde_json::to_string(&project_data)
            .map_err(|e| format!("Failed to serialize project data: {}", e))?;
        // Script: Fetch images from session, create blobs, then load project
        let script = format!(r#"
            (async function() {{
                try {{
                    // Data from backend
                    const data = {};
                    const sessionId = "{}";
                    
                    console.log("Headless: Starting resource hydration for session " + sessionId);

                    if (!window.store) {{
                        console.error("Store not found!");
                        window.HEADLESS_ERROR = "Store not found";
                        return;
                    }}

                    // Hydrate scenes with Blobs
                    // We need to mutate the scene objects in 'data.scenes' to add 'file' property (Blob)
                    // But JSON parsing makes them plain objects.
                    // We must fetch blobs.
                    
                    if (data.scenes && Array::isArray(data.scenes)) {{
                        await Promise.all(data.scenes.map(async (scene) => {{
                            try {{
                                // Filename in project match filename stored
                                const url = `/api/session/${{sessionId}}/${{encodeURIComponent(scene.name)}}`;
                                const resp = await fetch(url);
                                if (!resp.ok) throw new Error("Fetch failed: " + resp.status);
                                const blob = await resp.blob();
                                // Create File object
                                // Note: Pannellum needs .file property on scene object if it uses it.
                                // Or store.loadProject handles it? store.loadProject handles blobs if provided.
                                scene.file = new File([blob], scene.name, {{ type: 'image/webp' }});
                                scene.originalFile = scene.file;
                                scene.tinyFile = scene.file; 
                            }} catch (e) {{
                                console.error("Failed to hydrate scene: " + scene.name, e);
                            }}
                        }}));
                    }}

                    // Load Project
                    await Promise.resolve(window.store.loadProject(data)); // This sets store.state.scenes = data.scenes (with blobs!)
                    
                    console.log("Project loaded in headless mode");
                    
                    // Allow UI to settle (Pannellum init)
                    setTimeout(() => {{ window.HEADLESS_READY = true; }}, 2000);

                }} catch (e) {{
                    console.error("Headless initialization failed:", e);
                    window.HEADLESS_ERROR = e.toString();
                }}
            }})();
        "#, json_str, session_id_clone);
        
        tab.evaluate(&script, false).map_err(|e| format!("Injection failed: {}", e))?;

        // Wait for ready
        let start_wait = std::time::Instant::now();
        loop {
            if std::time::Instant::now() - start_wait > Duration::from_secs(60) { // Increased timeout for fetch
                return Err("Timeout waiting for project load".to_string());
            }
            
            // Check success
            let val = tab.evaluate("window.HEADLESS_READY", false);
            if let Ok(v) = val {
                if v.value.and_then(|x| x.as_bool()).unwrap_or(false) {
                    break;
                }
            }
            
            // Check error
            let err_val = tab.evaluate("window.HEADLESS_ERROR", false);
             if let Ok(v) = err_val {
                if let Some(msg) = v.value.and_then(|x| x.as_str().map(|s| s.to_string())) {
                     return Err(format!("Headless Client Error: {}", msg));
                }
            }
            
            std::thread::sleep(Duration::from_millis(500));
        }

        // 4. Start FFmpeg Process
        let local_ffmpeg = PathBuf::from("./bin/ffmpeg");
        let ffmpeg_cmd = if local_ffmpeg.exists() {
            local_ffmpeg.to_str()
                .ok_or("Invalid ffmpeg path encoding".to_string())?
                .to_string()
        } else {
            "ffmpeg".to_string()
        };

        let mut child = Command::new(&ffmpeg_cmd)
            .args(&[
                "-y",
                "-f", "image2pipe",
                "-vcodec", "png",
                "-r", "30",
                "-i", "-",
                "-c:v", "libx264",
                "-preset", "ultrafast",
                "-pix_fmt", "yuv420p",
                "-movflags", "+faststart",
                &output_str
            ])
            .stdin(std::process::Stdio::piped())
            .stderr(std::process::Stdio::inherit()) // Log ffmpeg error to stderr
            .spawn()
            .map_err(|e| format!("Failed to spawn ffmpeg: {}", e))?;

        let mut stdin = child.stdin.take().ok_or("Failed to open ffmpeg stdin")?;

        // 5. Trigger Cinematic Teaser via Frontend (MP4 mode, autoPilot)
        tab.evaluate("window.startCinematicTeaser(true, 'mp4', true)", false)
            .map_err(|e| format!("Failed to start teaser: {}", e))?;

        // 6. Capture Loop
        let start_sim = std::time::Instant::now();
        let max_dur = Duration::from_secs(duration_limit);
        
        loop {
            if std::time::Instant::now() - start_sim > max_dur {
                break;
            }

            // Check if simulation finished
            let active = tab.evaluate("window.isAutoPilotActive()", false);
            if let Ok(v) = active {
                if !v.value.and_then(|x| x.as_bool()).unwrap_or(true) {
                    break;
                }
            }

            // Capture Screenshot
            let png_data = tab.capture_screenshot(headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::Png, None, None, true)
                .map_err(|e| format!("Screenshot failed: {}", e))?;

            if let Err(_e) = stdin.write_all(&png_data) {
                // EPIPE means ffmpeg closed (maybe finished or errored)
                break; 
            }
            
            std::thread::sleep(Duration::from_millis(10));
        }

        drop(stdin); // Close stdin to signal EOF
        child.wait().map_err(|e| format!("FFmpeg failed: {}", e))?;

        Ok(())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    // Clean up session files
    let _ = fs::remove_dir_all(&session_path);

    match result {
        Ok(_) => {
            tracing::info!(module = "TeaserGenerator", "TEASER_GENERATION_COMPLETE");
            let file_bytes = fs::read(&output_path).map_err(AppError::IoError)?;
            let _ = fs::remove_file(output_path); // Cleanup result file
            Ok(HttpResponse::Ok()
                .content_type("video/mp4")
                .body(file_bytes))
        },
        Err(e) => {
            let _ = fs::remove_file(&output_path); // Cleanup on error
            Err(AppError::InternalError(e))
        },
    }
}
