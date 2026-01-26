use crate::models::AppError;
use actix_web::{HttpResponse, web};

/// Calculates the optimal navigation path between scenes.
///
/// Supports both "Walk" (exploratory) and "Timeline" (guided) navigation modes.
/// It uses the pathfinder logic to determine camera rotations and transition
/// targets between multiple spherical panoramas.
///
/// # Arguments
/// * `req` - A JSON payload containing the `PathRequest` (Walk or Timeline).
///
/// # Returns
/// A JSON array of `Step` objects representing the calculated path.
///
/// # Errors
/// * `ValidationError` if the requested path involves non-existent scenes or broken links.
pub async fn calculate_path(
    req: web::Json<crate::pathfinder::PathRequest>,
) -> Result<HttpResponse, AppError> {
    let result = match req.into_inner() {
        crate::pathfinder::PathRequest::Walk {
            scenes,
            skip_auto_forward,
        } => crate::pathfinder::calculate_walk_path(scenes, skip_auto_forward),
        crate::pathfinder::PathRequest::Timeline {
            scenes,
            timeline,
            skip_auto_forward,
        } => crate::pathfinder::calculate_timeline_path(scenes, timeline, skip_auto_forward),
    }
    .map_err(AppError::ValidationError)?;
    Ok(HttpResponse::Ok().json(result))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::pathfinder::{
        PathRequest,
        graph::{Hotspot, Scene, TimelineItem},
    };
    use actix_web::http::StatusCode;

    fn create_scene(id: &str, targets: Vec<&str>) -> Scene {
        Scene {
            id: id.to_string(),
            name: id.to_string(),
            is_auto_forward: false,
            hotspots: targets
                .into_iter()
                .map(|t| Hotspot {
                    link_id: Some(format!("link-to-{}", t)),
                    yaw: 0.0,
                    pitch: 0.0,
                    target: t.to_string(),
                    target_yaw: None,
                    target_pitch: None,
                    is_return_link: Some(false),
                    view_frame: None,
                })
                .collect(),
        }
    }

    #[actix_web::test]
    async fn test_calculate_walk_path() {
        let scenes = vec![
            create_scene("A", vec!["B"]),
            create_scene("B", vec!["C"]),
            create_scene("C", vec![]),
        ];

        let req = PathRequest::Walk {
            scenes,
            skip_auto_forward: false,
        };

        let result = calculate_path(web::Json(req)).await;
        assert!(result.is_ok());

        let resp = result.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);
    }

    #[actix_web::test]
    async fn test_calculate_timeline_path() {
        let scenes = vec![create_scene("A", vec!["B"]), create_scene("B", vec![])];

        let timeline = vec![TimelineItem {
            id: "t1".to_string(),
            link_id: "link-to-B".to_string(),
            scene_id: "A".to_string(),
            target_scene: "B".to_string(),
        }];

        let req = PathRequest::Timeline {
            scenes,
            timeline,
            skip_auto_forward: false,
        };

        let result = calculate_path(web::Json(req)).await;
        assert!(result.is_ok());

        let resp = result.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);
    }
}
