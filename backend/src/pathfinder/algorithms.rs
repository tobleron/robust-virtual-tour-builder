// @efficiency-role: domain-logic
use super::graph::{
    ArrivalView, Hotspot, PathRequest, Scene, Step, TimelineItem, TransitionTarget,
};
use std::collections::HashSet;

// --- UTILS ---

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

fn dedupe_path(path: Vec<Step>) -> Vec<Step> {
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

// --- ALGORITHMS ---

fn find_timeline_hotspot<'a>(
    scene: &'a Scene,
    item: &TimelineItem,
) -> Option<&'a Hotspot> {
    if !item.link_id.is_empty() {
        scene
            .hotspots
            .iter()
            .find(|h| h.link_id.as_deref() == Some(&item.link_id))
    } else {
        scene
            .hotspots
            .iter()
            .find(|h| h.target == item.target_scene)
    }
}

fn append_transition_step(
    path: &mut Vec<Step>,
    start_scene_idx: usize,
    hotspot: Option<&Hotspot>,
    item: &TimelineItem,
) {
    let (trans_yaw, trans_pitch) = match hotspot {
        Some(h) => get_hotspot_view(h),
        None => (0.0, 0.0),
    };

    let transition = TransitionTarget {
        yaw: trans_yaw,
        pitch: trans_pitch,
        target_name: item.target_scene.clone(),
        timeline_item_id: Some(item.id.clone()),
    };

    if let Some(last) = path.last_mut() {
        if last.idx == start_scene_idx && last.transition_target.is_none() {
            last.transition_target = Some(transition);
            return;
        }
    }

    path.push(Step {
        idx: start_scene_idx,
        transition_target: Some(transition),
        arrival_view: get_default_view(),
    });
}

fn process_timeline_item(
    scenes: &[Scene],
    item: &TimelineItem,
    skip_auto_forward: bool,
    path: &mut Vec<Step>,
) -> Result<(), String> {
    let start_idx_opt = find_scene_index_by_id(scenes, &item.scene_id);
    if let Some(start_scene_idx) = start_idx_opt {
        let scene = &scenes[start_scene_idx];

        if !(skip_auto_forward && scene.is_auto_forward) {
            let hotspot = find_timeline_hotspot(scene, item);

            append_transition_step(path, start_scene_idx, hotspot, item);

            // Arrival
            let target_idx_opt = find_scene_index(scenes, &item.target_scene);
            let mut arrival_view = get_default_view();

            if let Some(mut target_idx) = target_idx_opt {
                if let Some(h) = hotspot {
                    if let (Some(ty), Some(tp)) = (h.target_yaw, h.target_pitch) {
                        arrival_view = ArrivalView {
                            yaw: ty,
                            pitch: tp,
                            hfov: None,
                        };
                    }
                }

                if skip_auto_forward {
                    let mut local_visited = HashSet::new(); // Local visited for this chain only
                    let original_target = target_idx;
                    target_idx =
                        follow_auto_forward_chain(scenes, target_idx, &mut local_visited, false)?;

                    if target_idx != original_target {
                        arrival_view = get_default_view();
                    }
                }

                path.push(Step {
                    idx: target_idx,
                    transition_target: None,
                    arrival_view,
                });
            }
        }
    }
    Ok(())
}

/// Calculates a guided "timeline" path based on a predefined sequence.
pub fn calculate_timeline_path(
    scenes: Vec<Scene>,
    timeline: Vec<TimelineItem>,
    skip_auto_forward: bool,
) -> Result<Vec<Step>, String> {
    let mut path: Vec<Step> = Vec::new();

    for item in timeline {
        process_timeline_item(&scenes, &item, skip_auto_forward, &mut path)?;
    }

    // Cleanup
    let final_path = if skip_auto_forward {
        path.into_iter()
            .filter(|step| !scenes[step.idx].is_auto_forward)
            .collect::<Vec<_>>()
    } else {
        path
    };

    Ok(dedupe_path(final_path))
}

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

pub fn calculate_path(request: PathRequest) -> Result<Vec<Step>, String> {
    match request {
        PathRequest::Walk {
            scenes,
            skip_auto_forward,
        } => calculate_walk_path(scenes, skip_auto_forward),
        PathRequest::Timeline {
            scenes,
            timeline,
            skip_auto_forward,
        } => calculate_timeline_path(scenes, timeline, skip_auto_forward),
    }
}
