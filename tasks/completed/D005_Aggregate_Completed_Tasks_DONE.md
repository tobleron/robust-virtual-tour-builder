# Task D005: Aggregate Completed Tasks

## 🚨 Trigger
Completed tasks count exceeds 20 (Current: 34).

## Objective
Aggregate all but the last 10 completed tasks into `tasks/completed/_CONCISE_SUMMARY.md` and cleanup.

## AI Prompt
"Please perform the following maintenance on the task system:
1. Identify all completed task files in `tasks/completed/` except for the 10 most recent ones (based on their numerical prefix).
2. Read these older files and the existing `tasks/completed/_CONCISE_SUMMARY.md`.
3. Integrate the core accomplishments from these older tasks into `tasks/completed/_CONCISE_SUMMARY.md`, following its established style (categorized, bullet points, extremely concise).
4. After successful integration and verification, delete the processed original task files from `tasks/completed/`.
5. Ensure the `_CONCISE_SUMMARY.md` remains the definitive high-level history of the project."
