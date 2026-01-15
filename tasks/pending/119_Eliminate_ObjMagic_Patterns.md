# Task 119: Eliminate Remaining Obj.magic Patterns

## Priority: LOW

## Context
The codebase currently has **263 `Obj.magic` calls** across ReScript modules. While some are necessary at JSON parsing boundaries, many can be replaced with proper type definitions for improved type safety.

`Obj.magic` bypasses the type system, meaning:
- Runtime errors instead of compile-time errors
- Harder to refactor safely
- Less IDE support for autocomplete

## Objective
Reduce `Obj.magic` usage by 50%+ by adding proper type definitions.

## Current Distribution
Run to check: `grep -r "Obj.magic" --include="*.res" src/ | wc -l`

## Strategy

### 1. Identify Categories of Obj.magic Usage

**Acceptable (Keep):**
- JSON.parse result typing (unavoidable)
- FFI boundaries with JavaScript libraries

**Eliminate:**
- Record field access that should use proper types
- Type conversions that could use type declarations

### 2. Priority Modules

Focus on modules with highest Obj.magic density:
1. `BackendApi.res` - API response typing
2. `Reducer.res` - Action payload typing
3. `Main.res` - Initialization typing
4. `ProjectManager.res` - Project data typing

### 3. Example Refactoring

**Before (Bad):**
```rescript
let handleResponse = (json: Js.Json.t) => {
  let data = Obj.magic(json)
  let name = data["name"] // TypeScript-style access
  let count = data["count"]
  (name, count)
}
```

**After (Good):**
```rescript
type apiResponse = {
  name: string,
  count: int,
}

let handleResponse = (json: Js.Json.t): result<apiResponse, string> => {
  try {
    let data: apiResponse = Obj.magic(json) // Single Obj.magic at boundary
    Ok(data)
  } catch {
  | _ => Error("Invalid response format")
  }
}
```

**Even Better (With Validation):**
```rescript
let decodeResponse = (json: Js.Json.t): result<apiResponse, string> => {
  switch Js.Json.decodeObject(json) {
  | None => Error("Expected object")
  | Some(obj) =>
    switch (
      Js.Dict.get(obj, "name")->Option.flatMap(Js.Json.decodeString),
      Js.Dict.get(obj, "count")->Option.flatMap(Js.Json.decodeNumber)
    ) {
    | (Some(name), Some(count)) => Ok({name, count: count->Int.fromFloat})
    | _ => Error("Missing required fields")
    }
  }
}
```

## Acceptance Criteria
- [ ] Reduce Obj.magic count from 263 to <130
- [ ] Add proper record types for API responses
- [ ] Add proper record types for reducer payloads
- [ ] All refactored code compiles: `npm run res:build`
- [ ] All tests pass: `npm test`
- [ ] No new runtime errors introduced

## Verification Process
1. Before: `grep -r "Obj.magic" --include="*.res" src/ | wc -l`
2. Make changes
3. `npm run res:build` - must succeed
4. `npm test` - must pass
5. After: `grep -r "Obj.magic" --include="*.res" src/ | wc -l`
6. Manual testing of affected features

## Estimated Effort
8-16 hours (can be done incrementally across multiple sessions)

## Notes
- Can be done incrementally, one module at a time
- Each module can be a separate sub-task if needed
- Focus on high-value modules first (BackendApi, Reducer)
