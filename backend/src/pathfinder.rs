use serde::{Deserialize, Serialize};
use std::collections::HashSet;

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
    pub waypoints: Option<Vec<ViewFrame>>,
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

/* Helpers */

fn find_scene_index(scenes: &[Scene], name: &str) -> Option<usize> {
    scenes.iter().position(|s| s.name == name)
}

fn find_scene_index_by_id(scenes: &[Scene], id: &str) -> Option<usize> {
    scenes.iter().position(|s| s.id == id)
}

fn get_hotspot_view(hotspot: &Hotspot) -> (f32, f32) {
    match &hotspot.view_frame {
        Some(vf) => (vf.yaw, vf.pitch),
        None => (hotspot.yaw, hotspot.pitch),
    }
}

fn get_arrival_view(hotspot: &Hotspot) -> ArrivalView {
    match &hotspot.view_frame {
        Some(vf) => ArrivalView { yaw: vf.yaw, pitch: vf.pitch },
        None => ArrivalView {
            yaw: hotspot.target_yaw.unwrap_or(0.0),
            pitch: hotspot.target_pitch.unwrap_or(0.0),
        },
    }
}

fn get_default_view() -> ArrivalView {
    ArrivalView { yaw: 0.0, pitch: 0.0 }
}

pub fn calculate_walk_path(scenes: Vec<Scene>, skip_auto_forward: bool) -> Vec<Step> {
    if scenes.is_empty() {
        return Vec::new();
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
                .expect(&format!("Pathfinding error: Scene '{}' not found", link.target));
            
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
                let mut chain_counter = 0;
                while chain_counter < 10 {
                    let next_scene = &scenes[next_idx];
                    if next_scene.is_auto_forward {
                        visited.insert(next_idx);
                        let jump_link = next_scene.hotspots.iter().find(|h| {
                            match find_scene_index(&scenes, &h.target) {
                                Some(idx) => !visited.contains(&idx),
                                None => false,
                            }
                        });

                        if let Some(j_link) = jump_link {
                           next_idx = find_scene_index(&scenes, &j_link.target)
                               .expect(&format!("Pathfinding error: Junction scene '{}' not found", j_link.target));
                        } else {
                            break;
                        }
                    } else {
                        break;
                    }
                    chain_counter += 1;
                }
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
                let mut chain_counter = 0;
                let mut visited_in_chain = HashSet::new();
                visited_in_chain.insert(next_idx);

                while chain_counter < 10 {
                    let next_scene = &scenes[next_idx];
                    if next_scene.is_auto_forward {
                        let jump_link = next_scene.hotspots.iter().find(|h| {
                            if h.is_return_link.unwrap_or(false) {
                                match find_scene_index(&scenes, &h.target) {
                                    Some(idx) => !visited_in_chain.contains(&idx),
                                    None => false,
                                }
                            } else {
                                false
                            }
                        });

                        if let Some(j_link) = jump_link {
                            if let Some(j_idx) = find_scene_index(&scenes, &j_link.target) {
                                next_idx = j_idx;
                                visited_in_chain.insert(next_idx);
                            } else {
                                break;
                            }
                        } else {
                            break;
                        }
                    } else {
                        break;
                    }
                    chain_counter += 1;
                }
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
    if final_path.is_empty() { return Vec::new(); }
    let mut deduped = Vec::with_capacity(final_path.len());
    let mut last_idx = None;
    for step in final_path {
        if Some(step.idx) != last_idx {
            last_idx = Some(step.idx);
            deduped.push(step);
        }
    }

    deduped
}

pub fn calculate_timeline_path(scenes: Vec<Scene>, timeline: Vec<TimelineItem>, skip_auto_forward: bool) -> Vec<Step> {
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
                        let mut chain_counter = 0;
                        let mut visited_in_chain = HashSet::new();
                        visited_in_chain.insert(target_idx);

                        while chain_counter < 10 {
                            let next_scene = &scenes[target_idx];
                            if next_scene.is_auto_forward {
                                let jump_link = next_scene.hotspots.iter().find(|h| {
                                    match find_scene_index(&scenes, &h.target) {
                                        Some(idx) => !visited_in_chain.contains(&idx),
                                        None => false,
                                    }
                                });

                                if let Some(j_link) = jump_link {
                                    if let Some(j_idx) = find_scene_index(&scenes, &j_link.target) {
                                        target_idx = j_idx;
                                        visited_in_chain.insert(target_idx);
                                        arrival_view = get_default_view();
                                    } else {
                                        break;
                                    }
                                } else {
                                    break;
                                }
                            } else {
                                break;
                            }
                            chain_counter += 1;
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
    if final_path.is_empty() { return Vec::new(); }
    let mut deduped = Vec::with_capacity(final_path.len());
    let mut last_idx = None;
    for step in final_path {
        if Some(step.idx) != last_idx {
            last_idx = Some(step.idx);
            deduped.push(step);
        }
    }

    deduped
}
