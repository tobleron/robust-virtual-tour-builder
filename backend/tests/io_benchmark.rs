use std::time::{Duration, Instant};
use tokio::time::sleep;

// This benchmark demonstrates how blocking IO halts the async runtime
// compared to async IO which allows other tasks to progress.

async fn monitor_task(stop_signal: tokio::sync::mpsc::Receiver<()>) -> u64 {
    let mut ticks = 0;
    let mut rx = stop_signal;
    loop {
        tokio::select! {
            _ = rx.recv() => break,
            _ = sleep(Duration::from_millis(1)) => {
                ticks += 1;
            }
        }
    }
    ticks
}

#[tokio::test(flavor = "current_thread")]
async fn benchmark_blocking_vs_async_io() {
    let file_path = "large_test_file.bin";
    let size_mb = 100; // 100MB file to ensure noticeable read time

    // Create a large file using blocking IO (setup)
    {
        use std::io::Write;
        let mut file = std::fs::File::create(file_path).unwrap();
        let chunk = vec![0u8; 1024 * 1024]; // 1MB chunk
        for _ in 0..size_mb {
            file.write_all(&chunk).unwrap();
        }
        file.sync_all().unwrap();
    }

    println!("Created {}MB test file", size_mb);

    // --- CASE 1: BLOCKING IO ---
    let (tx, rx) = tokio::sync::mpsc::channel(1);
    let monitor = tokio::spawn(monitor_task(rx));

    let start = Instant::now();

    // Simulate what happens in save_project currently:
    // This blocks the CURRENT thread. Since tokio test runtime might be single-threaded
    // or multi-threaded, the impact depends. But actix-web handlers run on worker threads.
    // If we block a worker, we block other futures on that worker.
    let _data = std::fs::read(file_path).unwrap();

    let duration_blocking = start.elapsed();
    tx.send(()).await.unwrap();
    let ticks_blocking = monitor.await.unwrap();

    println!(
        "Blocking IO duration: {:?}, Monitor ticks: {}",
        duration_blocking, ticks_blocking
    );

    // --- CASE 2: ASYNC IO ---
    let (tx, rx) = tokio::sync::mpsc::channel(1);
    let monitor = tokio::spawn(monitor_task(rx));

    let start = Instant::now();

    // This should yield to the runtime, allowing monitor to tick
    let _data = tokio::fs::read(file_path).await.unwrap();

    let duration_async = start.elapsed();
    tx.send(()).await.unwrap();
    let ticks_async = monitor.await.unwrap();

    println!(
        "Async IO duration: {:?}, Monitor ticks: {}",
        duration_async, ticks_async
    );

    // Cleanup
    let _ = std::fs::remove_file(file_path);

    // Assertions
    // In a single-threaded runtime, ticks_blocking should be 0 or very close to 0.
    // In a multi-threaded runtime, it might still tick if monitor is on another thread,
    // but we want to show that async allows MORE ticks or AT LEAST works.
    // Since unit tests often run on a basic scheduler or multi-thread scheduler,
    // we expect async to have significantly more ticks relative to duration.

    let ticks_per_sec_blocking = (ticks_blocking as f64) / duration_blocking.as_secs_f64();
    let ticks_per_sec_async = (ticks_async as f64) / duration_async.as_secs_f64();

    println!("Ticks/sec Blocking: {:.2}", ticks_per_sec_blocking);
    println!("Ticks/sec Async:    {:.2}", ticks_per_sec_async);

    // Async should be much more responsive (more ticks per second of execution)
    // Note: If the file read is too fast, the difference might be small.
    // But for 100MB it should be clear.

    assert!(
        ticks_per_sec_async > ticks_per_sec_blocking * 1.5,
        "Async IO should be significantly more responsive"
    );
}
