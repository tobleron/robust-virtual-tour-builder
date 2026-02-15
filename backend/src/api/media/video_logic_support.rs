use headless_chrome::Tab;
use serde::Serialize;
use serde_json::Value;
use std::env;
use std::path::PathBuf;
use std::time::Duration;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct HeadlessControl {
    pub project: Value,
    pub backend_origin: String,
    pub session_id: String,
    pub auth_token: Option<String>,
}

const HEADLESS_CONTROL_SCRIPT: &str = r#"
(function() {
  const control = window.__VTB_HEADLESS_CONTROL__;
  if (!control || !control.project) {
    window.HEADLESS_ERROR = "Missing headless control payload";
    return;
  }
  const project = control.project;
  const scenes = Array.isArray(project.scenes) ? project.scenes : [];
  const projectSessionId = project.sessionId || control.sessionId || "";
  const backendOrigin = control.backendOrigin || "";
  const authToken = control.authToken;
  if (!backendOrigin) {
    window.HEADLESS_ERROR = "Missing backend origin";
    return;
  }
  if (!projectSessionId && scenes.length > 0) {
    window.HEADLESS_ERROR = "Missing project/session id for resource hydration";
    return;
  }
  const buildUrl = (scene) => {
    if (typeof scene.file === "string" && scene.file.startsWith("http")) {
      return scene.file;
    }
    if (!projectSessionId) {
      throw new Error("Project/session id missing while building fallback URL");
    }
    return `${backendOrigin}/api/project/${encodeURIComponent(projectSessionId)}/file/${encodeURIComponent(scene.name)}`;
  };
  const fetchScene = async (scene) => {
    const url = buildUrl(scene);
    const headers = {};
    if (authToken) {
      headers.Authorization = "Bearer " + authToken;
    }
    const response = await fetch(url, { headers });
    if (!response.ok) {
      throw new Error(`Hydration fetch failed ${response.status} for ${scene.name}`);
    }
    const blob = await response.blob();
    const file = new File([blob], scene.name, { type: "image/webp" });
    scene.file = file;
    scene.originalFile = file;
    scene.tinyFile = file;
  };
  (async () => {
    await Promise.all(scenes.map(fetchScene));
    await window.store.loadProject(project);
    window.HEADLESS_READY = true;
  })().catch((err) => {
    window.HEADLESS_ERROR = (err && err.message) || err.toString();
  });
})();
"#;

pub fn headless_backend_origin() -> String {
    env::var("BACKEND_ORIGIN").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

pub fn get_ffmpeg_command() -> Result<String, String> {
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

pub fn inject_headless_control(tab: &Tab, control: &HeadlessControl) -> Result<(), String> {
    let control_json = serde_json::to_string(control)
        .map_err(|e| format!("Failed to serialize headless control payload: {}", e))?;
    let assign_control = format!("window.__VTB_HEADLESS_CONTROL__ = {};", control_json);

    tab.evaluate(&assign_control, false)
        .map_err(|e| format!("Failed to inject headless control payload: {}", e))?;
    tab.evaluate(HEADLESS_CONTROL_SCRIPT, false)
        .map_err(|e| format!("Failed to run headless hydration script: {}", e))?;

    Ok(())
}

pub fn wait_for_headless_ready(
    tab: &Tab,
    session_id: &str,
    timeout: Duration,
) -> Result<(), String> {
    let start_wait = std::time::Instant::now();
    loop {
        if std::time::Instant::now() - start_wait > timeout {
            tracing::error!(session_id=%session_id, stage="hydration", "Timeout waiting for project load");
            return Err("Timeout waiting for project load".to_string());
        }
        if let Ok(v) = tab.evaluate("window.HEADLESS_READY", false)
            && v.value.and_then(|x| x.as_bool()).unwrap_or(false)
        {
            return Ok(());
        }
        if let Ok(v) = tab.evaluate("window.HEADLESS_ERROR", false)
            && let Some(msg) = v.value.and_then(|x| x.as_str().map(|s| s.to_string()))
        {
            tracing::error!(session_id=%session_id, stage="hydration", error=%msg, "Headless client error");
            return Err(format!("Headless Client Error: {}", msg));
        }
        std::thread::sleep(Duration::from_millis(500));
    }
}
