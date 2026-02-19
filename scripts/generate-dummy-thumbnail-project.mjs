import fs from 'fs';
import path from 'path';
import JSZip from 'jszip';

const args = process.argv.slice(2);
const sceneCount = Number(args[0] ?? 70);
const thumbnailCount = Number(args[1] ?? 100);
const outputPath = args[2] ?? 'artifacts/dummy_70_images_100_thumbnails.vt.zip';

if (!Number.isFinite(sceneCount) || sceneCount <= 0) {
  console.error('sceneCount must be a positive number');
  process.exit(1);
}

if (!Number.isFinite(thumbnailCount) || thumbnailCount < sceneCount) {
  console.error('thumbnailCount must be a number >= sceneCount');
  process.exit(1);
}

const root = process.cwd();

// 1x1 transparent PNG (minimal and valid for image rendering)
const tinyPngBase64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO8lM7kAAAAASUVORK5CYII=';
const imageBytes = Buffer.from(tinyPngBase64, 'base64');

const scenes = Array.from({ length: sceneCount }, (_, i) => {
  const idx = String(i + 1).padStart(3, '0');
  return {
    id: `scene-${idx}`,
    name: `Scene ${idx}`,
    label: `Scene ${idx}`,
    file: `images/image-${idx}.png`,
    tinyFile: `thumbnails/thumb-${idx}.png`,
    hotspots: [],
    quality: { score: 9.0, stats: { avgLuminance: 120 } },
    colorGroup: String(((i % 6) + 1)),
  };
});

const projectJson = {
  id: `dummy-${sceneCount}-images-${thumbnailCount}-thumbnails`,
  tourName: `Dummy ${sceneCount} images / ${thumbnailCount} thumbnails`,
  scenes,
};

async function main() {
  const zip = new JSZip();
  zip.file('project.json', JSON.stringify(projectJson, null, 2));

  for (let i = 0; i < sceneCount; i += 1) {
    const idx = String(i + 1).padStart(3, '0');
    zip.file(`images/image-${idx}.png`, imageBytes);
    zip.file(`thumbnails/thumb-${idx}.png`, imageBytes);
  }

  for (let i = sceneCount; i < thumbnailCount; i += 1) {
    const idx = String(i + 1).padStart(3, '0');
    zip.file(`thumbnails/thumb-${idx}.png`, imageBytes);
  }

  const content = await zip.generateAsync({
    type: 'nodebuffer',
    compression: 'DEFLATE',
    compressionOptions: { level: 9 },
  });
  const absoluteOutput = path.isAbsolute(outputPath)
    ? outputPath
    : path.join(root, outputPath);

  fs.mkdirSync(path.dirname(absoluteOutput), { recursive: true });
  fs.writeFileSync(absoluteOutput, content);

  console.log(`Created: ${absoluteOutput}`);
  console.log(`Scenes: ${sceneCount}`);
  console.log(`Image files: ${sceneCount}`);
  console.log(`Thumbnail files: ${thumbnailCount}`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
