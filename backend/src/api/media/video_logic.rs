use super::video_logic_support::{
    HeadlessControl, HeadlessMotionProfile, headless_app_origin, inject_headless_control,
    wait_for_headless_ready,
};
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use headless_chrome::{
    Browser, LaunchOptions, Tab,
    protocol::cdp::{Page, types::Event},
};
use serde_json::Value;
use std::env;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use std::sync::Arc;
use std::time::Duration;

const TEASER_CAPTURE_MODE_SCRIPT: &str = r#"
(function() {
  try {
    window.__VTB_TEASER_CAPTURE__ = true;
    document.body.classList.add("vtb-teaser-capture");

    const hiddenIds = [
      "sidebar",
      "viewer-utility-bar",
      "viewer-floor-nav",
      "visual-pipeline-container",
      "viewer-hotspot-lines",
      "viewer-center-indicator",
      "v-scene-persistent-label",
      "v-scene-quality-indicator",
      "viewer-notifications-container",
      "cursor-guide",
      "placeholder-text",
      "modal-container"
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
      #sidebar,
      #viewer-utility-bar,
      #viewer-floor-nav,
      #visual-pipeline-container,
      #viewer-hotspot-lines,
      #viewer-center-indicator,
      #v-scene-persistent-label,
      #v-scene-quality-indicator,
      #viewer-notifications-container,
      #cursor-guide,
      #placeholder-text,
      #modal-container,
      #viewer-scene-elements-layer { display: none !important; }
      #viewer-container {
        width: 100vw !important;
        max-width: 100vw !important;
        flex: 1 1 100% !important;
      }
      #viewer-stage {
        width: 100vw !important;
        max-width: 100vw !important;
      }
      html, body, #root {
        width: 100vw !important;
        max-width: 100vw !important;
        overflow: hidden !important;
      }
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
const CDP_FRAME_TIMEOUT_MS: u64 = 120;
const CDP_FRAME_STALL_MS: u64 = 1500;
const CDP_LATE_FRAME_FACTOR: f64 = 1.5;

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

struct CaptureStats {
    mode: &'static str,
    duration_s: f64,
    emitted_frames: u64,
    captured_frames: u64,
    duplicated_frames: u64,
    dropped_frames: u64,
    late_frames: u64,
    emitted_fps: f64,
    captured_fps: f64,
}

struct CaptureFailure {
    message: String,
    emitted_frames: u64,
}

fn start_script_content(format: TeaserOutputFormat) -> &'static str {
    match format {
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
    }
}

