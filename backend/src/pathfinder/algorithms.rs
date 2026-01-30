// @efficiency-role: domain-logic
use super::graph::{PathRequest, Step};
use super::timeline;
use super::walk;

pub fn calculate_path(request: PathRequest) -> Result<Vec<Step>, String> {
    match request {
        PathRequest::Walk {
            scenes,
            skip_auto_forward,
        } => walk::calculate_walk_path(scenes, skip_auto_forward),
        PathRequest::Timeline {
            scenes,
            timeline,
            skip_auto_forward,
        } => timeline::calculate_timeline_path(scenes, timeline, skip_auto_forward),
    }
}
