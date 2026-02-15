/* backend/src/services/media/mod.rs - Facade for Media Services */

pub mod analysis;
pub mod analysis_exif;
pub mod analysis_quality;
pub mod naming;
pub mod resizing;
pub mod storage;
pub mod webp;

pub use analysis::*;
#[allow(unused_imports)]
pub use analysis_exif::*;
#[allow(unused_imports)]
pub use analysis_quality::*;
pub use naming::*;
pub use resizing::*;
pub use storage::*;
pub use webp::*;

#[cfg(test)]
mod tests {
    use super::*;
    use image::DynamicImage;

    #[test]
    fn test_suggested_name_regex() {
        assert_eq!(get_suggested_name("_240114_00_001.jpg"), "240114_001");
        assert_eq!(get_suggested_name("random_file.png"), "random_file");
        assert_eq!(
            get_suggested_name("images/_240114_00_001.jpg"),
            "240114_001"
        );
    }

    #[test]
    fn test_extract_metadata_success() -> Result<(), Box<dyn std::error::Error>> {
        let data = vec![0; 100];
        let img = image::RgbaImage::new(100, 100);
        let result = perform_metadata_extraction_rgba(&img, 100, 100, &data, Some("test.jpg"));
        assert!(result.is_ok());
        let meta = result?;
        assert_eq!(meta.exif.width, 100);
        assert_eq!(meta.exif.height, 100);
        Ok(())
    }

    #[test]
    fn test_extract_metadata_no_filename() -> Result<(), Box<dyn std::error::Error>> {
        let data = vec![0; 100];
        let img = image::RgbaImage::new(100, 100);
        let result = perform_metadata_extraction_rgba(&img, 100, 100, &data, None);
        assert!(result.is_ok());
        let meta = result?;
        assert_eq!(meta.suggested_name, None);
        Ok(())
    }

    #[test]
    fn test_extract_metadata_with_filename_logic() -> Result<(), Box<dyn std::error::Error>> {
        let data = vec![0; 100];
        let img = image::RgbaImage::new(100, 100);
        let filename = "R0010123_123456_01_005.jpg";
        let result = perform_metadata_extraction_rgba(&img, 100, 100, &data, Some(filename));
        assert!(result.is_ok());
        let meta = result?;
        assert_eq!(meta.suggested_name, Some("123456_005".to_string()));
        Ok(())
    }

    #[test]
    fn test_extract_metadata_invalid_filename() -> Result<(), Box<dyn std::error::Error>> {
        let data = vec![0; 100];
        let img = image::RgbaImage::new(100, 100);
        let filename = "normal_photo.jpg";
        let result = perform_metadata_extraction_rgba(&img, 100, 100, &data, Some(filename));
        assert!(result.is_ok());
        let meta = result?;
        assert_eq!(meta.suggested_name, Some("normal_photo".to_string()));
        Ok(())
    }

    #[test]
    fn test_checksum_format() -> Result<(), Box<dyn std::error::Error>> {
        let data = b"hello world";
        let rgba = vec![0u8; 400 * 400 * 4];
        let res = perform_metadata_extraction_rgba(&rgba, 400, 400, data, None)?;
        assert!(res.checksum.starts_with("b94d27b9934d3e08"));
        assert!(res.checksum.ends_with("_11"));
        Ok(())
    }

    #[test]
    fn test_blur_detection() -> Result<(), Box<dyn std::error::Error>> {
        let w = 400;
        let h = 400;
        let rgba = vec![128u8; (w * h * 4) as usize];
        let data = vec![0u8; 100];
        let res = perform_metadata_extraction_rgba(&rgba, w, h, &data, None)?;
        assert!(res.quality.is_blurry);
        assert_eq!(res.quality.stats.sharpness_variance, 0);
        Ok(())
    }

    #[test]
    fn test_brightness_detection() -> Result<(), Box<dyn std::error::Error>> {
        let w = 400;
        let h = 400;
        let mut dark_rgba = vec![0u8; (w * h * 4) as usize];
        for i in 0..(w * h) {
            dark_rgba[(i * 4) as usize] = 10;
            dark_rgba[(i * 4 + 1) as usize] = 10;
            dark_rgba[(i * 4 + 2) as usize] = 10;
            dark_rgba[(i * 4 + 3) as usize] = 255;
        }
        let res_dark = perform_metadata_extraction_rgba(&dark_rgba, w, h, &vec![0], None)?;
        assert!(res_dark.quality.is_severely_dark);

        let mut bright_rgba = vec![0u8; (w * h * 4) as usize];
        for i in 0..(w * h) {
            bright_rgba[(i * 4) as usize] = 250;
            bright_rgba[(i * 4 + 1) as usize] = 250;
            bright_rgba[(i * 4 + 2) as usize] = 250;
            bright_rgba[(i * 4 + 3) as usize] = 255;
        }
        let res_bright = perform_metadata_extraction_rgba(&bright_rgba, w, h, &vec![0], None)?;
        assert!(
            res_bright
                .quality
                .analysis
                .as_ref()
                .ok_or("Analysis missing")?
                .contains("Very bright")
        );
        Ok(())
    }

    #[test]
    fn test_encode_webp_basic() -> Result<(), Box<dyn std::error::Error>> {
        let img = DynamicImage::new_rgba8(100, 100);
        let result = encode_webp(&img, 80.0);
        assert!(result.is_ok());
        let bytes = result?;
        assert!(bytes.len() > 0);
        assert_eq!(&bytes[0..4], b"RIFF");
        Ok(())
    }

    #[test]
    fn test_webp_encoding_integration() -> Result<(), Box<dyn std::error::Error>> {
        let img = image::DynamicImage::ImageRgba8(image::RgbaImage::new(10, 10));
        let result = encode_webp(&img, 80.0);
        assert!(result.is_ok());
        let bytes = result?;
        assert!(!bytes.is_empty());
        Ok(())
    }

    #[test]
    fn test_webp_metadata_injection() -> Result<(), Box<dyn std::error::Error>> {
        // Mock data
        let img = image::DynamicImage::ImageRgba8(image::RgbaImage::new(10, 10));
        let webp_bytes = encode_webp(&img, 80.0)?;

        let meta = perform_metadata_extraction_rgba(
            &image::RgbaImage::new(10, 10),
            10,
            10,
            &[0; 10],
            None,
        )?;

        let result = inject_remx_chunk(webp_bytes, &meta);
        assert!(result.is_ok());
        let final_bytes = result?;
        assert!(final_bytes.len() > 12);
        Ok(())
    }
}
