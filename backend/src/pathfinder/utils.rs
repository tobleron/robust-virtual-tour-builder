// @efficiency: domain-logic
use super::graph::Scene;
use super::graph_utils::find_scene_index;
use std::collections::HashSet;

/// Follows a chain of "auto-forward" scenes until a non-auto-forward scene is reached.
pub fn follow_auto_forward_chain(
    scenes: &[Scene],
    start_idx: usize,
    visited: &mut HashSet<usize>,
    require_return_link: bool,
) -> Result<usize, String> {
    let mut current_idx = start_idx;
    let mut chain_counter = 0;

    while chain_counter < 10 {
        let scene = scenes.get(current_idx).ok_or_else(|| {
            format!(
                "Pathfinding error: Scene index {} out of bounds",
                current_idx
            )
        })?;

        if !scene.is_auto_forward {
            break;
        }

        visited.insert(current_idx);

        let jump_link = scene.hotspots.iter().find(|h| {
            if require_return_link && !h.is_return_link.unwrap_or(false) {
                return false;
            }
            match find_scene_index(scenes, &h.target) {
                Some(idx) => !visited.contains(&idx),
                None => false,
            }
        });

        if let Some(link) = jump_link {
            current_idx = find_scene_index(scenes, &link.target).ok_or_else(|| {
                format!(
                    "Pathfinding error: Junction scene '{}' not found",
                    link.target
                )
            })?;
        } else {
            break;
        }
        chain_counter += 1;
    }
    Ok(current_idx)
}
