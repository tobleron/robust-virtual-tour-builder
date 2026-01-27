import fs from 'fs';
import path from 'path';
import { getNextId, createTask, taskExists } from './utils.js';

const bt = String.fromCharCode(96);
const MAP_FILE = 'MAP.md';

function getAllFiles(dirPath, arrayOfFiles) {
    if (!fs.existsSync(dirPath)) return arrayOfFiles || [];
    const files = fs.readdirSync(dirPath);
    arrayOfFiles = arrayOfFiles || [];
  
    files.forEach(function(file) {
      const fullPath = path.join(dirPath, file);
      if (fs.statSync(fullPath).isDirectory()) {
        if (file !== 'node_modules' && file !== 'dist' && file !== 'target' && file !== 'libs') {
            arrayOfFiles = getAllFiles(fullPath, arrayOfFiles);
        }
      } else {
        if (file.endsWith('.res') || file.endsWith('.rs')) {
            arrayOfFiles.push(fullPath);
        }
      }
    });
  
    return arrayOfFiles;
}

export default function checkMap() {
    if (!fs.existsSync(MAP_FILE)) return;

    const mapContent = fs.readFileSync(MAP_FILE, 'utf8');
    
    // Extract paths from MAP.md
    const regex = /\ \[.*? \]\[(.*?)\)/g;
    const mappedPaths = new Set();
    let match;
    while ((match = regex.exec(mapContent)) !== null) {
        let p = match[1];
        if (p.startsWith('file://')) {
             if (p.includes('/robust-virtual-tour-builder/')) {
                 p = p.split('/robust-virtual-tour-builder/')[1];
             }
        }
        mappedPaths.add(path.normalize(p));
    }
    
    // Also add the text part of the link as a fallback if the link is weird
    // [src/Main.res](...)
    const textRegex = / \[ (.*?) \]\[\(/g;
    while ((match = textRegex.exec(mapContent)) !== null) {
         mappedPaths.add(path.normalize(match[1]));
    }

    const allSrcFiles = getAllFiles('./src').concat(getAllFiles('./backend/src'));
    const unmappedFiles = [];

    allSrcFiles.forEach(f => {
        if (!mappedPaths.has(path.normalize(f))) {
            unmappedFiles.push(f);
        }
    });

    if (unmappedFiles.length > 0) {
        console.log(`🗺️  Found ${unmappedFiles.length} unmapped files.`);
        
        let newContent = mapContent;
        let addedSection = false;
        
        if (!newContent.includes('## 🆕 Unmapped Modules')) {
            newContent += "\n\n## 🆕 Unmapped Modules\n";
            addedSection = true;
        }

        let addedCount = 0;
        unmappedFiles.forEach(f => {
            // Check if already in the unmapped section to avoid duplicates if regex missed it
            if (!newContent.includes(`[${f}]`)) {
                // Use relative path for link
                const link = `file://${process.cwd()}/${f}`; 
                newContent += `* [${f}](${link}): New module detected. Please classify. #new\n`;
                addedCount++;
            }
        });

        if (addedCount > 0) {
            fs.writeFileSync(MAP_FILE, newContent);
            console.log(`🗺️  Added ${addedCount} files to MAP.md.`);
            
            if (!taskExists("Classify_Map_Entries")) {
                const nextId = getNextId();
                const taskFilename = `${nextId}_Classify_Map_Entries.md`;
                
                const taskContent = `# Task ${nextId}: Classify New Map Entries

## 🚨 Trigger
New modules were detected and added to the 'Unmapped Modules' section of 
${bt}MAP.md${bt}
.

## Objective
Move the entries from 'Unmapped Modules' to their appropriate semantic sections in 
${bt}MAP.md${bt}
.
`;
                createTask(taskFilename, taskContent);
            }
        }
    }
}