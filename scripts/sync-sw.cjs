const fs = require('fs');
const path = require('path');

const projectRoot = path.join(__dirname, '..');
const packageJsonPath = path.join(projectRoot, 'package.json');
const swPath = path.join(projectRoot, 'public', 'service-worker.js');
const publicDir = path.join(projectRoot, 'public');
const libsDir = path.join(projectRoot, 'src', 'libs');

function getFiles(dir, baseDir, fileList = []) {
    const files = fs.readdirSync(dir);
    files.forEach(file => {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) {
            getFiles(filePath, baseDir, fileList);
        } else {
            const relativePath = '/' + path.relative(baseDir, filePath);
            fileList.push(relativePath);
        }
    });
    return fileList;
}

function sync() {
    console.log('[Sync SW] Starting synchronization...');

    // 1. Get version from package.json
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    const version = packageJson.version;
    const cacheName = `vtb-cache-v${version}`;

    // 2. Scan public directory
    const publicFiles = getFiles(publicDir, publicDir);
    
    // 3. Scan libs directory
    // In dist, libs are in src/libs
    const libFiles = getFiles(libsDir, projectRoot);

    // 4. Combine assets
    const manualAssets = [
        '/',
        '/index.html',
        ...publicFiles,
        ...libFiles
    ].filter((asset, index, self) => {
        // Remove duplicates and ignored files
        return self.indexOf(asset) === index && !asset.endsWith('.DS_Store');
    });

    // 5. Update service-worker.js
    let swContent = fs.readFileSync(swPath, 'utf8');

    // Update CACHE_NAME
    swContent = swContent.replace(
        /const CACHE_NAME = '.*';/,
        `const CACHE_NAME = '${cacheName}';`
    );

    // Update MANUAL_ASSETS
    const manualAssetsString = JSON.stringify(manualAssets, null, 4);
    swContent = swContent.replace(
        /const MANUAL_ASSETS = \[[\s\S]*?\];/,
        `const MANUAL_ASSETS = ${manualAssetsString};`
    );

    fs.writeFileSync(swPath, swContent, 'utf8');
    console.log(`[Sync SW] Updated CACHE_NAME to: ${cacheName}`);
    console.log(`[Sync SW] Updated MANUAL_ASSETS with ${manualAssets.length} items.`);
}

sync();
