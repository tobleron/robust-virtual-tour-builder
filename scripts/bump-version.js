
import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const args = process.argv.slice(2);
const bumpType = args[0]; // 'major', 'minor', 'patch'

const validTypes = ['major', 'minor', 'patch'];

if (!validTypes.includes(bumpType)) {
    console.log('ℹ️  No semantic version bump requested (skipping).');
    process.exit(0);
}

const pkgPath = join(process.cwd(), 'package.json');
try {
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
    let [major, minor, patch] = pkg.version.split('.').map(Number);

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
    writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
    console.log(`✅  Bumped version to ${pkg.version} (${bumpType})`);

} catch (e) {
    console.error('❌ Error bumping version:', e.message);
    process.exit(1);
}
