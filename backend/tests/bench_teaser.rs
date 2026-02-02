use actix_web::{App, test, web};
use backend::api::media::video::generate_teaser;
use std::time::{Duration, Instant};
use tokio::time::sleep;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

#[actix_web::test]
async fn bench_teaser_blocking() {
    let app = test::init_service(
        App::new()
            .app_data(web::PayloadConfig::new(100 * 1024 * 1024))
            .route("/api/media/generate-teaser", web::post().to(generate_teaser)),
    )
    .await;

    let running = Arc::new(AtomicBool::new(true));
    let running_clone = running.clone();

    // Monitor task to detect blocking
    let monitor_handle = tokio::spawn(async move {
        let mut max_delay = Duration::from_micros(0);
        while running_clone.load(Ordering::Relaxed) {
            let before = Instant::now();
            sleep(Duration::from_millis(10)).await;
            let actual_duration = before.elapsed();
            let delay = actual_duration.saturating_sub(Duration::from_millis(10));
            if delay > max_delay {
                max_delay = delay;
            }
        }
        max_delay
    });

    let boundary = "------------------------Boundary123";
    let project_data = r#"{"scenes": [], "title": "Test Project"}"#;

    let mut body = Vec::new();
    body.extend_from_slice(format!("--{}\r\nContent-Disposition: form-data; name=\"project_data\"\r\n\r\n{}\r\n", boundary, project_data).as_bytes());
    body.extend_from_slice(format!("--{}\r\nContent-Disposition: form-data; name=\"files\"; filename=\"test.webp\"\r\n\r\n", boundary).as_bytes());
    body.extend_from_slice(&[0u8; 1024 * 1024]); // 1MB dummy data
    body.extend_from_slice(b"\r\n");
    body.extend_from_slice(format!("--{}--\r\n", boundary).as_bytes());

    let req = test::TestRequest::post()
        .uri("/api/media/generate-teaser")
        .insert_header((
            "content-type",
            format!("multipart/form-data; boundary={}", boundary),
        ))
        .set_payload(body)
        .to_request();

    let _resp = test::call_service(&app, req).await;

    running.store(false, Ordering::Relaxed);
    let max_delay = monitor_handle.await.unwrap();
    println!("Max event loop delay: {:?}", max_delay);
}
