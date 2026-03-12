use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64_STANDARD};
use std::io::Write;
use zip::ZipWriter;
use zip::write::FileOptions;

pub fn target_dimensions(src_w: u32, src_h: u32, max_width: u32) -> (u32, u32) {
    if src_w <= max_width {
        return (src_w, src_h);
    }

    let scale = max_width as f64 / src_w as f64;
    let out_h = ((src_h as f64) * scale).round().max(1.0) as u32;
    (max_width, out_h)
}

pub fn write_zip_file(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    path: &str,
    data: &[u8],
) -> Result<(), String> {
    zip.start_file(path, options).map_err(|e| e.to_string())?;
    zip.write_all(data).map_err(|e| e.to_string())?;
    Ok(())
}

pub fn create_root_index(
    include_web_only: bool,
    include_desktop: bool,
    include_desktop_landscape_touch_hd: bool,
    include_desktop_landscape_touch_2k: bool,
    include_desktop_landscape_touch_4k: bool,
) -> String {
    let mut cards = String::new();

    if include_web_only {
        cards.push_str(
            r#"<a href="web_only/index.html">Open Web Package<span>Adaptive 4K, 2K, and HD tours for website integration over HTTP/HTTPS.</span></a>"#,
        );
    }
    if include_desktop {
        cards.push_str(
            r#"<a href="desktop/index.html">Open Desktop Package<span>Single 2K standalone HTML with embedded scene blobs for direct local opening.</span></a>"#,
        );
    }
    if include_desktop_landscape_touch_hd {
        cards.push_str(
            r#"<a href="desktop_landscape_touch_hd/index.html">Open HD Landscape Touch Package<span>Single HD standalone HTML that forces the touch-friendly landscape UI for calibration.</span></a>"#,
        );
    }
    if include_desktop_landscape_touch_2k {
        cards.push_str(
            r#"<a href="desktop_landscape_touch/index.html">Open Landscape Touch Package<span>Single 2K standalone HTML that forces the touch-friendly landscape UI for calibration.</span></a>"#,
        );
    }
    if include_desktop_landscape_touch_4k {
        cards.push_str(
            r#"<a href="desktop_landscape_touch_4k/index.html">Open 4K Landscape Touch Package<span>Single 4K standalone HTML that forces the touch-friendly landscape UI for calibration.</span></a>"#,
        );
    }
    if cards.is_empty() {
        cards.push_str(
            r#"<div style="padding:16px 18px;border:1px solid #33486b;border-radius:12px;background:#162544;color:#f8fafc;font-weight:600;">No export variants were included in this package.</div>"#,
        );
    }

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
      __ROOT_EXPORT_CARDS__
    </div>
  </main>
</body>
 </html>"#
        .replace("__ROOT_EXPORT_CARDS__", &cards)
}

pub fn create_web_only_deployment_readme() -> String {
    String::from(
        r#"WEB-ONLY DEPLOYMENT INSTRUCTIONS

This folder is designed for website hosting over HTTP/HTTPS.

Each tour resolution adapts at runtime:
- desktop/laptop: classic UI
- touch portrait: portrait touch UI
- touch landscape: landscape touch UI

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

pub fn create_desktop_readme() -> String {
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

pub fn create_desktop_landscape_touch_readme(folder_name: &str, resolution_label: &str) -> String {
    format!(
        r#"LANDSCAPE TOUCH PACKAGE - QUICK GUIDE

Entry file:
- {folder_name}/index.html

Behavior:
- Uses {resolution_label} scenes only.
- Scenes are embedded as data URIs in one HTML file (blob-style standalone).
- Opens directly from extracted files (file:// supported).
- Forces the touch-friendly landscape UI so it can be calibrated on any device.

Notes:
1) Keep {folder_name}/libs beside {folder_name}/index.html.
2) This package is for UI calibration/testing and should not replace the classic desktop package yet.
"#,
    )
}

pub fn rewrite_tour_html_for_subfolder(web_html: &str, resolution_key: &str) -> String {
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

pub fn rewrite_web_only_index_html(index_html: &str) -> String {
    index_html.replace("../assets/logo/", "assets/logo/")
}

pub fn infer_mime_from_filename(file_name: &str) -> &'static str {
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

pub fn data_uri_for_bytes(mime: &str, bytes: &[u8]) -> String {
    format!("data:{};base64,{}", mime, BASE64_STANDARD.encode(bytes))
}

pub fn build_desktop_blob_html(
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
        .flat_map(|(file_name, bytes)| {
            let data_uri = data_uri_for_bytes("image/webp", bytes);
            [
                (
                    format!("../../assets/images/{}", file_name),
                    data_uri.clone(),
                ),
                (format!("assets/images/{}", file_name), data_uri),
            ]
        })
        .collect();

    replacements.sort_by(|(path_a, _), (path_b, _)| path_b.len().cmp(&path_a.len()));

    for (path, data_uri) in replacements {
        html = html.replace(&path, &data_uri);
    }

    html
}

#[cfg(test)]
mod tests {
    use super::build_desktop_blob_html;

    #[test]
    fn build_desktop_blob_html_rewrites_scene_asset_paths_in_css_and_runtime() {
        let html = r#"
            <style>
              #panorama { background-image: url("../../assets/images/scene-a.webp"); }
            </style>
            <script>
              const scene = { panorama: "assets/images/scene-a.webp" };
            </script>
        "#;
        let result = build_desktop_blob_html(
            html,
            &[("scene-a.webp".to_string(), vec![0x52, 0x49, 0x46, 0x46])],
            None,
        );

        assert!(result.contains("background-image: url(\"data:image/webp;base64,"));
        assert!(result.contains("panorama: \"data:image/webp;base64,"));
        assert!(!result.contains("../../data:image"));
        assert!(!result.contains("../../assets/images/scene-a.webp"));
        assert!(!result.contains("assets/images/scene-a.webp"));
    }
}
