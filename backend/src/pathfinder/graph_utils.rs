// @efficiency: util-pure
use super::graph::Scene;

pub fn find_scene_index(scenes: &[Scene], name: &str) -> Option<usize> {
    scenes.iter().position(|s| s.name == name)
}

pub fn find_scene_index_by_id(scenes: &[Scene], id: &str) -> Option<usize> {
    scenes.iter().position(|s| s.id == id)
}
