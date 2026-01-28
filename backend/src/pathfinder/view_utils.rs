// @efficiency: util-pure
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
