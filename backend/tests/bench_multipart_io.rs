use actix_multipart::Multipart;
use actix_web::{test, web, App, HttpResponse};
use backend::api::project_multipart;
use tokio::time::{sleep, Duration, Instant};
use std::io::Write;

async fn heartbeat() {
    let mut last_tick = Instant::now();
    loop {
        sleep(Duration::from_millis(10)).await;
        let now = Instant::now();
        if now.duration_since(last_tick) > Duration::from_millis(50) {
            println!("BLOCKED: Heartbeat delayed by {:?}", now.duration_since(last_tick));
        }
        last_tick = now;
    }
}

async fn test_handler(payload: Multipart) -> Result<HttpResponse, actix_web::Error> {
    project_multipart::parse_save_project_multipart(payload).await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;
    Ok(HttpResponse::Ok().finish())
}

#[actix_web::test]
async fn bench_multipart_io() {
    let app = test::init_service(App::new().route("/", web::post().to(test_handler))).await;

    // Start heartbeat
    tokio::spawn(heartbeat());

    // Create a large payload
    let payload_size = 100 * 1024 * 1024; // 100MB

    let boundary = "boundary";
    let mut body = Vec::new();
    write!(body, "--{}\r\n", boundary).unwrap();
    write!(body, "Content-Disposition: form-data; name=\"files\"; filename=\"large.bin\"\r\n\r\n").unwrap();

    let data = vec![b'x'; payload_size];
    body.extend_from_slice(&data);
    write!(body, "\r\n--{}--\r\n", boundary).unwrap();

    let start = Instant::now();
    let req = test::TestRequest::post()
        .uri("/")
        .insert_header(("content-type", format!("multipart/form-data; boundary={}", boundary)))
        .set_payload(body)
        .to_request();

    let resp = test::call_service(&app, req).await;
    let duration = start.elapsed();

    assert!(resp.status().is_success());
    println!("Upload of {}MB took {:?}", payload_size / (1024 * 1024), duration);
}
