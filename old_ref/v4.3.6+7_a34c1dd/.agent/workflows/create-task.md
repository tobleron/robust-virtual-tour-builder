---
description: Create a new formal task in the task management system
---

# Create Task Workflow

This workflow should **ONLY** be triggered when the user **explicitly** requests task creation.

## Trigger Phrases
- "Create a task for..."
- "Add this to tasks..."
- "Make this a formal task..."
- "/create-task [description]"

## Steps

1. **Read Task Rules**
   - Read `tasks/TASKS.md` to understand task creation rules and format

2. **Determine Next Task Number**
   - Scan all task folders: `completed/`, `pending/`, `postponed/`, `postponed/tests/`, `active/`
   - Find the highest task number across all folders
   - Increment by 1 to get the next sequential number

3. **Determine Task Location**
   - **Test-related tasks**: Create in `tasks/postponed/tests/`
   - **All other tasks**: Create in `tasks/pending/`

4. **Gather Task Information**
   - If user provided description, use it
   - If not, ask user for:
     - Task name (short, descriptive)
     - Task objective
     - Acceptance criteria (optional)

5. **Create Task File**
   - Format: `{number}_{task_name}.md` (e.g., `289_fix_navigation_bug.md`)
   - Use lowercase with underscores for task name
   - Create in appropriate folder (step 3)

6. **Populate Task File**
   ```markdown
   # Task: [Task Name]
   
   ## Objective
   [Clear description of what needs to be done]
   
   ## Acceptance Criteria
   - [ ] Criterion 1
   - [ ] Criterion 2
   
   ## Technical Notes
   [Any relevant technical context]
   ```

7. **Confirm Creation**
   - Inform user of task number and location
   - Example: "Created task #289 in `tasks/pending/289_fix_navigation_bug.md`"

## Important Notes
- **Do NOT auto-create tasks** for normal user requests
- Only create tasks when explicitly requested
- Always follow sequential numbering
- Test tasks go in `postponed/tests/`, others in `pending/`
- **Build verification**: Formal tasks require `npm run build` before completion (see `tasks/TASKS.md`)

