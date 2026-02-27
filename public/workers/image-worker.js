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
    self.postMessage({ id, ok: true, isImage });
    return;
  }

  if (type === "generateTiny") {
    try {
      const blob = data.blob;
      const width = Number(data.width || 256);
      const height = Number(data.height || 144);
      if (!blob || typeof createImageBitmap !== "function" || typeof OffscreenCanvas !== "function") {
        self.postMessage({ id, ok: false, error: "Worker tiny generation unsupported" });
        return;
      }
      const bitmap = await createImageBitmap(blob);
      const canvas = new OffscreenCanvas(width, height);
      const ctx = canvas.getContext("2d", { alpha: false });
      ctx.drawImage(bitmap, 0, 0, width, height);
      const tiny = await canvas.convertToBlob({ type: "image/webp", quality: 0.82 });
      self.postMessage({ id, ok: true, tiny, type: "generateTiny" });
      return;
    } catch (error) {
      const message = error && error.message ? String(error.message) : "Worker tiny generation failed";
      self.postMessage({ id, ok: false, error: message, type: "generateTiny" });
      return;
    }
  }

  if (type !== "fingerprint") {
    self.postMessage({ id, ok: false, error: "Unsupported worker task type" });
    return;
  }

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
  } catch (error) {
    const message = error && error.message ? String(error.message) : "Worker fingerprint failed";
    self.postMessage({ id, ok: false, error: message, type: "fingerprint" });
  }
};
