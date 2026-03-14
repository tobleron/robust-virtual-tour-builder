// @efficiency-role: service-orchestrator
#[path = "package_assets.rs"]
mod package_assets;
#[path = "package_output.rs"]
mod package_output;

use std::collections::HashMap;
use zip::ZipWriter;
use zip::write::FileOptions;

use crate::services::project::package_utils;

const WEBP_QUALITY: f32 = 80.0;
const MAX_EXPORT_SOURCE_WIDTH: u32 = 4096;
const MAX_EXPORT_SOURCE_HEIGHT: u32 = 4096;
const TARGETS: [(&str, &str, u32); 3] = [
    ("4k", "tour_4k", 4096),
    ("2k", "tour_2k", 2048),
    ("hd", "tour_hd", 1280),
];

type ProcessedResult = Result<Vec<ResolutionArtifact>, String>;

#[derive(Debug)]
struct ResolutionArtifact {
    resolution_key: &'static str,
    file_name: String,
    data: Vec<u8>,
}

fn target_dimensions(src_w: u32, src_h: u32, max_width: u32) -> (u32, u32) {
    package_utils::target_dimensions(src_w, src_h, max_width)
}

fn write_zip_file(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    path: &str,
    data: &[u8],
) -> Result<(), String> {
    package_utils::write_zip_file(zip, options, path, data)
}

fn create_root_index(
    include_web_only: bool,
    include_desktop: bool,
    include_desktop_landscape_touch_hd: bool,
    include_desktop_landscape_touch_2k: bool,
    include_desktop_landscape_touch_4k: bool,
) -> String {
    package_utils::create_root_index(
        include_web_only,
        include_desktop,
        include_desktop_landscape_touch_hd,
        include_desktop_landscape_touch_2k,
        include_desktop_landscape_touch_4k,
    )
}

fn create_web_only_deployment_readme() -> String {
    package_utils::create_web_only_deployment_readme()
}

fn create_desktop_readme() -> String {
    package_utils::create_desktop_readme()
}

fn create_desktop_landscape_touch_readme(folder_name: &str, resolution_label: &str) -> String {
    package_utils::create_desktop_landscape_touch_readme(folder_name, resolution_label)
}

fn rewrite_tour_html_for_subfolder(web_html: &str, resolution_key: &str) -> String {
    package_utils::rewrite_tour_html_for_subfolder(web_html, resolution_key)
}

fn rewrite_web_only_index_html(index_html: &str) -> String {
    package_utils::rewrite_web_only_index_html(index_html)
}

fn build_desktop_blob_html(
    desktop_html: &str,
    assets_2k: &[(String, Vec<u8>)],
    logo_asset: Option<&(String, Vec<u8>)>,
) -> String {
    package_utils::build_desktop_blob_html(desktop_html, assets_2k, logo_asset)
}

/// Creates a production-ready tour package ZIP.
pub fn create_tour_package(
    image_files: Vec<(String, std::path::PathBuf)>,
    fields: HashMap<String, String>,
    output_zip_path: std::path::PathBuf,
) -> Result<(), String> {
    {
        let selected_profiles = package_assets::selected_profiles(&fields);
        let package_assets = package_assets::collect_package_assets(&image_files)?;

        let file = std::fs::File::create(&output_zip_path).map_err(|e| e.to_string())?;
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);

        package_output::write_root_launcher(&mut zip, options, &selected_profiles)?;
        package_output::write_shared_assets(
            &mut zip,
            options,
            &selected_profiles,
            &package_assets,
        )?;
        package_output::write_image_assets(
            &mut zip,
            options,
            &selected_profiles,
            &package_assets.artifacts_by_resolution,
        )?;
        package_output::write_tour_htmls(&mut zip, options, &fields, &selected_profiles)?;
        package_output::write_supporting_files(
            &mut zip,
            options,
            &fields,
            &selected_profiles,
            &package_assets,
        )?;
        package_output::write_project_metadata(&mut zip, options, &fields)?;
        zip.finish().map_err(|e| e.to_string())?;
    }

    // Cleanup temp files.
    for (_, path) in image_files {
        let _ = std::fs::remove_file(path);
    }

    Ok(())
}
