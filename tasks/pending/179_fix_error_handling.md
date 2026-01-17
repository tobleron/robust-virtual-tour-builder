# Replace Exceptions with Result Types

## Overview
Multiple systems currently use `JsError.throwWithMessage` and exceptions instead of the required `Result<T, string>` pattern. The Rust backend also uses forbidden `unwrap()` calls. This task converts all error handling to use Result types for consistent, functional error management.

## Affected Systems
- BackendApi.res - API call error handling
- ProjectManager.res - Project validation errors
- VideoEncoder.res - Encoding failure handling
- DownloadSystem.res - Download error handling
- Resizer.res - Image processing errors
- ExifParser.res - Metadata parsing errors
- Rust backend - unwrap() calls in production code

## Implementation Steps

### 1. Update BackendApi.res
Convert all API functions to return `Result<T, string>`:

```rescript
// Before
let fetchProjectData = async (projectId) => {
  let response = await fetch(\`/api/projects/\${projectId}\`)
  if (!response.ok) {
    JsError.throwWithMessage("Failed to fetch project")
  }
  response.json()
}

// After
let fetchProjectData = async (projectId): promise<result<project, string>> => {
  try {
    let response = await fetch(\`/api/projects/\${projectId}\`)
    if (!response.ok) {
      Error("Failed to fetch project: " ++ response.statusText)
    } else {
      let data = await response.json()
      Ok(data)
    }
  } catch (error) {
    Error("Network error: " ++ Obj.magic(error)["message"])
  }
}
```

### 2. Convert ProjectManager.res Functions
Update validation functions to return Results:

```rescript
// Before
let validateProjectStructure = (data) => {
  if (!data.scenes || !Array.isArray(data.scenes)) {
    JsError.throwWithMessage("Invalid project: missing or invalid scenes")
  }
  if (!data.name || typeof data.name !== "string") {
    JsError.throwWithMessage("Invalid project: missing or invalid name")
  }
  // ... rest of validation
  data // Return validated data
}

// After
let validateProjectStructure = (data): result<project, string> => {
  if (!data.scenes || !Array.isArray(data.scenes)) {
    Error("Invalid project: missing or invalid scenes array")
  } else if (!data.name || typeof data.name !== "string") {
    Error("Invalid project: missing or invalid name")
  } else {
    // ... rest of validation
    Ok(data)
  }
}
```

### 3. Update Function Callers
Convert all callers to pattern match on Results:

```rescript
// Before
let handleProjectLoad = (data) => {
  let validated = ProjectManager.validateProjectStructure(data)
  // Assume success, proceed with validated data
  processProject(validated)
}

// After
let handleProjectLoad = (data) => {
  switch ProjectManager.validateProjectStructure(data) {
  | Ok(validated) => processProject(validated)
  | Error(msg) => {
      Logger.error(~module_="ProjectLoader", ~message=msg, ())
      dispatch(Actions.ShowNotification({
        severity: Error,
        message: "Failed to load project: " ++ msg
      }))
    }
  }
}
```

### 4. Add Rust Error Types
Create proper error handling in Rust backend:

```rust
// Add to src/models/errors.rs or create new file
#[derive(Debug, Clone)]
pub enum AppError {
    ValidationError(String),
    IoError(String),
    NetworkError(String),
    ProcessingError(String),
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            AppError::ValidationError(msg) => write!(f, "Validation error: {}", msg),
            AppError::IoError(msg) => write!(f, "IO error: {}", msg),
            AppError::NetworkError(msg) => write!(f, "Network error: {}", msg),
            AppError::ProcessingError(msg) => write!(f, "Processing error: {}", msg),
        }
    }
}

// Update function signatures
pub fn validate_project(data: &serde_json::Value) -> Result<ValidatedProject, AppError> {
    // Replace unwrap() calls with proper error handling
    data.get("scenes")
        .and_then(|s| s.as_array())
        .ok_or_else(|| AppError::ValidationError("Missing scenes array".to_string()))?;

    // ... rest of validation
    Ok(validated_project)
}
```

### 5. Update Async Error Handling
Convert Promise-based functions to Result-returning:

```rescript
// Before
let transcodeVideo = async (blob) => {
  if (blob.size < 1024) {
    JsError.throwWithMessage("Blob too small")
  }
  // ... processing
}

// After
let transcodeVideo = async (blob): promise<result<blob, string>> => {
  if (blob.size < 1024) {
    Error("Blob too small: minimum 1KB required")
  } else {
    // ... processing
    Ok(processedBlob)
  }
}
```

## Testing Requirements
- Update all existing tests to handle Result types
- Add specific error path tests for each function
- Test error message content and formatting
- Ensure no exceptions are thrown in business logic
- Verify proper error propagation through call chains

## Completion Criteria
- [ ] BackendApi.res fully converted to Result types
- [ ] ProjectManager.res validation functions return Results
- [ ] VideoEncoder.res async functions return Result promises
- [ ] DownloadSystem.res error handling updated
- [ ] Resizer.res and ExifParser.res converted
- [ ] All callers updated to pattern match Results
- [ ] Rust backend replaces unwrap() with proper error types
- [ ] All tests pass with new error handling
- [ ] No JsError.throwWithMessage calls remain in systems