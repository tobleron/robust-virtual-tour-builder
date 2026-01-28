// @efficiency: domain-logic
use super::super::graph::{ArrivalView, Scene, Step, TransitionTarget};
use super::super::graph_utils::find_scene_index;
use super::super::utils::follow_auto_forward_chain;
use super::super::view_utils::{get_arrival_view, get_default_view, get_hotspot_view};
use std::collections::HashSet;

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
    let mut forward_steps = 0;
    while forward_steps < 12 {
        forward_steps += 1;
        let current_scene = &scenes[current_idx];

        // Find forward link
        let forward_link = current_scene.hotspots.iter().find(|h| {
            if h.is_return_link.unwrap_or(false) {
                false
            } else {
                match find_scene_index(&scenes, &h.target) {
                    Some(idx) => !visited.contains(&idx),
                    None => false,
                }
            }
        });

        if let Some(link) = forward_link {
            let mut next_idx = find_scene_index(&scenes, &link.target)
                .ok_or_else(|| format!("Pathfinding error: Scene '{}' not found", link.target))?;

            // Update previous step transition target
            if let Some(last_step) = path.last_mut() {
                let (trans_yaw, trans_pitch) = get_hotspot_view(link);
                last_step.transition_target = Some(TransitionTarget {
                    yaw: trans_yaw,
                    pitch: trans_pitch,
                    target_name: link.target.clone(),
                    timeline_item_id: None,
                });
            }

            let original_target_idx = next_idx;

            // Skip Auto Forward
            if skip_auto_forward {
                next_idx = follow_auto_forward_chain(&scenes, next_idx, &mut visited, false)?;
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
            current_idx = next_idx;
        } else {
            break;
        }
    }

    // Phase 2: Return
    let mut return_steps = 0;
    while return_steps < 12 {
        return_steps += 1;
        let current_scene = &scenes[current_idx];

        let return_link = current_scene
            .hotspots
            .iter()
            .find(|h| h.is_return_link.unwrap_or(false));

        if let Some(link) = return_link {
            let mut next_idx = match find_scene_index(&scenes, &link.target) {
                Some(idx) => idx,
                None => break,
            };

            if let Some(last_step) = path.last_mut() {
                let (trans_yaw, trans_pitch) = get_hotspot_view(link);
                last_step.transition_target = Some(TransitionTarget {
                    yaw: trans_yaw,
                    pitch: trans_pitch,
                    target_name: link.target.clone(),
                    timeline_item_id: None,
                });
            }

            let original_target_idx = next_idx;

            if skip_auto_forward {
                let mut local_visited = HashSet::new();
                next_idx = follow_auto_forward_chain(&scenes, next_idx, &mut local_visited, true)?;
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

            current_idx = next_idx;
            if current_idx == 0 {
                break;
            }
        } else {
            break;
        }
    }

    // Cleanup
    let final_path = if skip_auto_forward {
        path.into_iter()
            .filter(|step| !scenes[step.idx].is_auto_forward)
            .collect()
    } else {
        path
    };

    // Dedupe adjacent
    if final_path.is_empty() {
        return Ok(Vec::new());
    }
    let mut deduped = Vec::with_capacity(final_path.len());
    let mut last_idx = None;
    for step in final_path {
        if Some(step.idx) != last_idx {
            last_idx = Some(step.idx);
            deduped.push(step);
        }
    }

    Ok(deduped)
}
