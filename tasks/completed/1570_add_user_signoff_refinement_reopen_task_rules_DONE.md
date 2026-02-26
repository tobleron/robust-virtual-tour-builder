# 1570 Add User Sign-Off, Refinement Loop, and Reopen Task Rules

## Objective
Update task workflow policy so tasks are not archived before explicit user approval, refinements stay in the same active task, and completed tasks can be reopened into active when additional work is requested.

## Scope
- `tasks/TASKS.md`

## Acceptance Criteria
1. Workflow docs require explicit user sign-off before moving `active/` task files to `completed/`.
2. Workflow docs require continued refinements to remain in the same `active/` task.
3. Workflow docs define reopening a completed task by moving it back to `active/` before further changes.
4. Existing workflow step order is updated to include sign-off gate prior to archive.
