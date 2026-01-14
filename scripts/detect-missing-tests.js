const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🕵️  Scanning for missing unit tests...');

// 1. Get List of Staged Files
const stagedFiles = execSync('git diff --name-only --cached').toString().split('\n').filter(Boolean);

// Filter for logic files (ReScript/Rust) in src/ or backend/src/
// Exclude: UI components (usually in components/), bindings, types, and the test runner itself
const sourceFiles = stagedFiles.filter(file => {
    return (
        (file.endsWith('.res') && !file.includes('/components/') && !file.includes('/types/') && !file.includes('TestRunner')) ||
        (file.endsWith('.rs') && !file.includes('mod.rs'))
    );
});

const missingTests = [];

sourceFiles.forEach(file => {
    const fileName = path.basename(file);
    const nameWithoutExt = fileName.split('.')[0];

    let testExists = false;

    if (file.endsWith('.res')) {
        // ReScript: Expect tests/unit/NameTest.res
        const expectedTestPath = `tests/unit/${nameWithoutExt}Test.res`;
        if (fs.existsSync(expectedTestPath)) {
            testExists = true;
        }
    } else if (file.endsWith('.rs')) {
        // Rust: Expect inline #[cfg(test)]
        // We read the file content to check for test module
        try {
            const content = fs.readFileSync(file, 'utf8');
            if (content.includes('#[cfg(test)]')) {
                testExists = true;
            } else {
                // Also check for separate test file in tests/ or sibling
                if (fs.existsSync(file.replace('.rs', '_test.rs'))) testExists = true;
            }
        } catch (e) {
            // file might be deleted
        }
    }

    if (!testExists) {
        missingTests.push({
            file: file,
            expected: file.endsWith('.res') ? `tests/unit/${nameWithoutExt}Test.res` : `Start file with #[cfg(test)]`
        });
    }
});

// Report Results
if (missingTests.length > 0) {
    console.log('\n⚠️  \x1b[33mPOTENTIAL TEST GAPS DETECTED:\x1b[0m');
    missingTests.forEach(item => {
        console.log(`   - Modified: \x1b[36m${item.file}\x1b[0m`);
        console.log(`     Missing:  ${item.expected}`);
    });
    console.log('\n(Rule: New logic should have corresponding tests.)');
    process.exit(1); // Exit with error to trigger strict check
} else {
    console.log('✅ All logic changes have corresponding tests (or are exempt).');
    process.exit(0);
}
