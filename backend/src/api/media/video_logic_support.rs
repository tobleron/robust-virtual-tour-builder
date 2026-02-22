use headless_chrome::Tab;
use serde::Deserialize;
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
    pub motion_profile: HeadlessMotionProfile,
    pub motion_manifest: Option<MotionManifestV1>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HeadlessMotionProfile {
    pub skip_auto_forward: bool,
    pub start_at_waypoint: bool,
    pub include_intro_pan: bool,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MotionAnimationSegment {
    pub start_yaw: f64,
    pub end_yaw: f64,
    pub start_pitch: f64,
    pub end_pitch: f64,
    pub start_hfov: f64,
    pub end_hfov: f64,
    pub easing: String,
    pub duration_ms: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MotionTransitionOut {
    #[serde(rename = "type")]
    pub transition_type: String,
    pub duration_ms: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ArrivalPose {
    pub yaw: f64,
    pub pitch: f64,
    pub hfov: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MotionShot {
    pub scene_id: String,
    pub arrival_pose: ArrivalPose,
    pub animation_segments: Vec<MotionAnimationSegment>,
    pub transition_out: Option<MotionTransitionOut>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MotionManifestV1 {
    pub version: String,
    pub fps: u32,
    pub canvas_width: u32,
    pub canvas_height: u32,
    pub include_intro_pan: bool,
    pub shots: Vec<MotionShot>,
}

impl Default for HeadlessMotionProfile {
    fn default() -> Self {
        Self {
            skip_auto_forward: false,
            start_at_waypoint: true,
            include_intro_pan: false,
        }
    }
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
  const requestSessionId = control.sessionId || "";
  const backendOrigin = control.backendOrigin || "";
  const authToken = control.authToken;
  const motionProfile = control.motionProfile || {
    skipAutoForward: false,
    startAtWaypoint: true,
    includeIntroPan: false
  };
  window.__VTB_HEADLESS_MOTION_PROFILE__ = motionProfile;
  window.__VTB_MOTION_MANIFEST__ = control.motionManifest || null;
  if (authToken) {
    try {
      document.cookie = `auth_token=${authToken}; path=/; SameSite=Strict`;
      window.localStorage && window.localStorage.setItem("auth_token", authToken);
    } catch (_err) {}
  }
  if (!backendOrigin) {
    window.HEADLESS_ERROR = "Missing backend origin";
    return;
  }
  if (!projectSessionId && !requestSessionId && scenes.length > 0) {
    window.HEADLESS_ERROR = "Missing project/session id for resource hydration";
    return;
  }
  const unwrapFileRef = (value) => {
    if (typeof value === "string") return value.trim();
    if (value && typeof value === "object" && typeof value._0 === "string") {
      return value._0.trim();
    }
    return "";
  };
  const toAbsoluteUrl = (rawRef) => {
    const raw = unwrapFileRef(rawRef);
    if (!raw) return null;
    if (raw.startsWith("http://") || raw.startsWith("https://")) {
      try {
        const parsed = new URL(raw);
        // Normalize API assets to backend origin so headless capture stays deterministic.
        if (parsed.pathname && parsed.pathname.startsWith("/api/")) {
          return backendOrigin + parsed.pathname + (parsed.search || "");
        }
        return raw;
      } catch (_err) {
        return raw;
      }
    }
    if (raw.startsWith("/")) return backendOrigin + raw;
    if (raw.startsWith("api/")) return `${backendOrigin}/${raw}`;
    return null;
  };
  const buildFallbackUrl = (sessionId, sceneName) => {
    if (!sessionId || !sceneName) return null;
    return `${backendOrigin}/api/project/${encodeURIComponent(sessionId)}/file/${encodeURIComponent(sceneName)}`;
  };
  const buildUrlCandidates = (scene) => {
    const candidates = [];
    const addCandidate = (url) => {
      if (url && !candidates.includes(url)) candidates.push(url);
    };

    addCandidate(toAbsoluteUrl(scene.file));
    addCandidate(toAbsoluteUrl(scene.originalFile));
    addCandidate(toAbsoluteUrl(scene.tinyFile));

    const sceneName = unwrapFileRef(scene.name);
    if (!sceneName) return candidates;

    // Prefer request-scoped session (this request's uploaded files).
    addCandidate(buildFallbackUrl(requestSessionId, sceneName));
    // Keep project session as secondary fallback for persisted URL projects.
    addCandidate(buildFallbackUrl(projectSessionId, sceneName));
    return candidates;
  };
  const fetchScene = async (scene) => {
    const candidates = buildUrlCandidates(scene);
    if (candidates.length === 0) {
      throw new Error(`No hydration URL candidates for ${scene && scene.name ? scene.name : "unknown scene"}`);
    }
    const headers = {};
    if (authToken) {
      headers.Authorization = "Bearer " + authToken;
    }

    let response = null;
    let lastError = "";
    for (const url of candidates) {
      try {
        const res = await fetch(url, { headers });
        if (res.ok) {
          response = res;
          break;
        }
        lastError = `status ${res.status} @ ${url}`;
      } catch (err) {
        lastError = (err && err.message) ? err.message : String(err);
      }
    }

    if (!response) {
      throw new Error(`Hydration fetch failed for ${scene.name}: ${lastError}`);
    }
    const blob = await response.blob();
    const file = new File([blob], scene.name, { type: "image/webp" });
    scene.file = file;
    scene.originalFile = file;
    scene.tinyFile = file;
  };
  const loadProject = typeof window.__VTB_LOAD_PROJECT__ === "function"
    ? window.__VTB_LOAD_PROJECT__
    : (window.store && typeof window.store.loadProject === "function" ? window.store.loadProject : null);
  if (!loadProject) {
    window.HEADLESS_ERROR = "Missing headless project loader";
    return;
  }

  (async () => {
    await Promise.all(scenes.map(fetchScene));
    await loadProject(project);
    // Give React + viewer lifecycle a short settle window before teaser starts.
    await new Promise(resolve => setTimeout(resolve, 700));
    window.HEADLESS_READY = true;
  })().catch((err) => {
    window.HEADLESS_ERROR = (err && err.message) || err.toString();
  });
})();
"#;

pub fn headless_backend_origin() -> String {
    env::var("BACKEND_ORIGIN").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

pub fn headless_app_origin() -> String {
    if let Ok(origin) = env::var("HEADLESS_APP_ORIGIN") {
        return origin;
    }
    if cfg!(debug_assertions) {
        "http://localhost:3000".to_string()
    } else {
        headless_backend_origin()
    }
}

pub fn get_ffmpeg_command() -> Result<String, String> {
    if let Ok(custom_path) = env::var("FFMPEG_PATH")
        && !custom_path.trim().is_empty()
    {
        return Ok(custom_path);
    }

    // Prefer system ffmpeg first; local bundled binaries can drift or have missing dylib deps.
    if let Ok(output) = std::process::Command::new("ffmpeg")
        .arg("-version")
        .output()
        && output.status.success()
    {
        return Ok("ffmpeg".to_string());
    }

    let local_ffmpeg = PathBuf::from("./bin/ffmpeg");
    if local_ffmpeg.exists() {
        local_ffmpeg
            .to_str()
            .ok_or_else(|| "Invalid ffmpeg path encoding".to_string())
            .map(|s| s.to_string())
    } else {
        Err("ffmpeg not found. Install ffmpeg or set FFMPEG_PATH.".to_string())
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
