// @efficiency-role: orchestrator

pub mod algorithms;
pub mod graph;
pub mod timeline;
pub mod utils;
pub mod walk;

#[cfg(test)]
mod tests;

// Re-exports for backward compatibility and clean API
pub use algorithms::calculate_path;
pub use graph::PathRequest;
// pub use timeline::calculate_timeline_path;
// pub use walk::calculate_walk_path;

// pub use graph::{ArrivalView, Hotspot, Scene, Step, TimelineItem, TransitionTarget, ViewFrame};
