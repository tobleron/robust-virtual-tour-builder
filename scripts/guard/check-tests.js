import fs from 'fs';
import path from 'path';
import { getNextId, createTask, taskExists } from './utils.js';

const bt = String.fromCharCode(96);

function getHints(content) {
    let hints = "";
    if (content.includes("Pannellum")) {
        hints += `\n- **Mock Pannellum**: This module interacts with Pannellum. Mock the global ${bt}window.pannellum${bt} object in ${bt}tests/node-setup.js${bt} or locally.`;
    }
    if (content.includes("FFmpeg")) {
        hints += `\n- **Mock FFmpeg**: This module uses FFmpeg. Ensure the FFmpeg core is mocked or its promises are resolved instantly.`;
    }
    if (content.includes("EventBus")) {
        hints += `\n- **EventBus Integration**: Use ${bt}EventBus.dispatch${bt} spies to verify that actions are triggered correctly.`;
    }
    if (content.includes("Fetch") || content.includes("BackendApi")) {
        hints += `\n- **API Mocks**: Mock ${bt}fetch${bt} and ${bt}RequestQueue.schedule${bt}. Jules should verify that the correct endpoints are called with the expected payloads.`;
    }
    if (content.includes("Window") || content.includes("Dom")) {
        hints += `\n- **DOM/Window Bindings**: Use ${bt}ReBindings${bt} to mock browser-specific properties like ${bt}localStorage${bt}, ${bt}location${bt}, or ${bt}window.innerWidth${bt}.`;
    }

    if (hints) {
        return `\n## 💡 Implementation Hints for Cloud Agents (Jules)\n${hints}`;
    }
    return "";
}

export default function checkTests(filePath) {
    if (!fs.existsSync(filePath)) return;
    
    // Filters
    if (filePath.includes('.bs.js')) return;
    if (filePath.includes('/libs/')) return;
    if (!filePath.endsWith('.res')) return; // Only ReScript for now
    
    const filename = path.basename(filePath);
    const fileBase = path.basename(filePath, '.res');
    if (fileBase === 'Version') return;

    // Check for tests
    const testDir = 'tests/unit';
    const possibleTests = [
        path.join(testDir, `${fileBase}_v.test.res`),
        path.join(testDir, `${fileBase}.test.res`),
        path.join(testDir, `${fileBase}Test.res`)
    ];

    let existingTest = null;
    for (const t of possibleTests) {
        if (fs.existsSync(t)) {
            existingTest = t;
            break;
        }
    }

    const content = fs.readFileSync(filePath, 'utf8');

    if (!existingTest) {
        // Missing Test
        if (!taskExists(`Test_${fileBase}_New`)) {
            const nextId = getNextId();
            const taskFilename = `tests/${nextId}_Test_${fileBase}_New.md`;
            
            const taskContent = `# Task ${nextId}: Add Unit Tests for ${filename}

## 🚨 Trigger
Modifications detected in ${bt}${filePath}${bt} without established unit tests.

## Objective
Create a Vitest file ${bt}tests/unit/${fileBase}_v.test.res${bt} to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.
${getHints(content)}
`;
            createTask(taskFilename, taskContent);
        }
    } else {
        // Stale Test
        const srcStats = fs.statSync(filePath);
        const testStats = fs.statSync(existingTest);

        if (srcStats.mtimeMs > testStats.mtimeMs) {
            if (!taskExists(`Test_${fileBase}_Update`)) {
                const nextId = getNextId();
                const taskFilename = `tests/${nextId}_Test_${fileBase}_Update.md`;
                
                const taskContent = `# Task ${nextId}: Update Unit Tests for ${filename}

## 🚨 Trigger
Implementation file ${bt}${filePath}${bt} is newer than its test file ${bt}${existingTest}${bt}.

## Objective
Update ${bt}${existingTest}${bt} to ensure it covers recent changes in ${bt}${filename}${bt}.

## Requirements
- Review recent changes in ${bt}${filePath}${bt}.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.
${getHints(content)}
`;
                createTask(taskFilename, taskContent);
                console.log(`🔄 Created Update Test Task: ${taskFilename}`);
            }
        }
    }
}