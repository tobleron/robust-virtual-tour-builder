pub struct FolderStats {
    pub file_count: usize,
    pub total_loc: usize,
}

/// AI-Efficiency Merge Score
/// Merging is good if the combined context fits comfortably in an agent's context window (~800 LOC target).
/// Every separate file has a 500-token "Read Tax".
pub fn calculate_merge_score(stats: FolderStats, hard_ceiling: usize) -> f64 {
    if stats.file_count < 2 {
        return 0.0;
    }

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
        let stats_small = FolderStats {
            file_count: 5,
            total_loc: 400,
        };
        assert!(calculate_merge_score(stats_small, ceiling) > 0.0);

        // Case 2: Large folder > 1.1 * ceiling, should be 0
        let stats_huge = FolderStats {
            file_count: 5,
            total_loc: 1000,
        };
        assert_eq!(calculate_merge_score(stats_huge, ceiling), 0.0);

        // Case 3: Borderline, might pass
        let stats_border = FolderStats {
            file_count: 5,
            total_loc: 850,
        };
        assert!(calculate_merge_score(stats_border, ceiling) > 0.0);
    }
}

pub struct FileInfo {
    pub path: String,
    pub loc: usize,
    pub drag: f64,
}

pub struct Cluster {
    pub root_folder: String,
    pub files: Vec<String>,
    pub total_loc: usize,
    pub max_drag: f64,
}

use std::collections::HashMap;

struct DirNode {
    files: Vec<(String, f64)>, // Path, Drag
    loc: usize,
    children: HashMap<String, DirNode>,
}

impl DirNode {
    fn new() -> Self {
        Self {
            files: Vec::new(),
            loc: 0,
            children: HashMap::new(),
        }
    }

    fn insert(&mut self, path_parts: &[&str], full_path: String, loc: usize, drag: f64) {
        if path_parts.is_empty() {
            self.files.push((full_path, drag));
            self.loc += loc;
            return;
        }

        self.children
            .entry(path_parts[0].to_string())
            .or_insert_with(DirNode::new)
            .insert(&path_parts[1..], full_path, loc, drag);
    }
}

pub fn find_recursive_clusters(files: Vec<FileInfo>, max_loc: usize) -> Vec<Cluster> {
    let mut root = DirNode::new();

    // Build Trie
    for file in files {
        let p = file.path.replace("\\", "/");
        let clean = p.replace("../../", "");
        let clean_parts: Vec<&str> = clean.split('/').collect();

        // We use full path for storage, cleaned parts for structure
        root.insert(
            &clean_parts[..clean_parts.len() - 1],
            file.path,
            file.loc,
            file.drag,
        );
    }

    let mut clusters = Vec::new();
    let (_, _, _, top_cluster) = scan_node(&root, String::new(), max_loc, &mut clusters);
    if let Some(c) = top_cluster {
        clusters.push(c);
    }
    clusters
}

// Returns: (Total LOC, All Files, Max Drag, Candidate Cluster)
fn scan_node(
    node: &DirNode,
    current_path: String,
    max_loc: usize,
    final_clusters: &mut Vec<Cluster>,
) -> (usize, Vec<(String, f64)>, f64, Option<Cluster>) {
    let mut total_loc = node.loc;
    let mut all_files = node.files.clone();
    let mut max_drag: f64 = node.files.iter().map(|(_, d)| *d).fold(0.0, f64::max);
    let mut child_candidates: Vec<Cluster> = Vec::new();

    for (name, child) in &node.children {
        let child_path = if current_path.is_empty() {
            name.clone()
        } else {
            format!("{}/{}", current_path, name)
        };
        let (c_loc, c_files, c_drag, c_cluster) =
            scan_node(child, child_path, max_loc, final_clusters);

        total_loc += c_loc;
        all_files.extend(c_files);
        if c_drag > max_drag {
            max_drag = c_drag;
        }

        if let Some(c) = c_cluster {
            child_candidates.push(c);
        }
    }

    // Logic: Greedy Clustering (Merge highest possible node)
    if total_loc <= max_loc && all_files.len() > 1 {
        // I supersede all child candidates. They are swallowed.
        return (
            total_loc,
            all_files.clone(),
            max_drag,
            Some(Cluster {
                root_folder: current_path,
                files: all_files.into_iter().map(|(p, _)| p).collect(),
                total_loc,
                max_drag,
            }),
        );
    } else {
        // I am too big to be a cluster myself.
        // Commit child candidates to final list.
        for c in child_candidates {
            final_clusters.push(c);
        }
        return (total_loc, all_files, max_drag, None);
    }
}
