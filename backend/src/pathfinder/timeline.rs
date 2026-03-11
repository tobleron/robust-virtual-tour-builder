// @efficiency-role: domain-logic
use std::collections::HashSet;

use super::graph::{ArrivalView, Hotspot, Scene, Step, TimelineItem, TransitionTarget};
use super::utils::{
    dedupe_path, find_scene_index, find_scene_index_by_id, follow_auto_forward_chain,
    get_default_view, get_hotspot_view,
};

fn find_timeline_hotspot<'a>(scene: &'a Scene, item: &TimelineItem) -> Option<&'a Hotspot> {
    if !item.link_id.is_empty() {
        scene
            .hotspots
            .iter()
            .find(|h| h.link_id.as_deref() == Some(item.link_id.as_str()))
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
