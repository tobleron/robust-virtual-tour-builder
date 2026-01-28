use super::*;
use crate::models::{ColorHist, MetadataResponse, QualityAnalysis, QualityStats};
use actix_web::{App, http::StatusCode, web};
use image::{ImageFormat, RgbaImage};
use std::io::Cursor;

#[test]
fn test_quality_analysis_serialization() {
    let stats = QualityStats {
        avg_luminance: 128,
        black_clipping: 0.01,
        white_clipping: 0.01,
        sharpness_variance: 500,
    };

    let qa = QualityAnalysis {
        score: 0.85,
        histogram: vec![0; 256],
        color_hist: ColorHist {
            r: vec![],
            g: vec![],
            b: vec![],
        },
        stats,
        is_blurry: false,
        is_soft: false,
        is_severely_dark: false,
        is_severely_bright: false,
        is_dim: false,
        has_black_clipping: false,
        has_white_clipping: false,
        issues: 0,
        warnings: 0,
        analysis: Some("Good".to_string()),
    };

    let json = serde_json::to_string(&qa).expect("Serialization failed");
    assert!(json.contains("score"));
    assert!(json.contains("stats"));
}

fn create_test_image() -> Vec<u8> {
    let img = RgbaImage::new(100, 100);
    let mut bytes: Vec<u8> = Vec::new();
    img.write_to(&mut Cursor::new(&mut bytes), ImageFormat::Png)
        .expect("Failed to create test image");
    bytes
}

fn create_multipart_body(boundary: &str, name: &str, filename: &str, content: &[u8]) -> Vec<u8> {
    let mut body = Vec::new();
    body.extend_from_slice(format!("--{}\r\n", boundary).as_bytes());
    body.extend_from_slice(
        format!(
            "Content-Disposition: form-data; name=\"{}\"; filename=\"{}\"\r\n",
            name, filename
        )
        .as_bytes(),
    );
    body.extend_from_slice(b"Content-Type: image/png\r\n\r\n");
    body.extend_from_slice(content);
    body.extend_from_slice(format!("\r\n--{}--\r\n", boundary).as_bytes());
    body
}

#[actix_web::test]
async fn test_extract_metadata_endpoint() {
    let app = actix_web::test::init_service(
        App::new().route("/metadata", web::post().to(extract_metadata)),
    )
    .await;

    let boundary = "test_boundary";
    let image_data = create_test_image();
    let body = create_multipart_body(boundary, "file", "test.png", &image_data);

    let req = actix_web::test::TestRequest::post()
        .uri("/metadata")
        .insert_header((
            "content-type",
            format!("multipart/form-data; boundary={}", boundary),
        ))
        .set_payload(body)
        .to_request();

    let resp = actix_web::test::call_service(&app, req).await;
    assert_eq!(resp.status(), StatusCode::OK);

    let result: MetadataResponse = actix_web::test::read_body_json(resp).await;
    assert_eq!(result.exif.width, 100);
    assert_eq!(result.exif.height, 100);
}

#[actix_web::test]
async fn test_optimize_image_endpoint() {
    let app = actix_web::test::init_service(
        App::new().route("/optimize", web::post().to(optimize_image)),
    )
    .await;

    let boundary = "test_boundary";
    let image_data = create_test_image();
    let body = create_multipart_body(boundary, "file", "test.png", &image_data);

    let req = actix_web::test::TestRequest::post()
        .uri("/optimize")
        .insert_header((
            "content-type",
            format!("multipart/form-data; boundary={}", boundary),
        ))
        .set_payload(body)
        .to_request();

    let resp = actix_web::test::call_service(&app, req).await;
    assert_eq!(resp.status(), StatusCode::OK);
    assert_eq!(
        resp.headers()
            .get("content-type")
            .expect("Missing content-type"),
        "image/webp"
    );
}
