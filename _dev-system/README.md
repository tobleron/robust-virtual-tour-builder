# 🛠️ _dev-system: Architectural Efficiency Engine

This system monitors the codebase for complexity, bloat, and fragmentation. It is currently isolated from the main build.

## 🔄 The Workflow

1.  **Detection**: Run the analyzer (Rust binary) to scan the project.
2.  **Task Generation**: If the system finds an issue, it creates a task in the `pending/` folder.
3.  **Delegation**: You (The Orchestrator) see a new task file. You tell your AI Agent: "Process the task in `_dev-system/pending/<TASK_NAME>.md`".
4.  **Verification**: After the AI Agent finishes, the system re-scans to ensure the 100% accuracy threshold is met.

## 📁 Folder Map

-   `/analyzer`: The Rust core (AST parsing, Math engine).
-   `/config`: Industry-standard taxonomy and language weights.
-   `/pending`: Surgical blueprints for the AI Agent to execute.
