use headless_chrome::{Browser, LaunchOptions};
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

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
