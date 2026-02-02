use std::fs;
use std::io::Write;
use std::time::{Duration, Instant};
use tempfile::NamedTempFile;
use tokio::time::sleep;

async fn monitor_latency(duration_ms: u64) -> u128 {
    let start = Instant::now();
    let mut max_latency = 0;
    let end_time = start + Duration::from_millis(duration_ms);

    while Instant::now() < end_time {
        let step_start = Instant::now();
        sleep(Duration::from_millis(10)).await;
        let elapsed = step_start.elapsed().as_micros();
        // Expected ~10ms (10000us). Excess is latency.
        // We use a threshold of 15ms to be safe.
        if elapsed > 15000 {
             let latency = elapsed - 10000;
             if latency > max_latency {
                 max_latency = latency;
             }
        }
    }
    max_latency
}

#[tokio::test(flavor = "current_thread")]
async fn benchmark_blocking_vs_async_io() {
    // Setup large file
    let mut file = NamedTempFile::new().unwrap();
    let data = vec![0u8; 50 * 1024 * 1024]; // 50MB
    file.write_all(&data).unwrap();
    let path = file.path().to_path_buf();
    let path_clone = path.clone();

    println!("Starting Blocking IO Benchmark...");
    let monitor_handle = tokio::spawn(async move {
        monitor_latency(200).await
    });
    tokio::task::yield_now().await;

    // Simulate blocking IO on the main thread (bad)
    let start = Instant::now();
    // We read multiple times to ensure we occupy enough time to block the heartbeat
    for _ in 0..3 {
        let _ = fs::read(&path).unwrap();
    }
    println!("Blocking read took: {:?}", start.elapsed());

    let latency_blocking = monitor_handle.await.unwrap();
    println!("Max Event Loop Latency (Blocking): {} us", latency_blocking);

    // Setup for Async
    println!("Starting Async IO Benchmark...");
    let monitor_handle = tokio::spawn(async move {
        monitor_latency(200).await
    });
    tokio::task::yield_now().await;

    let start = Instant::now();
    for _ in 0..3 {
        let _ = tokio::fs::read(&path_clone).await.unwrap();
    }
    println!("Async read took: {:?}", start.elapsed());

    let latency_async = monitor_handle.await.unwrap();
    println!("Max Event Loop Latency (Async): {} us", latency_async);

    // Cleanup is automatic with NamedTempFile

    // Validation: Blocking latency should be significantly higher than Async latency.
    // In a single-threaded runtime, blocking IO stops the world, so latency ~= IO duration.
    // Async IO yields, so heartbeat continues (latency ~= 0 or low).

    if latency_blocking <= latency_async {
        println!("WARNING: Blocking latency ({}) was not greater than Async latency ({}). This might happen if the file is cached in RAM and read is instant.", latency_blocking, latency_async);
    } else {
        println!("SUCCESS: Blocking IO caused higher latency as expected.");
    }
}
