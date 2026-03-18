use crate::config::EfficiencyConfig;
use std::path::Path;

pub fn normalize_repo_relative_path(raw: &str) -> String {
    let normalized = raw
        .trim()
        .trim_matches('`')
        .trim_matches('"')
        .replace('\\', "/");
    let mut parts: Vec<String> = Vec::new();

    for part in normalized.split('/') {
        match part {
            "" | "." => continue,
            ".." => {
                if !parts.is_empty() {
                    parts.pop();
                }
            }
            value => parts.push(value.to_string()),
        }
    }

    let collapsed = parts.join("/");
    for root in ["backend/src/", "src/", "css/"] {
        if let Some(index) = collapsed.rfind(root) {
            return collapsed[index..].to_string();
        }
    }

    collapsed
}

pub fn canonicalize_tracked_file_path(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty()
        || trimmed.contains('\n')
        || trimmed.contains('\r')
        || trimmed.contains(' ')
    {
        return None;
    }

    let normalized = normalize_repo_relative_path(trimmed);
    if normalized.is_empty() {
        return None;
    }

    let path = Path::new(&normalized);
    let extension = path.extension().and_then(|value| value.to_str())?;
    if !matches!(extension, "rs" | "res" | "js" | "jsx" | "css" | "html") {
        return None;
    }
    path.file_name()?;
    Some(normalized)
}

pub fn get_drag_target(config: &EfficiencyConfig, path: &str) -> f64 {
    let ext = Path::new(path)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("");

    for profile in config.profiles.values() {
        if profile
            .extensions
            .iter()
            .any(|candidate| candidate.trim_start_matches('.') == ext)
        {
            if let Some(drag_target) = profile.drag_target {
                return drag_target;
            }
        }
    }

    config.settings.drag_target
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::EfficiencyConfig;

    fn config() -> EfficiencyConfig {
        EfficiencyConfig::load_from("../config/efficiency.json").expect("config should load")
    }

    #[test]
    fn canonicalize_tracked_file_path_normalizes_repo_relative_variants() {
        assert_eq!(
            canonicalize_tracked_file_path(
                "src/systems/Upload/../../src/systems/Upload/UploadProcessorUtils.res"
            ),
            Some("src/systems/Upload/UploadProcessorUtils.res".to_string())
        );
        assert_eq!(
            canonicalize_tracked_file_path(
                "../../backend/src/auth/../../backend/src/auth/middleware.rs"
            ),
            Some("backend/src/auth/middleware.rs".to_string())
        );
        assert_eq!(
            canonicalize_tracked_file_path(
                "Reference `src/core/SchemaDefinitions.res` for current shapes."
            ),
            None
        );
    }

    #[test]
    fn get_drag_target_uses_language_specific_thresholds() {
        let config = config();
        assert_eq!(get_drag_target(&config, "src/App.res"), 2.4);
        assert_eq!(get_drag_target(&config, "backend/src/main.rs"), 2.6);
        assert_eq!(get_drag_target(&config, "index.html"), 2.2);
    }
}
