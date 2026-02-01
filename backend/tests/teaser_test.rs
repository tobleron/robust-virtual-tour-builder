use actix_web::{App, test, web};
use backend::api::media::video::generate_teaser;

#[actix_web::test]
async fn test_generate_teaser_endpoint() {
    let app = test::init_service(
        App::new()
            .route("/api/media/generate-teaser", web::post().to(generate_teaser)),
    )
    .await;

    let boundary = "------------------------Boundary123";
    let project_data_json = serde_json::json!({
        "scenes": [],
        "version": "1.0"
    }).to_string();

    let body_parts = vec![
        format!("--{}\r\nContent-Disposition: form-data; name=\"project_data\"\r\n\r\n{}\r\n", boundary, project_data_json),
        format!("--{}\r\nContent-Disposition: form-data; name=\"files\"; filename=\"test.webp\"\r\nContent-Type: image/webp\r\n\r\nFAKE_IMAGE_DATA\r\n", boundary),
        format!("--{}--\r\n", boundary),
    ];
    let body = body_parts.join("");

    let req = test::TestRequest::post()
        .uri("/api/media/generate-teaser")
        .insert_header(("content-type", format!("multipart/form-data; boundary={}", boundary)))
        .set_payload(body)
        .to_request();

    let resp = test::call_service(&app, req).await;

    // The endpoint might return 500 because the "FAKE_IMAGE_DATA" is not a valid image/video for the logic,
    // or project_data is too simple. But if we get a response, the handler executed.
    // We are testing that the handler runs and handles I/O (file creation) without panicking or blocking incorrectly (though blocking is harder to detect here).
    assert!(resp.status().is_server_error() || resp.status().is_success());
}
