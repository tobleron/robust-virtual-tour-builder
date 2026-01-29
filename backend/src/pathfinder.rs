// backend/src/pathfinder.rs

pub mod graph {
    use serde::{Deserialize, Serialize};

    #[derive(Deserialize, Debug, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Hotspot {
        pub link_id: Option<String>,
        pub yaw: f32,
        pub pitch: f32,
        pub target: String,
        pub target_yaw: Option<f32>,
        pub target_pitch: Option<f32>,
        pub is_return_link: Option<bool>,
        pub view_frame: Option<ViewFrame>,
    }

    #[derive(Deserialize, Serialize, Debug, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct ViewFrame {
        pub yaw: f32,
        pub pitch: f32,
        pub hfov: f32,
    }

    #[derive(Deserialize, Debug, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Scene {
        pub id: String,
        pub name: String,
        pub hotspots: Vec<Hotspot>,
        pub is_auto_forward: bool,
    }

    #[derive(Deserialize, Debug, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct TimelineItem {
        pub id: String,
        pub link_id: String,
        pub scene_id: String,
        pub target_scene: String,
    }

    #[derive(Deserialize, Debug)]
    #[serde(tag = "type", rename_all = "lowercase")]
    pub enum PathRequest {
        Walk {
            scenes: Vec<Scene>,
            #[serde(rename = "skipAutoForward")]
            skip_auto_forward: bool,
        },
        Timeline {
            scenes: Vec<Scene>,
            timeline: Vec<TimelineItem>,
            #[serde(rename = "skipAutoForward")]
            skip_auto_forward: bool,
        },
    }

    #[derive(Serialize, Debug, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct TransitionTarget {
        pub yaw: f32,
        pub pitch: f32,
        pub target_name: String,
        pub timeline_item_id: Option<String>,
    }

    #[derive(Serialize, Debug, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct ArrivalView {
        pub yaw: f32,
        pub pitch: f32,
    }

    #[derive(Serialize, Debug, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Step {
        pub idx: usize,
        pub transition_target: Option<TransitionTarget>,
        pub arrival_view: ArrivalView,
    }
}

pub mod graph_utils {
    use super::graph::Scene;

    pub fn find_scene_index(scenes: &[Scene], name: &str) -> Option<usize> {
        scenes.iter().position(|s| s.name == name)
    }

    pub fn find_scene_index_by_id(scenes: &[Scene], id: &str) -> Option<usize> {
        scenes.iter().position(|s| s.id == id)
    }
}

pub mod utils {
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
}

pub mod view_utils {
    use super::graph::{ArrivalView, Hotspot};

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
            },
            None => ArrivalView {
                yaw: hotspot.target_yaw.unwrap_or(0.0),
                pitch: hotspot.target_pitch.unwrap_or(0.0),
            },
        }
    }

    pub fn get_default_view() -> ArrivalView {
        ArrivalView {
            yaw: 0.0,
            pitch: 0.0,
        }
    }
}

pub mod algorithms {
    pub mod timeline {
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
    }

    pub mod walk {
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
                    let mut next_idx =
                        find_scene_index(&scenes, &link.target).ok_or_else(|| {
                            format!("Pathfinding error: Scene '{}' not found", link.target)
                        })?;

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
                        next_idx =
                            follow_auto_forward_chain(&scenes, next_idx, &mut visited, false)?;
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
                        next_idx =
                            follow_auto_forward_chain(&scenes, next_idx, &mut local_visited, true)?;
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
    }

    pub use timeline::calculate_timeline_path;
    pub use walk::calculate_walk_path;
}

pub use algorithms::{calculate_timeline_path, calculate_walk_path};
pub use graph::PathRequest;

pub fn calculate_path(request: PathRequest) -> Result<Vec<graph::Step>, String> {
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

#[cfg(test)]
mod tests {
    use super::graph::{Hotspot, Scene};
    use super::utils;
    use std::collections::HashSet;

    fn create_scene(name: &str, auto_forward: bool, targets: Vec<(&str, bool)>) -> Scene {
        Scene {
            id: name.to_string(),
            name: name.to_string(),
            is_auto_forward: auto_forward,
            hotspots: targets
                .into_iter()
                .map(|(t, is_return)| Hotspot {
                    link_id: None,
                    yaw: 0.0,
                    pitch: 0.0,
                    target: t.to_string(),
                    target_yaw: None,
                    target_pitch: None,
                    is_return_link: Some(is_return),
                    view_frame: None,
                })
                .collect(),
        }
    }

    #[test]
    fn test_auto_forward_chain() {
        let scenes = vec![
            create_scene("A", false, vec![("B", false)]),
            create_scene("B", true, vec![("C", false)]),
            create_scene("C", true, vec![("D", false)]),
            create_scene("D", false, vec![]),
        ];

        let mut visited = HashSet::new();
        // Start at B
        let start_idx = 1;
        let result = utils::follow_auto_forward_chain(&scenes, start_idx, &mut visited, false);
        assert!(result.is_ok());
        assert_eq!(scenes[result.expect("Pathfinding failed")].name, "D");
    }

    #[test]
    fn test_auto_forward_loop() {
        let scenes = vec![
            create_scene("A", true, vec![("B", false)]),
            create_scene("B", true, vec![("A", false)]),
        ];

        let mut visited = HashSet::new();
        let result = utils::follow_auto_forward_chain(&scenes, 0, &mut visited, false);
        // Loop detected: 0 visited->jump to 1. 1 visited->jump to 0. 0 visited. stop.
        assert!(result.is_ok());
        assert_eq!(scenes[result.expect("Pathfinding failed")].name, "B");
    }

    #[test]
    fn test_broken_link_stops_chain() {
        let scenes = vec![create_scene("A", true, vec![("B", false)])];

        let mut visited = HashSet::new();
        let result = utils::follow_auto_forward_chain(&scenes, 0, &mut visited, false);
        // Should stop at A (0) because B is missing
        assert!(result.is_ok());
        assert_eq!(result.expect("Pathfinding failed"), 0);
    }
}
