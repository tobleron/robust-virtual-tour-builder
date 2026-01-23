# 🚀 Initialization Standards

**Version**: 1.0  
**Last Updated**: 2026-01-23  
**Status**: Active Standard

---

## 📋 Overview

This document defines the standardized initialization practices for the Robust Virtual Tour Builder. These standards ensure consistent behavior across application startup, new project creation, and project loading scenarios.

## 🎯 Core Principles

### 1. **Predictable Defaults**
- All state fields must have sensible, non-empty default values
- Default values should be meaningful placeholders that guide user intent
- Avoid empty strings where a placeholder would be more helpful

### 2. **Clean Session Management**
- Session state must be explicitly cleared when creating new projects
- Cached state should never "bleed" into fresh sessions
- State restoration should validate cached values before applying them

### 3. **Graceful Fallbacks**
- Loading operations must provide consistent fallback values
- Unknown or invalid data should degrade to standard defaults
- Placeholder detection should be centralized and comprehensive

---

## 🔧 Implementation Standards

### Default State Values

#### Project Name (`tourName`)
```rescript
// ✅ CORRECT: Meaningful placeholder
tourName: "Tour Name"

// ❌ WRONG: Empty string prevents placeholder visibility
tourName: ""
```

**Rationale**: 
- Provides clear visual feedback in the UI
- Allows placeholder text to show when input is focused
- Enables natural typing experience without forced sanitization
- Recognized as a placeholder by `TourLogic.isUnknownName()`

#### Active Scene Index
```rescript
// ✅ CORRECT: Indicates no active scene
activeIndex: -1

// ❌ WRONG: Could reference invalid scene
activeIndex: 0
```

#### Session ID
```rescript
// ✅ CORRECT: Explicitly optional
sessionId: None

// ❌ WRONG: Empty string suggests a session exists
sessionId: Some("")
```

### Placeholder Recognition

All placeholder/unknown names must be registered in `TourLogic.isUnknownName()`:

```rescript
let isUnknownName = name => {
  let n = String.toLowerCase(name)
  n == "" ||
  String.includes(n, "unknown") ||
  n == "untitled" ||
  n == "imported tour" ||
  n == "tour" ||
  n == "tour name" ||
  RegExp.test(/^tour_\d{6}_\d{4}$/i, name) // Matches Tour_DDMMYY_HHMM pattern
}
```

**Purpose**: Enables intelligent name replacement when meaningful data (e.g., EXIF location) becomes available.

### Session State Management

#### Clearing State on New Project

```rescript
// ✅ CORRECT: Explicit state clearing
SessionStore.clearState()
reload()

// ❌ WRONG: Reload without clearing allows state persistence
reload()
```

**Implementation**:
```rescript
// SessionStore.res
let clearState = () => {
  try {
    removeItem(storageKey)
  } catch {
  | _ => ()
  }
}
```

#### Loading Cached State

```rescript
// ✅ CORRECT: Validate before applying
let loadedState = React.useMemo0(() => {
  switch SessionStore.loadState() {
  | Some(s) => {
      ...initialState,
      tourName: TourLogic.isUnknownName(s.tourName) ? initialState.tourName : s.tourName,
      activeIndex: s.activeIndex == -1 ? initialState.activeIndex : s.activeIndex,
      // ... other validated fields
    }
  | None => initialState
  }
})

// ❌ WRONG: Blindly apply cached state
let loadedState = SessionStore.loadState()->Option.getOr(initialState)
```

### Input Sanitization Strategy

#### During User Input (Typing)
```rescript
// ✅ CORRECT: Allow raw input for natural typing
| SetTourName(name) =>
    Some({...state, tourName: name})

// ❌ WRONG: Aggressive sanitization prevents placeholder visibility
| SetTourName(name) =>
    let sanitized = TourLogic.sanitizeName(name, ~maxLength=100)
    Some({...state, tourName: sanitized})
```

#### During Export/Save Operations
```rescript
// ✅ CORRECT: Sanitize at persistence boundaries
let tourName = if state.tourName == "" {
  "Virtual_Tour"
} else {
  state.tourName
}
let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")
```

**Rationale**: 
- Users can clear the input to see the placeholder
- Natural typing experience without forced transformations
- Filesystem safety is enforced only when necessary

### Project Loading Fallbacks

#### From ZIP Files
```rescript
// ✅ CORRECT: Consistent fallback
let tourName = switch Nullable.toOption(pd.tourName) {
| Some(tn) if !TourLogic.isUnknownName(tn) => tn
| _ => "Tour Name"
}

// ❌ WRONG: Inconsistent or unclear fallback
| _ => "Imported Tour"  // Different from initialState
| _ => ""               // Empty string
```

