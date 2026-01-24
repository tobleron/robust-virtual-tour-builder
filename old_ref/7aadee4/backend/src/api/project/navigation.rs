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
    #[test]
    fn placeholder() {}
}
