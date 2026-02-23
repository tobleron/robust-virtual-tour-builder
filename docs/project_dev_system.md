# Project Dev System (`_dev-system`)

The `_dev-system` is an AI-native codebase governance system designed to optimize for AI cognitive load rather than traditional human-centric metrics.

## 1. Core Principles & Metrics

### The "Drag" Metric
A cognitive resistance metric for AI inference.
- **Formula**: `(1.0 + Nesting*0.6 + Density*1.0 + StateDensity*8.0 + DepthPenalty*0.6) * FailurePenalty`
- **Target**: Drag score < 1.8.
- **Why**: Files with high Drag (>1.8) cause context fog and AI hallucinations.

### Hysteresis Mechanism
Prevents architectural thrashing.
- **Split Trigger**: 1.15x
- **Merge Safety**: 0.85x

### Role-Based Limits (Taxonomy)
Files have different line count (`LOC`) limits based on their semantic role:
- Domain Logic: More constrained due to complexity.
- UI Components: Moderately constrained.
- Orchestrators / Presentational: More forgiving limits.

## 2. Dev System Configuration

The system is configured via `config/efficiency.json` which includes:
- `scanned_roots`: Directories to analyze.
- `settings`: Numeric thresholds (e.g., `base_loc_limit: 400`).
- `profiles`: Language-specific AST parsing rules.
- `taxonomy`: Role-based multipliers.

## 3. Tooling & Automation

### Task Generation
The analyzer inspects the codebase and generates tasks in `tasks/pending/`.
```bash
./scripts/dev-system.sh  # Generate actionable tasks (surgical, merge, violation)
```

### Standardized Task Schema
Tasks follow a rigid frontmatter schema for automation:
```yaml
---
id: {task_id}
type: {surgical|merge|violation|ambiguity}
priority: {high|medium|low}
target_file: {root_relative_path}
drag_score: {float}
loc: {int}
---
```

### Planned Optimizations (Action Plan)
- **Tool Integration**: Implementing a REST API for the analyzer to enable real-time analysis IDE plugins.
- **Calibration Tool**: Automated tuning of weights (`nesting_weight`, `state_weight`) per AI model.
- **Multi-Agent Support**: Assigning specific tasks (e.g., surgical vs violation) to specialized agents.
- **Semantic Analysis**: Embedding-based similarity checks for finding refactor patterns.

## 4. AI Agent Quick Start

1. **What**: This system prevents files from becoming too complex for AI inference.
2. **How**: Run `./scripts/dev-system.sh` to generate tasks in `tasks/pending/`.
3. **Execution**: Pick a task, follow its instructions, run `npm run build`, and check Drag improvement.
4. **Pathing**: ALWAYS use root-relative paths (`src/Main.res`) for reliable context.
