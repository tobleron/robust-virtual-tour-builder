# Task 87: Create Centralized Version Management

## Priority: 🟢 LOW

## Context
Version numbers are scattered across multiple files with no single source of truth:
- `package.json` → `"version": "4.2.39"`
- `index.html` → Multiple `?v=4.2.39` cache busters
- `src/version.js` → Exists but may not be the source

This leads to:
1. Inconsistent versions
2. Manual updates needed in multiple places
3. The malformed CSP header (`http-equiv=4.2.39"...`) suggests copy-paste errors

## Goals
1. Create a single source of truth for version
2. Automate cache-buster updates
3. Prevent version drift

## Implementation

### Option A: Package.json as Source (Recommended)

**1. Create version injection script:**
```javascript
// scripts/update-version.js
import { readFileSync, writeFileSync } from 'fs';

const pkg = JSON.parse(readFileSync('package.json', 'utf8'));
const version = pkg.version;

// Update index.html cache busters
let html = readFileSync('index.html', 'utf8');
html = html.replace(/\?v=[\d.]+/g, `?v=${version}`);
writeFileSync('index.html', html);

// Update src/version.js
writeFileSync('src/version.js', `export const VERSION = "${version}";\n`);

console.log(`Updated version to ${version}`);
```

**2. Add npm scripts:**
```json
{
  "scripts": {
    "version": "node scripts/update-version.js",
    "precommit": "npm run version"
  }
}
```

**3. Use version in ReScript:**
```rescript
// src/utils/Version.res
@module("../version.js") external version: string = "VERSION"

let getVersion = () => version
```

### Option B: Build-time Injection

If using a bundler, inject version at build time:
```javascript
// vite.config.js or similar
define: {
  __VERSION__: JSON.stringify(pkg.version)
}
```

## Current Version References to Update

| File | Location | Current |
|------|----------|---------|
| `package.json` | Line 3 | `"version": "4.2.39"` ← SOURCE |
| `index.html` | Line 104 | `output.css?v=4.2.39` |
| `index.html` | Line 106 | `style.css?v=4.2.39` |
| `index.html` | Line 113 | `Main.bs.js?v=4.2.39` |
| `src/version.js` | Line 1 | Check current value |

## Acceptance Criteria
- [ ] Single source of truth in `package.json`
- [ ] Script to sync version to other files
- [ ] Version accessible in ReScript code
- [ ] Cache busters use correct version
- [ ] Documentation on how to bump version

## Files to Create
- `scripts/update-version.js`

## Files to Modify
- `package.json` - add version script
- `index.html` - ensure version placeholders work
- `src/version.js` - auto-updated by script
- `src/utils/Version.res` - optional accessor

## Testing
1. Run `npm run version`
2. Check all files have matching version
3. Bump version in package.json
4. Run script again
5. Verify all files updated
