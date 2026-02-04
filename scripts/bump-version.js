import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

/**
 * Smart Versioning Utility
 * Logic:
 * 1. Explicit Argument: 'major', 'minor', 'patch' (overrides message)
 * 2. Auto-Detection (from commit message):
 *    - 'breaking change', '!' prefix -> Major
 *    - 'feat:', 'refactor:', 'perf:', 'implement' -> Minor
 *    - 'fix:', 'chore:', 'test:', 'docs:', 'build:', 'ci:', 'merge' -> Patch
 * 3. Fallback: If no detection, only build number increments.
 */

const args = process.argv.slice(2);
const input = args[0]; // Can be 'major', 'minor', 'patch', 'none', or a commit message

const pkgPath = join(process.cwd(), 'package.json');
try {
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
    let [major, minor, patch] = pkg.version.split('.').map(Number);
    let bumpType = 'none';

    // 1. Determine bump type
    if (['major', 'minor', 'patch'].includes(input)) {
        bumpType = input;
    } else if (input && input !== 'none') {
        const msg = input.toLowerCase();

        // Breaking Change Detection
        if (msg.includes('breaking change:') || /^(\w+)\!(\(\w+\))?:/.test(msg)) {
            bumpType = 'major';
        }
        // Feature / Progress Detection
        else if (
            msg.startsWith('feat:') ||
            msg.startsWith('refactor:') ||
            msg.startsWith('perf:') ||
            msg.includes('implement') ||
            msg.includes('add') ||
            msg.includes('new feature')
        ) {
            bumpType = 'minor';
        }
        // Maintenance / Fix Detection
        else if (
            msg.startsWith('fix:') ||
            msg.startsWith('chore:') ||
            msg.startsWith('test:') ||
            msg.startsWith('docs:') ||
            msg.startsWith('build:') ||
            msg.startsWith('ci:') ||
            msg.startsWith('merge') ||
            msg.includes('fix') ||
            msg.includes('update') ||
            msg.includes('patch')
        ) {
            bumpType = 'patch';
        }
    }

    // 2. Apply bump
    if (bumpType !== 'none') {
        if (bumpType === 'major') {
            major++;
            minor = 0;
            patch = 0;
        } else if (bumpType === 'minor') {
            minor++;
            patch = 0;
        } else if (bumpType === 'patch') {
            patch++;
        }

        pkg.version = `${major}.${minor}.${patch}`;
        // Reset build number on semantic bump to signify new release cycle
        pkg.buildNumber = 0;
        console.log(`✅  Semantic Bump: ${pkg.version} (${bumpType.toUpperCase()}) | Build reset to 0`);
    } else {
        // Just increment build number if no semantic trigger found
        pkg.buildNumber = (pkg.buildNumber || 0) + 1;
        console.log(`🔢  Standard Build: v${pkg.version}+${pkg.buildNumber} (No semantic change)`);
    }

    writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');

} catch (e) {
    console.error('❌ Versioning Error:', e.message);
    process.exit(1);
}
