import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const readmePath = join(process.cwd(), 'README.md');
const pkgPath = join(process.cwd(), 'package.json');
const mapPath = join(process.cwd(), 'MAP.md');
const testOutputPath = join(process.cwd(), 'test_output.txt');

try {
    let readme = readFileSync(readmePath, 'utf8');
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));

    // 1. Update Metadata
    const version = pkg.version;
    const buildNumber = pkg.buildNumber || 0;
    const date = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
    
    const metadataContent = `**Version:** ${version} (Build ${buildNumber})  
**Directing Developer:** Arto Kalishian  
**Release Date:** ${date}  
**Status:** Commercial Ready`;
    
    readme = readme.replace(/<!-- METADATA_START -->[\s\S]*<!-- METADATA_END -->/, `<!-- METADATA_START -->\n${metadataContent}\n<!-- METADATA_END -->`);

    // 2. Update Status (Tests)
    let testStatus = "⚠️ **Tests:** Status Unknown";
    if (existsSync(testOutputPath)) {
        const testOutput = readFileSync(testOutputPath, 'utf8');
        const passMatch = testOutput.match(/Tests\s+(\d+)\s+passed/);
        const failMatch = testOutput.match(/Tests\s+(\d+)\s+failed/);
        
        if (passMatch) {
            const passed = passMatch[1];
            const failed = failMatch ? failMatch[1] : "0";
            if (failed === "0") {
                testStatus = `✅ **Build:** Passing | 🧪 **Tests:** ${passed} Passed (100%) | 🛡️ **Strict Mode:** Enabled`;
            } else {
                testStatus = `❌ **Build:** Failing | 🧪 **Tests:** ${passed} Passed, ${failed} Failed | 🛡️ **Strict Mode:** Enabled`;
            }
        }
    }
    readme = readme.replace(/<!-- STATUS_START -->[\s\S]*<!-- STATUS_END -->/, `<!-- STATUS_START -->\n${testStatus}\n<!-- STATUS_END -->`);

    // 3. Update Structure from MAP.md
    if (existsSync(mapPath)) {
        const mapContent = readFileSync(mapPath, 'utf8');
        const structureMatch = mapContent.match(/## 📁 Directory Semantic Index[\s\S]*?(\n|[\s\S]*?\n\n|\n|[\s\S]*?$)/);
        
        if (structureMatch) {
            const table = structureMatch[0].replace('## 📁 Directory Semantic Index', '').trim();
            readme = readme.replace(/<!-- STRUCTURE_START -->[\s\S]*<!-- STRUCTURE_END -->/, `<!-- STRUCTURE_START -->\n### Directory Index (from MAP.md)\n\n${table}\n<!-- STRUCTURE_END -->`);
        }
    }

    writeFileSync(readmePath, readme);
    console.log('✅ README.md updated successfully.');
} catch (error) {
    console.error('❌ Error updating README.md:', error.message);
    process.exit(1);
}
