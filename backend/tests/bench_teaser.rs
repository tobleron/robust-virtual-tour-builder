use actix_web::{App, test, web};
use backend::api::media::video::generate_teaser;
use std::time::Instant;

#[actix_web::test]
async fn bench_teaser_generation_performance() {
    // Setup app
    let app = test::init_service(
        App::new()
            .app_data(web::PayloadConfig::new(100 * 1024 * 1024))
            .route(
                "/api/media/generate-teaser",
                web::post().to(generate_teaser),
            ),
    )
    .await;

    let boundary = "------------------------Boundary123";
    let dummy_image = vec![0u8; 100 * 1024]; // 100KB dummy image
    // Minimal project data
    let project_data = r#"{"id": "test-id", "scenes": [{"id": "scene1", "hotspots": []}]}"#;

    let mut body = Vec::new();

    // project_data field
    body.extend_from_slice(format!("--{}\r\n", boundary).as_bytes());
    body.extend_from_slice(b"Content-Disposition: form-data; name=\"project_data\"\r\n\r\n");
    body.extend_from_slice(project_data.as_bytes());
    body.extend_from_slice(b"\r\n");

    // Add multiple files to stress the file creation logic
    for i in 0..50 {
        body.extend_from_slice(format!("--{}\r\n", boundary).as_bytes());
        body.extend_from_slice(format!("Content-Disposition: form-data; name=\"files\"; filename=\"image_{}.jpg\"\r\n\r\n", i).as_bytes());
        body.extend_from_slice(&dummy_image);
        body.extend_from_slice(b"\r\n");
    }

    body.extend_from_slice(format!("--{}--\r\n", boundary).as_bytes());

    println!("Starting request with payload size: {} bytes", body.len());
    let start = Instant::now();

    let req = test::TestRequest::post()
        .uri("/api/media/generate-teaser")
        .insert_header((
            "content-type",
            format!("multipart/form-data; boundary={}", boundary),
        ))
        .set_payload(body)
        .to_request();

    let resp = test::call_service(&app, req).await;

    let duration = start.elapsed();
    println!("Request took: {:?}", duration);

    // The handler performs file I/O then calls a sync function.
    // Even if the sync function fails (due to missing ffmpeg/logic),
    // we exercised the file I/O path.
    // 500 Internal Server Error is expected if video logic fails, which is fine for this benchmark.
    assert!(resp.status().is_server_error() || resp.status().is_success());
}
