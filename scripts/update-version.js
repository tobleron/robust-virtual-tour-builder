import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const pkgPath = join(process.cwd(), 'package.json');
const htmlPath = join(process.cwd(), 'index.html');
const versionJsPath = join(process.cwd(), 'src', 'version.js');

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
    html = html.replace(/\?v=[\d.]+/g, `?v=${version}`);

    if (html !== originalHtml) {
        writeFileSync(htmlPath, html);
        console.log('✅ Updated index.html (cache busters and/or CSP header)');
    } else {
        console.log('ℹ️ No change needed for index.html');
    }

    // 2. Update src/version.js
    const versionJsContent = `export const VERSION = "${version}";\nexport const BUILD_INFO = "[Stable Release]";\n`;
    writeFileSync(versionJsPath, versionJsContent);
    console.log('✅ Updated src/version.js');

    console.log(`Successfully updated version to ${version}`);
} catch (error) {
    console.error('❌ Error updating version:', error.message);
    process.exit(1);
}
