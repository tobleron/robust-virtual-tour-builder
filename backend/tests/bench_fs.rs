use std::fs;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::oneshot;

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn bench_fs_performance() {
    let temp_dir = tempfile::tempdir().unwrap();
    let base_dir = temp_dir.path().to_path_buf();
    let base_dir_async = base_dir.join("async");
    let base_dir_bad = base_dir.join("bad");

    fs::create_dir_all(&base_dir_async).unwrap();
    fs::create_dir_all(&base_dir_bad).unwrap();

    let iterations = 1000;
    let base_dir_async = Arc::new(base_dir_async);
    let base_dir_bad = Arc::new(base_dir_bad);

    // Function to measure max latency of the runtime
    async fn measure_latency(stop_rx: oneshot::Receiver<()>) -> Duration {
        let mut max_latency = Duration::ZERO;
        let mut interval = tokio::time::interval(Duration::from_millis(1));
        interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);

        let mut stop_rx = stop_rx;

        loop {
            tokio::select! {
                _ = interval.tick() => {
                     let start = Instant::now();
                     // Yield to allow other tasks to run.
                     // If threads are blocked by fs calls, this will take a long time to return.
                     tokio::task::yield_now().await;
                     let elapsed = start.elapsed();
                     if elapsed > max_latency {
                         max_latency = elapsed;
                     }
                }
                _ = &mut stop_rx => {
                    break;
                }
            }
        }
        max_latency
    }

    // 1. Benchmark Bad Blocking
    let (stop_tx, stop_rx) = oneshot::channel();
    let monitor = tokio::spawn(measure_latency(stop_rx));

    let start_bad = Instant::now();
    let mut handles = Vec::new();
    for i in 0..iterations {
        let dir = base_dir_bad.clone();
        handles.push(tokio::spawn(async move {
            let path = dir.join(format!("dir_{}", i));
            // BAD: Blocking call in async context
            fs::create_dir_all(&path).unwrap();
            fs::remove_dir_all(&path).unwrap();
        }));
    }
    for handle in handles {
        handle.await.unwrap();
    }
    let _ = stop_tx.send(());
    let latency_bad = monitor.await.unwrap();
    let duration_bad = start_bad.elapsed();


    // 2. Benchmark Good Async
    let (stop_tx, stop_rx) = oneshot::channel();
    let monitor = tokio::spawn(measure_latency(stop_rx));

    let start_async = Instant::now();
    let mut handles = Vec::new();
    for i in 0..iterations {
        let dir = base_dir_async.clone();
        handles.push(tokio::spawn(async move {
            let path = dir.join(format!("dir_{}", i));
            // GOOD: Async call
            tokio::fs::create_dir_all(&path).await.unwrap();
            tokio::fs::remove_dir_all(&path).await.unwrap();
        }));
    }
    for handle in handles {
        handle.await.unwrap();
    }
    let _ = stop_tx.send(());
    let latency_async = monitor.await.unwrap();
    let duration_async = start_async.elapsed();

    println!("Blocking Direct (Bad): Duration={:?}, Max Latency={:?}", duration_bad, latency_bad);
    println!("Async (Good):          Duration={:?}, Max Latency={:?}", duration_async, latency_async);

    // TempDir auto cleans up when dropped
}
