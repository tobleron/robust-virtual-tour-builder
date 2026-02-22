use super::video_logic_support::{
    HeadlessControl, HeadlessMotionProfile, headless_app_origin, inject_headless_control,
    wait_for_headless_ready,
};
use headless_chrome::{Browser, LaunchOptions, Tab, protocol::cdp::Page};
use serde_json::Value;
use std::env;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

const TEASER_CAPTURE_MODE_SCRIPT: &str = r#"
(function() {
  try {
    window.__VTB_TEASER_CAPTURE__ = true;
    document.body.classList.add("vtb-teaser-capture");

    const hiddenIds = [
      "viewer-utility-bar",
      "viewer-floor-nav",
      "visual-pipeline-container",
      "viewer-hotspot-lines",
      "viewer-center-indicator",
      "v-scene-persistent-label",
      "v-scene-quality-indicator",
      "viewer-notifications-container",
      "cursor-guide"
    ];
    hiddenIds.forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.style.display = "none";
    });

    const sceneLayer = document.getElementById("viewer-scene-elements-layer");
    if (sceneLayer) sceneLayer.style.display = "none";

    const styleId = "__vtb_teaser_capture_style";
    let style = document.getElementById(styleId);
    if (!style) {
      style = document.createElement("style");
      style.id = styleId;
      document.head.appendChild(style);
    }
    style.textContent = `
      #viewer-utility-bar,
      #viewer-floor-nav,
      #visual-pipeline-container,
      #viewer-hotspot-lines,
      #viewer-center-indicator,
      #v-scene-persistent-label,
      #v-scene-quality-indicator,
      #viewer-notifications-container,
      #cursor-guide,
      #viewer-scene-elements-layer { display: none !important; }
      #viewer-logo {
        display: block !important;
        visibility: visible !important;
        opacity: 1 !important;
        pointer-events: none !important;
      }
    `;

    const logo = document.getElementById("viewer-logo");
    if (logo) {
      logo.style.display = "block";
      logo.style.visibility = "visible";
      logo.style.opacity = "1";
      logo.style.pointerEvents = "none";
    }

    return true;
  } catch (err) {
    window.HEADLESS_ERROR = (err && err.message) ? err.message : String(err);
    return false;
  }
})();
"#;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TeaserOutputFormat {
    Webm,
    Mp4,
}

const TEASER_OUTPUT_FPS: f64 = 60.0;
const TEASER_CAPTURE_JPEG_QUALITY: u32 = 92;

impl TeaserOutputFormat {
    pub fn from_str(raw: &str) -> Self {
        match raw.to_ascii_lowercase().as_str() {
            "mp4" => Self::Mp4,
            _ => Self::Webm,
        }
    }

    pub fn extension(self) -> &'static str {
        match self {
            Self::Webm => "webm",
            Self::Mp4 => "mp4",
        }
    }

    pub fn content_type(self) -> &'static str {
        match self {
            Self::Webm => "video/webm",
            Self::Mp4 => "video/mp4",
        }
    }
}

struct KillOnDrop(Option<std::process::Child>);

impl KillOnDrop {
    fn new(child: std::process::Child) -> Self {
        Self(Some(child))
    }

    fn take(&mut self) -> Option<std::process::Child> {
        self.0.take()
    }
}

