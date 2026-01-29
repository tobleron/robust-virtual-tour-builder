/* backend/src/api/media/video.rs - Consolidated Video API */

use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use futures_util::TryStreamExt as _;
use headless_chrome::{Browser, LaunchOptions};
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;
use uuid::Uuid;

use crate::api::utils::{MAX_UPLOAD_SIZE, TEMP_DIR, get_temp_path, sanitize_filename};
use crate::models::AppError;

// --- HANDLERS ---

/// Generates a cinematic teaser video of the virtual tour.
#[tracing::instrument(skip(payload), name = "generate_teaser")]
pub async fn generate_teaser(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let session_id = Uuid::new_v4().to_string();
    let session_path = std::path::PathBuf::from(TEMP_DIR).join(&session_id);
    fs::create_dir_all(&session_path).map_err(AppError::IoError)?;

    tracing::info!(module = "TeaserGenerator", session_id = %session_id, "TEASER_GENERATION_START");

    let mut project_data_value: Option<serde_json::Value> = None;
    let mut width = 1920;
    let mut height = 1080;
    let duration_limit = 120;

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition =
            field
                .content_disposition()
                .cloned()
                .ok_or(AppError::InternalError(
                    "Missing content disposition".into(),
                ))?;
        let name = content_disposition.get_name().unwrap_or("").to_string();

        if name == "project_data" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            project_data_value = serde_json::from_slice(&bytes).ok();
        } else if name == "width" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(bytes)
                && let Ok(val) = s.parse::<u32>()
            {
                width = val;
            }
        } else if name == "height" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(bytes)
                && let Ok(val) = s.parse::<u32>()
            {
                height = val;
            }
        } else if name == "files" {
            let filename = content_disposition
                .get_filename()
                .map(|f| f.to_string())
                .unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized = sanitize_filename(&filename).unwrap_or(filename);
            let file_path = session_path.join(&sanitized);
            let mut f = fs::File::create(file_path).map_err(AppError::IoError)?;
            while let Some(chunk) = field.try_next().await? {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }
        }
    }

    let project_data = project_data_value
        .ok_or_else(|| AppError::InternalError("Missing project_data JSON".into()))?;
    let output_path = get_temp_path("mp4");
    let output_str = output_path.to_string_lossy().to_string();
    let session_id_clone = session_id.clone();

    let result = web::block(move || {
        generate_teaser_sync(
            project_data,
            session_id_clone,
            width,
            height,
            output_str,
            duration_limit as u64,
        )
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    let _ = fs::remove_dir_all(&session_path);

    match result {
        Ok(_) => {
            tracing::info!(module = "TeaserGenerator", "TEASER_GENERATION_COMPLETE");
            let file_bytes = fs::read(&output_path).map_err(AppError::IoError)?;
            let _ = fs::remove_file(output_path);
            Ok(HttpResponse::Ok()
                .content_type("video/mp4")
                .body(file_bytes))
        }
        Err(e) => {
            let _ = fs::remove_file(&output_path);
            Err(AppError::InternalError(e))
        }
    }
}

/// Transcodes an uploaded video file to MP4.
#[tracing::instrument(skip(payload), name = "transcode_video")]
pub async fn transcode_video(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let input_path = get_temp_path("webm");
    let mut total_size = 0;

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field
            .content_disposition()
            .ok_or_else(|| AppError::InternalError("Missing content disposition".to_string()))?;
        if content_disposition.get_name() == Some("file") {
            let mut f = fs::File::create(&input_path)?;
            while let Some(chunk) = field.try_next().await? {
                total_size += chunk.len();
                if total_size > MAX_UPLOAD_SIZE {
                    let _ = fs::remove_file(&input_path);
                    return Err(AppError::ImageError(format!(
                        "Video upload exceeds maximum size of {}MB",
                        MAX_UPLOAD_SIZE / (1024 * 1024)
                    )));
                }
                f.write_all(&chunk)?;
            }
        }
    }

    let output_path = get_temp_path("mp4");
    let input_str = input_path.to_string_lossy().to_string();
    let output_str = output_path.to_string_lossy().to_string();

    tracing::info!(module = "VideoEncoder", input = %input_str, output = %output_str, "TRANSCODE_START");

    let result = web::block(move || transcode_video_sync(input_str, output_str))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;

    match result {
        Ok(path) => {
            tracing::info!(module = "VideoEncoder", "TRANSCODE_COMPLETE");
            let file_bytes = fs::read(&path)?;
            let _ = fs::remove_file(path);
            Ok(HttpResponse::Ok()
                .content_type("video/mp4")
                .body(file_bytes))
        }
        Err(e) => {
            let _ = fs::remove_file(&input_path);
            Err(AppError::FFmpegError(e))
        }
    }
}

// --- INTERNAL SYNC LOGIC ---

