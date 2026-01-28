// @efficiency: domain-logic
use super::super::graph::{ArrivalView, Scene, Step, TransitionTarget};
use super::super::graph_utils::{find_scene_index, find_scene_index_by_id};
use super::super::utils::follow_auto_forward_chain;
use super::super::view_utils::{get_default_view, get_hotspot_view};
use std::collections::HashSet;

/// Calculates a guided "timeline" path based on a predefined sequence.
pub fn calculate_timeline_path(
    scenes: Vec<Scene>,
    timeline: Vec<super::super::graph::TimelineItem>,
    skip_auto_forward: bool,
) -> Result<Vec<Step>, String> {
    let mut path: Vec<Step> = Vec::new();

    for item in timeline {
        let start_idx_opt = find_scene_index_by_id(&scenes, &item.scene_id);
        if let Some(start_scene_idx) = start_idx_opt {
            let scene = &scenes[start_scene_idx];

            if !(skip_auto_forward && scene.is_auto_forward) {
                let hotspot = if !item.link_id.is_empty() {
                    scene
                        .hotspots
                        .iter()
                        .find(|h| h.link_id.as_deref() == Some(&item.link_id))
                } else {
                    scene
                        .hotspots
                        .iter()
                        .find(|h| h.target == item.target_scene)
                };

                let (trans_yaw, trans_pitch) = match hotspot {
                    Some(h) => get_hotspot_view(h),
                    None => (0.0, 0.0),
                };

                let mut push_new = true;
                if let Some(last) = path.last_mut()
                    && last.idx == start_scene_idx
                    && last.transition_target.is_none()
                {
                    last.transition_target = Some(TransitionTarget {
                        yaw: trans_yaw,
                        pitch: trans_pitch,
                        target_name: item.target_scene.clone(),
                        timeline_item_id: Some(item.id.clone()),
                    });
                    push_new = false;
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
                    if let Some(h) = hotspot
                        && let (Some(ty), Some(tp)) = (h.target_yaw, h.target_pitch)
                    {
                        arrival_view = ArrivalView { yaw: ty, pitch: tp };
                    }

                    if skip_auto_forward {
                        let mut local_visited = HashSet::new(); // Local visited for this chain only
                        let original_target = target_idx;
                        target_idx = follow_auto_forward_chain(
                            &scenes,
                            target_idx,
                            &mut local_visited,
                            false,
                        )?;

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
        path.into_iter()
            .filter(|step| !scenes[step.idx].is_auto_forward)
            .collect::<Vec<_>>()
    } else {
        path
    };

    // Dedupe
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
