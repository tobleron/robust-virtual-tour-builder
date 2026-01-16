import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

console.log('🕵️  Scanning for missing unit tests...');

// 1. Get List of Staged Files
const stagedFiles = execSync('git diff --name-only --cached').toString().split('\n').filter(Boolean);

// Filter for logic files: ReScript (.res) or Rust (.rs)
// Exclude: UI components, types, bindings, test runners, and mod.rs
const sourceFiles = stagedFiles.filter(file => {
    // 1. Ignore deleted files
    if (!fs.existsSync(file)) return false;

    // 2. Ignore whitespace-only changes (Formatting)
    try {
        const diff = execSync(`git diff -w --cached "${file}"`).toString();
        if (diff.trim().length === 0) return false;
    } catch (e) {
        return true; // If diff fails, assume it changed
    }

    return (
        (file.endsWith('.res') && !file.startsWith('tests/') && !file.endsWith('Test.res') && !file.includes('/components/') && !file.includes('/types/') && !file.includes('TestRunner')) ||
        (file.endsWith('.rs') && !file.includes('mod.rs') && !file.includes('main.rs') && !file.endsWith('_test.rs') && !file.endsWith('_tests.rs'))
    );
});

const missingTests = [];

sourceFiles.forEach(file => {
    const fileName = path.basename(file);
    const nameWithoutExt = fileName.split('.')[0];
    let testExists = false;

    if (file.endsWith('.res')) {
        const expectedTestPath = `tests/unit/${nameWithoutExt}Test.res`;
        if (fs.existsSync(expectedTestPath)) testExists = true;
    } else if (file.endsWith('.rs')) {
        try {
            const content = fs.readFileSync(file, 'utf8');
            if (content.includes('#[cfg(test)]')) testExists = true;
            else if (fs.existsSync(file.replace('.rs', '_test.rs'))) testExists = true;
            else if (fs.existsSync(file.replace('.rs', '_tests.rs'))) testExists = true;
            else {
                // Check if this is a sub-module file (e.g., backend/src/foo/bar.rs)
                // If so, check if parent mod.rs has tests
                const dirName = path.dirname(file);
                const modPath = path.join(dirName, 'mod.rs');
                if (fs.existsSync(modPath)) {
                    const modContent = fs.readFileSync(modPath, 'utf8');
                    if (modContent.includes('#[cfg(test)]')) testExists = true;
                }
            }
        } catch (e) { }
    }

    if (!testExists) {
        missingTests.push({
            file: file,
            name: nameWithoutExt,
            type: file.endsWith('.res') ? 'ReScript' : 'Rust'
        });
    }
});

// 2. Generate Tasks for Missing Tests
if (missingTests.length > 0) {
    console.log('\n⚠️  \x1b[33mPOTENTIAL TEST GAPS DETECTED:\x1b[0m');

    // Get next Task ID
    let nextId = 0;
    try {
        const allTasks = fs.readdirSync('tasks/pending').concat(fs.existsSync('tasks/completed') ? fs.readdirSync('tasks/completed') : []);
        const ids = allTasks
            .map(f => parseInt(f.split('_')[0]))
            .filter(n => !isNaN(n));
        const maxId = ids.length > 0 ? Math.max(...ids) : 0;
        nextId = maxId + 1;
    } catch (e) {
        // failed to read dirs, fallback to 0
        console.warn("Could not determine next task ID, using timestamp suffix.");
    }

    let createdCount = 0;

    missingTests.forEach(item => {
        const taskTitle = `Add_Tests_for_${item.name}`;

        // Check if task already exists (fuzzy check)
        const exists = fs.readdirSync('tasks/pending').some(f => f.includes(taskTitle));

        if (!exists) {
            const taskId = nextId + createdCount;
            const taskFileName = `tasks/pending/${taskId}_${taskTitle}.md`;

            const content = `# Task ${taskId}: Add Unit Tests for ${item.name}\n\n` +
                `## 🚨 Context\n` +
                `This task was auto-generated because modifications were detected in \`${item.file}\` without corresponding unit tests.\n\n` +
                `## 🎯 Objective\n` +
                `Create a unit test file to verify the logic in \`${item.file}\`.\n\n` +
                `## 🛠Implementation Specs\n` +
                (item.type === 'ReScript'
                    ? `- Create \`tests/unit/${item.name}Test.res\`\n- Register it in \`tests/TestRunner.res\``
                    : `- Add \`#[cfg(test)]\` module to the bottom of \`${item.file}\``) +
                `\n- Ensure all tests pass with \`npm test\`.\n`;

            fs.writeFileSync(taskFileName, content);
            console.log(`   - Generated Task: \x1b[36m${taskFileName}\x1b[0m`);
            createdCount++;
        } else {
            console.log(`   - Task already exists for: ${item.file}`);
        }
    });

    if (createdCount > 0) {
        console.log(`\n\x1b[32m✅ Created ${createdCount} task(s) to address missing tests.\x1b[0m`);
    }

    console.log('❌ Commit blocked until tests are implemented.');
    process.exit(1);
} else {
    console.log('✅ All logic changes have corresponding tests.');
    process.exit(0);
}
