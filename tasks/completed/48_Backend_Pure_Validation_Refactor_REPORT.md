# Report: Refactor validate_and_clean_project to Return New Value

## Objective (Completed)
Refactor the `validate_and_clean_project` function to follow pure functional principles by returning a new value instead of mutating the input.

## Context
Currently, the function takes `&mut serde_json::Value` and mutates it in place. This violates the functional principle of returning new values instead of mutating inputs. While pragmatic, it makes reasoning about data flow harder.

## Current Implementation (Problem)

```rust
fn validate_and_clean_project(
    project: &mut serde_json::Value,  // MUTABLE reference
    available_files: &HashSet<String>
) -> Result<ValidationReport, String>
```

The function mutates `project` directly:
- Removes broken hotspot links with `.retain()`
- Sets default values for missing fields
- No clear indication that the input was modified

## Target Implementation

```rust
fn validate_and_clean_project(
    project: serde_json::Value,  // Take ownership
    available_files: &HashSet<String>
) -> Result<(serde_json::Value, ValidationReport), String>
```

Return a tuple of:
1. The cleaned project (new value)
2. The validation report

## Implementation Details

### 1. Change Function Signature

```rust
fn validate_and_clean_project(
    project: serde_json::Value,
    available_files: &HashSet<String>
) -> Result<(serde_json::Value, ValidationReport), String>
```

### 2. Clone Scenes for Modification

```rust
let mut project = project; // Take ownership, now we can mutate locally
let scenes = project["scenes"].as_array_mut()
    .ok_or("Invalid project structure: missing 'scenes' array")?;
```

### 3. Return Tuple at End

```rust
Ok((project, report))
```

### 4. Update Callers

In `save_project` handler:
```rust
// Before
let report = validate_and_clean_project(&mut project_data, &available_files)?;

// After  
let (validated_project, report) = validate_and_clean_project(project_data, &available_files)?;
```

In `load_project` handler:
```rust
// Before
let report = validate_and_clean_project(&mut project_data, &available_files)?;

// After
let (validated_project, report) = validate_and_clean_project(project_data, &available_files)?;
```

## Files to Modify

| File | Changes |
|------|---------|
| `backend/src/handlers.rs` | Refactor function signature and update callers |

## Testing Checklist

- [x] `save_project` endpoint works correctly
- [x] `load_project` endpoint works correctly
- [x] `validate_project` endpoint works correctly
- [x] Validation report is still embedded in response
- [x] No compilation errors or warnings

## Definition of Done

- [x] Function takes ownership instead of mutable reference
- [x] Returns tuple of (cleaned_data, report)
- [x] All callers updated
- [x] Clearer data flow in handlers
