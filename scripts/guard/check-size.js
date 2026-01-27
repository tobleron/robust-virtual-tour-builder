import fs from 'fs';
import path from 'path';
import { getNextId, createTask, taskExists } from './utils.js';

const bt = String.fromCharCode(96);
const LIMIT = 360;

export default function checkSize(filePath) {
    if (!fs.existsSync(filePath)) return;
    
    // Filters
    if (filePath.includes('.bs.js')) return;
    if (filePath.includes('/libs/')) return;
    const filename = path.basename(filePath);
    if (!filename.endsWith('.res') && !filename.endsWith('.rs') && !filename.endsWith('.js')) return;
    if (filename.startsWith('Version')) return;

    // Check size
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n').length;

    if (lines > LIMIT) {
        const fileBase = path.basename(filePath, path.extname(filePath));
        
        // Check if task already exists
        if (!taskExists(`Refactor_${fileBase}`)) {
            const nextId = getNextId();
            const taskFilename = `${nextId}_Refactor_${fileBase}.md`;
            
            const taskContent = `# Task ${nextId}: Refactor ${filename} (Oversized)

## 🚨 Trigger
File ${bt}${filePath}${bt} exceeds **${LIMIT} lines** (Current: ${lines}).

## Objective
Decompose ${bt}${filename}${bt} into smaller, focused modules. Aim for < 300 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze ${filePath}. It has ${lines} lines. Extract the core logic into new specialized modules (e.g. ${fileBase}Types.res, ${fileBase}Logic.res) while keeping the main module as a lightweight facade."
`;
            createTask(taskFilename, taskContent);
            console.log(`⚠️  Created Refactor Task: ${taskFilename}`);
        }
    }
}
