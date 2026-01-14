---
description: Standards for implementing new ReScript modules with proper logging
---

# New Module Implementation Workflow

Follow these steps when creating a new ReScript module or significantly modifying an existing one.

## 1. Module Structure

### Required Imports
```rescript
// At the top of every new module
open ReBindings // If needed for DOM/Viewer bindings

// For logging (use the Logger module)
// Logger is in src/utils/Logger.res
```

### Initialization Logging
Every module that initializes should log its startup:
```rescript
let init = (): unit => {
  Logger.initialized(~module_="ModuleName")
  // ... initialization logic
}
```

## 2. Standard Log Points

Every module must include these log points where applicable:

| Event | Code Pattern | When to Use |
|-------|--------------|-------------|
| Init | `Logger.initialized(~module_="Name")` | Module startup |
| Action Start | `Logger.startOperation(~module_, ~operation="ACTION", ())` | Before async work |
| Action End | `Logger.endOperation(~module_, ~operation="ACTION", ())` | After success |
| Debug Step | `Logger.debug(~module_, ~message="step", ())` | Internal steps |
| Warning | `Logger.warn(~module_, ~message="issue", ())` | Unexpected states |
| Error | Via `Logger.attempt` or `Logger.error` | On failure |

## 3. Error Handling Pattern

### Synchronous Operations
```rescript
let parseConfig = (raw: string): result<config, string> => {
  Logger.attempt(~module_="Config", ~operation="PARSE", () => {
    Json.parseExn(raw)->decodeConfig
  })
}

// Usage:
switch parseConfig(rawJson) {
| Ok(config) => use(config)
| Error(_) => showError("Invalid config") // Already logged!
}
```

### Asynchronous Operations
```rescript
let fetchData = async (): result<data, string> => {
  await Logger.attemptAsync(~module_="Loader", ~operation="FETCH", 
    async () => {
      let response = await Fetch.fetchSimple(url)
      await Fetch.json(response)
    }
  )
}
```

## 4. Performance Timing

### For Critical Operations
```rescript
let processImages = (images: array<image>): array<processed> => {
  let {result, durationMs: _} = Logger.timed(
    ~module_="Processor",
    ~operation="BATCH_PROCESS",
    () => images->Array.map(processOne)
  )
  result
}
```

### For Async Operations
```rescript
let loadTexture = async (url: string): texture => {
  let {result, _} = await Logger.timedAsync(
    ~module_="Viewer",
    ~operation="TEXTURE_LOAD",
    async () => await fetchTexture(url)
  )
  result
}
```

## 5. Message Naming Conventions

### Action Messages (UPPER_SNAKE_CASE)
- `NAV_START`, `NAV_COMPLETE`, `NAV_FAILED`
- `SCENE_LOAD_START`, `SCENE_LOAD_COMPLETE`
- `EXPORT_START`, `EXPORT_PROGRESS`, `EXPORT_COMPLETE`

### Descriptive Format
```rescript
Logger.info(~module_="Navigation", ~message="NAV_START", ~data=Some({
  "targetScene": sceneName,
  "animate": true
}), ())
```

## 6. Data Context

Always include relevant context in log data:

| Module Type | Include in Data |
|-------------|-----------------|
| Navigation | scene names, indices, coordinates |
| Viewer | scene name, texture quality, load time |
| Hotspot | hotspot ID, type, target |
| Export | phase, file count, progress |
| Upload | filename, size, quality stats |

## 7. Checklist Before Completion

- [ ] Module has `Logger.initialized` call (if applicable)
- [ ] Major operations have start/end logs
- [ ] Risky operations use `Logger.attempt` or `Logger.attemptAsync`
- [ ] Performance-critical sections use `Logger.timed`
- [ ] No `Console.log` or `console.log` calls
- [ ] Error logs include relevant context data
- [ ] Message naming follows UPPER_SNAKE_CASE
- [ ] New module has corresponding unit tests (see `/testing-standards`)
- [ ] `npm test` passes
