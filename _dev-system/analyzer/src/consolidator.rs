pub struct FolderStats {
    pub file_count: usize,
    pub avg_loc: usize,
}

pub fn calculate_merge_score(stats: FolderStats) -> f64 {
    if stats.file_count < 2 { return 0.0; }
    (stats.file_count as f64 * 10.0) / (stats.avg_loc as f64 + 1.0)
}
