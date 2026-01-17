/* src/utils/ImageOptimizer.resi */
open ReBindings

let init: unit => unit

/**
 * Compresses a File/Blob to WebP format using the browser's Canvas API.
 * Quality should be between 0.0 and 1.0.
 */
let compressToWebP: (File.t, float) => Promise.t<Blob.t>
