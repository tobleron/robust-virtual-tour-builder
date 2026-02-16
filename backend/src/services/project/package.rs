// @efficiency: service-orchestrator
use crate::services::media;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64_STANDARD};
use rayon::prelude::*;
use std::collections::HashMap;
use std::io::{Cursor, Write};
use zip::ZipWriter;
use zip::write::FileOptions;

const WEBP_QUALITY: f32 = 92.0;
const VARIANTS: [&str; 2] = ["web_only", "standalone"];
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

fn write_zip_file(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    path: &str,
    data: &[u8],
) -> Result<(), String> {
    zip.start_file(path, options).map_err(|e| e.to_string())?;
    zip.write_all(data).map_err(|e| e.to_string())?;
    Ok(())
}

fn create_root_index() -> String {
    String::from(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Virtual Tour Export Package</title>
  <style>
    :root { color-scheme: dark; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif; }
    body { margin: 0; min-height: 100vh; background: #0b1220; color: #e5e7eb; display: grid; place-items: center; }
    .wrap { width: min(760px, 92vw); background: #101a2f; border: 1px solid #24304a; border-radius: 16px; padding: 28px; }
    h1 { margin: 0 0 10px; font-size: 1.5rem; }
    p { margin: 0 0 20px; line-height: 1.5; color: #cbd5e1; }
    .grid { display: grid; gap: 12px; }
    a { display: block; text-decoration: none; background: #1a2a4a; border: 1px solid #33486b; border-radius: 12px; padding: 14px 16px; color: #f8fafc; font-weight: 600; }
    a span { display: block; margin-top: 4px; color: #93c5fd; font-weight: 400; font-size: 0.92rem; }
  </style>
</head>
<body>
  <main class="wrap">
    <h1>Virtual Tour Export</h1>
    <p>This package contains two complete outputs. Use <strong>web_only</strong> for hosting on a web server, or <strong>standalone</strong> to open directly from extracted files.</p>
    <div class="grid">
      <a href="web_only/index.html">Open Web-Only Package<span>For HTTP/HTTPS hosting and embedding.</span></a>
      <a href="standalone/index.html">Open Standalone Package<span>For direct local file opening after extraction.</span></a>
    </div>
  </main>
</body>
</html>"#,
    )
}

fn build_standalone_html(web_html: &str, assets: &[(String, Vec<u8>)]) -> String {
    let mut standalone_html = web_html.to_owned();
    let mut replacements: Vec<(String, String)> = assets
        .iter()
        .map(|(file_name, data)| {
            (
                format!("assets/images/{}", file_name),
                format!("data:image/webp;base64,{}", BASE64_STANDARD.encode(data)),
            )
        })
        .collect();
    replacements.sort_by(|(path_a, _), (path_b, _)| path_b.len().cmp(&path_a.len()));

    for (path, data_uri) in replacements {
        standalone_html = standalone_html.replace(&path, &data_uri);
    }
    standalone_html
}

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

        // 1. Root launcher
        let root_index = create_root_index();
        write_zip_file(&mut zip, options, "index.html", root_index.as_bytes())?;

        // 2. Add Static Assets (Logo)
        if let Some((name, logo_path)) = image_files
            .iter()
            .find(|(name, _)| name.starts_with("logo."))
        {
            let logo_bytes = std::fs::read(logo_path).map_err(|e| e.to_string())?;
            for variant in VARIANTS {
                for (_, folder, _) in TARGETS {
                    write_zip_file(
                        &mut zip,
                        options,
                        &format!("{}/{}/assets/{}", variant, folder, name),
                        &logo_bytes,
                    )?;
                }
            }
        }

        // 3. Add Libraries
        let lib_files = ["pannellum.js", "pannellum.css"];
        for lib in lib_files {
            if let Some((_, lib_path)) = image_files.iter().find(|(name, _)| name == lib) {
                let lib_bytes = std::fs::read(lib_path).map_err(|e| e.to_string())?;
                for variant in VARIANTS {
                    for (_, folder, _) in TARGETS {
                        write_zip_file(
                            &mut zip,
                            options,
                            &format!("{}/{}/libs/{}", variant, folder, lib),
                            &lib_bytes,
                        )?;
                    }
                }
            }
        }

        // 4. Process Scenes (Resize)
        let scene_files: Vec<_> = image_files
            .iter()
            .filter(|(name, _)| !name.starts_with("logo.") && !lib_files.contains(&name.as_str()))
            .collect();

        let processed_results: Vec<ProcessedResult> = scene_files
            .par_iter()
            .map(|(name, path)| -> Result<Vec<ResolutionArtifact>, String> {
                let bytes = std::fs::read(path).map_err(|e| e.to_string())?;
                let img = image::ImageReader::new(Cursor::new(bytes))
                    .with_guessed_format()
                    .map_err(|e| format!("Failed to guess format for {}: {}", name, e))?
                    .decode()
                    .map_err(|e| format!("Failed to decode {}: {}", name, e))?;

                let mut artifacts = Vec::new();
                for (resolution_key, _, width) in TARGETS {
                    let resized = media::resize_fast(&img, width, width)
                        .map_err(|e| format!("Resize failed: {}", e))?;
                    let webp_name = std::path::Path::new(name).with_extension("webp");
                    let fname = webp_name
                        .file_name()
                        .ok_or("Invalid filename")?
                        .to_str()
                        .ok_or("Invalid filename")?;

                    let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;

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

        // 5. Write web-only scene images
        for (resolution_key, folder, _) in TARGETS {
            if let Some(artifacts) = artifacts_by_resolution.get(resolution_key) {
                for (file_name, data) in artifacts {
                    write_zip_file(
                        &mut zip,
                        options,
                        &format!("web_only/{}/assets/images/{}", folder, file_name),
                        data,
                    )?;
                }
            }
        }

        // 6. Resolution HTML templates for both variants
        let html_targets = [
            ("html_4k", "4k", "tour_4k"),
            ("html_2k", "2k", "tour_2k"),
            ("html_hd", "hd", "tour_hd"),
        ];

        for (field_name, resolution_key, folder) in html_targets {
            if let Some(web_html) = fields.get(field_name) {
                write_zip_file(
                    &mut zip,
                    options,
                    &format!("web_only/{}/index.html", folder),
                    web_html.as_bytes(),
                )?;

                let standalone_html = match artifacts_by_resolution.get(resolution_key) {
                    Some(artifacts) => build_standalone_html(web_html, artifacts),
                    None => web_html.to_owned(),
                };
                write_zip_file(
                    &mut zip,
                    options,
                    &format!("standalone/{}/index.html", folder),
                    standalone_html.as_bytes(),
                )?;
            }
        }

        // 7. Variant index pages + embed codes
        if let Some(html) = fields.get("html_index") {
            for variant in VARIANTS {
                write_zip_file(
                    &mut zip,
                    options,
                    &format!("{}/index.html", variant),
                    html.as_bytes(),
                )?;
            }
        }
        if let Some(embed) = fields.get("embed_codes") {
            for variant in VARIANTS {
                write_zip_file(
                    &mut zip,
                    options,
                    &format!("{}/embed_codes.txt", variant),
                    embed.as_bytes(),
                )?;
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
