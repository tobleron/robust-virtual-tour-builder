# Task Processing Workflow

To ensure systematic progress and maintain a clear audit trail of all changes, follow this process for every task:

## 1. Starting a Task
Move the task file from `tasks/pending/` to `tasks/active/`. **This action signals the immediate start of the implementation phase.** The agent must then proceed directly to step 2 without further prompting.

## 2. Implementation
Autonomously implement the requirements defined in the active task file. This includes:
- Researching existing code and patterns.
- Writing/updating code following all project standards.
- Adding or updating tests to verify the changes.
- Ensuring `npm test` passes before proceeding.

## 3. Completion & Reporting
Once implementation and verification are complete, create a "REPORT" version of the task file:
- Filename: `<original_name>_REPORT.md` (e.g., `131_Security_And_SW_Hardening_REPORT.md`).
- Content must include:
    - **Before State**: The state of the objective before starting.
    - **After State**: The final state of the objective.
    - **Accomplishments**: A concise list of what was implemented or fixed.

## 4. Finalization
- Move the `_REPORT` file into `tasks/completed/`.
- Remove the original task file from `tasks/active/`.