fn capture_frames_cdp(
    tab: &Tab,
    session_id: &str,
    start_sim: std::time::Instant,
    max_dur: Duration,
    stdin: &mut std::process::ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, CaptureFailure> {
    let (tx, rx) = std::sync::mpsc::channel();
    let capture_width = capture_viewport.width.round().max(1.0) as u32;
    let capture_height = capture_viewport.height.round().max(1.0) as u32;

    tab.call_method(Page::StartScreencast {
        format: Some(headless_chrome::protocol::cdp::Page::StartScreencastFormatOption::Jpeg),
        quality: Some(TEASER_CAPTURE_JPEG_QUALITY),
        max_width: Some(capture_width),
        max_height: Some(capture_height),
        every_nth_frame: Some(1),
    })
    .map_err(|e| CaptureFailure {
        message: format!("Failed to enable screencast: {}", e),
        emitted_frames: 0,
    })?;

    let listener_tx = tx.clone();
    tab.add_event_listener(Arc::new(move |event: &Event| {
        if let Event::PageScreencastFrame(e) = event {
            let _ = listener_tx.send(e.clone());
        }
    }))
    .map_err(|e| {
        let _ = tab.call_method(Page::StopScreencast(None));
        CaptureFailure {
            message: format!("Failed to add event listener: {}", e),
            emitted_frames: 0,
        }
    })?;

    let target_frame_step_s = 1.0 / TEASER_OUTPUT_FPS;
    let mut emitted_frames: u64 = 0;
    let mut captured_frames: u64 = 0;
    let mut duplicated_frames: u64 = 0;
    let mut dropped_frames: u64 = 0;
    let mut late_frames: u64 = 0;
    let mut last_frame_data: Option<Vec<u8>> = None;
    let mut last_frame_wall = start_sim;
    let mut last_frame_ts: Option<f64> = None;
    let mut first_frame_received = false;

    loop {
        if std::time::Instant::now() - start_sim > max_dur {
            break;
        }

        match rx.recv_timeout(Duration::from_millis(CDP_FRAME_TIMEOUT_MS)) {
            Ok(event) => {
                let _ = tab.ack_screencast(event.params.session_id);
                let frame_data = match BASE64.decode(&event.params.data) {
                    Ok(bytes) => bytes,
                    Err(e) => {
                        tracing::warn!(
                            session_id=%session_id,
                            stage="cdp_capture_decode",
                            error=%e,
                            "Failed to decode CDP frame; skipping"
                        );
                        continue;
                    }
                };

                let now = std::time::Instant::now();
                let metadata_ts = event.params.metadata.timestamp;
                let elapsed_wall = now.duration_since(last_frame_wall).as_secs_f64();
                let delta_s = match (last_frame_ts, metadata_ts) {
                    (Some(prev), Some(current)) if current > prev => current - prev,
                    _ => elapsed_wall,
                };

                let mut frames_to_emit = if first_frame_received {
                    (delta_s * TEASER_OUTPUT_FPS).round() as u64
                } else {
                    1
                };
                if frames_to_emit == 0 {
                    frames_to_emit = 1;
                }

                if first_frame_received && delta_s > target_frame_step_s * CDP_LATE_FRAME_FACTOR {
                    late_frames = late_frames.saturating_add(1);
                }

                if frames_to_emit > 1 {
                    let inferred_missing = frames_to_emit - 1;
                    duplicated_frames = duplicated_frames.saturating_add(inferred_missing);
                    dropped_frames = dropped_frames.saturating_add(inferred_missing);
                }

                for _ in 0..frames_to_emit {
                    if stdin.write_all(&frame_data).is_err() {
                        let _ = tab.call_method(Page::StopScreencast(None));
                        return Err(CaptureFailure {
                            message: "Failed to write CDP frame to ffmpeg".to_string(),
                            emitted_frames,
                        });
                    }
                }

                emitted_frames = emitted_frames.saturating_add(frames_to_emit);
                captured_frames = captured_frames.saturating_add(1);
                first_frame_received = true;
                last_frame_wall = now;
                if let Some(ts) = metadata_ts {
                    last_frame_ts = Some(ts);
                } else if let Some(prev_ts) = last_frame_ts {
                    last_frame_ts = Some(prev_ts + delta_s);
                } else {
                    last_frame_ts = Some(delta_s);
                }
                last_frame_data = Some(frame_data);
            }
            Err(std::sync::mpsc::RecvTimeoutError::Timeout) => {
                if let Ok(v) = tab.evaluate("window.isAutoPilotActive()", false)
                    && !v.value.and_then(|x| x.as_bool()).unwrap_or(true)
                {
                    break;
                }

                if !first_frame_received {
                    if std::time::Instant::now() - start_sim > Duration::from_secs(5) {
                        let _ = tab.call_method(Page::StopScreencast(None));
                        return Err(CaptureFailure {
                            message: "Timeout waiting for first screencast frame".to_string(),
                            emitted_frames: 0,
                        });
                    }
                } else if last_frame_wall.elapsed() > Duration::from_millis(CDP_FRAME_STALL_MS) {
                    let _ = tab.call_method(Page::StopScreencast(None));
                    return Err(CaptureFailure {
                        message: "Screencast stalled waiting for frames".to_string(),
                        emitted_frames,
                    });
                }
            }
            Err(std::sync::mpsc::RecvTimeoutError::Disconnected) => {
                let _ = tab.call_method(Page::StopScreencast(None));
                return Err(CaptureFailure {
                    message: "Screencast channel disconnected".to_string(),
                    emitted_frames,
                });
            }
        }
    }

    let _ = tab.call_method(Page::StopScreencast(None));

    if let Some(last_frame) = last_frame_data.as_ref() {
        let expected_total_frames =
            (start_sim.elapsed().as_secs_f64() * TEASER_OUTPUT_FPS).round() as u64;
        if expected_total_frames > emitted_frames {
            let tail_pad = expected_total_frames - emitted_frames;
            duplicated_frames = duplicated_frames.saturating_add(tail_pad);
            dropped_frames = dropped_frames.saturating_add(tail_pad);
            for _ in 0..tail_pad {
                if stdin.write_all(last_frame).is_err() {
                    return Err(CaptureFailure {
                        message: "Failed to write CDP tail frame to ffmpeg".to_string(),
                        emitted_frames,
                    });
                }
            }
            emitted_frames = emitted_frames.saturating_add(tail_pad);
        }
    }

    let elapsed_secs = start_sim.elapsed().as_secs_f64();
    Ok(CaptureStats {
        mode: "cdp",
        duration_s: elapsed_secs,
        emitted_frames,
        captured_frames,
        duplicated_frames,
        dropped_frames,
        late_frames,
        emitted_fps: if elapsed_secs > 0.0 {
            emitted_frames as f64 / elapsed_secs
        } else {
            0.0
        },
        captured_fps: if elapsed_secs > 0.0 {
            captured_frames as f64 / elapsed_secs
        } else {
            0.0
        },
    })
}

fn capture_frames_polling(
    tab: &Tab,
    session_id: &str,
    start_sim: std::time::Instant,
    max_dur: Duration,
    stdin: &mut std::process::ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, String> {
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
                        session_id=%session_id,
                        stage="frame_capture",
                        error=%e,
                        "Screenshot failed; reusing previous frame"
                    );
                    previous
                } else {
                    tracing::error!(session_id=%session_id, stage="frame_capture", error=%e, "Screenshot capture failed");
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

    if screenshot_failed {
        return Err("Screenshot failed during generation".to_string());
    }

    let elapsed_secs = start_sim.elapsed().as_secs_f64();
    Ok(CaptureStats {
        mode: "polling",
        duration_s: elapsed_secs,
        emitted_frames,
        captured_frames,
        duplicated_frames,
        dropped_frames: duplicated_frames,
        late_frames: 0,
        emitted_fps: if elapsed_secs > 0.0 {
            emitted_frames as f64 / elapsed_secs
        } else {
            0.0
        },
        captured_fps: if elapsed_secs > 0.0 {
            captured_frames as f64 / elapsed_secs
        } else {
            0.0
        },
    })
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

    let start_script = start_script_content(output_format);
    if let Err(e) = tab.evaluate(start_script, false) {
        drop(guard);
        drop(browser);
        return Err(format!("Failed to start teaser: {}", e));
    }
    std::thread::sleep(Duration::from_millis(120));

    let start_sim = std::time::Instant::now();
    let max_dur = Duration::from_secs(duration_limit);

    // Try CDP first
    let stats_res = capture_frames_cdp(
        &tab,
        &session_id_clone,
        start_sim,
        max_dur,
        &mut stdin,
        &capture_viewport,
    );

    let stats = match stats_res {
        Ok(s) => {
            tracing::info!(session_id=%session_id_clone, mode="cdp", "Captured teaser using CDP");
            s
        }
        Err(failure) => {
            if failure.emitted_frames == 0 {
                tracing::warn!(
                    session_id=%session_id_clone,
                    mode="cdp",
                    error=%failure.message,
                    "CDP capture failed before first frame; falling back to screenshot polling"
                );
                capture_frames_polling(
                    &tab,
                    &session_id_clone,
                    std::time::Instant::now(),
                    max_dur,
                    &mut stdin,
                    &capture_viewport,
                )?
            } else {
                tracing::error!(
                    session_id=%session_id_clone,
                    mode="cdp",
                    emitted_frames=%failure.emitted_frames,
                    error=%failure.message,
                    "CDP capture failed after frame emission; aborting without polling fallback"
                );
                return Err(format!(
                    "CDP capture failed after {} emitted frames: {}",
                    failure.emitted_frames, failure.message
                ));
            }
        }
    };

    drop(stdin); // Close stdin to signal EOF to ffmpeg

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

    let encoded_duration_s = if stats.emitted_frames > 0 {
        stats.emitted_frames as f64 / TEASER_OUTPUT_FPS
    } else {
        0.0
    };
    let duration_drift_s = (encoded_duration_s - stats.duration_s).abs();
    let duplicate_ratio = if stats.emitted_frames > 0 {
        stats.duplicated_frames as f64 / stats.emitted_frames as f64
    } else {
        0.0
    };

    // Success
    tracing::info!(
        module = "TeaserGenerator",
        session_id = %session_id_clone,
        capture_mode = stats.mode,
        duration_s = stats.duration_s,
        encoded_duration_s = encoded_duration_s,
        duration_drift_s = duration_drift_s,
        emitted_frames = stats.emitted_frames,
        captured_frames = stats.captured_frames,
        duplicated_frames = stats.duplicated_frames,
        dropped_frames = stats.dropped_frames,
        late_frames = stats.late_frames,
        duplicate_ratio = duplicate_ratio,
        emitted_fps = stats.emitted_fps,
        captured_fps = stats.captured_fps,
        "TEASER_CAPTURE_STATS"
    );

    // browser is dropped here at end of scope
    Ok(())
}

fn get_ffmpeg_command() -> Result<String, String> {
    super::video_logic_support::get_ffmpeg_command()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn teaser_output_format_parses_mp4_and_defaults_to_webm() {
        assert_eq!(TeaserOutputFormat::from_str("mp4"), TeaserOutputFormat::Mp4);
        assert_eq!(TeaserOutputFormat::from_str("MP4"), TeaserOutputFormat::Mp4);
        assert_eq!(
            TeaserOutputFormat::from_str("webm"),
            TeaserOutputFormat::Webm
        );
        assert_eq!(
            TeaserOutputFormat::from_str("unexpected-format"),
            TeaserOutputFormat::Webm
        );
    }
}
