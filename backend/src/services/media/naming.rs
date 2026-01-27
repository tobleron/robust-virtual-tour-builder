/* backend/src/services/media/naming.rs */

use once_cell::sync::Lazy;
use regex::Regex;

static FILENAME_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"_(\d{6})_\d{2}_(\d{3})").expect("Invalid regex pattern in source code")
});

/// Extracts a suggested human-readable name from a camera-generated filename.
pub fn get_suggested_name(original: &str) -> String {
    let base_name = std::path::Path::new(original)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or(original);

    if let Some(caps) = FILENAME_REGEX.captures(base_name) && caps.len() >= 3 {
        return format!("{}_{}", &caps[1], &caps[2]);
    }

    base_name.to_string()
}
