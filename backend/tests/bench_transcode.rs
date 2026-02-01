use actix_web::{App, test, web};
use backend::api::media::video::transcode_video;
use std::time::Instant;

#[actix_web::test]
async fn bench_transcode_upload_performance() {
    let app = test::init_service(
        App::new()
            .app_data(web::PayloadConfig::new(100 * 1024 * 1024))
            .route(
                "/api/media/transcode-video",
                web::post().to(transcode_video),
            ),
    )
    .await;

    let boundary = "------------------------Boundary123";
    let large_data = vec![0u8; 10 * 1024 * 1024]; // 10MB

    let header = format!(
        "--{}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"video.mp4\"\r\nContent-Type: video/mp4\r\n\r\n",
        boundary
    );
    let footer = format!("\r\n--{}--\r\n", boundary);

    let mut body = Vec::new();
    body.extend_from_slice(header.as_bytes());
    body.extend_from_slice(&large_data);
    body.extend_from_slice(footer.as_bytes());

    let start = Instant::now();

    let req = test::TestRequest::post()
        .uri("/api/media/transcode-video")
        .insert_header((
            "content-type",
            format!("multipart/form-data; boundary={}", boundary),
        ))
        .set_payload(body)
        .to_request();

    let resp = test::call_service(&app, req).await;

    let duration = start.elapsed();
    println!("Request took: {:?}", duration);

    // Expect server error (500) because the video is invalid/dummy
    assert!(resp.status().is_server_error() || resp.status().is_success());
}
