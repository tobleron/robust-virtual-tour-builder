# Task Management - Follow Instructions in Exact Order

## Task Creation Rule
- **Mandatory Prefix**: Every new task MUST have a sequential number prefix (e.g., `189_task_name.md`).
- **Sequence Basis**: The sequence number must be the next available number based on the highest existing number across `completed/`, `pending/`, and `active/` folders.
- **Format**: Use three-digit padding where possible (or two if consistent with history) to ensure proper sorting.
- **Test Tasks**: Create all test-related tasks inside `tasks/pending/Tests/`. They MUST follow the same sequential numbering rule as other tasks.

## Workflow Instructions (Must be followed sequentially)

1. **Move the task to active folder first**: Before starting any work, move the intended task file from `pending/` to the `active/` folder.

2. **Read and implement the task**: Start reading the task file and working on its implementation to completion.

3. **Complete the task**: After finishing the task, rename the task file by adding the postfix `_REPORT` and change its content to state what the objective was and how it was fulfilled and realized technically and concisely.

4. **Archive the task**: Move the renamed `_REPORT` file from `active/` to the `completed/` folder.

5. **Wait**: Do not proceed to the next task until the current one is fully verified.
273_centralize_rescript_styling_tokens.md
