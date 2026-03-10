/* src/utils/ImageOptimizer.resi */
open ReBindings

let init: unit => unit

/**
 * Compresses a File/Blob to WebP format using the browser's Canvas API.
 * Quality should be between 0.0 and 1.0.
 */
let compressToWebP: (File.t, float) => Promise.t<result<Blob.t, string>>

/**
 * Compresses a File/Blob to WebP with explicit geometry constraints.
 * `maxWidth` and `maxHeight` are upper bounds; source aspect ratio is preserved.
 */
let compressToWebPConstrained: (
  File.t,
  ~quality: float,
  ~maxWidth: float,
  ~maxHeight: float,
) => Promise.t<result<Blob.t, string>>

/**
 * Compresses a logo File/Blob to WebP with explicit geometry constraints while preserving alpha.
 */
let compressLogoToWebPConstrained: (
  File.t,
  ~quality: float,
  ~maxWidth: float,
  ~maxHeight: float,
) => Promise.t<result<Blob.t, string>>
