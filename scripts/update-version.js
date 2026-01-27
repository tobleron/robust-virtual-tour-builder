import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

const pkgPath = join(process.cwd(), 'package.json');
const htmlPath = join(process.cwd(), 'index.html');

try {
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
    const version = pkg.version;

    console.log(`Syncing version ${version} across files...`);

    // 1. Update index.html cache busters
    const originalHtml = readFileSync(htmlPath, 'utf8');
    let html = originalHtml;

    // Fix the malformed CSP header if it exists
    // It looks like: <meta http-equiv=4.2.55"Content-Security-Policy"
    html = html.replace(/http-equiv=[\d.]+"Content-Security-Policy"/, 'http-equiv="Content-Security-Policy"');

    // Update legitimate cache busters: ?v=1.2.3
    const buildNumber = pkg.buildNumber || 0;
    const fullVersion = `${version}+${buildNumber}`;
    html = html.replace(/\?v=[\d.+]+/g, `?v=${fullVersion}`);

    if (html !== originalHtml) {
        writeFileSync(htmlPath, html);
        console.log('✅ Updated index.html (cache busters and/or CSP header)');
    } else {
        console.log('ℹ️ No change needed for index.html');
    }

    // 2. Update src/utils/VersionData.res
    let currentBranch = 'unknown';
    try {
        currentBranch = execSync('git branch --show-current').toString().trim();
    } catch (e) {
        console.warn('⚠️ Could not detect git branch, defaulting to unknown.');
    }

    let buildInfo = "[Experimental Build]";
    if (currentBranch === 'main') {
        buildInfo = "[Stable Release]";
    } else if (currentBranch === 'testing') {
        buildInfo = "[Testing Release]";
    } else if (currentBranch === 'development') {
        buildInfo = "[Development Build]";
    }

    const versionResPath = join(process.cwd(), 'src', 'utils', 'VersionData.res');
    const versionResContent = `/**\n * GENERATED FILE - DO NOT EDIT MANUALLY\n * This file is updated by scripts/update-version.js\n */\n\nlet version = "${version}"\nlet buildNumber = ${buildNumber}\nlet buildInfo = "${buildInfo}"\n`;
    writeFileSync(versionResPath, versionResContent);
    console.log(`✅ Updated src/utils/VersionData.res (Branch: ${currentBranch} -> ${buildInfo})`);

    console.log(`Successfully updated version to ${version}`);
} catch (error) {
    console.error('❌ Error updating version:', error.message);
    process.exit(1);
}
