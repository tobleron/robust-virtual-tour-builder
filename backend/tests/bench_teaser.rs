use actix_web::{App, test, web};
use backend::api::media::video::generate_teaser;
use std::time::Instant;

#[actix_web::test]
async fn bench_teaser_sequential() {
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
    let file_content = vec![0u8; 1024];
    let header = format!(
        "--{}\r\nContent-Disposition: form-data; name=\"files\"; filename=\"test.png\"\r\nContent-Type: image/png\r\n\r\n",
        boundary
    );
    let footer = format!("\r\n--{}--\r\n", boundary);
    let mut body = Vec::new();
    body.extend_from_slice(header.as_bytes());
    body.extend_from_slice(&file_content);
    body.extend_from_slice(footer.as_bytes());

    let iterations = 500;
    let start = Instant::now();

    for _ in 0..iterations {
        let req = test::TestRequest::post()
            .uri("/api/media/generate-teaser")
            .insert_header((
                "content-type",
                format!("multipart/form-data; boundary={}", boundary),
            ))
            .set_payload(body.clone())
            .to_request();

        let resp = test::call_service(&app, req).await;
        // We expect 500 because project_data is missing,
        // but by then the directory creation and file writing has occurred.
        assert_eq!(resp.status(), 500);
    }

    let duration = start.elapsed();
    println!("{} sequential requests took: {:?}", iterations, duration);
}
