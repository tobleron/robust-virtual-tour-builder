// @efficiency: service-orchestrator
use crate::services::media;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64_STANDARD};
use rayon::prelude::*;
use std::collections::HashMap;
use std::io::{Cursor, Write};
use zip::ZipWriter;
use zip::write::FileOptions;

const WEBP_QUALITY: f32 = 92.0;
const REQUIRED_SCENE_POLICY: &str = "browser-webp92-v1";
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
    // Preserve aspect ratio and avoid upscaling beyond source dimensions.
    if src_w <= max_width {
        return (src_w, src_h);
    }

    let scale = max_width as f64 / src_w as f64;
    let out_h = ((src_h as f64) * scale).round().max(1.0) as u32;
    (max_width, out_h)
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

fn require_scene_policy(fields: &HashMap<String, String>) -> Result<(), String> {
    let provided = fields
        .get("scene_policy")
        .map(|v| v.trim())
        .unwrap_or_default();

    if provided != REQUIRED_SCENE_POLICY {
        return Err(format!(
            "Rejected export payload: invalid scene policy (expected '{}', got '{}')",
            REQUIRED_SCENE_POLICY, provided
        ));
    }

    Ok(())
}

fn create_root_index() -> String {
    String::from(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Virtual Tour Package</title>
  <style>
    :root { color-scheme: dark; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif; }
    body { margin: 0; min-height: 100vh; background: radial-gradient(1200px 600px at 10% 10%, rgba(30,64,175,0.18), transparent), radial-gradient(1200px 600px at 90% 90%, rgba(22,78,99,0.18), transparent), #0b1220; color: #e5e7eb; display: grid; place-items: center; }
    .wrap { width: min(980px, 92vw); background: rgba(16,26,47,0.86); border: 1px solid #24304a; border-radius: 18px; padding: 28px; backdrop-filter: blur(6px); }
    h1 { margin: 0 0 10px; font-size: 1.65rem; }
    p { margin: 0 0 20px; line-height: 1.5; color: #cbd5e1; }
    .grid { display: grid; gap: 14px; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); }
    a { display: block; text-decoration: none; background: #162544; border: 1px solid #33486b; border-radius: 12px; padding: 16px 18px; color: #f8fafc; font-weight: 700; transition: transform .2s ease, border-color .2s ease, background .2s ease; }
    a:hover { transform: translateY(-2px); border-color: #f97316; background: #1a2f55; }
    a span { display: block; margin-top: 6px; color: #93c5fd; font-weight: 500; font-size: 0.92rem; }
  </style>
</head>
<body>
  <main class="wrap">
    <h1>Virtual Tour Export</h1>
    <p>Choose the package mode for your distribution target.</p>
    <div class="grid">
      <a href="web_only/index.html">Open Web Package<span>4K, 2K, and HD tours for website integration over HTTP/HTTPS.</span></a>
      <a href="desktop/index.html">Open Desktop Package<span>Single 2K standalone HTML with embedded scene blobs for direct local opening.</span></a>
    </div>
  </main>
</body>
</html>"#,
    )
}

fn create_web_only_deployment_readme() -> String {
    String::from(
        r#"WEB-ONLY DEPLOYMENT INSTRUCTIONS

This folder is designed for website hosting over HTTP/HTTPS.

Upload this folder exactly as-is:
- web_only/
  - assets/
  - libs/
  - tour_4k/
  - tour_2k/
  - tour_hd/

Primary entry:
- web_only/index.html

Embed URLs:
- web_only/tour_4k/index.html
- web_only/tour_2k/index.html
- web_only/tour_hd/index.html

Example iframe:
<iframe src="/virtual-tour/web_only/tour_4k/index.html" width="100%" height="640" style="border:none" title="360 Virtual Tour"></iframe>

Notes:
1) Keep folder structure unchanged.
2) Keep web_only/libs unless you intentionally rewrite script/style paths to a shared site library.
3) Serve through HTTP/HTTPS (not file://).
4) Ensure your static host serves .webp, .js, and .css.
"#,
    )
}

fn create_desktop_readme() -> String {
    String::from(
        r#"DESKTOP PACKAGE - QUICK GUIDE

Entry file:
- desktop/index.html

Behavior:
- Uses 2K scenes only.
- Scenes are embedded as data URIs in one HTML file (blob-style standalone).
- Opens directly from extracted files (file:// supported).

Notes:
1) Keep desktop/libs beside desktop/index.html.
2) No local webserver is required for desktop mode.
"#,
    )
}

fn rewrite_tour_html_for_subfolder(web_html: &str, resolution_key: &str) -> String {
    let image_prefix = format!("../assets/images/{}/", resolution_key);
    let image_placeholder = "__EXPORT_IMAGE_PREFIX__";

    web_html
        .replace("../../libs/pannellum.css", "../libs/pannellum.css")
        .replace("../../libs/pannellum.js", "../libs/pannellum.js")
        .replace("../../assets/logo/", "../assets/logo/")
        .replace("../../assets/images/", image_placeholder)
        .replace("assets/images/", image_placeholder)
        .replace(image_placeholder, &image_prefix)
}

fn rewrite_web_only_index_html(index_html: &str) -> String {
    index_html.replace("../assets/logo/", "assets/logo/")
}

fn infer_mime_from_filename(file_name: &str) -> &'static str {
    let lower = file_name.to_lowercase();
    if lower.ends_with(".png") {
        "image/png"
    } else if lower.ends_with(".jpg") || lower.ends_with(".jpeg") {
        "image/jpeg"
    } else if lower.ends_with(".svg") {
        "image/svg+xml"
    } else {
        "image/webp"
    }
}

