#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();
const srcRoot = path.join(repoRoot, "src");
const allowedExtensions = new Set([".res", ".resi"]);
const consolePattern = /\bconsole\.(log|info|warn|error|debug)\s*\(/g;

function collectFiles(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === "node_modules" || entry.name.startsWith(".")) continue;
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectFiles(fullPath, out);
      continue;
    }
    if (allowedExtensions.has(path.extname(entry.name))) {
      out.push(fullPath);
    }
  }
  return out;
}

const offenders = [];
for (const filePath of collectFiles(srcRoot)) {
  const contents = fs.readFileSync(filePath, "utf8");
  const lines = contents.split("\n");
  for (let i = 0; i < lines.length; i++) {
    if (consolePattern.test(lines[i])) {
      offenders.push(`${path.relative(repoRoot, filePath)}:${i + 1}:${lines[i].trim()}`);
    }
    consolePattern.lastIndex = 0;
  }
}

if (offenders.length > 0) {
  console.error("Direct console.* usage is forbidden in ReScript source files:");
  offenders.forEach(line => console.error(`- ${line}`));
  process.exit(1);
}

console.log("No direct console.* usage found in ReScript source files.");
