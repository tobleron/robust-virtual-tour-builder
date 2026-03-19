#[path = "portal_admin_routes.rs"]
mod portal_admin_routes;
#[path = "portal_public_routes.rs"]
mod portal_public_routes;

pub use self::portal_admin_routes::*;
pub use self::portal_public_routes::*;
