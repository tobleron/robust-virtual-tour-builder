# Task 122: Split Large Backend Modules

## Priority: LOW

## Context
Two backend modules are approaching the 500+ line threshold:
- `services/project.rs`: 535 lines
- `pathfinder.rs`: 510 lines

While functional, larger modules are harder to:
- Navigate and understand
- Test in isolation
- Modify without side effects

## Objective
Refactor large backend modules into smaller, focused sub-modules.

## Target Modules

### 1. `services/project.rs` (535 lines)

**Current Structure:**
- Project saving logic
- Project loading logic
- ZIP handling
- Validation logic
- Tour package creation

**Proposed Split:**
```
services/
├── project/
│   ├── mod.rs          # Re-exports
│   ├── save.rs         # save_project, serialize_state
│   ├── load.rs         # load_project, deserialize_state
│   ├── validate.rs     # validate_project, find_orphans, find_broken_links
│   └── package.rs      # create_tour_package, zip_handling
└── project.rs          # Delete (replaced by project/)
```

### 2. `pathfinder.rs` (510 lines)

**Current Structure:**
- Graph building
- Path calculation algorithms
- Optimal tour generation
- Helper utilities

**Proposed Split:**
```
src/
├── pathfinder/
│   ├── mod.rs          # Re-exports, main API
│   ├── graph.rs        # Graph data structures, building
│   ├── algorithms.rs   # DFS, shortest path, optimization
│   └── utils.rs        # Helper functions
└── pathfinder.rs       # Delete (replaced by pathfinder/)
```

## Implementation Steps

### Step 1: Create Directory Structure
```bash
mkdir -p backend/src/services/project
mkdir -p backend/src/pathfinder
```

### Step 2: Extract Functions
Move related functions to sub-modules, keeping public API in `mod.rs`.

### Step 3: Update mod.rs Re-exports
```rust
// backend/src/services/project/mod.rs
mod save;
mod load;
mod validate;
mod package;

pub use save::save_project;
pub use load::load_project;
pub use validate::validate_project;
pub use package::create_tour_package;
```

### Step 4: Update Imports
Update all files that import from these modules:
```rust
// Before
use crate::services::project::save_project;

// After (should work unchanged due to re-exports)
use crate::services::project::save_project;
```

## Acceptance Criteria
- [ ] Each sub-module is under 200 lines
- [ ] Public API unchanged (no breaking changes)
- [ ] `cargo build` succeeds
- [ ] `cargo test` passes
- [ ] No new warnings introduced
- [ ] Rust documentation (`///` comments) preserved

## Verification
1. `cd backend && cargo build`
2. `cargo test`
3. `cargo doc --open` - verify documentation still works
4. Count lines: `find src -name '*.rs' -exec wc -l {} \; | sort -rn | head -10`

## Notes
- This is a refactoring task - no new functionality
- Can be done incrementally (one module at a time)
- Consider doing services/project.rs first as it has clearer boundaries

## Estimated Effort
4-6 hours
