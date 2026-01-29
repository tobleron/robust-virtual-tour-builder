pub struct FolderStats {
    pub file_count: usize,
    pub total_loc: usize,
}

/// AI-Efficiency Merge Score
/// Merging is good if the combined context fits comfortably in an agent's context window (~800 LOC target).
/// Every separate file has a 500-token "Read Tax".
pub fn calculate_merge_score(stats: FolderStats, hard_ceiling: usize) -> f64 {
    if stats.file_count < 2 { return 0.0; }
    
    // Safety Break: If merging creates a file larger than the hard ceiling, do not suggest it.
    // We allow a small margin (1.1x) if it helps reduce massive fragmentation, but generally avoid it.
    if stats.total_loc > (hard_ceiling as f64 * 1.1) as usize {
        return 0.0;
    }

    // Read Tax: tokens / 500 (normalized)
    let total_read_tax = stats.file_count as f64 * 0.5;
    
    // Context Utility: How much can be understood in one shot.
    // If sum < 600, utility is high. If sum > 1500, utility per read is low (too much noise).
    let context_utility = if stats.total_loc < 600 {
        2.0 // HIGH: Everything in one view_file
    } else if stats.total_loc < 1200 {
        1.0 // NORMAL
    } else {
        0.2 // LOW: File is becoming too large to safely edit even if merged
    };

    total_read_tax * context_utility
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_merge_score_respects_ceiling() {
        let ceiling = 800;

        // Case 1: Small folder, should have score
        let stats_small = FolderStats { file_count: 5, total_loc: 400 };
        assert!(calculate_merge_score(stats_small, ceiling) > 0.0);

        // Case 2: Large folder > 1.1 * ceiling, should be 0
        let stats_huge = FolderStats { file_count: 5, total_loc: 1000 };
        assert_eq!(calculate_merge_score(stats_huge, ceiling), 0.0);

        // Case 3: Borderline, might pass
        let stats_border = FolderStats { file_count: 5, total_loc: 850 };
        assert!(calculate_merge_score(stats_border, ceiling) > 0.0);
    }
}
