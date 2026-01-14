# Task 88: Eliminate Obj.magic in Reducer.res

## Priority: 🟡 IMPORTANT

## Context
`Reducer.res` uses `Obj.magic` extensively for JSON parsing. While this works, it bypasses type checking and can lead to runtime errors that the compiler can't catch.

## Current State

The `parseProject`, `parseScene`, and `parseHotspots` functions convert JSON to typed records using:
```rescript
let pd = (Obj.magic(projectDataJson): {..})
```

This creates an open object type that can access any property without compiler verification.

## Problems

1. **No compile-time field validation**
   - `pd["tourName"]` might not exist
   - Misspellings like `pd["tourname"]` won't error

2. **No type safety on field values**
   - If `pd["scenes"]` is not an array, runtime crash

3. **Nullable handling is manual**
   - Need `Nullable.toOption(pd["field"])` everywhere

## Solution: JSON Decoders

### Option A: Manual Pattern Matching (Low Effort)

Keep Obj.magic but add validation:
```rescript
let parseProject = (json: JSON.t): result<state, string> => {
  let obj = Obj.magic(json)
  
  // Validate required fields exist
  if Js.typeof(obj["scenes"]) == "undefined" {
    Error("Missing scenes field")
  } else if !Array.isArray(obj["scenes"]) {
    Error("scenes must be an array")
  } else {
    Ok({
      tourName: Nullable.getOr(obj["tourName"], "Untitled"),
      scenes: parseScenes(obj["scenes"]),
      // ...
    })
  }
}
```

### Option B: Use rescript-json (Medium Effort)

Add a JSON decoding library:
```rescript
// With @glennsl/rescript-json-combinators

let projectDecoder = Json.Decode.(
  object(field => {
    tourName: field.optional("tourName", string)->Option.getOr("Untitled"),
    scenes: field.required("scenes", array(sceneDecoder)),
    // ...
  })
)

let parseProject = (json: JSON.t): result<state, string> => {
  Json.decode(json, projectDecoder)
}
```

### Option C: Define External Types (Matches Backend)

```rescript
// Define types that match exact JSON structure
type projectJson = {
  tourName: Nullable.t<string>,
  scenes: array<sceneJson>,
}

type sceneJson = {
  id: Nullable.t<string>,
  name: string,
  file: JSON.t,
  hotspots: Nullable.t<array<hotspotJson>>,
  // All fields as they appear in JSON
}

// Then cast once and use safely
let parseProject = (json: JSON.t): state => {
  let pj: projectJson = Obj.magic(json)
  // Now pj.tourName, pj.scenes are properly typed
}
```

## Recommended Approach

**Start with Option C** - Define intermediate JSON types that mirror the backend output, then convert to internal types. This:
1. Documents the JSON contract
2. Catches field name mismatches at the type level
3. Makes nullable fields explicit
4. Minimal refactoring effort

## Task Steps

1. [ ] Define `projectJson`, `sceneJson`, `hotspotJson` types
2. [ ] Update `parseProject` to use typed intermediate
3. [ ] Update `parseScene` to use typed intermediate
4. [ ] Update `parseHotspots` to use typed intermediate
5. [ ] Convert intermediate types to internal `state`
6. [ ] Verify all project loading works

## Acceptance Criteria
- [ ] Intermediate JSON types defined
- [ ] Obj.magic only at the initial parse boundary
- [ ] Field access uses typed records
- [ ] `npm run res:build` succeeds
- [ ] Project load/save works correctly

## Files to Modify
- `src/core/Reducer.res` - update parse functions
- `src/core/Types.res` - add JSON intermediates (optional)
- Create `src/core/JsonTypes.res` - JSON-shaped types

## Testing
1. Load an existing project
2. Verify all fields populated correctly
3. Load a malformed project
4. Verify graceful error (not crash)
5. Save and reload project
6. Verify round-trip works
