import fs from 'fs';
import path from 'path';
import JSZip from 'jszip';

const inputZipPath = process.argv[2] ?? 'artifacts/x445.zip';
const outputZipPath = process.argv[3] ?? 'artifacts/x700.zip';
const desiredSceneCount = Number(process.argv[4] ?? 700);
const desiredThumbnailCount = Number(process.argv[5] ?? 100);

if (!Number.isFinite(desiredSceneCount) || desiredSceneCount < 2) {
  console.error('desiredSceneCount must be >= 2');
  process.exit(1);
}
if (!Number.isFinite(desiredThumbnailCount) || desiredThumbnailCount < 0) {
  console.error('desiredThumbnailCount must be >= 0');
  process.exit(1);
}

const root = process.cwd();
const inputAbs = path.isAbsolute(inputZipPath) ? inputZipPath : path.join(root, inputZipPath);
const outputAbs = path.isAbsolute(outputZipPath) ? outputZipPath : path.join(root, outputZipPath);

const readZip = async zipPath => {
  const bytes = fs.readFileSync(zipPath);
  return JSZip.loadAsync(bytes);
};

const deepClone = value => JSON.parse(JSON.stringify(value));

const findImagePaths = entries =>
  entries
    .map(name => name.replace(/^\/+/, ''))
    .filter(name => name.startsWith('images/') && !name.endsWith('/'));

const pick = (arr, idx) => arr[idx % arr.length];

async function main() {
  const inZip = await readZip(inputAbs);
  const projectText = await inZip.file('project.json')?.async('string');
  if (!projectText) {
    throw new Error('Input zip missing project.json');
  }

  const project = JSON.parse(projectText);
  const originalInventory = Array.isArray(project.inventory) ? project.inventory : [];
  if (originalInventory.length === 0) {
    throw new Error('Input project inventory is empty; cannot derive scene schema');
  }

  const entryNames = Object.keys(inZip.files);
  const imagePaths = findImagePaths(entryNames);
  if (imagePaths.length === 0) {
    throw new Error('Input zip has no images/* assets');
  }

  const sourceScenes = originalInventory.map(item => item.entry?.scene).filter(Boolean);
  const templateScene = deepClone(sourceScenes[0]);
  const templateHotspot =
    Array.isArray(templateScene.hotspots) && templateScene.hotspots.length > 0
      ? deepClone(templateScene.hotspots[0])
      : {
          linkId: 'A00',
          yaw: 0,
          pitch: 0,
          target: '',
          targetSceneId: '',
        };

  const sceneIds = Array.from({ length: desiredSceneCount }, (_, i) => `x700-scene-${String(i + 1).padStart(4, '0')}`);
  const sceneNames = Array.from({ length: desiredSceneCount }, (_, i) => `X700 Scene ${String(i + 1).padStart(4, '0')}`);
  const thumbnailAssetNames = Array.from(
    { length: desiredThumbnailCount },
    (_, i) => `thumbnails/thumb-${String(i + 1).padStart(3, '0')}.webp`,
  );

  const scenes = sceneIds.map((id, i) => {
    const scene = deepClone(templateScene);
    const targetIndex = (i + 1) % desiredSceneCount;
    const targetId = sceneIds[targetIndex];
    const targetName = sceneNames[targetIndex];

    scene.id = id;
    scene.name = sceneNames[i];
    scene.label = sceneNames[i];
    scene.file = '/' + pick(imagePaths, i).replace(/^\/+/, '');
    scene.hotspots = [
      {
        ...deepClone(templateHotspot),
        linkId: `L${String(i + 1).padStart(4, '0')}`,
        yaw: ((i * 17) % 360) - 180,
        pitch: ((i * 7) % 40) - 20,
        target: targetName,
        targetSceneId: targetId,
      },
    ];

    scene.tinyFile =
      desiredThumbnailCount > 0
        ? '/' + pick(thumbnailAssetNames, i).replace(/^\/+/, '')
        : null;

    scene.category = scene.category ?? 'outdoor';
    scene.floor = scene.floor ?? 'ground';
    scene._metadataSource = scene._metadataSource ?? 'user';
    scene.categorySet = Boolean(scene.categorySet);
    scene.labelSet = Boolean(scene.labelSet);
    scene.isAutoForward = Boolean(scene.isAutoForward);
    scene.colorGroup = String((i % 8) + 1);

    return scene;
  });

  const inventory = scenes.map(scene => ({
    id: scene.id,
    entry: {
      scene,
      status: 'Active',
    },
  }));

  const sceneOrder = scenes.map(scene => scene.id);
  const timeline = scenes.map((scene, i) => ({
    id: `step-${String(i + 1).padStart(4, '0')}`,
    linkId: scene.hotspots[0]?.linkId ?? `L${String(i + 1).padStart(4, '0')}`,
    sceneId: scene.id,
    targetScene: scene.hotspots[0]?.targetSceneId ?? scene.hotspots[0]?.target ?? '',
    transition: 'fade',
    duration: 1000,
  }));

  project.tourName = `${project.tourName ?? 'Imported'} - X700 Preview`;
  project.scenes = scenes;
  project.inventory = inventory;
  project.sceneOrder = sceneOrder;
  project.deletedSceneIds = [];
  project.timeline = timeline;

  if (project.validationReport && typeof project.validationReport === 'object') {
    project.validationReport = {
      ...project.validationReport,
      brokenLinksRemoved: 0,
      orphanedScenes: [],
      errors: [],
      warnings: [],
    };
  }

  const outZip = new JSZip();

  for (const [name, entry] of Object.entries(inZip.files)) {
    if (entry.dir) {
      continue;
    }
    if (name === 'project.json') {
      continue;
    }
    const bytes = await entry.async('nodebuffer');
    outZip.file(name, bytes);
  }

  for (let i = 0; i < thumbnailAssetNames.length; i += 1) {
    const thumbName = thumbnailAssetNames[i];
    const sourceImagePath = pick(imagePaths, i);
    const sourceFile = inZip.file(sourceImagePath);
    if (!sourceFile) {
      throw new Error(`Missing source image for thumbnail generation: ${sourceImagePath}`);
    }
    const bytes = await sourceFile.async('nodebuffer');
    outZip.file(thumbName, bytes);
  }

  outZip.file('project.json', JSON.stringify(project, null, 2));
  outZip.file(
    'summary.txt',
    [
      'Generated from artifacts/x445.zip',
      `Scene count: ${desiredSceneCount}`,
      `Scenes with tinyFile thumbnails: ${desiredSceneCount}`,
      `Thumbnail assets in zip: ${desiredThumbnailCount}`,
      `Image assets reused: ${imagePaths.length}`,
    ].join('\n'),
  );

  const outputBytes = await outZip.generateAsync({
    type: 'nodebuffer',
    compression: 'DEFLATE',
    compressionOptions: { level: 9 },
  });

  fs.mkdirSync(path.dirname(outputAbs), { recursive: true });
  fs.writeFileSync(outputAbs, outputBytes);

  console.log(`Created ${outputAbs}`);
  console.log(`Scenes: ${desiredSceneCount}`);
  console.log(`Hotspots: ${desiredSceneCount}`);
  console.log(`Thumbnail references: ${desiredSceneCount}`);
  console.log(`Thumbnail assets: ${desiredThumbnailCount}`);
  console.log(`Timeline items: ${timeline.length}`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
