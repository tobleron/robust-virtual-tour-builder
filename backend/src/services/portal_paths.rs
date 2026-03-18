use std::path::{Path, PathBuf};

use crate::models::AppError;

const PORTAL_STORAGE_ROOT_DEFAULT: &str = "data/portal";

pub fn portal_storage_root() -> PathBuf {
    std::env::var("PORTAL_STORAGE_ROOT")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from(PORTAL_STORAGE_ROOT_DEFAULT))
}

pub fn portal_library_tour_dir(tour_slug: &str) -> Result<PathBuf, AppError> {
    Ok(portal_storage_root().join("tours").join(validate_slug(tour_slug)?))
}

pub fn validate_slug(raw: &str) -> Result<String, AppError> {
    let normalized = slugify(raw);
    if normalized.len() < 3 {
        return Err(AppError::ValidationError(
            "Slug must normalize to at least 3 characters.".into(),
        ));
    }
    Ok(normalized)
}

fn slugify(raw: &str) -> String {
    let lower = raw.trim().to_ascii_lowercase();
    let replaced = regex::Regex::new(r"[^a-z0-9]+")
        .ok()
        .map(|regex| regex.replace_all(&lower, "-").into_owned())
        .unwrap_or(lower);
    replaced.trim_matches('-').to_string()
}

pub fn should_keep_portal_relative_path(relative_path: &str) -> bool {
    relative_path == "index.html"
        || relative_path.starts_with("tour_4k/")
        || relative_path.starts_with("tour_2k/")
        || relative_path.starts_with("assets/")
        || relative_path.starts_with("libs/")
}

pub fn detect_portal_package_root(entry_names: &[String]) -> Result<String, AppError> {
    let mut preferred_root: Option<String> = None;
    let mut fallback_root: Option<String> = None;

    for entry_name in entry_names {
        if let Some(prefix) = entry_name.strip_suffix("tour_4k/index.html") {
            let normalized = prefix.to_string();
            if normalized.ends_with("web_only/") {
                preferred_root = Some(normalized.clone());
            }
            if fallback_root.is_none() {
                fallback_root = Some(normalized);
            }
        }
    }

    preferred_root.or(fallback_root).ok_or_else(|| {
        AppError::ValidationError(
            "Portal ZIP must include a valid web_only package with tour_4k/index.html and tour_2k/index.html.".into(),
        )
    })
}

pub fn sanitize_relative_path(relative_path: &str) -> Result<PathBuf, AppError> {
    if relative_path.trim().is_empty() {
        return Err(AppError::ValidationError(
            "Portal asset path is required.".into(),
        ));
    }

    let candidate = Path::new(relative_path);
    if candidate.is_absolute() {
        return Err(AppError::ValidationError(
            "Portal asset path must be relative.".into(),
        ));
    }

    let mut clean = PathBuf::new();
    for component in candidate.components() {
        match component {
            std::path::Component::Normal(part) => clean.push(part),
            _ => {
                return Err(AppError::ValidationError(
                    "Portal asset path contains unsupported segments.".into(),
                ));
            }
        }
    }

    Ok(clean)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slugify_normalizes_and_strips_noise() {
        assert_eq!(slugify("  ACME Tower  "), "acme-tower");
        assert_eq!(slugify("Unit # 19 / Showroom"), "unit-19-showroom");
    }

    #[test]
    fn sanitize_relative_path_blocks_parent_segments() {
        assert!(sanitize_relative_path("../tour_4k/index.html").is_err());
        assert!(sanitize_relative_path("/tmp/tour_4k/index.html").is_err());
        assert!(sanitize_relative_path("tour_4k/index.html").is_ok());
    }
}
