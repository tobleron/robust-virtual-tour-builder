# Task Management - Follow Instructions in Exact Order

## Task Creation Rule
- **Mandatory Prefix**: Every new task MUST have a sequential number prefix (e.g., `189_task_name.md`).
- **Sequence Basis**: The sequence number must be the next available number based on the highest existing number across `completed/`, `pending/`, `postponed/`, `postponed/tests/`, and `active/` folders.
- **Format**: Use three-digit padding where possible (or two if consistent with history) to ensure proper sorting.
- **Test Tasks**: (⚠️ SUSPENDED) Automated test task generation is disabled during heavy refactoring.
- **Detail Requirement**: Every task MUST be self-documenting. Provide enough technical detail, context, and clear objective so that a rename (e.g., `_DONE`) is sufficient to signify completion without a separate report.


## Workflow Instructions (Must be followed sequentially)

1. **Move the task to active folder first**: Before starting any work, move the intended task file from `pending/` or `postponed/` to the `active/` folder.

2. **Read and implement the task**: Start reading the task file and working on its implementation to completion.

3. **Verify the build**: Run `npm run build` to ensure compilation passes and there are no errors.

4. **Archive & Finish**: Once implementation is verified:
    - **Action**: Move the task file from `active/` to the `completed/` folder.
    - **Renaming**: Append a representative postfix during the move:
        - `_DONE`, `_UPDATED`, or `_TESTED` for successful completion.
        - `_ABORTED` if the task is cancelled or abandoned.
    - **Note**: Do NOT modify the file content; the move/rename is the sole indicator of status.

5. **Wait**: Do not proceed to the next task until the current move is confirmed by the system.


## Documentation Rule
- **Location**: If you generate an additional technical summary, analysis, session report, or any documentation, it MUST be placed in `docs/_pending_integration/`.

## Folder Structure
- `pending/`: Tasks waiting to be started.
- `active/`: The single task currently being worked on.
- `completed/`: All finished tasks (`_DONE`, `_UPDATED`, etc.) and cancelled tasks (`_ABORTED`).
- `postponed/`: Tasks deferred for later.

