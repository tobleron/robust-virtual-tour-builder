import fs from 'fs';
import path from 'path';
import JSZip from 'jszip';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = __dirname;
const IMAGE_PATH = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');
const ZIP_PATH = path.join(FIXTURES_DIR, 'tour.vt.zip');
const ZIP_LINKED_PATH = path.join(FIXTURES_DIR, 'tour_linked.vt.zip');
const ZIP_SIM_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

const minimalJpeg = fs.readFileSync(path.join(__dirname, '../../../public/images/logo.png'));
// Note: Rename to image.jpg is fine for testing, browser will detect MIME type from content.

const projectJson = {
  id: "test-tour-id",
  tourName: "Test Tour",
  scenes: [
    {
      id: "scene-1",
      name: "Scene 1",
      label: "Scene 1",
      file: "images/image.jpg",
      hotspots: [],
      quality: { score: 9.0, stats: { avgLuminance: 120 } },
      colorGroup: "1"
    }
  ]
};

const projectJsonLinked = {
  id: "test-tour-linked",
  tourName: "Test Tour Linked",
  scenes: [
    {
      id: "scene-1",
      name: "Scene 1",
      label: "Scene 1",
      file: "images/image.jpg",
      hotspots: [
        {
          linkId: "link-1",
          yaw: 0,
          pitch: 0,
          target: "Scene 2",
          targetYaw: 0,
          targetPitch: 0
        }
      ],
      quality: { score: 9.0, stats: { avgLuminance: 120 } },
      colorGroup: "1"
    },
    {
      id: "scene-2",
      name: "Scene 2",
      label: "Scene 2",
      file: "images/image.jpg",
      hotspots: [],
      quality: { score: 9.0, stats: { avgLuminance: 120 } },
      colorGroup: "2"
    }
  ]
};

const projectJsonSim = {
  id: "test-tour-sim",
  tourName: "Test Tour Sim",
  scenes: [
    {
      id: "scene-1",
      name: "Scene 1",
      label: "Scene 1",
      file: "images/image.jpg",
      hotspots: [{ linkId: "l1", yaw: 0, pitch: 0, target: "Scene 2" }],
      quality: { score: 9.0, stats: { avgLuminance: 120 } },
      colorGroup: "1"
    },
    {
      id: "scene-2",
      name: "Scene 2",
      label: "Scene 2",
      file: "images/image.jpg",
      hotspots: [{ linkId: "l2", yaw: 0, pitch: 0, target: "Scene 3" }],
      quality: { score: 9.0, stats: { avgLuminance: 120 } },
      colorGroup: "1"
    },
    {
      id: "scene-3",
      name: "Scene 3",
      label: "Scene 3",
      file: "images/image.jpg",
      hotspots: [{ linkId: "l3", yaw: 0, pitch: 0, target: "Scene 1" }],
      quality: { score: 9.0, stats: { avgLuminance: 120 } },
      colorGroup: "1"
    }
  ]
};

async function main() {
  console.log('Generating fixtures...');

  // Write image
  fs.writeFileSync(IMAGE_PATH, minimalJpeg);
  console.log(`Created ${IMAGE_PATH}`);

  // Write unique images (append byte to change hash)
  const jpeg2 = Buffer.concat([minimalJpeg, Buffer.from([0x01])]);
  fs.writeFileSync(IMAGE_PATH_2, jpeg2);
  console.log(`Created ${IMAGE_PATH_2}`);

  const jpeg3 = Buffer.concat([minimalJpeg, Buffer.from([0x02])]);
  fs.writeFileSync(IMAGE_PATH_3, jpeg3);
  console.log(`Created ${IMAGE_PATH_3}`);

  // Create ZIP
  const zip = new JSZip();
  zip.file("project.json", JSON.stringify(projectJson, null, 2));
  zip.file("images/image.jpg", minimalJpeg);
  const content = await zip.generateAsync({ type: "nodebuffer" });
  fs.writeFileSync(ZIP_PATH, content);
  console.log(`Created ${ZIP_PATH}`);

  // Create Linked ZIP
  const zipLinked = new JSZip();
  zipLinked.file("project.json", JSON.stringify(projectJsonLinked, null, 2));
  zipLinked.file("images/image.jpg", minimalJpeg);
  const contentLinked = await zipLinked.generateAsync({ type: "nodebuffer" });
  fs.writeFileSync(ZIP_LINKED_PATH, contentLinked);
  console.log(`Created ${ZIP_LINKED_PATH}`);

  // Create Sim ZIP
  const zipSim = new JSZip();
  zipSim.file("project.json", JSON.stringify(projectJsonSim, null, 2));
  zipSim.file("images/image.jpg", minimalJpeg);
  const contentSim = await zipSim.generateAsync({ type: "nodebuffer" });
  fs.writeFileSync(ZIP_SIM_PATH, contentSim);
  console.log(`Created ${ZIP_SIM_PATH}`);
}

main().catch(console.error);
