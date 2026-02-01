use actix_web::{App, test, web};
use backend::api::media::video::generate_teaser;
use std::time::Instant;

#[actix_web::test]
async fn bench_generate_teaser_directory_creation() {
    let app = test::init_service(
        App::new()
            .route(
                "/api/media/generate-teaser",
                web::post().to(generate_teaser),
            ),
    )
    .await;

    let boundary = "------------------------BoundaryTeaser";
    // Minimal payload to just trigger the handler logic up to directory creation
    let header = format!(
        "--{}\r\nContent-Disposition: form-data; name=\"project_data\"\r\n\r\n{{}}\r\n",
        boundary
    );
    let footer = format!("\r\n--{}--\r\n", boundary);

    let mut body = Vec::new();
    body.extend_from_slice(header.as_bytes());
    body.extend_from_slice(footer.as_bytes());

    let start = Instant::now();

    let req = test::TestRequest::post()
        .uri("/api/media/generate-teaser")
        .insert_header((
            "content-type",
            format!("multipart/form-data; boundary={}", boundary),
        ))
        .set_payload(body)
        .to_request();

    // This will likely fail with "Missing project_data JSON" or similar
    // because we provided an empty JSON object which is valid JSON but maybe structurally invalid for the logic
    // OR "Missing content disposition" if we messed up headers.
    // But importantly, it executes the blocking create_dir_all BEFORE failing.
    let resp = test::call_service(&app, req).await;

    let duration = start.elapsed();
    println!("Teaser request (partial) took: {:?}", duration);

    // We expect it to run and return something (likely 500 error due to logic failure later)
    assert!(resp.status().is_server_error() || resp.status().is_success());
}