fn data_uri_for_bytes(mime: &str, bytes: &[u8]) -> String {
    format!("data:{};base64,{}", mime, BASE64_STANDARD.encode(bytes))
}

fn build_desktop_blob_html(
    desktop_html: &str,
    assets_2k: &[(String, Vec<u8>)],
    logo_asset: Option<&(String, Vec<u8>)>,
) -> String {
    let mut html = desktop_html
        .replace("../../libs/pannellum.css", "./libs/pannellum.css")
        .replace("../../libs/pannellum.js", "./libs/pannellum.js");

    if let Some((logo_name, logo_bytes)) = logo_asset {
        let logo_path = format!("../../assets/logo/{}", logo_name);
        let logo_data_uri = data_uri_for_bytes(infer_mime_from_filename(logo_name), logo_bytes);
        html = html.replace(&logo_path, &logo_data_uri);
    }

    let mut replacements: Vec<(String, String)> = assets_2k
        .iter()
        .map(|(file_name, bytes)| {
            (
                format!("assets/images/{}", file_name),
                data_uri_for_bytes("image/webp", bytes),
            )
        })
        .collect();

    replacements.sort_by(|(path_a, _), (path_b, _)| path_b.len().cmp(&path_a.len()));

    for (path, data_uri) in replacements {
        html = html.replace(&path, &data_uri);
    }

    html
}

/// Creates a production-ready tour package ZIP.
pub fn create_tour_package(
    image_files: Vec<(String, std::path::PathBuf)>,
    fields: HashMap<String, String>,
    output_zip_path: std::path::PathBuf,
) -> Result<(), String> {
    {
        require_scene_policy(&fields)?;

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

        // 6) Write indexes, docs, and embeds.
        if let Some(index_html) = fields.get("html_index") {
            let web_only_index = rewrite_web_only_index_html(index_html);
            write_zip_file(
                &mut zip,
                options,
                "web_only/index.html",
                web_only_index.as_bytes(),
            )?;
        }

        write_zip_file(
            &mut zip,
            options,
            "web_only/DEPLOYMENT_README.txt",
            create_web_only_deployment_readme().as_bytes(),
        )?;
        write_zip_file(
            &mut zip,
            options,
            "desktop/README.txt",
            create_desktop_readme().as_bytes(),
        )?;

        if let Some(embed) = fields.get("embed_codes") {
            write_zip_file(
                &mut zip,
                options,
                "web_only/embed_codes.txt",
                embed.as_bytes(),
            )?;
        }

        let desktop_embed = "DESKTOP PACKAGE\n\nOpen:\ndesktop/index.html\n";
        write_zip_file(
            &mut zip,
            options,
            "desktop/embed_codes.txt",
            desktop_embed.as_bytes(),
        )?;

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
