const fs = require('fs');
const path = require('path');

const ROOT_DIRS = ['src', 'backend/src'];
const TAG_PATTERN = /@efficiency/;

function walkDir(dir, callback) {
    if (!fs.existsSync(dir)) return;
    fs.readdirSync(dir).forEach(f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        if (isDirectory) {
            walkDir(dirPath, callback);
        } else {
            callback(path.join(dir, f));
        }
    });
}

function stripTags(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    let modified = false;
    let newLines = [];

    lines.forEach((line, index) => {
        // preserve first 4 lines (index 0-3)
        if (index < 4) {
            newLines.push(line);
            return;
        }

        if (TAG_PATTERN.test(line)) {
            console.log(`[STRIP] Removing zombie tag from ${filePath}:${index + 1}: ${line.trim()}`);
            modified = true;
        } else {
            newLines.push(line);
        }
    });

    if (modified) {
        fs.writeFileSync(filePath, newLines.join('\n'));
    }
}

console.log("🔍 Scanning for zombie @efficiency tags...");
ROOT_DIRS.forEach(dir => {
    walkDir(dir, stripTags);
});
console.log("✅ Scan complete.");
