import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = __dirname;
const IMAGE_PATH = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');
const STANDARD_PROJECT_ZIP = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

const minimalJpeg = fs.readFileSync(path.join(__dirname, '../../../public/images/logo.png'));
// Note: Rename to image.jpg is fine for testing, browser will detect MIME type from content.

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

  if (!fs.existsSync(STANDARD_PROJECT_ZIP)) {
    throw new Error(`Missing required E2E project artifact: ${STANDARD_PROJECT_ZIP}`);
  }
  console.log(`Verified standard E2E project: ${STANDARD_PROJECT_ZIP}`);
}

main().catch(console.error);
