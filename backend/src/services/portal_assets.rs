#![allow(dead_code)]
// @efficiency-role: service-orchestrator
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use actix_files::NamedFile;
use image::{DynamicImage, Rgba, RgbaImage};
use sqlx::SqlitePool;
use zip::ZipArchive;

use crate::api::utils::validate_path_safe;
use crate::models::AppError;
use crate::services::portal::PortalLibraryTour;
use crate::services::portal_paths::{
    detect_portal_package_root, sanitize_relative_path, should_keep_portal_relative_path,
};
use crate::services::portal_sessions::load_authorized_portal_tour;
use crate::services::portal_support::{
    boost_portal_launch_branding, inject_base_href, portal_launch_entry_candidates,
};

const PORTAL_REQUIRED_ENTRY_SUFFIXES: [&str; 3] =
    ["index.html", "tour_4k/index.html", "tour_2k/index.html"];

pub async fn load_portal_launch_document(
    pool: &SqlitePool,
    customer_slug: &str,
    tour_slug: &str,
    access_kind: &str,
    access_ref: &str,
    user_agent: Option<&str>,
) -> Result<String, AppError> {
    let tour = load_authorized_portal_tour(pool, customer_slug, tour_slug, access_kind, access_ref)
        .await?;
    let storage_root = PathBuf::from(&tour.storage_path);

    for candidate in portal_launch_entry_candidates(user_agent) {
        let resolved = storage_root.join(candidate);
        if !resolved.exists() {
            continue;
        }

        validate_path_safe(&storage_root, &resolved)?;
        let document = fs::read_to_string(&resolved).map_err(AppError::IoError)?;
        let base_href = match candidate.rsplit_once('/') {
            Some((dir, _)) => format!("/portal-assets/{}/{}/{}/", customer_slug, tour_slug, dir),
            None => format!("/portal-assets/{}/{}/", customer_slug, tour_slug),
        };
        return Ok(boost_portal_launch_branding(inject_base_href(
            document, &base_href,
        )));
    }

    Err(AppError::ValidationError(
        "Portal launch document not found.".into(),
    ))
}

pub async fn resolve_portal_asset(
    pool: &SqlitePool,
    customer_slug: &str,
    tour_slug: &str,
    relative_path: &str,
    access_kind: &str,
    access_ref: &str,
) -> Result<NamedFile, AppError> {
    let tour = load_authorized_portal_tour(pool, customer_slug, tour_slug, access_kind, access_ref)
        .await?;
    let storage_root = PathBuf::from(&tour.storage_path);
    let safe_relative = sanitize_relative_path(relative_path)?;
    let resolved = storage_root.join(&safe_relative);
    if !resolved.exists() {
        return Err(AppError::ValidationError("Portal asset not found.".into()));
    }

    validate_path_safe(&storage_root, &resolved)?;
    NamedFile::open_async(resolved)
        .await
        .map_err(AppError::IoError)
}

pub(crate) async fn ensure_portal_cover_path(
    pool: &SqlitePool,
    tour: &PortalLibraryTour,
) -> Result<Option<String>, AppError> {
    let generated_relative = "portal_cover.webp".to_string();
    let generated_path = Path::new(&tour.storage_path).join(&generated_relative);
    if generated_path.exists() {
        return Ok(Some(generated_relative));
    }

    let source_relative = tour.cover_path.clone().or_else(|| {
        let fallback = Path::new(&tour.storage_path)
            .join("assets")
            .join("images")
            .join("2k");
        fs::read_dir(fallback)
            .ok()?
            .filter_map(|entry| entry.ok())
            .find(|entry| entry.path().extension().and_then(|value| value.to_str()) == Some("webp"))
            .and_then(|entry| {
                entry
                    .path()
                    .strip_prefix(&tour.storage_path)
                    .ok()
                    .map(|path| path.to_string_lossy().replace('\\', "/"))
            })
    });

    let Some(source_relative) = source_relative else {
        return Ok(None);
    };

    let source_path = Path::new(&tour.storage_path).join(&source_relative);
    if !source_path.exists() {
        return Ok(None);
    }

    generate_portal_cover_thumbnail(&source_path, &generated_path)?;
    sqlx::query("UPDATE portal_library_tours SET cover_path = ?, updated_at = ? WHERE id = ?")
        .bind(&generated_relative)
        .bind(chrono::Utc::now())
        .bind(&tour.id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal cover-path update failed: {}", error))
        })?;

    Ok(Some(generated_relative))
}

pub(crate) struct ExtractedPackage {
    pub(crate) cover_path: Option<String>,
}