impl Drop for KillOnDrop {
    fn drop(&mut self) {
        if let Some(mut child) = self.0.take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

fn headless_backend_origin() -> String {
    super::video_logic_support::headless_backend_origin()
}

fn apply_capture_mode(tab: &Tab, session_id: &str) -> Result<(), String> {
    let result = tab
        .evaluate(TEASER_CAPTURE_MODE_SCRIPT, false)
        .map_err(|e| format!("Failed to apply teaser capture mode: {}", e))?;

    let ok = result.value.and_then(|v| v.as_bool()).unwrap_or(false);
    if ok {
        Ok(())
    } else {
        tracing::error!(session_id=%session_id, stage="capture_mode", "Capture mode script reported failure");
        Err("Capture mode initialization failed".to_string())
    }
}

fn resolve_capture_viewport(tab: &Tab, session_id: &str) -> Result<Page::Viewport, String> {
    let element = tab
        .wait_for_element("#viewer-stage")
        .map_err(|e| format!("viewer-stage not found for capture: {}", e))?;
    let model = element
        .get_box_model()
        .map_err(|e| format!("viewer-stage box model unavailable: {}", e))?;
    let viewport = model.content_viewport();
    if viewport.width <= 1.0 || viewport.height <= 1.0 {
        tracing::error!(
            session_id=%session_id,
            stage="capture_mode",
            width=viewport.width,
            height=viewport.height,
            "viewer-stage viewport invalid"
        );
        return Err("viewer-stage viewport invalid".to_string());
    }
    Ok(viewport)
}

pub async fn transcode_video(input_str: String, output_str: String) -> Result<PathBuf, String> {
    let ffmpeg_cmd = get_ffmpeg_command()?;
    let mut cmd = tokio::process::Command::new(&ffmpeg_cmd);
    cmd.args([
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
    .stdout(std::process::Stdio::piped())
    .stderr(std::process::Stdio::piped())
    .kill_on_drop(true);

    let child = cmd
        .spawn()
        .map_err(|e| format!("Failed to spawn ffmpeg: {}", e))?;

    let timeout_duration = Duration::from_secs(120);
    match tokio::time::timeout(timeout_duration, child.wait_with_output()).await {
        Ok(Ok(output)) => {
            if !output.status.success() {
                return Err(format!(
                    "FFmpeg exited with code {}: {}",
                    output.status.code().unwrap_or(-1),
                    String::from_utf8_lossy(&output.stderr)
                ));
            }
        }
        Ok(Err(e)) => return Err(format!("FFmpeg wait failed: {}", e)),
        Err(_) => {
            return Err("FFmpeg timed out".to_string());
        }
    }

    let _ = tokio::fs::remove_file(&input_str).await;
    Ok(PathBuf::from(output_str))
}

pub fn generate_teaser_sync(
    project_data: Value,
    session_id: String,
    width: u32,
    height: u32,
    output_str: String,
    duration_limit: u64,
    output_format: TeaserOutputFormat,
    auth_token: Option<String>,
    motion_profile: HeadlessMotionProfile,
    motion_manifest: Option<Value>,
) -> Result<(), String> {
    let browser = Browser::new(LaunchOptions {
        headless: true,
        window_size: Some((width, height)),
        args: vec![
            std::ffi::OsStr::new("--force-device-scale-factor=1.0"),
            std::ffi::OsStr::new("--enable-webgl"),
            std::ffi::OsStr::new("--ignore-gpu-blacklist"),
            std::ffi::OsStr::new("--ignore-gpu-blocklist"),
            std::ffi::OsStr::new("--use-gl=swiftshader"),
            std::ffi::OsStr::new("--use-angle=swiftshader"),
            std::ffi::OsStr::new("--enable-unsafe-swiftshader"),
            std::ffi::OsStr::new("--disable-background-timer-throttling"),
            std::ffi::OsStr::new("--disable-renderer-backgrounding"),
            std::ffi::OsStr::new("--disable-backgrounding-occluded-windows"),
            std::ffi::OsStr::new("--run-all-compositor-stages-before-draw"),
            std::ffi::OsStr::new("--disable-frame-rate-limit"),
            std::ffi::OsStr::new("--disable-gpu-vsync"),
        ],
        ..LaunchOptions::default()
    })
    .map_err(|e| format!("Failed to launch browser: {}", e))?;

    let tab = match browser.new_tab() {
        Ok(t) => t,
        Err(e) => {
            drop(browser);
            return Err(format!("Failed to create tab: {}", e));
        }
    };

    let app_origin = headless_app_origin();
    if let Err(e) = tab.navigate_to(&app_origin) {
        // Dev fallback when frontend dev server isn't available.
        if app_origin != "http://localhost:8080" {
            if let Err(e2) = tab.navigate_to("http://localhost:8080") {
                drop(browser);
                return Err(format!("Nav failed: {} / fallback failed: {}", e, e2));
            }
        } else {
            drop(browser);
            return Err(format!("Nav failed: {}", e));
        }
    }

    if let Err(e) = tab.wait_until_navigated() {
        drop(browser);
        return Err(format!("Nav timeout: {}", e));
    }
    let session_id_clone = session_id.clone();
    let project_session_id = project_data
        .get("sessionId")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string());
    let fallback_session_id = project_session_id.unwrap_or_else(|| session_id_clone.clone());

    let control = HeadlessControl {
        project: project_data,
        backend_origin: headless_backend_origin(),
        session_id: fallback_session_id,
        auth_token: auth_token.or_else(|| env::var("HEADLESS_API_TOKEN").ok()),
        motion_profile,
        motion_manifest,
    };

    if let Err(e) = inject_headless_control(&tab, &control) {
        drop(browser);
        return Err(e);
    }

    if let Err(e) = wait_for_headless_ready(&tab, &session_id_clone, Duration::from_secs(60)) {
        drop(browser);
        return Err(e);
    }
    if let Err(e) = apply_capture_mode(&tab, &session_id_clone) {
        drop(browser);
        return Err(e);
    }
    let capture_viewport = resolve_capture_viewport(&tab, &session_id_clone)?;

    let ffmpeg_cmd = get_ffmpeg_command()?;

    let child_res = Command::new(&ffmpeg_cmd)
        .args(match output_format {
            TeaserOutputFormat::Mp4 => vec![
                "-y",
                "-f",
                "image2pipe",
                "-vcodec",
                "mjpeg",
                "-framerate",
                "60",
                "-i",
                "-",
                "-c:v",
                "libx264",
                "-preset",
                "ultrafast",
                "-pix_fmt",
                "yuv420p",
                "-r",
                "60",
                "-movflags",
                "+faststart",
                &output_str,
            ],
            TeaserOutputFormat::Webm => vec![
                "-y",
                "-f",
                "image2pipe",
                "-vcodec",
                "mjpeg",
                "-framerate",
                "60",
                "-i",
                "-",
                "-an",
                "-c:v",
                "libvpx-vp9",
                "-pix_fmt",
                "yuv420p",
                "-r",
                "60",
                "-deadline",
                "good",
                "-cpu-used",
                "2",
                "-crf",
                "30",
                "-b:v",
                "0",
                &output_str,
            ],
        })
        .stdin(std::process::Stdio::piped())
        .stderr(std::process::Stdio::inherit())
        .spawn();

    let mut child = match child_res {
        Ok(c) => c,
        Err(e) => {
            tracing::error!(session_id=%session_id_clone, stage="ffmpeg", error=%e, "Failed to spawn ffmpeg");
            drop(browser);
            return Err(format!("Failed to spawn ffmpeg: {}", e));
        }
    };

    let mut stdin = match child.stdin.take() {
        Some(s) => s,
        None => {
            let _ = child.kill();
            let _ = child.wait();
            drop(browser);
            return Err("Failed to open ffmpeg stdin".to_string());
        }
    };

    let mut guard = KillOnDrop::new(child);

    let start_script = match output_format {
        TeaserOutputFormat::Mp4 => {
            r#"(function(){
                const profile = window.__VTB_HEADLESS_MOTION_PROFILE__ || {};
                const skip = !!profile.skipAutoForward;
                if (typeof window.__VTB_START_TEASER__ === "function") return window.__VTB_START_TEASER__(true, "mp4", skip);
                if (typeof window.startHeadlessTeaser === "function") return window.startHeadlessTeaser(true, "mp4", skip);
                if (typeof window.startCinematicTeaser === "function") return window.startCinematicTeaser(true, "mp4", skip);
                throw new Error("No teaser start function found on window");
            })()"#
        }
        TeaserOutputFormat::Webm => {
            r#"(function(){
                const profile = window.__VTB_HEADLESS_MOTION_PROFILE__ || {};
                const skip = !!profile.skipAutoForward;
                if (typeof window.__VTB_START_TEASER__ === "function") return window.__VTB_START_TEASER__(true, "webm", skip);
                if (typeof window.startHeadlessTeaser === "function") return window.startHeadlessTeaser(true, "webm", skip);
                if (typeof window.startCinematicTeaser === "function") return window.startCinematicTeaser(true, "webm", skip);
                throw new Error("No teaser start function found on window");
            })()"#
        }
    };
    if let Err(e) = tab.evaluate(start_script, false) {
        drop(guard);
        drop(browser);
        return Err(format!("Failed to start teaser: {}", e));
    }
    std::thread::sleep(Duration::from_millis(120));

    let start_sim = std::time::Instant::now();
    let max_dur = Duration::from_secs(duration_limit);
    let mut screenshot_failed = false;
    let frame_interval = Duration::from_secs_f64(1.0 / TEASER_OUTPUT_FPS);
    let mut next_frame_deadline = start_sim;
    let mut emitted_frames: u64 = 0;
    let mut captured_frames: u64 = 0;
    let mut duplicated_frames: u64 = 0;
    let mut last_png: Option<Vec<u8>> = None;

    loop {
        let now = std::time::Instant::now();
        if now - start_sim > max_dur {
            break;
        }

        if now < next_frame_deadline {
            std::thread::sleep(next_frame_deadline - now);
            continue;
        }

        if let Ok(v) = tab.evaluate("window.isAutoPilotActive()", false)
            && !v.value.and_then(|x| x.as_bool()).unwrap_or(true)
        {
            break;
        }

        use std::io::Write;

        let current_frame = match tab.capture_screenshot(
            headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::Jpeg,
            Some(TEASER_CAPTURE_JPEG_QUALITY),
            Some(capture_viewport.clone()),
            true,
        ) {
            Ok(frame_data) => {
                last_png = Some(frame_data.clone());
                captured_frames = captured_frames.saturating_add(1);
                frame_data
            }
            Err(e) => {
                if let Some(previous) = last_png.clone() {
                    tracing::warn!(
                        session_id=%session_id_clone,
                        stage="frame_capture",
                        error=%e,
                        "Screenshot failed; reusing previous frame"
                    );
                    previous
                } else {
                    tracing::error!(session_id=%session_id_clone, stage="frame_capture", error=%e, "Screenshot capture failed");
                    screenshot_failed = true;
                    break;
                }
            }
        };

        let elapsed_secs = std::time::Instant::now()
            .duration_since(start_sim)
            .as_secs_f64();
        let expected_frames = (elapsed_secs * TEASER_OUTPUT_FPS).floor() as u64;
        let frames_to_emit = std::cmp::max(1, expected_frames.saturating_sub(emitted_frames));
        if frames_to_emit > 1 {
            duplicated_frames = duplicated_frames.saturating_add(frames_to_emit - 1);
        }
        for _ in 0..frames_to_emit {
            if stdin.write_all(&current_frame).is_err() {
                screenshot_failed = true;
                break;
            }
        }
        if screenshot_failed {
            break;
        }
        emitted_frames = emitted_frames.saturating_add(frames_to_emit);

        while next_frame_deadline <= std::time::Instant::now() {
            next_frame_deadline += frame_interval;
        }
    }

    drop(stdin); // Close stdin to signal EOF to ffmpeg

    if screenshot_failed {
        tracing::error!(session_id=%session_id_clone, stage="frame_capture", "Screenshot failed during generation");
        drop(guard); // Kills child
        drop(browser);
        return Err("Screenshot failed during generation".to_string());
    }

    // Now wait for ffmpeg to finish
    // We take child out of guard so guard doesn't kill it
    let mut child = match guard.take() {
        Some(c) => c,
        None => {
            drop(browser);
            return Err("Failed to retrieve ffmpeg child process".to_string());
        }
    };

    let start_wait = std::time::Instant::now();
    let wait_timeout = Duration::from_secs(60);

    loop {
        match child.try_wait() {
            Ok(Some(status)) => {
                if !status.success() {
                    tracing::error!(session_id=%session_id_clone, stage="ffmpeg", code=?status.code(), "FFmpeg exited with error");
                    drop(browser);
                    return Err(format!(
                        "FFmpeg exited with error code: {:?}",
                        status.code()
                    ));
                }
                break;
            }
            Ok(None) => {
                if start_wait.elapsed() > wait_timeout {
                    tracing::error!(session_id=%session_id_clone, stage="ffmpeg", "Timeout waiting for FFmpeg to finish");
                    let _ = child.kill();
                    let _ = child.wait();
                    drop(browser);
                    return Err("Timeout waiting for FFmpeg to finish".to_string());
                }
                std::thread::sleep(Duration::from_millis(100));
            }
            Err(e) => {
                tracing::error!(session_id=%session_id_clone, stage="ffmpeg", error=%e, "FFmpeg wait error");
                let _ = child.kill();
                let _ = child.wait();
                drop(browser);
                return Err(format!("FFmpeg wait error: {}", e));
            }
        }
    }

    // Success
    let elapsed_secs = start_sim.elapsed().as_secs_f64();
    let emitted_fps = if elapsed_secs > 0.0 {
        emitted_frames as f64 / elapsed_secs
    } else {
        0.0
    };
    let captured_fps = if elapsed_secs > 0.0 {
        captured_frames as f64 / elapsed_secs
    } else {
        0.0
    };
    tracing::info!(
        module = "TeaserGenerator",
        session_id = %session_id_clone,
        duration_s = elapsed_secs,
        emitted_frames = emitted_frames,
        captured_frames = captured_frames,
        duplicated_frames = duplicated_frames,
        emitted_fps = emitted_fps,
        captured_fps = captured_fps,
        "TEASER_CAPTURE_STATS"
    );

    // browser is dropped here at end of scope
    Ok(())
}

fn get_ffmpeg_command() -> Result<String, String> {
    super::video_logic_support::get_ffmpeg_command()
}
