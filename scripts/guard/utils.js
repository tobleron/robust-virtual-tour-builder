import fs from 'fs';
import path from 'path';

const TASKS_DIR = 'tasks/pending';

export function getNextId() {
  if (!fs.existsSync('tasks')) return 1;
  
  // Find all task files in all subdirectories of tasks/
  const taskFiles = [];
  function scan(dir) {
    if (!fs.existsSync(dir)) return;
    const items = fs.readdirSync(dir);
    for (const item of items) {
      const fullPath = path.join(dir, item);
      if (fs.statSync(fullPath).isDirectory()) {
        scan(fullPath);
      } else if (item.match(/^\d+_/)) {
        taskFiles.push(item);
      }
    }
  }
  
  scan('tasks');
  
  let maxId = 0;
  for (const file of taskFiles) {
    const match = file.match(/^(\d+)_/);
    if (match) {
      const id = parseInt(match[1], 10);
      if (id > maxId) maxId = id;
    }
  }
  
  return maxId + 1;
}

export function createTask(filename, content) {
    const filePath = path.join(TASKS_DIR, filename);
    
    // Ensure directory exists (handles cases like tasks/pending/tests/)
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }

    if (!fs.existsSync(filePath)) {
        fs.writeFileSync(filePath, content);
        console.log(`📝 Created Task: ${filePath}`);
        return true;
    }
    return false;
}

export function taskExists(pattern) {
    let found = false;
    function scan(dir) {
        if (!fs.existsSync(dir)) return;
        const items = fs.readdirSync(dir);
        for (const item of items) {
            const fullPath = path.join(dir, item);
            if (fs.statSync(fullPath).isDirectory()) {
                scan(fullPath);
            } else {
                if (item.includes(pattern)) {
                    found = true;
                }
            }
        }
    }
    scan('tasks');
    return found;
}