fn generate_portal_cover_thumbnail(
    source_path: &Path,
    destination_path: &Path,
) -> Result<(), AppError> {
    let source_image = image::open(source_path).map_err(|error| {
        AppError::ValidationError(format!("Portal cover decode failed: {}", error))
    })?;
    let source_rgba = source_image.to_rgba8();
    let src_w = source_rgba.width();
    let src_h = source_rgba.height();

    if src_w == 0 || src_h == 0 {
        return Err(AppError::ValidationError(
            "Portal cover source image is empty.".into(),
        ));
    }

    let width: u32 = 640;
    let height: u32 = 360;
    let hfov = std::f32::consts::FRAC_PI_2;
    let half_tan_h = (hfov / 2.0).tan();
    let aspect = width as f32 / height as f32;
    let half_tan_v = half_tan_h / aspect;
    let mut output = RgbaImage::new(width, height);

    for y in 0..height {
        for x in 0..width {
            let u = (x as f32 / width as f32) * 2.0 - 1.0;
            let v = 1.0 - (y as f32 / height as f32) * 2.0;

            let theta = (u * half_tan_h).atan();
            let phi = (v * half_tan_v * theta.cos()).atan();

            let lon = theta / (2.0 * std::f32::consts::PI) + 0.5;
            let lat = 0.5 - phi / std::f32::consts::PI;

            let sx = (lon * src_w as f32).floor().clamp(0.0, (src_w - 1) as f32) as u32;
            let sy = (lat * src_h as f32).floor().clamp(0.0, (src_h - 1) as f32) as u32;
            let pixel = source_rgba.get_pixel(sx, sy);
            output.put_pixel(x, y, Rgba([pixel[0], pixel[1], pixel[2], 255]));
        }
    }

    if let Some(parent) = destination_path.parent() {
        fs::create_dir_all(parent).map_err(AppError::IoError)?;
    }
    let cover_image = DynamicImage::ImageRgba8(output);
    let cover_bytes =
        encode_portal_cover_webp(&cover_image, 82.0).map_err(AppError::ValidationError)?;
    fs::write(destination_path, cover_bytes).map_err(AppError::IoError)?;
    Ok(())
}

fn encode_portal_cover_webp(img: &DynamicImage, quality: f32) -> Result<Vec<u8>, String> {
    let rgba = img.to_rgba8();
    let encoder = webp::Encoder::from_rgba(&rgba, img.width(), img.height());
    Ok(encoder.encode(quality).to_vec())
}

pub(crate) fn extract_portal_package(
    zip_path: &Path,
    destination_dir: &Path,
) -> Result<ExtractedPackage, AppError> {
    let file = std::fs::File::open(zip_path).map_err(AppError::IoError)?;
    let mut archive = ZipArchive::new(file).map_err(|error| {
        AppError::ValidationError(format!("Portal ZIP could not be opened: {}", error))
    })?;

    let mut entry_names: Vec<String> = Vec::new();
    for index in 0..archive.len() {
        let entry = archive.by_index(index).map_err(|error| {
            AppError::ValidationError(format!("Portal ZIP entry could not be read: {}", error))
        })?;
        let enclosed = entry.enclosed_name().ok_or_else(|| {
            AppError::ValidationError("Portal ZIP contains an unsafe path.".into())
        })?;
        let entry_name = enclosed.to_string_lossy().replace('\\', "/");
        if !entry.is_dir() {
            entry_names.push(entry_name);
        }
    }

    let package_root = detect_portal_package_root(&entry_names)?;
    let mut found_entries: Vec<&str> = Vec::new();
    let mut source_cover_path: Option<String> = None;

    for index in 0..archive.len() {
        let mut entry = archive.by_index(index).map_err(|error| {
            AppError::ValidationError(format!("Portal ZIP entry could not be read: {}", error))
        })?;
        let enclosed = entry.enclosed_name().ok_or_else(|| {
            AppError::ValidationError("Portal ZIP contains an unsafe path.".into())
        })?;
        let entry_name = enclosed.to_string_lossy().replace('\\', "/");
        if !entry_name.starts_with(&package_root) || entry.is_dir() {
            continue;
        }

        let relative_path = entry_name
            .strip_prefix(&package_root)
            .ok_or_else(|| AppError::ValidationError("Portal ZIP entry prefix mismatch.".into()))?;

        if !should_keep_portal_relative_path(relative_path) {
            continue;
        }

        for required in PORTAL_REQUIRED_ENTRY_SUFFIXES {
            if relative_path == required && !found_entries.contains(&required) {
                found_entries.push(required);
            }
        }

        let destination = destination_dir.join(relative_path);
        if let Some(parent) = destination.parent() {
            fs::create_dir_all(parent).map_err(AppError::IoError)?;
        }
        let mut output = std::fs::File::create(&destination).map_err(AppError::IoError)?;
        std::io::copy(&mut entry, &mut output).map_err(AppError::IoError)?;
        output.flush().map_err(AppError::IoError)?;

        if source_cover_path.is_none()
            && relative_path.starts_with("assets/images/2k/")
            && relative_path.ends_with(".webp")
        {
            source_cover_path = Some(relative_path.to_string());
        }
    }

    if PORTAL_REQUIRED_ENTRY_SUFFIXES
        .iter()
        .any(|required| !found_entries.contains(required))
    {
        return Err(AppError::ValidationError(
            "Portal ZIP must include web_only/index.html plus both tour_4k/index.html and tour_2k/index.html.".into(),
        ));
    }

    let generated_cover_path = source_cover_path
        .as_ref()
        .map(|relative| {
            let source_path = destination_dir.join(relative);
            let destination_relative = "portal_cover.webp".to_string();
            let destination_path = destination_dir.join(&destination_relative);
            generate_portal_cover_thumbnail(&source_path, &destination_path)?;
            Ok::<String, AppError>(destination_relative)
        })
        .transpose()?;

    Ok(ExtractedPackage {
        cover_path: generated_cover_path.or(source_cover_path),
    })
}
