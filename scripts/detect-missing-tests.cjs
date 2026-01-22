// scripts/detect-missing-tests.js
const fs = require('fs');
const path = require('path');

function getAllFiles(dirPath, arrayOfFiles) {
  const files = fs.readdirSync(dirPath);
  arrayOfFiles = arrayOfFiles || [];

  files.forEach(function(file) {
    if (fs.statSync(dirPath + "/" + file).isDirectory()) {
      arrayOfFiles = getAllFiles(dirPath + "/" + file, arrayOfFiles);
    } else {
      if (file.endsWith('.res')) {
        arrayOfFiles.push(path.join(dirPath, "/", file));
      }
    }
  });

  return arrayOfFiles;
}

const srcFiles = getAllFiles('./src');
const testFiles = getAllFiles('./tests/unit');

const missingTests = [];

srcFiles.forEach(srcFile => {
  const fileName = path.basename(srcFile, '.res');
  
  // Check for various test naming conventions
  const exactMatch = testFiles.find(t => path.basename(t) === fileName + 'Test.res');
  const dotTestMatch = testFiles.find(t => path.basename(t) === fileName + '.test.res');
  const vTestMatch = testFiles.find(t => path.basename(t) === fileName + '_v.test.res');
  
  // Check if logic file has a test
  if (!exactMatch && !dotTestMatch && !vTestMatch) {
    // Filter out UI components if they are purely view (though ideally they should have tests)
    // For this pass, we want to catch logic/system files primarily.
    // However, the prompt said "every code file that has no test".
    
    // Skip some obvious non-testable or trivial files if needed, but for now list all.
    // Maybe skip .resi interface files if they were picked up (getAllFiles filters .res)
    
    missingTests.push(srcFile);
  }
});

console.log("Missing Tests:");
missingTests.forEach(f => console.log(f));