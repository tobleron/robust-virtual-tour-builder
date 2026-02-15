// @efficiency: service-orchestrator
use crate::services::media;
use rayon::prelude::*;
use std::collections::HashMap;
use std::io::{Cursor, Write};
use zip::write::FileOptions;

const WEBP_QUALITY: f32 = 92.0;

type ProcessedResult = Result<Vec<(String, Vec<u8>)>, String>;

/// Creates a production-ready tour package ZIP.
///
/// This function performs the heavy lifting for tour export:
/// 1. Resizes all uploaded panoramas into 4K, 2K, and HD WebP versions.
/// 2. Injects the appropriate HTML templates for each resolution.
/// 3. Bundles external dependencies (Pannellum) and branding assets.
///
/// # Arguments
/// * `image_files` - A vector of (filename, path) for the tour assets.
/// * `fields` - A map containing HTML templates and other metadata.
/// * `output_zip_path` - The path where the generated ZIP should be saved.
///
/// # Returns
/// Success or a String error.
pub fn create_tour_package(
    image_files: Vec<(String, std::path::PathBuf)>,
    fields: HashMap<String, String>,
    output_zip_path: std::path::PathBuf,
) -> Result<(), String> {
    {
        let file = std::fs::File::create(&output_zip_path).map_err(|e| e.to_string())?;
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);

        // 1. Add Static Assets (Logo)
        if let Some((name, logo_path)) = image_files
            .iter()
            .find(|(name, _)| name.starts_with("logo."))
        {
            let logo_bytes = std::fs::read(logo_path).map_err(|e| e.to_string())?;
            for folder in &["tour_4k", "tour_2k", "tour_hd"] {
                zip.start_file(format!("{}/assets/{}", folder, name), options)
                    .map_err(|e| e.to_string())?;
                zip.write_all(&logo_bytes).map_err(|e| e.to_string())?;
            }
        }

        // 2. Add Libraries
        let lib_files = ["pannellum.js", "pannellum.css"];
        for lib in lib_files {
            if let Some((_, lib_path)) = image_files.iter().find(|(name, _)| name == lib) {
                let lib_bytes = std::fs::read(lib_path).map_err(|e| e.to_string())?;
                for folder in &["tour_4k", "tour_2k", "tour_hd"] {
                    zip.start_file(format!("{}/libs/{}", folder, lib), options)
                        .map_err(|e| e.to_string())?;
                    zip.write_all(&lib_bytes).map_err(|e| e.to_string())?;
                }
            }
        }

        // 3. Add HTML Templates
        if let Some(html) = fields.get("html_4k") {
            zip.start_file("tour_4k/index.html", options)
                .map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(html) = fields.get("html_2k") {
            zip.start_file("tour_2k/index.html", options)
                .map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(html) = fields.get("html_hd") {
            zip.start_file("tour_hd/index.html", options)
                .map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(html) = fields.get("html_index") {
            zip.start_file("index.html", options)
                .map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(embed) = fields.get("embed_codes") {
            zip.start_file("embed_codes.txt", options)
                .map_err(|e| e.to_string())?;
            zip.write_all(embed.as_bytes()).map_err(|e| e.to_string())?;
        }

        // 4. Process Scenes (Resize)
        let scene_files: Vec<_> = image_files
            .iter()
            .filter(|(name, _)| !name.starts_with("logo.") && !lib_files.contains(&name.as_str()))
            .collect();

        let processed_results: Vec<ProcessedResult> = scene_files
            .par_iter()
            .map(|(name, path)| -> Result<Vec<(String, Vec<u8>)>, String> {
                let bytes = std::fs::read(path).map_err(|e| e.to_string())?;
                let img = image::ImageReader::new(Cursor::new(bytes))
                    .with_guessed_format()
                    .map_err(|e| format!("Failed to guess format for {}: {}", name, e))?
                    .decode()
                    .map_err(|e| format!("Failed to decode {}: {}", name, e))?;

                let targets = [("tour_4k", 4096), ("tour_2k", 2048), ("tour_hd", 1280)];

                let mut artifacts = Vec::new();
                for (folder, width) in targets {
                    let resized = media::resize_fast(&img, width, width)
                        .map_err(|e| format!("Resize failed: {}", e))?;
                    let webp_name = std::path::Path::new(name).with_extension("webp");
                    let fname = webp_name
                        .file_name()
                        .ok_or("Invalid filename")?
                        .to_str()
                        .ok_or("Invalid filename")?;
                    let zip_path = format!("{}/assets/images/{}", folder, fname);

                    let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;

                    artifacts.push((zip_path, webp_bytes));
                }
                Ok(artifacts)
            })
            .collect();

        for result in processed_results {
            let artifacts = result?;
            for (zip_path, data) in artifacts {
                zip.start_file(zip_path, options)
                    .map_err(|e| e.to_string())?;
                zip.write_all(&data).map_err(|e| e.to_string())?;
            }
        }

        zip.finish().map_err(|e| e.to_string())?;
    }

    // Cleanup temp files
    for (_, path) in image_files {
        let _ = std::fs::remove_file(path);
    }

    Ok(())
}