pub fn transcode_video_sync(input_str: String, output_str: String) -> Result<PathBuf, String> {
    let ffmpeg_cmd = get_ffmpeg_command()?;
    let output = Command::new(&ffmpeg_cmd)
        .args([
            "-y",
            "-i",
            &input_str,
            "-c:v",
            "libx264",
            "-preset",
            "medium",
            "-crf",
            "23",
            "-c:a",
            "aac",
            &output_str,
        ])
        .output()
        .map_err(|e| format!("Failed to spawn ffmpeg: {}", e))?;
    if !output.status.success() {
        return Err(format!(
            "FFmpeg exited with code {}: {}",
            output.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    let _ = fs::remove_file(&input_str);
    Ok(PathBuf::from(output_str))
}

pub fn generate_teaser_sync(
    project_data: serde_json::Value,
    session_id: String,
    width: u32,
    height: u32,
    output_str: String,
    duration_limit: u64,
) -> Result<(), String> {
    let browser = Browser::new(LaunchOptions {
        headless: true,
        window_size: Some((width, height)),
        args: vec![
            std::ffi::OsStr::new("--force-device-scale-factor=1.0"),
            std::ffi::OsStr::new("--enable-webgl"),
            std::ffi::OsStr::new("--ignore-gpu-blacklist"),
        ],
        ..LaunchOptions::default()
    })
    .map_err(|e| format!("Failed to launch browser: {}", e))?;

    let tab = browser
        .new_tab()
        .map_err(|e| format!("Failed to create tab: {}", e))?;
    tab.navigate_to("http://localhost:8080")
        .map_err(|e| format!("Nav failed: {}", e))?;
    tab.wait_until_navigated()
        .map_err(|e| format!("Nav timeout: {}", e))?;

    let json_str = serde_json::to_string(&project_data)
        .map_err(|e| format!("Failed to serialize project data: {}", e))?;
    let script = format!(
        r#"
        (async function() {{
            try {{
                const data = {};
                const sessionId = "{}";
                console.log("Headless: Starting resource hydration for session " + sessionId);
                if (!window.store) {{
                    console.error("Store not found!");
                    window.HEADLESS_ERROR = "Store not found";
                    return;
                }}
                if (data.scenes && Array.isArray(data.scenes)) {{
                    await Promise.all(data.scenes.map(async (scene) => {{
                        try {{
                            const url = `/api/session/${{sessionId}}/${{encodeURIComponent(scene.name)}}`;
                            const resp = await fetch(url);
                            if (!resp.ok) throw new Error("Fetch failed: " + resp.status);
                            const blob = await resp.blob();
                            scene.file = new File([blob], scene.name, {{ type: 'image/webp' }});
                            scene.originalFile = scene.file;
                            scene.tinyFile = scene.file;
                        }} catch (e) {{
                            console.error("Failed to hydrate scene: " + scene.name, e);
                        }}
                    }}));
                }}
                await Promise.resolve(window.store.loadProject(data));
                console.log("Project loaded in headless mode");
                setTimeout(() => {{ window.HEADLESS_READY = true; }}, 2000);
            }} catch (e) {{
                console.error("Headless initialization failed:", e);
                window.HEADLESS_ERROR = e.toString();
            }}
        }})();
    "#,
        json_str, session_id
    );

    tab.evaluate(&script, false)
        .map_err(|e| format!("Injection failed: {}", e))?;

    let start_wait = std::time::Instant::now();
    loop {
        if std::time::Instant::now() - start_wait > Duration::from_secs(60) {
            return Err("Timeout waiting for project load".to_string());
        }
        if let Ok(v) = tab.evaluate("window.HEADLESS_READY", false)
            && v.value.and_then(|x| x.as_bool()).unwrap_or(false)
        {
            break;
        }
        if let Ok(v) = tab.evaluate("window.HEADLESS_ERROR", false)
            && let Some(msg) = v.value.and_then(|x| x.as_str().map(|s| s.to_string()))
        {
            return Err(format!("Headless Client Error: {}", msg));
        }
        std::thread::sleep(Duration::from_millis(500));
    }

    let ffmpeg_cmd = get_ffmpeg_command()?;
    let mut child = Command::new(&ffmpeg_cmd)
        .args([
            "-y",
            "-f",
            "image2pipe",
            "-vcodec",
            "png",
            "-r",
            "30",
            "-i",
            "-",
            "-c:v",
            "libx264",
            "-preset",
            "ultrafast",
            "-pix_fmt",
            "yuv420p",
            "-movflags",
            "+faststart",
            &output_str,
        ])
        .stdin(std::process::Stdio::piped())
        .stderr(std::process::Stdio::inherit())
        .spawn()
        .map_err(|e| format!("Failed to spawn ffmpeg: {}", e))?;
    let mut stdin = child.stdin.take().ok_or("Failed to open ffmpeg stdin")?;

    tab.evaluate("window.startCinematicTeaser(true, 'mp4', true)", false)
        .map_err(|e| format!("Failed to start teaser: {}", e))?;

    let start_sim = std::time::Instant::now();
    let max_dur = Duration::from_secs(duration_limit);

    loop {
        if std::time::Instant::now() - start_sim > max_dur {
            break;
        }
        if let Ok(v) = tab.evaluate("window.isAutoPilotActive()", false)
            && !v.value.and_then(|x| x.as_bool()).unwrap_or(true)
        {
            break;
        }
        let png_data = tab
            .capture_screenshot(
                headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::Png,
                None,
                None,
                true,
            )
            .map_err(|e| format!("Screenshot failed: {}", e))?;
        if stdin.write_all(&png_data).is_err() {
            break;
        }
        std::thread::sleep(Duration::from_millis(10));
    }

    drop(stdin);
    child.wait().map_err(|e| format!("FFmpeg failed: {}", e))?;
    Ok(())
}

fn get_ffmpeg_command() -> Result<String, String> {
    let local_ffmpeg = PathBuf::from("./bin/ffmpeg");
    if local_ffmpeg.exists() {
        local_ffmpeg
            .to_str()
            .ok_or_else(|| "Invalid ffmpeg path encoding".to_string())
            .map(|s| s.to_string())
    } else {
        Ok("ffmpeg".to_string())
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}
