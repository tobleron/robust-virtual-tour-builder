# Task 78: Improve Error Handling in BackendApi.res

## Priority: 🟡 IMPORTANT

## Context
Several API functions in `BackendApi.res` silently swallow errors by catching exceptions and returning empty results. This makes debugging difficult and can lead to silent failures that users don't notice.

## Issues to Fix

### Issue 1: batchCalculateSimilarity swallows errors
**Location**: `BackendApi.res` ~lines 340-343

**Current (Problematic):**
```rescript
->Promise.catch(e => {
  Logger.error(
    ~module_="BackendApi",
    ~message="SIMILARITY_BATCH_ERROR",
    ~data=Obj.magic({"error": e}),
    (),
  )
  Promise.resolve([])  // Returns empty array - caller has no idea it failed
})
```

**Options for Fix:**

**Option A: Return Result type (Recommended)**
```rescript
// Change return type to Promise.t<result<array<similarityResult>, string>>
->Promise.then(json => {
  let data: similarityResponse = Obj.magic(json)
  Promise.resolve(Ok(data.results))
})
->Promise.catch(e => {
  Logger.error(...)
  Promise.resolve(Error("Similarity calculation failed"))
})
```

**Option B: Re-throw with context**
```rescript
->Promise.catch(e => {
  Logger.error(...)
  Promise.reject(JsError.throwWithMessage("Batch similarity failed: backend error"))
})
```

**Option C: Return option type**
```rescript
// Change return type to Promise.t<option<array<similarityResult>>>
->Promise.catch(e => {
  Logger.error(...)
  Promise.resolve(None)
})
```

### Issue 2: reverseGeocode returns fallback string
**Location**: `BackendApi.res` ~lines 293-295

**Current:**
```rescript
->Promise.catch(_ => {
  Promise.resolve("[Geocoding failed]")
})
```

**Analysis**: This is actually **acceptable** for geocoding since:
1. It's non-critical (just display data)
2. The caller gets a visible indication of failure
3. The fallback string is user-friendly

**Recommendation**: Keep as-is, but ensure Logger captures the error for debugging.

---

## Pattern to Establish

Create a standard error handling pattern for all API calls:

```rescript
// At top of BackendApi.res
type apiResult<'a> = result<'a, string>

// Example usage
let processImageFull = (file: File.t): Promise.t<apiResult<Blob.t>> => {
  // ...
  ->Promise.then(blob => Promise.resolve(Ok(blob)))
  ->Promise.catch(e => {
    Logger.error(...)
    Promise.resolve(Error("Image processing failed"))
  })
}
```

Then callers can pattern match:
```rescript
BackendApi.processImageFull(file)
->Promise.then(result => {
  switch result {
  | Ok(blob) => handleSuccess(blob)
  | Error(msg) => handleError(msg)
  }
})
```

## Acceptance Criteria
- [ ] `batchCalculateSimilarity` propagates errors to caller
- [ ] All critical API functions return `result` or `option` types
- [ ] Errors are both logged AND propagated
- [ ] Non-critical functions (like geocoding) have sensible fallbacks
- [ ] Callers are updated to handle new return types

## Files to Modify
- `src/systems/BackendApi.res`
- `src/systems/UploadProcessor.res` (caller of similarity)
- Any other callers of modified functions

## Testing
1. Stop the backend server
2. Attempt to upload images
3. Verify meaningful error messages appear (not silent failures)
4. Restart backend
5. Verify normal operation resumes
