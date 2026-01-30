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
    pub hfov: Option<f32>,
}

#[derive(Serialize, Debug, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Step {
    pub idx: usize,
    pub transition_target: Option<TransitionTarget>,
    pub arrival_view: ArrivalView,
}
