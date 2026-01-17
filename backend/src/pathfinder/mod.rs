pub mod algorithms;
pub mod graph;
pub mod utils;

// Re-export public API (only what's actually used)
pub use algorithms::{calculate_timeline_path, calculate_walk_path};
pub use graph::PathRequest;

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
        assert_eq!(scenes[result.unwrap()].name, "D");
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
        assert_eq!(scenes[result.unwrap()].name, "B");
    }

    #[test]
    fn test_broken_link_stops_chain() {
        let scenes = vec![create_scene("A", true, vec![("B", false)])];

        let mut visited = HashSet::new();
        let result = utils::follow_auto_forward_chain(&scenes, 0, &mut visited, false);
        // Should stop at A (0) because B is missing
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 0);
    }
}
