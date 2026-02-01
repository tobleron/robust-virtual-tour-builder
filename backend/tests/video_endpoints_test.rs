use actix_web::{App, test, web};
use backend::api::media::video;

#[actix_web::test]
async fn test_generate_teaser_execution() {
    // Initialize the app with the handler
    let app = test::init_service(App::new().route("/generate_teaser", web::post().to(video::generate_teaser))).await;

    // Create a multipart payload
    let payload = "--abbc54650145\r\n\
                   Content-Disposition: form-data; name=\"dummy\"\r\n\
                   \r\n\
                   dummy\r\n\
                   --abbc54650145--\r\n";

    // Create request
    let req = test::TestRequest::post()
        .uri("/generate_teaser")
        .insert_header(("content-type", "multipart/form-data; boundary=abbc54650145"))
        .set_payload(payload)
        .to_request();

    // Send request
    let resp = test::call_service(&app, req).await;

    assert_eq!(resp.status(), actix_web::http::StatusCode::INTERNAL_SERVER_ERROR);

    let body = test::read_body(resp).await;
    let body_str = std::str::from_utf8(&body).unwrap();
    assert!(body_str.contains("Missing project_data JSON"));
}
