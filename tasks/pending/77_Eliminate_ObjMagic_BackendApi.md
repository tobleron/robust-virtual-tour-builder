# Task 77: Eliminate Obj.magic in BackendApi.res

## Priority: 🟡 IMPORTANT

## Context
`Obj.magic` is ReScript's escape hatch for bypassing the type system. While sometimes necessary for FFI, overuse leads to runtime errors that the compiler can't catch. Several instances in `BackendApi.res` can be replaced with proper type definitions.

## Instances to Fix

### Instance 1: reverseGeocode response parsing
**Location**: `BackendApi.res` ~line 290

**Current:**
```rescript
Fetch.json(response)->Promise.then(json => {
  let data: {"address": string} = Obj.magic(json)
  Promise.resolve(data["address"])
})
```

**Fixed:**
```rescript
// Define proper response type
type geocodeResponse = {
  address: string,
}

// Use type annotation on json parse
Fetch.json(response)->Promise.then(json => {
  let data: geocodeResponse = Obj.magic(json) // Still magic but typed
  Promise.resolve(data.address)
})
```

**Better Fix (with external decoder):**
```rescript
// If we add a JSON decoder library, we can validate at runtime
let decodeGeocodeResponse = (json: JSON.t): result<geocodeResponse, string> => {
  // Proper decoding logic
}
```

### Instance 2: batchCalculateSimilarity response
**Location**: `BackendApi.res` ~line 335

**Current:**
```rescript
let data: similarityResponse = Obj.magic(json)
Promise.resolve(data["results"])
```

**Fixed:**
```rescript
// Already has type definition, just use proper record access
let data: similarityResponse = Obj.magic(json)
Promise.resolve(data.results) // Use dot notation for records
```

### Instance 3: calculatePath payload
**Location**: `BackendApi.res` ~line 255

**Current:**
```rescript
body: JSON.stringify(Obj.magic(payload)),
```

**Recommendation:** Caller should pass a properly typed payload that matches the PathRequest structure.

### Instance 4: importProject response
**Location**: `BackendApi.res` ~line 112

**Current:**
```rescript
.then(json => Promise.resolve((Obj.magic(json): importResponse)))
```

**This is acceptable** since `importResponse` is already defined and Obj.magic is just casting the parsed JSON.

## Acceptance Criteria
- [ ] All response types have explicit record definitions
- [ ] Record field access uses dot notation, not string keys
- [ ] Obj.magic is only used at the JSON parsing boundary
- [ ] No TypeScript-style object access (`data["field"]`) on ReScript records
- [ ] `npm run res:build` compiles with no errors

## Files to Modify
- `src/systems/BackendApi.res`

## Testing
1. Run `npm run res:build`
2. Test each API call:
   - Upload an image → verify metadata extraction works
   - Reverse geocode → verify address returned
   - Calculate path → verify teaser/timeline works
   - Batch similarity → verify duplicate detection works
