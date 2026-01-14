# Report: Migrate Sidebar.res to Logger System

## Objective (Completed)
Update Sidebar.res to use the new Logger module for tracking project load/save and UI state changes.

## Context
Sidebar handles project management (new, load, save) and scene list interactions. These are critical user operations that need logging for troubleshooting file handling issues.

## Prerequisites
- Logger.res module exists ✅

## Implementation Details

### 1. Update Project Load

```rescript
let loadProject = async (file: File.t): unit => {
  Logger.startOperation(~module_="Sidebar", ~operation="PROJECT_LOAD", ~data=Some({
    "filename": File.name(file),
    "size": File.size(file)
  }), ())
  
  // On success
  Logger.endOperation(~module_="Sidebar", ~operation="PROJECT_LOAD", ~data=Some({
    "sceneCount": sceneCount
  }), ())
  
  // On failure
  Logger.error(~module_="Sidebar", ~message="PROJECT_LOAD_FAILED", ~data=Some({
    "error": errorMessage
  }), ())
}
```

### 2. Update Project Save

```rescript
let saveProject = async (): unit => {
  Logger.info(~module_="Sidebar", ~message="PROJECT_SAVE", ~data=Some({
    "sceneCount": sceneCount,
    "tourName": tourName
  }), ())
}
```

### 3. Update New Project

```rescript
let newProject = (): unit => {
  Logger.info(~module_="Sidebar", ~message="PROJECT_NEW", ())
}
```

### 4. Update Scene Selection

```rescript
let selectScene = (index: int): unit => {
  Logger.debug(~module_="Sidebar", ~message="SCENE_SELECT", ~data=Some({
    "sceneIndex": index
  }), ())
}
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Load start | `info` | `PROJECT_LOAD_START` | filename, size |
| Load complete | `info` | `PROJECT_LOAD_COMPLETE` | sceneCount |
| Load failed | `error` | `PROJECT_LOAD_FAILED` | error |
| Save | `info` | `PROJECT_SAVE` | sceneCount, tourName |
| New | `info` | `PROJECT_NEW` | - |
| Scene select | `debug` | `SCENE_SELECT` | sceneIndex |

## Files to Modify

| File | Changes |
|------|---------|
| `src/components/Sidebar.res` | Replace Debug calls with Logger calls |

## Testing Checklist

- [ ] Project load logs filename and success
- [ ] Project save logs scene count
- [ ] Load failures log error message
- [ ] Scene selection logged at debug level

## Definition of Done

- All Debug calls replaced with Logger calls
- Project management operations instrumented
- Clear error context for failures
