use crate::config::EfficiencyConfig;
use std::path::Path;

/// Get the effective drag target for a file based on its extension (language-specific)
pub fn get_drag_target(config: &EfficiencyConfig, path: &str) -> f64 {
    let ext = Path::new(path)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("");
    
    // Check for language-specific drag target
    for profile in &config.profiles {
        let extensions: Vec<&str> = profile.1.extensions.iter().map(|s: &String| s.as_str()).collect();
        if extensions.contains(&ext) {
            if let Some(drag_target) = profile.1.drag_target {
                return drag_target;
            }
        }
    }
    
    // Fall back to global default
    config.settings.drag_target
}
