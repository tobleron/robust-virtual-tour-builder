import fs from 'fs';
import path from 'path';
import { getNextId, createTask, taskExists } from './utils.js';

const bt = String.fromCharCode(96);

export default function checkTasks() {
    const completedDir = 'tasks/completed';
    if (!fs.existsSync(completedDir)) return;

    const files = fs.readdirSync(completedDir).filter(f => f.endsWith('.md'));
    const count = files.length;

    if (count > 90) {
        if (!taskExists("Aggregate_Completed_Tasks")) {
            const nextId = getNextId();
            const taskFilename = `${nextId}_Aggregate_Completed_Tasks.md`;
            
            const taskContent = `# Task ${nextId}: Aggregate Completed Tasks

## 🚨 Trigger
Completed tasks count exceeds 90 (Current: ${count}).

## Objective
Aggregate the oldest 50 completed tasks into ${bt}tasks/completed/_CONCISE_SUMMARY.md${bt} and cleanup.

## AI Prompt
"Please perform the following maintenance on the task system:
1. Identify the oldest 50 task files in ${bt}tasks/completed/${bt} (based on their numerical prefix).
2. Read these 50 files and the existing ${bt}tasks/completed/CONCISE_SUMMARY.md${bt} (or ${bt}tasks/completed/_CONCISE_SUMMARY.md${bt}).
3. If ${bt}tasks/completed/CONCISE_SUMMARY.md${bt} exists, rename it to ${bt}tasks/completed/_CONCISE_SUMMARY.md${bt} to ensure it stays at the top.
4. Integrate the core accomplishments from these 50 tasks into ${bt}tasks/completed/_CONCISE_SUMMARY.md${bt}, following its established style (categorized, bullet points, extremely concise).
5. After successful integration and verification, delete the 50 original task files from ${bt}tasks/completed/${bt}.
6. Ensure the ${bt}_CONCISE_SUMMARY.md${bt} remains the definitive high-level history of the project."
`;
            createTask(taskFilename, taskContent);
            console.log(`🧹 Created Maintenance Task: ${taskFilename}`);
        }
    }
}
