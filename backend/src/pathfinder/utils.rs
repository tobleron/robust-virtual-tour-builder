// @efficiency-role: util-pure
use super::graph::{ArrivalView, Hotspot, Scene, Step};

use std::collections::HashSet;

pub fn find_scene_index(scenes: &[Scene], name: &str) -> Option<usize> {
    scenes.iter().position(|s| s.name == name)
}

pub fn find_scene_index_by_id(scenes: &[Scene], id: &str) -> Option<usize> {
    scenes.iter().position(|s| s.id == id)
}

pub fn get_hotspot_view(hotspot: &Hotspot) -> (f32, f32) {
    match &hotspot.view_frame {
        Some(vf) => (vf.yaw, vf.pitch),
        None => (hotspot.yaw, hotspot.pitch),
    }
}

pub fn get_arrival_view(hotspot: &Hotspot) -> ArrivalView {
    match &hotspot.view_frame {
        Some(vf) => ArrivalView {
            yaw: vf.yaw,
            pitch: vf.pitch,
            hfov: Some(vf.hfov),
        },
        None => ArrivalView {
            yaw: hotspot.target_yaw.unwrap_or(0.0),
            pitch: hotspot.target_pitch.unwrap_or(0.0),
            hfov: None,
        },
    }
}

pub fn get_default_view() -> ArrivalView {
    ArrivalView {
        yaw: 0.0,
        pitch: 0.0,
        hfov: None,
    }
}

pub fn dedupe_path(path: Vec<Step>) -> Vec<Step> {
    if path.is_empty() {
        return Vec::new();
    }
    let mut deduped = Vec::with_capacity(path.len());
    let mut last_idx = None;
    for step in path {
        if Some(step.idx) != last_idx {
            last_idx = Some(step.idx);
            deduped.push(step);
        }
    }
    deduped
}

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
