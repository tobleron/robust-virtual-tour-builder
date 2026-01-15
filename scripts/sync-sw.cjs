const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const projectRoot = path.join(__dirname, '..');
const packageJsonPath = path.join(projectRoot, 'package.json');
const swPath = path.join(projectRoot, 'public', 'service-worker.js');
const publicDir = path.join(projectRoot, 'public');

function getFiles(dir, baseDir, fileList = []) {
    if (!fs.existsSync(dir)) return fileList;
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

    try {
        // 1. Get version from package.json
        const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
        const version = packageJson.version;
        const cacheName = `vtb-cache-v${version}`;

        // 2. Scan public directory
        const publicFiles = getFiles(publicDir, publicDir);
        
        // 4. Combine assets
        const manualAssets = [
            '/',
            '/index.html',
            ...publicFiles
        ].filter((asset, index, self) => {
            // Remove duplicates and ignored files
            // Don't include the service worker itself in the manual assets to avoid circularity issues 
            // though it's often fine, some SW implementations prefer it not being in the cache list
            return self.indexOf(asset) === index && 
                   !asset.endsWith('.DS_Store') && 
                   asset !== '/service-worker.js' &&
                   !asset.endsWith('.map');
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
    } catch (err) {
        console.error('[Sync SW] Error during synchronization:', err);
    }
}

// Check for --watch flag
const isWatch = process.argv.includes('--watch');

if (isWatch) {
    console.log('[Sync SW] Watching for changes in public/ and src/libs/...');
    sync(); // Initial sync

    let debounceTimer;
    const watchHandler = (event, filename) => {
        if (filename && (filename.endsWith('.js') || filename.endsWith('.css') || filename.endsWith('.json') || filename.endsWith('.png') || filename.endsWith('.jpg') || filename.endsWith('.svg'))) {
            // Avoid infinite loop if service-worker.js itself is changed
            if (filename === 'service-worker.js') return;

            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                console.log(`[Sync SW] Change detected: ${filename}. Syncing...`);
                sync();
            }, 500);
        }
    };

    fs.watch(publicDir, { recursive: true }, watchHandler);
    fs.watch(packageJsonPath, watchHandler);
} else {
    sync();
}

