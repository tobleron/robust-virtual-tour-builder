# Analysis Report: _dev-system Accuracy & Refinement

## Executive Summary
The `_dev-system` architectural analyzer is **highly accurate for Rust (Backend)** tasks but currently **inaccurate for ReScript (Frontend)** tasks.

- **Backend Tasks:** 90% Accuracy. The system correctly identifies fragmentation and scope creep.
- **Frontend Tasks:** 10% Accuracy (mostly False Positives). The system penalizes standard ReScript syntax, labeling healthy code as "High Drag".

## Root Cause Analysis: The ReScript "Drag" Inflation

The primary issue lies in the **Complexity Density** calculation for ReScript files.

**Formula:**
`Drag = 1.0 + (Nesting * 0.15) + (Density * 1.0) + (Complexity_Density * 50.0) + Depth`

### 1. The "Switch" Penalty
ReScript code relies heavily on `switch` statements and pattern matching (`|`) for safe option unwrapping and type handling. This is idiomatic and desirable.
- Current Weights: `switch`: 0.8, `|`: 0.5.
- A standard 200 LOC component often has ~15 switches and ~50 branches.
- Complexity Score Contribution: `(15*0.8 + 50*0.5) = 37.0`.
- Drag Impact: `(37.0 / 200) * 50.0 = 9.25`.
- **Result:** A healthy file gets a Drag score of > 10.0, triggering a "Surgical Refactor".

### 2. Double Counting
Tokens like `->` (pipe), `switch`, and `|` are counted **twice**:
1.  **Density (Logic Count):** They add 1.0 weight per occurrence relative to LOC.
2.  **Complexity Dictionary:** They add their specific weight (e.g., 0.8) * multiplied by 50.0 * relative to LOC.

## Task Evaluation

| Task ID | Component | System Verdict | Human Verdict | Analysis |
|:---:|:---:|:---:|:---:|:---|
| **1086** | `HotspotManager.res` | **Critical (Drag 5.83)** | **False Positive** | Code is simple configuration. High score driven by `switch` penalty. Refactoring would introduce boilerplate. |
| **1086** | `ModalContext.res` | **Critical (Drag 11.83)** | **False Positive** | High score due to a single large `switch` for Icon mapping. Readable, cohesive code. |
| **1086** | `PreviewArrow.res` | **Critical (Drag 8.19)** | **False Positive** | Uses `switch` for safe `Option` handling. Punishment of safety features. |
| **1090** | `backend/api/project.rs` | **Warning (Drag 2.19)** | **Valid (Low Prio)** | File exceeded LOC limit. Separation of `create_tour_package` (Export logic) is a valid architectural move. |
| **1093** | `backend/auth` | **Merge Recommendation** | **Strong Positive** | Merging `jwt.rs` and `mod.rs` reduces fragmentation. Excellent suggestion. |

## Recommendations

To improve accuracy and prevent "Busy Work" refactors on the Frontend, we must adjust the `efficiency.json` configuration for ReScript.

### 1. Immediate Config Adjustment (Recommended)
Modify `_dev-system/config/efficiency.json` under `profiles.rescript.complexity_dictionary`:

```json
"rescript": {
  "extensions": [".res"],
  "complexity_dictionary": {
    "->": 0.0,          // Reduced from 0.05. Pipe is syntactic sugar, not complexity.
    "switch": 0.2,      // Reduced from 0.8. Essential control flow.
    "| ": 0.1,          // Reduced from 0.5. Branching is cheap in FP.
    "mutable": 2.0,     // Increased from 1.5. Mutability SHOULD be penalized.
    "Obj.magic": 5.0    // Increased from 2.5. Unsafe casting is dangerous.
  },
  ...
}
```

### 2. Logic Refinement (Long Term)
Update `_dev-system/analyzer/src/main.rs` to lower the global multiplier for `Complexity_Density` from `50.0` to `20.0`, or apply separate multipliers per language profile.

## Conclusion
The **Backend** prompts are productive and should be executed.
The **Frontend** prompts are counter-productive and should be **rejected** until the formula is tuned.
