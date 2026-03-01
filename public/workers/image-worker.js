self.onmessage = async event => {
  const data = event && event.data ? event.data : {};
  const id = data.id;
  const type = data.type;

  if (type === "validateImage") {
    const file = data.file;
    const fileName = file && file.name ? String(file.name) : "";
    const mime = file && file.type ? String(file.type).toLowerCase() : "";
    const ext = fileName.includes(".")
      ? fileName.split(".").pop().toLowerCase()
      : "";
    const allowed = ["jpg", "jpeg", "png", "webp", "heic", "heif"];
    const isImage = mime.startsWith("image/") || allowed.includes(ext);
    self.postMessage({ id, ok: true, isImage, type: "validateImage" });
    return;
  }

  if (type === "processFull") {
    try {
      const blob = data.blob;
      const targetWidth = Number(data.width || 4096);
      const quality = Number(data.quality || 0.95);
      const format = data.format || "image/jpeg"; // Default to JPEG for speed

      if (!blob || typeof createImageBitmap !== "function" || typeof OffscreenCanvas !== "function") {
        self.postMessage({ id, ok: false, error: "Worker full processing unsupported" });
        return;
      }

      const bitmap = await createImageBitmap(blob);
      const srcW = bitmap.width;
      const srcH = bitmap.height;

      // Maintain aspect ratio
      const scale = Math.min(1.0, targetWidth / srcW);
      const width = Math.floor(srcW * scale);
      const height = Math.floor(srcH * scale);

      const canvas = new OffscreenCanvas(width, height);
      const ctx = canvas.getContext("2d", { alpha: false });
      
      // Use standard high-quality scaling (equivalent to native browser resize)
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';
      
      ctx.drawImage(bitmap, 0, 0, width, height);
      
      // Convert to requested format (JPEG is much faster than WebP in most browsers)
      const optimized = await canvas.convertToBlob({ 
        type: format, 
        quality: quality 
      });

      // Cleanup bitmap memory immediately
      if (typeof bitmap.close === "function") bitmap.close();

      self.postMessage({ id, ok: true, blob: optimized, width, height, type: "processFull" });
      return;
    } catch (error) {
      const message = error && error.message ? String(error.message) : "Worker full processing failed";
      self.postMessage({ id, ok: false, error: message, type: "processFull" });
      return;
    }
  }

  if (type === "generateTiny") {
    try {
      const blob = data.blob;
      const width = Number(data.width || 512);
      const height = Number(data.height || 512);
      if (!blob || typeof createImageBitmap !== "function" || typeof OffscreenCanvas !== "function") {
        self.postMessage({ id, ok: false, error: "Worker tiny generation unsupported" });
        return;
      }
      const bitmap = await createImageBitmap(blob);
      const canvas = new OffscreenCanvas(width, height);
      const ctx = canvas.getContext("2d", { alpha: false });
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';
      ctx.drawImage(bitmap, 0, 0, width, height);
      const tiny = await canvas.convertToBlob({ type: "image/webp", quality: 0.82 });
      if (typeof bitmap.close === "function") bitmap.close();
      self.postMessage({ id, ok: true, tiny, type: "generateTiny" });
      return;
    } catch (error) {
      const message = error && error.message ? String(error.message) : "Worker tiny generation failed";
      self.postMessage({ id, ok: false, error: message, type: "generateTiny" });
      return;
    }
  }

  if (type === "extractExif") {
    try {
      const file = data.file;
      if (!file || typeof createImageBitmap !== "function") {
        self.postMessage({ id, ok: false, error: "Worker EXIF extraction unsupported", type: "extractExif" });
        return;
      }
      const bitmap = await createImageBitmap(file);
      const width = Number(bitmap.width || 0);
      const height = Number(bitmap.height || 0);
      if (typeof bitmap.close === "function") {
        bitmap.close();
      }
      self.postMessage({ id, ok: true, width, height, type: "extractExif" });
      return;
    } catch (error) {
      const message = error && error.message ? String(error.message) : "Worker EXIF extraction failed";
      self.postMessage({ id, ok: false, error: message, type: "extractExif" });
      return;
    }
  }

  if (type === "fingerprint") {
    try {
      const file = data.file;
      if (!file || typeof file.arrayBuffer !== "function") {
        self.postMessage({ id, ok: false, error: "Invalid file payload" });
        return;
      }

      const buffer = await file.arrayBuffer();
      const digest = await crypto.subtle.digest("SHA-256", buffer);
      const bytes = new Uint8Array(digest);
      const checksum = Array.from(bytes)
        .map(b => b.toString(16).padStart(2, "0"))
        .join("");

      self.postMessage({ id, ok: true, checksum, type: "fingerprint" });
      return;
    } catch (error) {
      const message = error && error.message ? String(error.message) : "Worker fingerprint failed";
      self.postMessage({ id, ok: false, error: message, type: "fingerprint" });
      return;
    }
  }

  self.postMessage({ id, ok: false, error: "Unsupported worker task type", type: "unknown" });
};
