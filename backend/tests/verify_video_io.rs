use actix_web::{App, test, web};
use backend::api::media::video;

#[actix_web::test]
async fn test_generate_teaser_io_check() {
    // We want to verify that the endpoint runs and performs directory creation.
    // If we send an empty payload, it should process the initial setup (mkdir)
    // and then fail because of missing project_data.

    let app = test::init_service(
        App::new().route("/", web::post().to(video::generate_teaser))
    ).await;

    // Create a multipart request with an ignored field to ensure valid multipart parsing
    let payload = "--abbc54650145\r\n\
                   Content-Disposition: form-data; name=\"ignore_me\"\r\n\
                   \r\n\
                   ignored\r\n\
                   --abbc54650145--\r\n";

    let req = test::TestRequest::post()
        .uri("/")
        .insert_header(("content-type", "multipart/form-data; boundary=abbc54650145"))
        .set_payload(payload)
        .to_request();

    let resp = test::call_service(&app, req).await;

    // It should be Internal Server Error because project_data is missing
    // If we get 400, it means multipart parsing failed, which isn't what we want to test.
    // If we get 500, it means it passed parsing and hit the logic check.

    let status = resp.status();
    let body_bytes = test::read_body(resp).await;
    let body_str = std::str::from_utf8(&body_bytes).unwrap();

    println!("Response Status: {}", status);
    println!("Response Body: {}", body_str);

    assert_eq!(status, actix_web::http::StatusCode::INTERNAL_SERVER_ERROR, "Expected 500, got {}. Body: {}", status, body_str);

    assert!(body_str.contains("Missing project_data JSON"));
}
