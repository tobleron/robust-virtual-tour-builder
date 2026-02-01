use actix_multipart::test::create_form_data_payload_and_headers;
use actix_multipart::Multipart;
use actix_web::web;
use backend::api::project_multipart;
use futures_util::stream::once;
use std::time::Instant;

#[actix_web::test]
async fn bench_extract_file_from_multipart() {
    // 1. Create a large file content (e.g., 50MB)
    let size = 50 * 1024 * 1024;
    let data = vec![0u8; size];

    // 2. Prepare multipart payload
    let (body, headers) = create_form_data_payload_and_headers(
        "file",
        Some("test_large_file.zip".to_string()),
        Some(mime_guess::mime::APPLICATION_OCTET_STREAM),
        web::Bytes::from(data),
    );

    // Create Multipart
    let stream = once(async { Ok::<_, actix_web::error::PayloadError>(body) });
    let multipart = Multipart::new(&headers, stream);

    // 3. Measure time
    let start = Instant::now();
    let result = project_multipart::extract_file_from_multipart(multipart, "zip").await;
    let duration = start.elapsed();

    // 4. Verify result
    assert!(result.is_ok(), "Extraction failed: {:?}", result.err());
    let path = result.unwrap();

    println!("Time taken to extract 50MB: {:.2?}", duration);
    println!("Extracted to: {:?}", path);

    // 5. Cleanup
    let _ = tokio::fs::remove_file(path).await;
}
