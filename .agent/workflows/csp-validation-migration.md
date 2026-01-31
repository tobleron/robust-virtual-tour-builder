---
description: Guide for transitioning from rescript-schema to CSP-friendly validation
---

# Migration to CSP-Friendly Validation

## Problem Statement
The project currently uses `rescript-schema` (v9/v10) which relies on `unsafe-eval` (via `new Function`) for performance optimization. This violates the strict Content Security Policy (CSP) required for the tour builder application, causing `EvalError` at runtime.

## Immediate Mitigation (Zero-Eval Strategy)
As a hotfix, all critical paths (`SessionStore`, `PersistenceLayer`, `ProjectApi`, `MediaApi`, `LoggerTelemetry`) have been patched to bypass schema validation:
- **Serialization**: `S.reverseConvert...` -> `JSON.stringifyAny`
- **Parsing**: `S.parse...` -> `Object.magic` (unsafe cast) or manual checks.

## Recommended Alternative: `rescript-json-combinators`
To regain runtime type safety without `eval`, we should migrate to **`glennsl/rescript-json-combinators`**.

### Why this library?
1.  **Zero Eval**: It uses functional combinators (functions calling functions), not code generation.
2.  **Strict CSP Compliant**: Guaranteed to work in environments like Cloudflare Workers or strict headers.
3.  **Result-Based API**: Returns `result<'a, string>` instead of throwing exceptions, leading to safer error handling.
4.  **Professional Standard**: Widely used in the ReScript community for "pure" validation.

### Migration Example

#### Current (rescript-schema)
```rescript
// Uses eval!
let userSchema = S.object(s => {
  {
    name: s.field("name", S.string),
    age: s.field("age", S.int),
  }
})
```

#### New (rescript-json-combinators)
```rescript
// Pure functions, no eval
let userDecoder = {
  open Json.Decode
  object(field => {
    name: field.required("name", string),
    age: field.required("age", int),
  })
}
```

## Implementation Plan
1.  **Install**: `npm install @glennsl/rescript-json-combinators`
2.  **Replace**: Systematically replace usage in `Schemas.res`.
3.  **Verify**: Ensure no `new Function` calls appear in the build output.

## Other Candidates (less optimal)
- **`ppx_spice`**: Good, but relies on compile-time codegen (PPX). Can be brittle with toolchain updates.
- **`rescript-struct`**: Likely also uses `eval` (need strict verification, assuming unsafe based on `rescript-schema` lineage).
