import path from 'path';
import fs from 'fs';

import checkTests from './check-tests.js';
import checkMap from './check-map.js';
import checkTasks from './check-tasks.js';

const WATCH_DIRS = ['./src', './backend/src'];

function fullScan() {
    console.log("🔍 Running Project Guard (Static Analysis)...");
    
    // 1. Check Tasks (Maintenance)
    checkTasks();

    // 2. Scan Files (Code Quality)
    function walk(dir) {
        if (!fs.existsSync(dir)) return;
        const items = fs.readdirSync(dir);
        for (const item of items) {
            const fullPath = path.join(dir, item);
            if (fs.statSync(fullPath).isDirectory()) {
                if (item !== 'node_modules' && item !== 'libs' && item !== 'target' && item !== 'test_output.txt') {
                    walk(fullPath);
                }
            } else {

                checkTests(fullPath);
            }
        }
    }

    WATCH_DIRS.forEach(dir => walk(dir));
    
    // 3. Check Map (Architecture)
    checkMap();
    
    console.log("✅ Project Guard checks complete.");
}

// Execute
fullScan();