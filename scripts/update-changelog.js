import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const changelogPath = join(process.cwd(), 'CHANGELOG.md');
const pkgPath = join(process.cwd(), 'package.json');

const commitMsg = process.argv[2];
if (!commitMsg) {
    console.error('❌ Error: No commit message provided for changelog update.');
    process.exit(1);
}

try {
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
    const version = pkg.version;
    const date = new Date().toISOString().split('T')[0];
    const versionHeader = `## [${version}] - ${date}`;

    let changelog = readFileSync(changelogPath, 'utf8');

    // Categorize based on prefix
    let category = 'Changed';
    let cleanMsg = commitMsg;

    if (commitMsg.startsWith('feat:')) {
        category = 'Added';
        cleanMsg = commitMsg.replace('feat:', '').trim();
    } else if (commitMsg.startsWith('fix:')) {
        category = 'Fixed';
        cleanMsg = commitMsg.replace('fix:', '').trim();
    } else if (commitMsg.startsWith('security:')) {
        category = 'Security';
        cleanMsg = commitMsg.replace('security:', '').trim();
    } else if (commitMsg.startsWith('perf:')) {
        category = 'Performance';
        cleanMsg = commitMsg.replace('perf:', '').trim();
    } else if (commitMsg.startsWith('chore:') || commitMsg.startsWith('docs:') || commitMsg.startsWith('style:') || commitMsg.startsWith('refactor:')) {
        category = 'Changed';
        cleanMsg = commitMsg.split(':').slice(1).join(':').trim();
    }

    // Capitalize first letter of cleanMsg
    cleanMsg = cleanMsg.charAt(0).toUpperCase() + cleanMsg.slice(1);

    const entry = `- ${cleanMsg}`;

    if (changelog.includes(versionHeader)) {
        // Version already exists, append to category
        const versionIndex = changelog.indexOf(versionHeader);
        const nextVersionIndex = changelog.indexOf('## [', versionIndex + 1);
        const versionSection = nextVersionIndex === -1 
            ? changelog.slice(versionIndex) 
            : changelog.slice(versionIndex, nextVersionIndex);

        if (versionSection.includes(`### ${category}`)) {
            // Category exists, append entry
            const categoryIndex = changelog.indexOf(`### ${category}`, versionIndex);
            
            // Find end of this category section
            let searchIndex = categoryIndex + `### ${category}`.length;
            let nextCategoryIndex = changelog.indexOf('\n### ', searchIndex);
            
            let insertIndex;
            if (nextCategoryIndex !== -1 && (nextVersionIndex === -1 || nextCategoryIndex < nextVersionIndex)) {
                insertIndex = nextCategoryIndex;
            } else {
                insertIndex = nextVersionIndex === -1 ? changelog.length : nextVersionIndex;
            }
            
            // Back up to find the last non-empty line
            while (changelog[insertIndex - 1] === '\n' || changelog[insertIndex - 1] === '\r') {
                insertIndex--;
            }

            changelog = changelog.slice(0, insertIndex) + `\n${entry}` + changelog.slice(insertIndex);
        } else {
            // Category doesn't exist, create it
            const nextVersionIndex = changelog.indexOf('## [', versionIndex + 1);
            const insertIndex = nextVersionIndex === -1 ? changelog.length : nextVersionIndex;
            
            changelog = changelog.slice(0, insertIndex).trimEnd() + `\n\n### ${category}\n${entry}\n\n` + changelog.slice(insertIndex).trimStart();
        }
    } else {
        // New version, insert header and entry at the top (after introduction)
        const insertAfter = 'and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).';
        const introIndex = changelog.indexOf(insertAfter);
        if (introIndex === -1) {
            // Fallback if intro text changed
            const firstHeaderIndex = changelog.indexOf('## [');
            const insertIndex = firstHeaderIndex === -1 ? changelog.length : firstHeaderIndex;
            const newSection = `\n\n${versionHeader}\n\n### ${category}\n${entry}\n`;
            changelog = changelog.slice(0, insertIndex) + newSection + changelog.slice(insertIndex);
        } else {
            const insertIndex = introIndex + insertAfter.length;
            const newSection = `\n\n${versionHeader}\n\n### ${category}\n${entry}`;
            changelog = changelog.slice(0, insertIndex) + newSection + changelog.slice(insertIndex);
        }
    }

    writeFileSync(changelogPath, changelog.trim() + '\n');
    console.log(`✅ Updated CHANGELOG.md for version ${version} [${category}]`);
} catch (error) {
    console.error('❌ Error updating CHANGELOG.md:', error.message);
    process.exit(1);
}
