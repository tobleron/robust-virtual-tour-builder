// @efficiency-role: service-orchestrator
use std::collections::HashMap;

use zip::ZipWriter;
use zip::write::FileOptions;

use super::TARGETS;
use super::package_assets::{PreparedPackageAssets, SelectedProfiles};

pub(super) fn write_root_launcher(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
) -> Result<(), String> {
    super::write_zip_file(
        zip,
        options,
        "index.html",
        super::create_root_index().as_bytes(),
    )
}

pub(super) fn write_shared_assets(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    package_assets: &PreparedPackageAssets,
) -> Result<(), String> {
    if let Some((name, bytes)) = &package_assets.logo_asset {
        super::write_zip_file(
            zip,
            options,
            &format!("web_only/assets/logo/{}", name),
            bytes,
        )?;
    }

    for (lib_name, bytes) in &package_assets.lib_assets {
        super::write_zip_file(zip, options, &format!("web_only/libs/{}", lib_name), bytes)?;
        super::write_zip_file(zip, options, &format!("desktop/libs/{}", lib_name), bytes)?;
    }

    Ok(())
}

pub(super) fn write_image_assets(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    selected_profiles: &SelectedProfiles,
    artifacts_by_resolution: &HashMap<&'static str, Vec<(String, Vec<u8>)>>,
) -> Result<(), String> {
    for (resolution_key, _, _) in TARGETS {
        let should_include = match resolution_key {
            "4k" => selected_profiles.include_4k,
            "2k" => selected_profiles.include_2k || selected_profiles.include_desktop_blob_2k,
            "hd" => selected_profiles.include_hd,
            _ => false,
        };
        if !should_include {
            continue;
        }

        if let Some(artifacts) = artifacts_by_resolution.get(resolution_key) {
            for (file_name, data) in artifacts {
                super::write_zip_file(
                    zip,
                    options,
                    &format!("web_only/assets/images/{}/{}", resolution_key, file_name),
                    data,
                )?;
            }
        }
    }

    Ok(())
}

pub(super) fn write_tour_htmls(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    fields: &HashMap<String, String>,
    selected_profiles: &SelectedProfiles,
) -> Result<(), String> {
    let html_targets = [
        ("html_4k", "4k", "tour_4k"),
        ("html_2k", "2k", "tour_2k"),
        ("html_hd", "hd", "tour_hd"),
    ];

    for (field_name, resolution_key, folder) in html_targets {
        let should_include = match resolution_key {
            "4k" => selected_profiles.include_4k,
            "2k" => selected_profiles.include_2k,
            "hd" => selected_profiles.include_hd,
            _ => false,
        };
        if !should_include {
            continue;
        }

        if let Some(web_html) = fields.get(field_name) {
            let web_only_html = super::rewrite_tour_html_for_subfolder(web_html, resolution_key);
            super::write_zip_file(
                zip,
                options,
                &format!("web_only/{}/index.html", folder),
                web_only_html.as_bytes(),
            )?;
        }
    }

    Ok(())
}

pub(super) fn write_supporting_files(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    fields: &HashMap<String, String>,
    selected_profiles: &SelectedProfiles,
    package_assets: &PreparedPackageAssets,
) -> Result<(), String> {
    write_desktop_bundle(zip, options, fields, selected_profiles, package_assets)?;
    write_web_only_support(zip, options, fields, selected_profiles)?;
    write_desktop_support(zip, options, selected_profiles)
}

pub(super) fn write_project_metadata(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    fields: &HashMap<String, String>,
) -> Result<(), String> {
    if let Some(project_data) = fields.get("project_data") {
        super::write_zip_file(
            zip,
            options,
            "project_metadata.vt.json",
            project_data.as_bytes(),
        )?;
    }
    Ok(())
}

fn write_desktop_bundle(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    fields: &HashMap<String, String>,
    selected_profiles: &SelectedProfiles,
    package_assets: &PreparedPackageAssets,
) -> Result<(), String> {
    if !selected_profiles.include_desktop_blob_2k {
        return Ok(());
    }

    let desktop_template = fields
        .get("html_desktop_2k_blob")
        .or_else(|| fields.get("html_2k"))
        .ok_or_else(|| "Missing desktop 2k html template".to_string())?;
    let assets_2k = package_assets
        .artifacts_by_resolution
        .get("2k")
        .ok_or_else(|| "Missing 2k assets for desktop package".to_string())?;
    let desktop_html = super::build_desktop_blob_html(
        desktop_template,
        assets_2k,
        package_assets.logo_asset.as_ref(),
    );
    super::write_zip_file(zip, options, "desktop/index.html", desktop_html.as_bytes())
}

fn write_web_only_support(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    fields: &HashMap<String, String>,
    selected_profiles: &SelectedProfiles,
) -> Result<(), String> {
    if selected_profiles.include_4k || selected_profiles.include_2k || selected_profiles.include_hd
    {
        if let Some(index_html) = fields.get("html_index") {
            let web_only_index = super::rewrite_web_only_index_html(index_html);
            super::write_zip_file(
                zip,
                options,
                "web_only/index.html",
                web_only_index.as_bytes(),
            )?;
        }

        super::write_zip_file(
            zip,
            options,
            "web_only/DEPLOYMENT_README.txt",
            super::create_web_only_deployment_readme().as_bytes(),
        )?;

        if let Some(embed_codes) = fields.get("embed_codes") {
            super::write_zip_file(
                zip,
                options,
                "web_only/embed_codes.txt",
                embed_codes.as_bytes(),
            )?;
        }
    }

    Ok(())
}

fn write_desktop_support(
    zip: &mut ZipWriter<std::fs::File>,
    options: FileOptions,
    selected_profiles: &SelectedProfiles,
) -> Result<(), String> {
    if !selected_profiles.include_desktop_blob_2k {
        return Ok(());
    }

    super::write_zip_file(
        zip,
        options,
        "desktop/README.txt",
        super::create_desktop_readme().as_bytes(),
    )?;
    super::write_zip_file(
        zip,
        options,
        "desktop/embed_codes.txt",
        b"DESKTOP PACKAGE\n\nOpen:\ndesktop/index.html\n",
    )
}
