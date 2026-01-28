// @efficiency: infra-adapter
/* backend/src/services/media/resizing.rs */

use fast_image_resize::{
    FilterType, PixelType, ResizeAlg, ResizeOptions, Resizer, images::Image as FrImage,
};

pub fn resize_fast_rgba(
    src_rgba: &[u8],
    src_w: u32,
    src_h: u32,
    target_width: u32,
    target_height: u32,
) -> Result<Vec<u8>, String> {
    if target_width == 0 || target_height == 0 {
        return Err("Invalid dimensions".to_string());
    }

    let src_image = FrImage::from_vec_u8(src_w, src_h, src_rgba.to_vec(), PixelType::U8x4)
        .map_err(|e| format!("FastResize Init Error: {:?}", e))?;

    let mut dst_image = FrImage::new(target_width, target_height, PixelType::U8x4);
    let mut resizer = Resizer::new();

    let options = ResizeOptions {
        algorithm: ResizeAlg::Convolution(FilterType::Lanczos3),
        ..Default::default()
    };

    resizer
        .resize(&src_image, &mut dst_image, &options)
        .map_err(|e| format!("FastResize Error: {:?}", e))?;

    Ok(dst_image.into_vec())
}

pub fn resize_fast(
    img: &image::DynamicImage,
    target_width: u32,
    target_height: u32,
) -> Result<image::DynamicImage, String> {
    let rgba = img.to_rgba8();
    let data = resize_fast_rgba(
        &rgba,
        img.width(),
        img.height(),
        target_width,
        target_height,
    )?;

    image::RgbaImage::from_raw(target_width, target_height, data)
        .map(image::DynamicImage::ImageRgba8)
        .ok_or_else(|| "Failed to create RgbaImage from resized data".to_string())
}
