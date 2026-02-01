use std::time::{Duration, Instant};
use tokio::io::AsyncWriteExt;
use tokio::time::sleep;

const FILE_SIZE: usize = 50 * 1024 * 1024; // 50MB
const CHUNK_SIZE: usize = 8 * 1024; // 8KB

async fn heartbeat_monitor(name: &str, duration: Duration) -> u128 {
    let start = Instant::now();
    let mut max_latency = 0;
    let mut count = 0;

    while start.elapsed() < duration {
        let loop_start = Instant::now();
        // Sleep for 1ms. If the runtime is blocked, this will take much longer.
        sleep(Duration::from_millis(1)).await;
        let elapsed = loop_start.elapsed().as_micros();
        // Expected is ~1,000us. Anything above is delay.
        if elapsed > max_latency {
            max_latency = elapsed;
        }
        count += 1;
    }
    println!("[{}] Max tick duration: {} us ({} ticks)", name, max_latency, count);
    max_latency
}

#[tokio::test]
async fn benchmark_blocking_vs_async_io() {
    let dir = tempfile::tempdir().unwrap();
    let file_path_blocking = dir.path().join("blocking.dat");
    let file_path_async = dir.path().join("async.dat");

    let data = vec![0u8; CHUNK_SIZE];
    let chunks = FILE_SIZE / CHUNK_SIZE;

    println!("Starting Benchmark: Writing {}MB in {} chunks", FILE_SIZE / 1024 / 1024, chunks);

    // --- CASE 1: BLOCKING I/O ---
    // This simulates the "Issue" where std::fs::write is called inside an async handler (on the worker thread).
    println!("\n--- Case 1: Blocking I/O (std::fs) ---");
    let heartbeat = tokio::spawn(heartbeat_monitor("Blocking", Duration::from_secs(1)));

    let path = file_path_blocking.clone();
    let data_clone = data.clone();

    // We spawn this on the current runtime to simulate an Actix handler doing blocking work
    let blocking_task = tokio::spawn(async move {
        let start = Instant::now();
        let mut f = std::fs::File::create(path).unwrap();
        use std::io::Write;
        for i in 0..chunks {
            // This blocks the thread!
            f.write_all(&data_clone).unwrap();
            // In a tight blocking loop (like unoptimized code), there are NO awaits.
            // This completely monopolizes the thread until the loop finishes.
        }
        println!("Blocking Write took: {:?}", start.elapsed());
    });

    let (max_latency_blocking, _) = tokio::join!(heartbeat, blocking_task);
    let max_latency_blocking = max_latency_blocking.unwrap();


    // --- CASE 2: ASYNC I/O ---
    // This simulates the "Fix" where tokio::fs is used.
    println!("\n--- Case 2: Async I/O (tokio::fs) ---");
    let heartbeat = tokio::spawn(heartbeat_monitor("Async", Duration::from_secs(1)));

    let path = file_path_async.clone();
    let data_clone = data.clone();
    let async_task = tokio::spawn(async move {
        let start = Instant::now();
        let f = tokio::fs::File::create(path).await.unwrap();
        let mut writer = tokio::io::BufWriter::new(f);
        for _ in 0..chunks {
            // This yields to the runtime!
            writer.write_all(&data_clone).await.unwrap();
        }
        writer.flush().await.unwrap();
        println!("Async Write took: {:?}", start.elapsed());
    });

    let (max_latency_async, _) = tokio::join!(heartbeat, async_task);
    let max_latency_async = max_latency_async.unwrap();

    println!("\n--- Results ---");
    println!("Blocking Max Tick Duration: {} us", max_latency_blocking);
    println!("Async Max Tick Duration:    {} us", max_latency_async);

    if max_latency_blocking > max_latency_async {
         let improvement = max_latency_blocking as f64 / max_latency_async as f64;
         println!("SUCCESS: Async I/O was {:.2}x more responsive.", improvement);
    } else {
         println!("WARNING: No significant difference observed.");
    }
}
