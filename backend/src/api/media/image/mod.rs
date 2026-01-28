/* backend/src/api/media/image.rs - Facade for Image API */

pub mod extract_metadata;
pub mod image_logic;
pub mod image_utils;
pub mod optimize;
pub mod process_full;
pub mod resize_batch;

#[cfg(test)]
mod tests;

pub use extract_metadata::extract_metadata;
pub use optimize::optimize_image;
pub use process_full::process_image_full;
pub use resize_batch::resize_image_batch;
