use actix_multipart::Multipart;
use actix_web::{App, Error, HttpResponse, test, web};
use backend::api::project_multipart;
use std::fs;

async fn test_handler(payload: Multipart) -> Result<HttpResponse, Error> {
    // We try to extract "zip" file from the multipart.
    // It will expect a field named "file".
    let path = project_multipart::extract_file_from_multipart(payload, "zip")
        .await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;

    // Read content to verify
    let content = fs::read(&path)?;
    let _ = fs::remove_file(&path); // Cleanup

    Ok(HttpResponse::Ok().body(content))
}

#[actix_web::test]
async fn test_extract_file_blocking() {
    // Initialize the app with the handler
    let app = test::init_service(App::new().route("/", web::post().to(test_handler))).await;

    // Create a multipart payload
    let payload = "--abbc54650145\r\n\
                   Content-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\r\n\
                   \r\n\
                   Hello World\r\n\
                   --abbc54650145--\r\n";

    // Create request
    let req = test::TestRequest::post()
        .uri("/")
        .insert_header(("content-type", "multipart/form-data; boundary=abbc54650145"))
        .set_payload(payload)
        .to_request();

    // Send request
    let resp = test::call_service(&app, req).await;

    // Check response
    assert!(resp.status().is_success());
    let body = test::read_body(resp).await;
    assert_eq!(body, "Hello World");
}
