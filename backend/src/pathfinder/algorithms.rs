use std::collections::HashSet;
use super::graph::{Scene, Step, TransitionTarget, ArrivalView};
use super::utils::{
    find_scene_index, find_scene_index_by_id, get_hotspot_view, 
    get_arrival_view, get_default_view, follow_auto_forward_chain
};

/// Calculates an exploratory "walk" path through the tour.
///
/// This algorithm attempts to move forward through the tour by following
/// primary links (non-return links) and then backtracks to the start
/// by following return links.
///
/// # Arguments
/// * `scenes` - The list of scenes in the project.
/// * `skip_auto_forward` - If true, compresses the path by skipping auto-forward scenes.
///
/// # Returns
/// A vector of `Step` objects representing the path.
pub fn calculate_walk_path(scenes: Vec<Scene>, skip_auto_forward: bool) -> Result<Vec<Step>, String> {
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
            Some(vf) => ArrivalView { yaw: vf.yaw, pitch: vf.pitch },
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

        let return_link = current_scene.hotspots.iter().find(|h| h.is_return_link.unwrap_or(false));

        if let Some(link) = return_link {
            let mut next_idx = find_scene_index(&scenes, &link.target).unwrap_or(usize::MAX);
            if next_idx == usize::MAX { break; }

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
        path.into_iter().filter(|step| !scenes[step.idx].is_auto_forward).collect()
    } else {
        path
    };

    // Dedupe adjacent
    if final_path.is_empty() { return Ok(Vec::new()); }
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

/// Calculates a guided "timeline" path based on a predefined sequence.
///
/// This algorithm translates a user-defined sequence of hotspots and scenes
/// into a series of camera rotations and navigation steps.
///
/// # Arguments
/// * `scenes` - The list of scenes in the project.
/// * `timeline` - The ordered list of timeline items defining the sequence.
/// * `skip_auto_forward` - If true, compresses the path by skipping auto-forward scenes.
///
/// # Returns
/// A vector of `Step` objects representing the path.
pub fn calculate_timeline_path(scenes: Vec<Scene>, timeline: Vec<super::graph::TimelineItem>, skip_auto_forward: bool) -> Result<Vec<Step>, String> {
    let mut path: Vec<Step> = Vec::new();

    for item in timeline {
        let start_idx_opt = find_scene_index_by_id(&scenes, &item.scene_id);
        if let Some(start_scene_idx) = start_idx_opt {
            let scene = &scenes[start_scene_idx];

            if !(skip_auto_forward && scene.is_auto_forward) {
                let hotspot = if !item.link_id.is_empty() {
                    scene.hotspots.iter().find(|h| h.link_id.as_deref() == Some(&item.link_id))
                } else {
                    scene.hotspots.iter().find(|h| h.target == item.target_scene)
                };

                let (trans_yaw, trans_pitch) = match hotspot {
                    Some(h) => get_hotspot_view(h),
                    None => (0.0, 0.0),
                };

                let mut push_new = true;
                if let Some(last) = path.last_mut() {
                    if last.idx == start_scene_idx && last.transition_target.is_none() {
                        last.transition_target = Some(TransitionTarget {
                            yaw: trans_yaw,
                            pitch: trans_pitch,
                            target_name: item.target_scene.clone(),
                            timeline_item_id: Some(item.id.clone()),
                        });
                        push_new = false;
                    }
                }

                if push_new {
                    path.push(Step {
                        idx: start_scene_idx,
                        transition_target: Some(TransitionTarget {
                            yaw: trans_yaw,
                            pitch: trans_pitch,
                            target_name: item.target_scene.clone(),
                            timeline_item_id: Some(item.id.clone()),
                        }),
                        arrival_view: get_default_view(),
                    });
                }

                // Arrival
                let target_idx_opt = find_scene_index(&scenes, &item.target_scene);
                let mut arrival_view = get_default_view();

                if let Some(mut target_idx) = target_idx_opt {
                    if let Some(h) = hotspot {
                        if let (Some(ty), Some(tp)) = (h.target_yaw, h.target_pitch) {
                            arrival_view = ArrivalView { yaw: ty, pitch: tp };
                        }
                    }

                    if skip_auto_forward {
                        let mut local_visited = HashSet::new(); // Local visited for this chain only
                        let original_target = target_idx;
                        target_idx = follow_auto_forward_chain(&scenes, target_idx, &mut local_visited, false)?;
                        
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
    }

    // Cleanup
    let final_path = if skip_auto_forward {
        path.into_iter().filter(|step| !scenes[step.idx].is_auto_forward).collect::<Vec<_>>()
    } else {
        path
    };

    // Dedupe
    if final_path.is_empty() { return Ok(Vec::new()); }
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
