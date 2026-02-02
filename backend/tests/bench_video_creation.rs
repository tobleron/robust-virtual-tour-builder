use actix_multipart::Multipart;
use actix_web::http::header::{self, HeaderMap};
use backend::api::media::video;
use bytes::Bytes;
use futures_util::stream;
use std::time::{Duration, Instant};
use tokio::time::sleep;

#[actix_web::test]
async fn bench_video_creation_lag() {
    // Monitor task to measure event loop lag
    let start = Instant::now();
    let monitor_handle = tokio::spawn(async move {
        let mut max_lag = Duration::from_micros(0);
        while start.elapsed() < Duration::from_secs(2) {
            let before = Instant::now();
            sleep(Duration::from_millis(10)).await;
            let elapsed = before.elapsed();

            // We expect sleep(10ms) to take roughly 10ms + small overhead.
            // If it takes significantly longer, the thread was blocked.
            let lag = elapsed.saturating_sub(Duration::from_millis(10));
            if lag > max_lag {
                max_lag = lag;
            }
        }
        max_lag
    });

    // Spawn concurrent requests
    let mut handles = vec![];
    for _ in 0..100 {
        handles.push(actix_web::rt::spawn(async {
            // Construct dummy multipart with empty body
            let mut headers = HeaderMap::new();
            headers.insert(
                header::CONTENT_TYPE,
                "multipart/form-data; boundary=boundary".parse().unwrap(),
            );

            let stream = stream::once(async {
                Ok::<_, actix_web::error::PayloadError>(Bytes::from("--boundary--"))
            });

            let multipart = Multipart::new(&headers, stream);

            // Call the handler. It will fail later due to missing fields,
            // but it executes the blocking create_dir_all first.
            let _ = video::generate_teaser(multipart).await;
        }));
    }

    // Wait for all requests to finish (or fail)
    for h in handles {
        let _ = h.await;
    }

    // Wait for monitor
    let max_lag = monitor_handle.await.unwrap();
    println!("BENCHMARK_RESULT: Max event loop lag: {:?}", max_lag);
}
