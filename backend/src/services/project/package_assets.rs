// @efficiency-role: service-orchestrator
use rayon::prelude::*;
use std::collections::{HashMap, HashSet};
use std::io::Cursor;
use std::path::PathBuf;

use super::{
    MAX_EXPORT_SOURCE_HEIGHT, MAX_EXPORT_SOURCE_WIDTH, ProcessedResult, ResolutionArtifact,
    TARGETS, WEBP_QUALITY,
};
use crate::services::media;

const LIB_FILES: [&str; 2] = ["pannellum.js", "pannellum.css"];

pub(super) struct SelectedProfiles {
    pub(super) include_4k: bool,
    pub(super) include_2k: bool,
    pub(super) include_hd: bool,
    pub(super) include_desktop_blob_2k: bool,
}

pub(super) struct PreparedPackageAssets {
    pub(super) logo_asset: Option<(String, Vec<u8>)>,
    pub(super) lib_assets: HashMap<String, Vec<u8>>,
    pub(super) artifacts_by_resolution: HashMap<&'static str, Vec<(String, Vec<u8>)>>,
}

pub(super) fn selected_profiles(fields: &HashMap<String, String>) -> SelectedProfiles {
    let profile_csv = fields
        .get("publish_profiles")
        .map(String::as_str)
        .unwrap_or("");
    let mut selected_profiles: HashSet<String> = profile_csv
        .split(',')
        .map(|profile| profile.trim().to_lowercase())
        .filter(|profile| !profile.is_empty())
        .collect();

    if selected_profiles.is_empty() {
        selected_profiles.extend([
            "4k".to_string(),
            "2k".to_string(),
            "hd".to_string(),
            "desktop_blob_2k".to_string(),
        ]);
    }

    SelectedProfiles {
        include_4k: selected_profiles.contains("4k"),
        include_2k: selected_profiles.contains("2k"),
        include_hd: selected_profiles.contains("hd"),
        include_desktop_blob_2k: selected_profiles.contains("desktop_blob_2k"),
    }
}

pub(super) fn collect_package_assets(
    image_files: &[(String, PathBuf)],
) -> Result<PreparedPackageAssets, String> {
    Ok(PreparedPackageAssets {
        logo_asset: load_logo_asset(image_files)?,
        lib_assets: load_lib_assets(image_files)?,
        artifacts_by_resolution: build_artifacts_by_resolution(processed_scene_results(
            image_files,
        )?)?,
    })
}

fn load_logo_asset(image_files: &[(String, PathBuf)]) -> Result<Option<(String, Vec<u8>)>, String> {
    image_files
        .iter()
        .find(|(name, _)| name.starts_with("logo."))
        .map(|(name, path)| {
            let bytes = std::fs::read(path).map_err(|e| e.to_string())?;
            Ok((name.clone(), bytes))
        })
        .transpose()
}

fn load_lib_assets(image_files: &[(String, PathBuf)]) -> Result<HashMap<String, Vec<u8>>, String> {
    let mut lib_assets = HashMap::new();
    for lib_name in LIB_FILES {
        if let Some((_, path)) = image_files.iter().find(|(name, _)| name == lib_name) {
            let bytes = std::fs::read(path).map_err(|e| e.to_string())?;
            lib_assets.insert(lib_name.to_string(), bytes);
        }
    }
    Ok(lib_assets)
}

fn processed_scene_results(
    image_files: &[(String, PathBuf)],
) -> Result<Vec<ProcessedResult>, String> {
    let scene_files: Vec<_> = image_files
        .iter()
        .filter(|(name, _)| !name.starts_with("logo.") && !LIB_FILES.contains(&name.as_str()))
        .collect();

    Ok(scene_files
        .par_iter()
        .map(|(name, path)| process_scene_file(name, path))
        .collect())
}

fn process_scene_file(name: &str, path: &PathBuf) -> ProcessedResult {
    let source_bytes = std::fs::read(path).map_err(|e| e.to_string())?;
    let reader = image::ImageReader::new(Cursor::new(source_bytes.as_slice()))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess format for {}: {}", name, e))?;

    if !matches!(reader.format(), Some(image::ImageFormat::WebP)) {
        return Err(format!(
            "Rejected export payload: scene '{}' is not WebP; export requires browser-normalized WebP inputs",
            name
        ));
    }

    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode {}: {}", name, e))?;
    let src_w = img.width();
    let src_h = img.height();

    if src_w > MAX_EXPORT_SOURCE_WIDTH || src_h > MAX_EXPORT_SOURCE_HEIGHT {
        return Err(format!(
            "Rejected export payload: scene '{}' exceeds max dimensions ({}x{} > {}x{})",
            name, src_w, src_h, MAX_EXPORT_SOURCE_WIDTH, MAX_EXPORT_SOURCE_HEIGHT
        ));
    }

    let mut artifacts = Vec::new();
    for (resolution_key, _, width) in TARGETS {
        let (target_w, target_h) = super::target_dimensions(src_w, src_h, width);
        let is_source_dimensions = target_w == src_w && target_h == src_h;
        let webp_name = std::path::Path::new(name).with_extension("webp");
        let file_name = webp_name
            .file_name()
            .ok_or("Invalid filename")?
            .to_str()
            .ok_or("Invalid filename")?;

        let webp_bytes = if is_source_dimensions {
            source_bytes.clone()
        } else {
            let resized = media::resize_fast(&img, target_w, target_h)
                .map_err(|e| format!("Resize failed: {}", e))?;
            media::encode_webp(&resized, WEBP_QUALITY)?
        };

        artifacts.push(ResolutionArtifact {
            resolution_key,
            file_name: file_name.to_string(),
            data: webp_bytes,
        });
    }

    Ok(artifacts)
}

fn build_artifacts_by_resolution(
    processed_results: Vec<ProcessedResult>,
) -> Result<HashMap<&'static str, Vec<(String, Vec<u8>)>>, String> {
    let mut artifacts_by_resolution: HashMap<&'static str, Vec<(String, Vec<u8>)>> =
        HashMap::from([("4k", Vec::new()), ("2k", Vec::new()), ("hd", Vec::new())]);

    for result in processed_results {
        let artifacts = result?;
        for artifact in artifacts {
            let bucket = artifacts_by_resolution
                .get_mut(artifact.resolution_key)
                .ok_or_else(|| {
                    format!(
                        "Unexpected resolution key during export: {}",
                        artifact.resolution_key
                    )
                })?;
            bucket.push((artifact.file_name, artifact.data));
        }
    }

    Ok(artifacts_by_resolution)
}
