use std::collections::{HashMap, HashSet};

pub struct DependencyGraph {
    // Map from File Path -> List of Imported File Paths (simplified)
    pub adj: HashMap<String, Vec<String>>,
}

impl DependencyGraph {
    pub fn new() -> Self {
        Self {
            adj: HashMap::new(),
        }
    }

    pub fn add_dependency(&mut self, from: &str, to: &str) {
        self.adj
            .entry(from.to_string())
            .or_default()
            .push(to.to_string());
    }

    /// Detects cycles using simple DFS
    #[allow(dead_code)]
    pub fn detect_cycles(&self) -> Vec<Vec<String>> {
        let mut cycles = Vec::new();
        let mut visited = HashSet::new();
        let mut recursion_stack = HashSet::new();

        for node in self.adj.keys() {
            if !visited.contains(node) {
                let mut path = Vec::new();
                self.dfs(
                    node,
                    &mut visited,
                    &mut recursion_stack,
                    &mut path,
                    &mut cycles,
                );
            }
        }
        cycles
    }

    #[allow(dead_code)]
    fn dfs(
        &self,
        node: &str,
        visited: &mut HashSet<String>,
        stack: &mut HashSet<String>,
        path: &mut Vec<String>,
        cycles: &mut Vec<Vec<String>>,
    ) {
        visited.insert(node.to_string());
        stack.insert(node.to_string());
        path.push(node.to_string());

        if let Some(neighbors) = self.adj.get(node) {
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    self.dfs(neighbor, visited, stack, path, cycles);
                } else if stack.contains(neighbor) {
                    // Cycle detected!
                    // Extract the cycle from the path
                    if let Some(pos) = path.iter().position(|x| x == neighbor) {
                        cycles.push(path[pos..].to_vec());
                    }
                }
            }
        }

        stack.remove(node);
        path.pop();
    }

    /// Finds all unreachable nodes given a set of entry points
    pub fn find_dead_code(
        &self,
        all_files: &HashSet<String>,
        entry_points: &HashSet<String>,
    ) -> Vec<String> {
        let mut visited = HashSet::new();
        let mut queue = Vec::new();

        for entry in entry_points {
            if all_files.contains(entry) {
                queue.push(entry.clone());
                visited.insert(entry.clone());
            } else {
                println!("DEBUG: Entry point NOT FOUND in registry: {}", entry);
            }
        }

        while let Some(node) = queue.pop() {
            if let Some(neighbors) = self.adj.get(&node) {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) && all_files.contains(neighbor) {
                        visited.insert(neighbor.clone());
                        queue.push(neighbor.clone());
                    }
                }
            }
        }

        all_files.difference(&visited).cloned().collect()
    }
}
