/* backend/src/api/media/video/mod.rs - Facade for Video API */

pub mod teaser;
pub mod transcode;
pub mod video_logic;

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}

pub use teaser::generate_teaser;
pub use transcode::transcode_video;
