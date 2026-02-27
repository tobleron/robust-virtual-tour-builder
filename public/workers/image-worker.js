self.onmessage = async event => {
  const data = event && event.data ? event.data : {};
  const id = data.id;
  const type = data.type;

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

    self.postMessage({ id, ok: true, checksum });
  } catch (error) {
    const message = error && error.message ? String(error.message) : "Worker fingerprint failed";
    self.postMessage({ id, ok: false, error: message });
  }
};

