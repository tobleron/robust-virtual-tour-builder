use std::time::{Duration, Instant};
use tokio::io::AsyncReadExt;
use futures_util::FutureExt;

#[tokio::test]
async fn test_blocking_vs_async_io() {
    let file_path = "test_large_file.dat";
    let size = 50 * 1024 * 1024; // 50MB
    {
        use std::io::Write;
        let mut file = std::fs::File::create(file_path).unwrap();
        let data = vec![0u8; size];
        file.write_all(&data).unwrap();
    }

    // --- TEST 1: Blocking Read ---
    let start_signal = std::sync::Arc::new(tokio::sync::Notify::new());
    let stop_signal = std::sync::Arc::new(tokio::sync::Notify::new());
    let (started_tx, started_rx) = tokio::sync::oneshot::channel();

    let start_clone = start_signal.clone();
    let stop_clone = stop_signal.clone();

    let monitor = tokio::spawn(async move {
        start_clone.notified().await;
        let _ = started_tx.send(());
        let mut max_gap = Duration::from_micros(0);
        let mut last_tick = Instant::now();

        loop {
            if stop_clone.notified().now_or_never().is_some() {
                break;
            }
            tokio::time::sleep(Duration::from_millis(1)).await;
            let now = Instant::now();
            let gap = now.duration_since(last_tick);
            if gap > max_gap {
                max_gap = gap;
            }
            last_tick = now;
        }
        max_gap
    });

    start_signal.notify_one();
    started_rx.await.unwrap();
    // Perform Blocking I/O
    let _ = std::fs::read(file_path).unwrap();
    stop_signal.notify_one();

    let max_gap_blocking = monitor.await.unwrap();
    println!("Max gap during blocking read: {:?}", max_gap_blocking);

    // --- TEST 2: Async Read ---
    let start_signal = std::sync::Arc::new(tokio::sync::Notify::new());
    let stop_signal = std::sync::Arc::new(tokio::sync::Notify::new());
    let (started_tx, started_rx) = tokio::sync::oneshot::channel();
    let start_clone = start_signal.clone();
    let stop_clone = stop_signal.clone();

    let monitor = tokio::spawn(async move {
        start_clone.notified().await;
        let _ = started_tx.send(());
        let mut max_gap = Duration::from_micros(0);
        let mut last_tick = Instant::now();

        loop {
            if stop_clone.notified().now_or_never().is_some() {
                break;
            }
            tokio::time::sleep(Duration::from_millis(1)).await;
            let now = Instant::now();
            let gap = now.duration_since(last_tick);
            if gap > max_gap {
                max_gap = gap;
            }
            last_tick = now;
        }
        max_gap
    });

    start_signal.notify_one();
    started_rx.await.unwrap();
    // Perform Async I/O
    let mut file = tokio::fs::File::open(file_path).await.unwrap();
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer).await.unwrap();
    stop_signal.notify_one();

    let max_gap_async = monitor.await.unwrap();
    println!("Max gap during async read: {:?}", max_gap_async);

    // Cleanup
    let _ = std::fs::remove_file(file_path);

    // Verify improvement
    // Blocking read should block the single thread for the entire duration of the read.
    // Async read should allow the monitor to tick (gap should be small, around sleep duration).

    // Note: 50MB might be too fast on some SSDs to cause massive blocking, but it should be measurable.
    assert!(max_gap_blocking > Duration::from_millis(5), "Blocking read gap too small: {:?}", max_gap_blocking);

    // Ideally async gap is small (1-2ms), but let's be generous for CI environments
    assert!(max_gap_async < Duration::from_millis(20), "Async read gap too large: {:?}", max_gap_async);

    assert!(max_gap_blocking > max_gap_async, "Blocking should be worse than async");
}
