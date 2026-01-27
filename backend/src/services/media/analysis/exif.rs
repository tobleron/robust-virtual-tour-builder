use crate::models::*;
use std::io::Cursor;

pub fn extract_exif(input_data: &[u8], width: u32, height: u32) -> ExifMetadata {
    let mut reader = Cursor::new(input_data);
    let exif_reader = exif::Reader::new();
    let exif_data = exif_reader.read_from_container(&mut reader).ok();

    let mut make = None;
    let mut model = None;
    let mut date_time = None;
    let mut gps = None;
    let mut focal_length = None;
    let mut aperture = None;
    let mut iso = None;

    if let Some(exif) = exif_data {
        make = exif
            .get_field(exif::Tag::Make, exif::In::PRIMARY)
            .map(|f| f.display_value().to_string().replace("\"", ""));
        model = exif
            .get_field(exif::Tag::Model, exif::In::PRIMARY)
            .map(|f| f.display_value().to_string().replace("\"", ""));
        date_time = exif
            .get_field(exif::Tag::DateTimeOriginal, exif::In::PRIMARY)
            .map(|f| f.display_value().to_string());
        focal_length = exif
            .get_field(exif::Tag::FocalLength, exif::In::PRIMARY)
            .and_then(|f| {
                if let exif::Value::Rational(ref v) = f.value {
                    v.first().map(|r| r.to_f64() as f32)
                } else {
                    None
                }
            });
        aperture = exif
            .get_field(exif::Tag::FNumber, exif::In::PRIMARY)
            .and_then(|f| {
                if let exif::Value::Rational(ref v) = f.value {
                    v.first().map(|r| r.to_f64() as f32)
                } else {
                    None
                }
            });
        iso = exif
            .get_field(exif::Tag::PhotographicSensitivity, exif::In::PRIMARY)
            .and_then(|f| f.value.get_uint(0));

        let lat_field = exif.get_field(exif::Tag::GPSLatitude, exif::In::PRIMARY);
        let lat_ref_field = exif.get_field(exif::Tag::GPSLatitudeRef, exif::In::PRIMARY);
        let lon_field = exif.get_field(exif::Tag::GPSLongitude, exif::In::PRIMARY);
        let lon_ref_field = exif.get_field(exif::Tag::GPSLongitudeRef, exif::In::PRIMARY);

        let parse_gps = |f: &exif::Field| -> Option<f64> {
            match &f.value {
                exif::Value::Rational(dms) if dms.len() >= 3 => {
                    Some(dms[0].to_f64() + dms[1].to_f64() / 60.0 + dms[2].to_f64() / 3600.0)
                }
                exif::Value::Ascii(strings) if !strings.is_empty() => {
                    let s = String::from_utf8_lossy(&strings[0]);
                    let parts: Vec<f64> = s
                        .split(|c: char| !c.is_digit(10) && c != '.' && c != '-')
                        .filter_map(|p| p.parse::<f64>().ok())
                        .collect();
                    if parts.len() >= 3 {
                        Some(parts[0] + parts[1] / 60.0 + parts[2] / 3600.0)
                    } else {
                        parts.first().copied()
                    }
                }
                _ => None,
            }
        };

        if let (Some(lat_v), Some(lon_v)) =
            (lat_field.and_then(parse_gps), lon_field.and_then(parse_gps))
        {
            let mut lat_val = lat_v;
            let mut lon_val = lon_v;
            if let Some(ref_f) = lat_ref_field
                && ref_f
                    .display_value()
                    .to_string()
                    .to_uppercase()
                    .contains('S')
            {
                lat_val = -lat_val;
            }
            if let Some(ref_f) = lon_ref_field
                && ref_f
                    .display_value()
                    .to_string()
                    .to_uppercase()
                    .contains('W')
            {
                lon_val = -lon_val;
            }
            gps = Some(GpsData {
                lat: lat_val,
                lon: lon_val,
            });
        }
    }

    ExifMetadata {
        make,
        model,
        date_time,
        gps,
        width,
        height,
        focal_length,
        aperture,
        iso,
    }
}
