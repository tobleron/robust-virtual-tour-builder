use actix_web::{HttpResponse, web};
use std::fs;

use crate::api::utils::{get_session_path, sanitize_filename};
use crate::models::AppError;

// Handler for serving session files
pub async fn serve_session_file(
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    let (session_id, filename) = path.into_inner();

    // Security Check: Sanitize
    let safe_filename = sanitize_filename(&filename)
        .map_err(|_| AppError::InternalError("Invalid filename".into()))?;

    let session_path = get_session_path(&session_id);
    // Images are inside "images" subdir based on our save structure?
    // Wait, import_project puts them directly in session dir?
    // In import_project: `outpath` is session_dir.join(path).
    // In generate_teaser: `file_path = session_path.join(&sanitized)`.
    // So for import/teaser hydration, files are at root of session_path.
    // The previous code in handlers.rs had logic:
    // `let file_path = session_path.join("images").join(&safe_filename);`
    // `if !file_path.exists() { let root_path = session_path.join(&safe_filename); ... }`
    // So it checks images/ then root.

    let file_path = session_path.join("images").join(&safe_filename);

    if !file_path.exists() {
        // Try root
        let root_path = session_path.join(&safe_filename);
        if root_path.exists() {
            let data = fs::read(root_path).map_err(AppError::IoError)?;
            let mime = mime_guess::from_path(&safe_filename).first_or_octet_stream();
            return Ok(HttpResponse::Ok().content_type(mime.as_ref()).body(data));
        }
        return Ok(HttpResponse::NotFound().body("File not found"));
    }

    let data = fs::read(file_path).map_err(AppError::IoError)?;
    let mime = mime_guess::from_path(&safe_filename).first_or_octet_stream();

    Ok(HttpResponse::Ok().content_type(mime.as_ref()).body(data))
}

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}
