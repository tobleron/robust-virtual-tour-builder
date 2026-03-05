#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();
const srcRoot = path.join(repoRoot, "src");
const allowedExtensions = new Set([".res", ".resi"]);

const forbiddenPatterns = [
  { regex: /\brescript-schema\b/, label: "rescript-schema" },
  { regex: /\bSchema\./, label: "Schema.* usage" },
  { regex: /\bparseOrThrow\b/, label: "parseOrThrow usage" },
  { regex: /\bJSON\.parseExn\b/, label: "JSON.parseExn usage" },
  { regex: /\bJs\.Json\.parseExn\b/, label: "Js.Json.parseExn usage" },
  { regex: /\bJSON\.parseOrThrow\b/, label: "JSON.parseOrThrow usage" },
];

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
    const line = lines[i];
    for (const pattern of forbiddenPatterns) {
      if (pattern.regex.test(line)) {
        offenders.push({
          file: path.relative(repoRoot, filePath),
          line: i + 1,
          label: pattern.label,
          code: line.trim(),
        });
      }
      pattern.regex.lastIndex = 0;
    }
  }
}

if (offenders.length > 0) {
  console.error("ReScript JSON standards check failed. Forbidden patterns found in src/:");
  offenders.forEach(entry => {
    console.error(`- ${entry.file}:${entry.line} [${entry.label}] ${entry.code}`);
  });
  process.exit(1);
}

console.log("ReScript JSON standards check passed for src/.");
