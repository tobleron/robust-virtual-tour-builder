// @efficiency: service-orchestrator
use crate::services::media;
use rayon::prelude::*;
use std::collections::HashMap;
use std::io::Cursor;
use zip::ZipWriter;
use zip::write::FileOptions;

use crate::services::project::package_utils;
use std::collections::HashSet;

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

fn create_root_index() -> String {
    package_utils::create_root_index()
}

fn create_web_only_deployment_readme() -> String {
    package_utils::create_web_only_deployment_readme()
}

fn create_desktop_readme() -> String {
    package_utils::create_desktop_readme()
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
        let profile_csv = fields.get("publish_profiles").map(String::as_str).unwrap_or("");
        let mut selected_profiles: HashSet<String> = profile_csv
            .split(',')
            .map(|p| p.trim().to_lowercase())
            .filter(|p| !p.is_empty())
            .collect();
        if selected_profiles.is_empty() {
            selected_profiles.extend([
                "4k".to_string(),
                "2k".to_string(),
                "hd".to_string(),
                "desktop_blob_2k".to_string(),
            ]);
        }
        let include_4k = selected_profiles.contains("4k");
        let include_2k = selected_profiles.contains("2k");
        let include_hd = selected_profiles.contains("hd");
        let include_desktop_blob_2k = selected_profiles.contains("desktop_blob_2k");

        let file = std::fs::File::create(&output_zip_path).map_err(|e| e.to_string())?;
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);

        // 1) Root launcher
        write_zip_file(
            &mut zip,
            options,
            "index.html",
            create_root_index().as_bytes(),
        )?;

        // 2) Collect optional logo + required libs once, then fan out into package variants.
        let logo_asset: Option<(String, Vec<u8>)> = image_files
            .iter()
            .find(|(name, _)| name.starts_with("logo."))
            .map(|(name, path)| {
                let bytes = std::fs::read(path).map_err(|e| e.to_string())?;
                Ok::<(String, Vec<u8>), String>((name.clone(), bytes))
            })
            .transpose()?;

        let lib_files = ["pannellum.js", "pannellum.css"];
        let mut lib_assets: HashMap<&str, Vec<u8>> = HashMap::new();
        for lib in lib_files {
            if let Some((_, path)) = image_files.iter().find(|(name, _)| name == lib) {
                let bytes = std::fs::read(path).map_err(|e| e.to_string())?;
                lib_assets.insert(lib, bytes);
            }
        }

        if let Some((name, bytes)) = &logo_asset {
            write_zip_file(
                &mut zip,
                options,
                &format!("web_only/assets/logo/{}", name),
                bytes,
            )?;
        }

        for (lib_name, bytes) in &lib_assets {
            write_zip_file(
                &mut zip,
                options,
                &format!("web_only/libs/{}", lib_name),
                bytes,
            )?;
            write_zip_file(
                &mut zip,
                options,
                &format!("desktop/libs/{}", lib_name),
                bytes,
            )?;
        }

        // 3) Process source scenes.
        let scene_files: Vec<_> = image_files
            .iter()
            .filter(|(name, _)| !name.starts_with("logo.") && !lib_files.contains(&name.as_str()))
            .collect();

        let processed_results: Vec<ProcessedResult> = scene_files
            .par_iter()
            .map(|(name, path)| -> ProcessedResult {
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
                        name,
                        src_w,
                        src_h,
                        MAX_EXPORT_SOURCE_WIDTH,
                        MAX_EXPORT_SOURCE_HEIGHT
                    ));
                }

                let mut artifacts = Vec::new();
                for (resolution_key, _, width) in TARGETS {
                    let (target_w, target_h) = target_dimensions(src_w, src_h, width);
                    let is_source_dimensions = target_w == src_w && target_h == src_h;
                    let webp_name = std::path::Path::new(name).with_extension("webp");
                    let fname = webp_name
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
                        file_name: fname.to_string(),
                        data: webp_bytes,
                    });
                }
                Ok(artifacts)
            })
            .collect();

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

        // 4) Write image assets.
        for (resolution_key, _, _) in TARGETS {
            let should_include = match resolution_key {
                "4k" => include_4k,
                "2k" => include_2k || include_desktop_blob_2k,
                "hd" => include_hd,
                _ => false,
            };
            if !should_include {
                continue;
            }
            if let Some(artifacts) = artifacts_by_resolution.get(resolution_key) {
                for (file_name, data) in artifacts {
                    write_zip_file(
                        &mut zip,
                        options,
                        &format!("web_only/assets/images/{}/{}", resolution_key, file_name),
                        data,
                    )?;
                }
            }
        }

        // 5) Write tour HTMLs.
        let html_targets = [
            ("html_4k", "4k", "tour_4k"),
            ("html_2k", "2k", "tour_2k"),
            ("html_hd", "hd", "tour_hd"),
        ];
        for (field_name, resolution_key, folder) in html_targets {
            let should_include = match resolution_key {
                "4k" => include_4k,
                "2k" => include_2k,
                "hd" => include_hd,
                _ => false,
            };
            if !should_include {
                continue;
            }
            if let Some(web_html) = fields.get(field_name) {
                let web_only_html = rewrite_tour_html_for_subfolder(web_html, resolution_key);
                write_zip_file(
                    &mut zip,
                    options,
                    &format!("web_only/{}/index.html", folder),
                    web_only_html.as_bytes(),
                )?;
            }
        }

        if include_desktop_blob_2k {
            let desktop_template = fields
                .get("html_desktop_2k_blob")
                .or_else(|| fields.get("html_2k"))
                .ok_or_else(|| "Missing desktop 2k html template".to_string())?;
            let assets_2k = artifacts_by_resolution
                .get("2k")
                .ok_or_else(|| "Missing 2k assets for desktop package".to_string())?;
            let desktop_html =
                build_desktop_blob_html(desktop_template, assets_2k, logo_asset.as_ref());
            write_zip_file(
                &mut zip,
                options,
                "desktop/index.html",
                desktop_html.as_bytes(),
            )?;
        }

        // 6) Write indexes, docs, and embeds.
        if (include_4k || include_2k || include_hd) && fields.get("html_index").is_some() {
            let index_html = fields.get("html_index").expect("checked");
            let web_only_index = rewrite_web_only_index_html(index_html);
            write_zip_file(
                &mut zip,
                options,
                "web_only/index.html",
                web_only_index.as_bytes(),
            )?;
        }

        if include_4k || include_2k || include_hd {
            write_zip_file(
                &mut zip,
                options,
                "web_only/DEPLOYMENT_README.txt",
                create_web_only_deployment_readme().as_bytes(),
            )?;
        }
        if include_desktop_blob_2k {
            write_zip_file(
                &mut zip,
                options,
                "desktop/README.txt",
                create_desktop_readme().as_bytes(),
            )?;
        }

        if (include_4k || include_2k || include_hd) && fields.get("embed_codes").is_some() {
            let embed = fields.get("embed_codes").expect("checked");
            write_zip_file(
                &mut zip,
                options,
                "web_only/embed_codes.txt",
                embed.as_bytes(),
            )?;
        }

        if include_desktop_blob_2k {
            let desktop_embed = "DESKTOP PACKAGE\n\nOpen:\ndesktop/index.html\n";
            write_zip_file(
                &mut zip,
                options,
                "desktop/embed_codes.txt",
                desktop_embed.as_bytes(),
            )?;
        }

        // 7) Canonical project metadata for parity with .vt.zip saves.
        if let Some(project_data) = fields.get("project_data") {
            write_zip_file(
                &mut zip,
                options,
                "project_metadata.vt.json",
                project_data.as_bytes(),
            )?;
        }

        zip.finish().map_err(|e| e.to_string())?;
    }

    // Cleanup temp files.
    for (_, path) in image_files {
        let _ = std::fs::remove_file(path);
    }

    Ok(())
}
