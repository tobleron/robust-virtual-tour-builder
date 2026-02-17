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
  <title>Virtual Tour</title>
  <style>
    :root { color-scheme: dark; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif; }
    body { margin: 0; min-height: 100vh; background: radial-gradient(1200px 600px at 10% 10%, rgba(30,64,175,0.18), transparent), radial-gradient(1200px 600px at 90% 90%, rgba(22,78,99,0.18), transparent), #0b1220; color: #e5e7eb; display: grid; place-items: center; }
    .wrap { width: min(980px, 92vw); background: rgba(16,26,47,0.86); border: 1px solid #24304a; border-radius: 18px; padding: 28px; backdrop-filter: blur(6px); }
    h1 { margin: 0 0 10px; font-size: 1.65rem; }
    p { margin: 0 0 20px; line-height: 1.5; color: #cbd5e1; }
    .grid { display: grid; gap: 14px; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); }
    a { display: block; text-decoration: none; background: #162544; border: 1px solid #33486b; border-radius: 12px; padding: 16px 18px; color: #f8fafc; font-weight: 700; transition: transform .2s ease, border-color .2s ease, background .2s ease; }
    a:hover { transform: translateY(-2px); border-color: #f97316; background: #1a2f55; }
    a span { display: block; margin-top: 6px; color: #93c5fd; font-weight: 500; font-size: 0.92rem; }
  </style>
</head>
<body>
  <main class="wrap">
    <h1>Choose Tour Resolution</h1>
    <p>Select the resolution you want to open.</p>
    <div class="grid">
      <a href="standalone/tour_4k/index.html">Open 4K Tour<span>Best quality for large displays.</span></a>
      <a href="standalone/tour_2k/index.html">Open 2K Tour<span>Balanced quality for desktop/laptop.</span></a>
      <a href="standalone/tour_hd/index.html">Open HD Tour<span>Lightweight option for mobile or slower devices.</span></a>
    </div>
  </main>
</body>
</html>"#,
    )
}

fn create_web_only_deployment_readme() -> String {
    String::from(
        r#"WEB-ONLY DEPLOYMENT INSTRUCTIONS

This folder is intended for website hosting (HTTP/HTTPS), not direct file:// opening.

Required upload structure (same parent directory level):
- web_only/
- assets/
- libs/

Embed URLs:
- web_only/tour_4k/index.html
- web_only/tour_2k/index.html
- web_only/tour_hd/index.html

Example iframe:
<iframe src="/virtual-tour/web_only/tour_4k/index.html" width="100%" height="640" style="border:none" title="360 Virtual Tour"></iframe>

Checklist:
1) Upload web_only, assets, and libs together.
2) Keep folder structure unchanged.
3) Serve from HTTP/HTTPS (not file://).
4) Ensure static serving allows .webp, .js, and .css files.
"#,
    )
}

fn rewrite_html_with_shared_assets(web_html: &str, resolution_key: &str) -> String {
    let prefix = format!("../../assets/images/{}/", resolution_key);
    web_html.replace("assets/images/", &prefix)
}

fn build_standalone_html_with_data_uris(web_html: &str, assets: &[(String, Vec<u8>)]) -> String {
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

        // 2. Add shared root logo asset
        if let Some((name, logo_path)) = image_files
            .iter()
            .find(|(name, _)| name.starts_with("logo."))
        {
            let logo_bytes = std::fs::read(logo_path).map_err(|e| e.to_string())?;
            write_zip_file(
                &mut zip,
                options,
                &format!("assets/logo/{}", name),
                &logo_bytes,
            )?;
        }

        // 3. Add shared root libraries
        let lib_files = ["pannellum.js", "pannellum.css"];
        for lib in lib_files {
            if let Some((_, lib_path)) = image_files.iter().find(|(name, _)| name == lib) {
                let lib_bytes = std::fs::read(lib_path).map_err(|e| e.to_string())?;
                write_zip_file(&mut zip, options, &format!("libs/{}", lib), &lib_bytes)?;
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

        // 5. Write shared root scene images for both variants
        for (resolution_key, _, _) in TARGETS {
            if let Some(artifacts) = artifacts_by_resolution.get(resolution_key) {
                for (file_name, data) in artifacts {
                    write_zip_file(
                        &mut zip,
                        options,
                        &format!("assets/images/{}/{}", resolution_key, file_name),
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
                let web_only_html = rewrite_html_with_shared_assets(web_html, resolution_key);
                write_zip_file(
                    &mut zip,
                    options,
                    &format!("web_only/{}/index.html", folder),
                    web_only_html.as_bytes(),
                )?;

                let standalone_html = match artifacts_by_resolution.get(resolution_key) {
                    Some(artifacts) => build_standalone_html_with_data_uris(web_html, artifacts),
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
        let deploy_readme = create_web_only_deployment_readme();
        write_zip_file(
            &mut zip,
            options,
            "web_only/DEPLOYMENT_README.txt",
            deploy_readme.as_bytes(),
        )?;

        zip.finish().map_err(|e| e.to_string())?;
    }

    // Cleanup temp files
    for (_, path) in image_files {
        let _ = std::fs::remove_file(path);
    }

    Ok(())
}
