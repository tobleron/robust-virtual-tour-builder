/**
 * Image Processing System
 * 
 * Handles panoramic image optimization:
 * - Resizes to 4K resolution (4096px width)
 * - Converts to WebP format for optimal compression
 * - Extracts intelligent filenames from Insta360 camera timestamps
 * 
 * @module Resizer
 */

import {
  PROCESSED_IMAGE_WIDTH,
  IMAGE_RESIZE_QUALITY,
  WEBP_QUALITY,
} from "../constants.js";

/**
 * Generate a SHA-256 checksum for a file.
 * Used for "fingerprinting" images to detect duplicates and maintain 
 * stable links regardless of renaming.
 */
export async function getChecksum(file) {
  const arrayBuffer = await file.arrayBuffer();
  const hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Process and optimize a panoramic image
 * 
 * This function performs several optimizations:
 * 1. Resizes to 4K width (4096px) - optimal for tablets and web
 * 2. Converts to WebP format (40% smaller than JPEG, better quality)
 * 3. Intelligently extracts filename from Insta360 timestamp pattern
 * 4. Uses bitmaprenderer context for zero-copy rendering (faster)
 * 
 * @param {File} file - Input image file (JPEG, PNG, etc.)
 * @returns {Promise<File>} Processed WebP file at 4K resolution
 * 
 * @example
 * const originalFile = fileInput.files[0]; // 8K JPEG, 15 MB
 * const optimizedFile = await processImage(originalFile); // 4K WebP, 4 MB
 */
export async function processImage(file) {
  try {
    // Use createImageBitmap for hardware-accelerated resizing
    // This is faster and more efficient than canvas drawImage
    const bitmap = await createImageBitmap(file, {
      resizeWidth: PROCESSED_IMAGE_WIDTH, // 4096px - The "sweet spot" for 7-inch tablets & web
      resizeQuality: IMAGE_RESIZE_QUALITY, // "high" quality interpolation
    });

    const canvas = document.createElement("canvas");
    canvas.width = bitmap.width;
    canvas.height = bitmap.height;

    // Use bitmaprenderer for zero-copy transfer (most efficient method)
    const ctx = canvas.getContext("bitmaprenderer");
    ctx.transferFromImageBitmap(bitmap);

    return new Promise((resolve, reject) => {
      canvas.toBlob(
        (blob) => {
          // GUARD: Validate blob was created successfully
          if (!blob) {
            reject(new Error(`Failed to convert ${file.name} to WebP`));
            return;
          }

          // Smart filename extraction from Insta360 camera format
          // Pattern: IMG_20231215_14_032.jpg → 20231215_032 (removing middle time segment)
          let newName = file.name.replace(/\.[^/.]+$/, ""); // Remove extension
          const match = file.name.match(/_(\d{6})_\d{2}_(\d{3})/); // Match pattern and capture date + serial

          if (match && match[1] && match[2]) {
            newName = `${match[1]}_${match[2]}`; // Combine: date_serial (e.g., 20231215_032)
          }

          // Create new file with WebP extension
          const newFile = new File([blob], newName + ".webp", {
            type: "image/webp",
            lastModified: Date.now(),
          });

          resolve(newFile);
        },
        "image/webp",
        WEBP_QUALITY, // 0.92 = visually lossless, ~40% smaller than JPEG
      );
    });
  } catch (err) {
    throw new Error(`Image processing failed for ${file.name}: ${err.message}`);
  }
}

