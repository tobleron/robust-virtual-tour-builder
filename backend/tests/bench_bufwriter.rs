use std::time::Instant;
use tokio::fs::File;
use tokio::io::{AsyncWriteExt, BufWriter};

#[tokio::test]
async fn bench_buffered_vs_unbuffered_write() {
    let chunk_size = 4096;
    let chunks_count = 10_000;
    let data = vec![0u8; chunk_size];

    // Unbuffered
    let start = Instant::now();
    let temp_dir = std::env::temp_dir();
    let file_path = temp_dir.join("bench_unbuffered.tmp");
    {
        let mut f = File::create(&file_path).await.unwrap();
        for _ in 0..chunks_count {
            f.write_all(&data).await.unwrap();
        }
        f.flush().await.unwrap();
    }
    let duration_unbuffered = start.elapsed();
    let _ = tokio::fs::remove_file(file_path).await;

    // Buffered
    let start = Instant::now();
    let file_path = temp_dir.join("bench_buffered.tmp");
    {
        let f = File::create(&file_path).await.unwrap();
        let mut writer = BufWriter::new(f);
        for _ in 0..chunks_count {
            writer.write_all(&data).await.unwrap();
        }
        writer.flush().await.unwrap();
    }
    let duration_buffered = start.elapsed();
    let _ = tokio::fs::remove_file(file_path).await;

    println!("Unbuffered write: {:?}", duration_unbuffered);
    println!("Buffered write:   {:?}", duration_buffered);

    // Check improvement
    if duration_buffered < duration_unbuffered {
        let improvement = (duration_unbuffered.as_secs_f64() - duration_buffered.as_secs_f64())
            / duration_unbuffered.as_secs_f64()
            * 100.0;
        println!("Improvement: {:.2}%", improvement);
    } else {
        println!("No improvement (overhead might dominate for this chunk size/count)");
    }
}
