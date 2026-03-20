#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import { gzipSync } from 'node:zlib';

const DIST_DIR = path.resolve('dist');
const MANIFEST_PATH = path.join(DIST_DIR, 'asset-manifest.json');

const budgets = {
  maxTotalJsBytes: Number(process.env.BUDGET_MAX_TOTAL_JS_BYTES ?? 6_500_000),
  maxTotalGzipBytes: Number(process.env.BUDGET_MAX_TOTAL_GZIP_BYTES ?? 1_050_000),
  maxLargestChunkBytes: Number(process.env.BUDGET_MAX_LARGEST_CHUNK_BYTES ?? 2_500_000),
};

async function main() {
  const manifestRaw = await fs.readFile(MANIFEST_PATH, 'utf8');
  const manifest = JSON.parse(manifestRaw);
  const entries = Array.isArray(manifest.allFiles) ? manifest.allFiles : [];
  const jsFiles = entries
    .filter((v) => (v).endsWith('.js'))
    .map((v) => path.join(DIST_DIR, (v).replace(/^\//, '')));

  if (jsFiles.length === 0) {
    console.error(`[budget][bundle] No JS files found in ${MANIFEST_PATH}`);
    process.exit(1);
  }

  let totalJs = 0;
  let totalGzip = 0;
  let largest = { file: '', size: 0 };

  for (const abs of jsFiles) {
    const content = await fs.readFile(abs);
    const size = content.byteLength;
    const gzip = gzipSync(content).byteLength;
    const file = path.relative(DIST_DIR, abs);

    totalJs += size;
    totalGzip += gzip;
    if (size > largest.size) {
      largest = { file, size };
    }
  }

  const failures = [];
  if (totalJs > budgets.maxTotalJsBytes) {
    failures.push(
      `Total JS bytes exceeded: ${totalJs} > ${budgets.maxTotalJsBytes}`,
    );
  }
  if (totalGzip > budgets.maxTotalGzipBytes) {
    failures.push(
      `Total gzip bytes exceeded: ${totalGzip} > ${budgets.maxTotalGzipBytes}`,
    );
  }
  if (largest.size > budgets.maxLargestChunkBytes) {
    failures.push(
      `Largest chunk exceeded (${largest.file}): ${largest.size} > ${budgets.maxLargestChunkBytes}`,
    );
  }

  console.log('[budget][bundle] Summary');
  console.log(`- total_js_bytes=${totalJs}`);
  console.log(`- total_gzip_bytes=${totalGzip}`);
  console.log(`- largest_chunk=${largest.file}`);
  console.log(`- largest_chunk_bytes=${largest.size}`);

  if (failures.length > 0) {
    for (const f of failures) {
      console.error(`[budget][bundle][FAIL] ${f}`);
    }
    process.exit(1);
  }

  console.log('[budget][bundle][PASS] Build bundle is within budget.');
}

main().catch((err) => {
  console.error('[budget][bundle][ERROR]', err);
  process.exit(1);
});
