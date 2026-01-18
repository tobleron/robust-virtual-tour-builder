const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const projectRoot = path.join(__dirname, '..');
const packageJsonPath = path.join(projectRoot, 'package.json');
const swPath = path.join(projectRoot, 'public', 'service-worker.js');
const publicDir = path.join(projectRoot, 'public');
const swResPath = path.join(projectRoot, 'src', 'ServiceWorkerMain.res');
const swJsCompiledPath = path.join(projectRoot, 'src', 'ServiceWorkerMain.bs.js');

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

function compile() {
    console.log('[Sync SW] Compiling ReScript...');
    execSync('npm run res:build', { stdio: 'inherit' });
}

function bundle() {
    if (!fs.existsSync(swJsCompiledPath)) {
        console.log('[Sync SW] Compiled file not found, skipping bundle.');
        return;
    }
    console.log('[Sync SW] Bundling Service Worker...');
    try {
        execSync(`npx esbuild ${swJsCompiledPath} --bundle --minify --format=iife --outfile=${swPath}`, { stdio: 'inherit' });
        console.log(`[Sync SW] Successfully bundled to ${swPath}`);
    } catch (e) {
        console.error('[Sync SW] Bundling failed:', e.message);
    }
}

function updateResFile() {
    console.log('[Sync SW] Starting synchronization...');
    try {
        // 1. Get version from package.json
        const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
        const version = packageJson.version;
        const cacheName = `vtb-cache-v${version}`;

        // 2. Scan public directory
        const publicFiles = getFiles(publicDir, publicDir);

        // 3. Combine assets
        const manualAssets = [
            '/',
            '/index.html',
            ...publicFiles
        ].filter((asset, index, self) => {
            return self.indexOf(asset) === index &&
                !asset.endsWith('.DS_Store') &&
                asset !== '/service-worker.js' &&
                !asset.endsWith('.map');
        });

        // 4. Update src/ServiceWorkerMain.res
        let swResContent = fs.readFileSync(swResPath, 'utf8');

        // Update cacheName
        swResContent = swResContent.replace(
            /let cacheName = ".*"/,
            `let cacheName = "${cacheName}"`
        );

        // Update manualAssets
        const manualAssetsString = JSON.stringify(manualAssets);
        swResContent = swResContent.replace(
            /let manualAssets = \[.*\]/,
            `let manualAssets = ${manualAssetsString}`
        );

        fs.writeFileSync(swResPath, swResContent, 'utf8');
        console.log(`[Sync SW] Updated src/ServiceWorkerMain.res with ${manualAssets.length} assets.`);
    } catch (err) {
        console.error('[Sync SW] Error during synchronization:', err);
    }
}

// Check for --watch flag
const isWatch = process.argv.includes('--watch');

if (isWatch) {
    console.log('[Sync SW] Watching for changes in public/ and src/libs/...');
    updateResFile(); // Initial update

    // Do NOT compile here if we assume res:watch is running.
    // However, we should bundle if possible to ensure we have a SW.
    if (fs.existsSync(swJsCompiledPath)) {
        bundle();
    }

    let debounceTimer;
    const watchHandler = (event, filename) => {
        if (filename && (filename.endsWith('.js') || filename.endsWith('.css') || filename.endsWith('.json') || filename.endsWith('.png') || filename.endsWith('.jpg') || filename.endsWith('.svg'))) {
            // Avoid infinite loop if service-worker.js itself is changed
            if (filename === 'service-worker.js') return;

            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                console.log(`[Sync SW] Change detected: ${filename}. Syncing...`);
                updateResFile();
            }, 500);
        }
    };

    fs.watch(publicDir, { recursive: true }, watchHandler);
    fs.watch(packageJsonPath, watchHandler);

    // Watch for .bs.js changes to trigger bundle
    // We use fs.watchFile because simpler file watching is enough and safer against replace events
    let bundleTimer;
    console.log(`[Sync SW] Watching ${swJsCompiledPath} for bundling...`);
    fs.watchFile(swJsCompiledPath, { interval: 1000 }, (curr, prev) => {
        if (curr.mtime !== prev.mtime) {
            console.log('[Sync SW] ServiceWorkerMain.bs.js changed. Bundling...');
            clearTimeout(bundleTimer);
            bundleTimer = setTimeout(bundle, 200);
        }
    });

} else {
    // One-off sync
    updateResFile();
    compile();
    bundle();
}