#### From Backend Response
```rescript
// ✅ CORRECT: Validate and fallback
Dict.set(
  loadedProject,
  "tourName",
  Dict.get(pd, "tourName")->Option.getOr(castToJson("Tour Name")),
)
```

---

## 📁 Critical Files

### State Initialization
- **`src/core/State.res`**: Defines `initialState` with all defaults
- **`src/core/AppContext.res`**: Loads and validates cached session state

### Session Management
- **`src/utils/SessionStore.res`**: Handles localStorage persistence and clearing
- **`src/components/Sidebar.res`**: Implements "New Project" workflow

### Validation & Logic
- **`src/utils/TourLogic.res`**: Centralized placeholder detection and sanitization
- **`src/core/reducers/ProjectReducer.res`**: State mutation logic

### Data Loading
- **`src/core/ReducerHelpers.res`**: Project parsing and scene deserialization
- **`src/systems/ProjectManager.res`**: ZIP loading and backend integration
- **`src/systems/UploadProcessor.res`**: EXIF-based name generation

---

## ✅ Checklist for New Features

When adding new state fields or initialization logic:

- [ ] Define a meaningful default value in `State.initialState`
- [ ] Add validation logic in `AppContext.Provider` if loading from cache
- [ ] Update `SessionStore.sessionState` type if persisting to localStorage
- [ ] Register placeholder values in `TourLogic.isUnknownName()` if applicable
- [ ] Ensure "New Project" workflow clears relevant cached state
- [ ] Document the initialization behavior in this file

---

## 🐛 Common Pitfalls

### ❌ Empty String Defaults
**Problem**: Empty strings prevent placeholder text from showing in inputs.
```rescript
// BAD
tourName: ""
```
**Solution**: Use a recognized placeholder value.
```rescript
// GOOD
tourName: "Tour Name"
```

### ❌ Cached State Pollution
**Problem**: Old session data persists into new projects.
```rescript
// BAD
onClick: () => reload()
```
**Solution**: Clear session before reload.
```rescript
// GOOD
onClick: () => {
  SessionStore.clearState()
  reload()
}
```

### ❌ Aggressive Input Sanitization
**Problem**: Users can't clear inputs or see placeholders.
```rescript
// BAD - Sanitizes during typing
| SetTourName(name) =>
    Some({...state, tourName: TourLogic.sanitizeName(name)})
```
**Solution**: Sanitize only at persistence boundaries.
```rescript
// GOOD - Raw input during typing
| SetTourName(name) =>
    Some({...state, tourName: name})

// GOOD - Sanitize during save
let safeName = TourLogic.sanitizeName(state.tourName)
```

### ❌ Inconsistent Fallbacks
**Problem**: Different parts of the codebase use different default values.
```rescript
// BAD
| None => "Imported Tour"  // In one place
| None => "Tour Name"      // In another place
| None => ""               // In yet another place
```
**Solution**: Use `State.initialState.tourName` or a consistent constant.

---

## 🔄 Migration Guide

### Updating Existing Code

1. **Audit Default Values**
   ```bash
   # Find empty string initializations
   rg 'tourName:\s*""' src/
   ```

2. **Update State Definitions**
   - Replace empty strings with meaningful placeholders
   - Ensure consistency with `State.initialState`

3. **Add Placeholder Recognition**
   - Register new placeholders in `TourLogic.isUnknownName()`
   - Test that intelligent replacement works correctly

4. **Implement Session Clearing**
   - Add `SessionStore.clearState()` calls before `reload()`
   - Verify no state pollution occurs

5. **Test Scenarios**
   - [ ] Fresh app load (no cached state)
   - [ ] App load with cached state
   - [ ] New project creation (with existing scenes)
   - [ ] New project creation (empty state)
   - [ ] Project loading from ZIP
   - [ ] Image upload with EXIF data
   - [ ] Image upload without EXIF data

---

## 📚 Related Documentation

- **[Functional Standards](../functional-standards.md)**: Immutability and pure functions
- **[ReScript Standards](../rescript-standards.md)**: Language-specific patterns
- **[Testing Standards](../testing-standards.md)**: How to test initialization logic
- **[Design System](./DESIGN_SYSTEM.md)**: UI placeholder and input patterns

---

## 📝 Version History

| Version | Date       | Changes                                      |
|---------|------------|----------------------------------------------|
| 1.0     | 2026-01-23 | Initial documentation of initialization standards |

---

## 🤝 Contributing

When proposing changes to initialization behavior:

1. Update this document with the new standard
2. Ensure backward compatibility or provide migration path
3. Add tests covering the new initialization scenario
4. Update related documentation (MAP.md, ARCHITECTURE.md)
5. Get review from project maintainers

---

**Remember**: Initialization is the first impression. Make it predictable, clean, and user-friendly.
