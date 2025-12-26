export async function processImage(file) {
  // TARGET: 4K (4096px) - The "Sweet Spot" for 7-inch tablets & Web
  const bitmap = await createImageBitmap(file, {
    resizeWidth: 4096,
    resizeQuality: "high",
  });

  const canvas = document.createElement("canvas");
  canvas.width = bitmap.width;
  canvas.height = bitmap.height;

  const ctx = canvas.getContext("bitmaprenderer");
  ctx.transferFromImageBitmap(bitmap);

  return new Promise((resolve) => {
    canvas.toBlob(
      (blob) => {
        // Smart Renaming Logic
        let newName = file.name.replace(/\.[^/.]+$/, "");
        const match = file.name.match(/_(\d{6}_\d{2}_\d{3})/); // Matches Insta360 timestamp
        if (match && match[1]) {
          newName = match[1];
        }

        const newFile = new File([blob], newName + ".webp", {
          type: "image/webp",
          lastModified: Date.now(),
        });
        resolve(newFile);
      },
      "image/webp",
      0.75,
    ); // 75% Quality is standard for WebP
  });
}
