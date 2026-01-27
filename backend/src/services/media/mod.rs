/* backend/src/services/media/mod.rs - Facade for Media Services */

pub mod analysis;
pub mod naming;
pub mod resizing;
pub mod webp;

pub use analysis::*;
pub use naming::*;
pub use resizing::*;
pub use webp::*;

#[cfg(test)]
mod tests {
    use super::*;
    use image::DynamicImage;

    #[test]
    fn test_suggested_name_regex() {
        assert_eq!(get_suggested_name("_240114_00_001.jpg"), "240114_001");
        assert_eq!(get_suggested_name("random_file.png"), "random_file");
        assert_eq!(get_suggested_name("images/_240114_00_001.jpg"), "240114_001");
    }

    #[test]
    fn test_checksum_format() {
        let data = b"hello world";
        let rgba = vec![0u8; 400 * 400 * 4];
        let res = perform_metadata_extraction_rgba(&rgba, 400, 400, data, None)
            .expect("Metadata extraction failed");
        assert!(res.checksum.starts_with("b94d27b9934d3e08"));
        assert!(res.checksum.ends_with("_11"));
    }

    #[test]
    fn test_blur_detection() {
        let w = 400;
        let h = 400;
        let rgba = vec![128u8; (w * h * 4) as usize];
        let data = vec![0u8; 100];
        let res = perform_metadata_extraction_rgba(&rgba, w, h, &data, None)
            .expect("Metadata extraction failed");
        assert!(res.quality.is_blurry);
        assert_eq!(res.quality.stats.sharpness_variance, 0);
    }

    #[test]
    fn test_brightness_detection() {
        let w = 400;
        let h = 400;
        let mut dark_rgba = vec![0u8; (w * h * 4) as usize];
        for i in 0..(w * h) {
            dark_rgba[(i * 4) as usize] = 10;
            dark_rgba[(i * 4 + 1) as usize] = 10;
            dark_rgba[(i * 4 + 2) as usize] = 10;
            dark_rgba[(i * 4 + 3) as usize] = 255;
        }
        let res_dark = perform_metadata_extraction_rgba(&dark_rgba, w, h, &vec![0], None)
            .expect("Metadata extraction failed");
        assert!(res_dark.quality.is_severely_dark);

        let mut bright_rgba = vec![0u8; (w * h * 4) as usize];
        for i in 0..(w * h) {
            bright_rgba[(i * 4) as usize] = 250;
            bright_rgba[(i * 4 + 1) as usize] = 250;
            bright_rgba[(i * 4 + 2) as usize] = 250;
            bright_rgba[(i * 4 + 3) as usize] = 255;
        }
        let res_bright = perform_metadata_extraction_rgba(&bright_rgba, w, h, &vec![0], None)
            .expect("Metadata extraction failed");
        assert!(res_bright.quality.analysis.expect("Analysis missing").contains("Very bright"));
    }

    #[test]
    fn test_encode_webp_basic() {
        let img = DynamicImage::new_rgba8(100, 100);
        let result = encode_webp(&img, 80.0);
        assert!(result.is_ok());
        let bytes = result.expect("WebP encoding failed");
        assert!(bytes.len() > 0);
        assert_eq!(&bytes[0..4], b"RIFF");
    }
}
