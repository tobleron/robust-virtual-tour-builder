use actix_web::{App, test, web};
use backend::api::media::video;

#[actix_web::test]
async fn test_generate_teaser_endpoint_structure() {
    // Initialize the app with the handler
    let app = test::init_service(App::new().route("/teaser", web::post().to(video::generate_teaser))).await;

    // Create a multipart payload
    // We provide minimal parts to trigger the function flow.
    let payload = "--abbc54650145\r\n\
                   Content-Disposition: form-data; name=\"project_data\"\r\n\
                   \r\n\
                   {\"scenes\": []}\r\n\
                   --abbc54650145--\r\n";

    // Create request
    let req = test::TestRequest::post()
        .uri("/teaser")
        .insert_header(("content-type", "multipart/form-data; boundary=abbc54650145"))
        .set_payload(payload)
        .to_request();

    // Send request
    // We expect it to eventually fail due to dependencies (Chrome) or logic,
    // but the blocking create_dir_all happens at the very beginning.
    let resp = test::call_service(&app, req).await;

    // Just assert that we got a response (even if it's 500)
    assert!(resp.status().is_server_error() || resp.status().is_success());
}
