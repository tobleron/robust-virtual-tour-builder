use actix_multipart::test::create_form_data_payload_and_headers;
use actix_web::{test, web, App};
use backend::api::media::video::generate_teaser;
use bytes::Bytes;
use std::fs;
use std::path::Path;

#[actix_web::test]
async fn test_generate_teaser_async_io_baseline() {
    // 1. Prepare multipart payload with a file but NO project_data
    // logic expects "files" field
    let content = "TEST_CONTENT_FOR_ASYNC_CHECK";
    let (body, headers) = create_form_data_payload_and_headers(
        "files",
        Some("test_image.webp".to_string()),
        None,
        Bytes::from_static(content.as_bytes()),
    );

    // 2. Initialize App with the handler
    let app = test::init_service(
        App::new().route("/generate_teaser", web::post().to(generate_teaser)),
    )
    .await;

    // 3. Send request
    let mut req = test::TestRequest::post()
        .uri("/generate_teaser")
        .set_payload(body);

    for (key, value) in headers.iter() {
        req = req.insert_header((key.clone(), value.clone()));
    }

    let req = req.to_request();

    let resp = test::call_service(&app, req).await;

    // 4. Expect 500 Internal Server Error (Missing project_data JSON)
    assert_eq!(resp.status(), 500);

    // 5. Verify file was written to /tmp/vt_backend
    let temp_dir = Path::new("/tmp/vt_backend");
    if !temp_dir.exists() {
        // If dir doesn't exist, maybe it wasn't created or test env is different.
        // But video.rs ensures creation.
        panic!("/tmp/vt_backend does not exist");
    }

    let mut found = false;
    // Iterate over subdirectories (session IDs)
    for entry in fs::read_dir(temp_dir).unwrap() {
        let entry = entry.unwrap();
        let path = entry.path();
        if path.is_dir() {
            // Check for our file inside
            // filename might be sanitized or generic.
            // video.rs: sanitize_filename(&filename).unwrap_or(filename);
            // We sent "test_image.webp".
            let file_path = path.join("test_image.webp");
            if file_path.exists() {
                let content_read = fs::read_to_string(&file_path).unwrap();
                if content_read == content {
                    found = true;
                    // Cleanup
                    fs::remove_dir_all(&path).unwrap();
                    break;
                }
            }
        }
    }

    assert!(found, "Did not find the uploaded file in any session directory in /tmp/vt_backend");
}
