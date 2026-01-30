use std::collections::HashSet;

use super::graph::{ArrivalView, Hotspot, Scene, Step, TransitionTarget};
use super::utils::{
    dedupe_path, find_scene_index, follow_auto_forward_chain, get_arrival_view, get_default_view,
    get_hotspot_view,
};

fn find_next_link<'a>(
    scenes: &[Scene],
    current_scene: &'a Scene,
    visited: &HashSet<usize>,
    require_return: bool,
) -> Option<&'a Hotspot> {
    current_scene.hotspots.iter().find(|h| {
        if require_return && !h.is_return_link.unwrap_or(false) {
            return false;
        }
        if !require_return && h.is_return_link.unwrap_or(false) {
            return false;
        }
        match find_scene_index(scenes, &h.target) {
            Some(idx) => !visited.contains(&idx),
            None => false,
        }
    })
}

fn update_step_with_link(path: &mut Vec<Step>, link: &Hotspot) {
    if let Some(last_step) = path.last_mut() {
        let (trans_yaw, trans_pitch) = get_hotspot_view(link);
        last_step.transition_target = Some(TransitionTarget {
            yaw: trans_yaw,
            pitch: trans_pitch,
            target_name: link.target.clone(),
            timeline_item_id: None,
        });
    }
}

fn walk_forward_phase(
    scenes: &[Scene],
    path: &mut Vec<Step>,
    visited: &mut HashSet<usize>,
    current_idx: &mut usize,
    skip_auto_forward: bool,
) -> Result<(), String> {
    let mut forward_steps = 0;
    while forward_steps < 12 {
        forward_steps += 1;
        let current_scene = &scenes[*current_idx];

        if let Some(link) = find_next_link(scenes, current_scene, visited, false) {
            let mut next_idx = find_scene_index(scenes, &link.target)
                .ok_or_else(|| format!("Pathfinding error: Scene '{}' not found", link.target))?;

            update_step_with_link(path, link);

            let original_target_idx = next_idx;

            if skip_auto_forward {
                next_idx = follow_auto_forward_chain(scenes, next_idx, visited, false)?;
            }

            let arr_view = if next_idx == original_target_idx {
                get_arrival_view(link)
            } else {
                get_default_view()
            };

            path.push(Step {
                idx: next_idx,
                transition_target: None,
                arrival_view: arr_view,
            });

            visited.insert(next_idx);
            *current_idx = next_idx;
        } else {
            break;
        }
    }
    Ok(())
}

fn walk_return_phase(
    scenes: &[Scene],
    path: &mut Vec<Step>,
    current_idx: &mut usize,
    skip_auto_forward: bool,
) -> Result<(), String> {
    let mut return_steps = 0;
    while return_steps < 12 {
        return_steps += 1;
        let current_scene = &scenes[*current_idx];

        let return_link = current_scene
            .hotspots
            .iter()
            .find(|h| h.is_return_link.unwrap_or(false));

        if let Some(link) = return_link {
            let mut next_idx = match find_scene_index(scenes, &link.target) {
                Some(idx) => idx,
                None => break,
            };

            update_step_with_link(path, link);

            let original_target_idx = next_idx;

            if skip_auto_forward {
                let mut local_visited = HashSet::new();
                next_idx = follow_auto_forward_chain(scenes, next_idx, &mut local_visited, true)?;
            }

            let arr_view = if next_idx == original_target_idx {
                get_arrival_view(link)
            } else {
                get_default_view()
            };

            path.push(Step {
                idx: next_idx,
                transition_target: None,
                arrival_view: arr_view,
            });

            *current_idx = next_idx;
            if *current_idx == 0 {
                break;
            }
        } else {
            break;
        }
    }
    Ok(())
}

/// Calculates an exploratory "walk" path through the tour.
pub fn calculate_walk_path(
    scenes: Vec<Scene>,
    skip_auto_forward: bool,
) -> Result<Vec<Step>, String> {
    if scenes.is_empty() {
        return Ok(Vec::new());
    }

    let mut visited = HashSet::new();
    let mut path: Vec<Step> = Vec::new();
    let mut current_idx = 0;
    visited.insert(0);

    // Initial view
    let initial_view = if !scenes[0].hotspots.is_empty() {
        match &scenes[0].hotspots[0].view_frame {
            Some(vf) => ArrivalView {
                yaw: vf.yaw,
                pitch: vf.pitch,
                hfov: Some(vf.hfov),
            },
            None => get_default_view(),
        }
    } else {
        get_default_view()
    };

    path.push(Step {
        idx: 0,
        transition_target: None,
        arrival_view: initial_view,
    });

    // Phase 1: Forward
    walk_forward_phase(
        &scenes,
        &mut path,
        &mut visited,
        &mut current_idx,
        skip_auto_forward,
    )?;

    // Phase 2: Return
    walk_return_phase(&scenes, &mut path, &mut current_idx, skip_auto_forward)?;

    // Cleanup
    let final_path = if skip_auto_forward {
        path.into_iter()
            .filter(|step| !scenes[step.idx].is_auto_forward)
            .collect()
    } else {
        path
    };

    Ok(dedupe_path(final_path))
}
