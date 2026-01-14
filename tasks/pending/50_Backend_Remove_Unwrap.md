# Task: Remove unwrap() Calls from Backend Handlers

## Objective
Replace all `unwrap()` and `expect()` calls in handler code with proper error handling using `?` operator or `.ok_or()`.

## Context
Using `unwrap()` in production code can cause panics, which crash the entire server. Functional programming requires handling all error cases explicitly.

## Current Issues

Search for unwrap usage:
```bash
grep -n "unwrap()" backend/src/handlers.rs
```

Known occurrences:
```rust
// Line 100 - get_temp_path
fs::create_dir_all(&path).unwrap_or_default();  // OK - intentional fallback

// Line 232 - regex
let re = Regex::new(r"_(\d{6})_\d{2}_(\d{3})").unwrap();  // Problem!

// Line 963 - content_disposition
let content_disposition = field.content_disposition().unwrap().clone();  // Problem!

// Line 1132 - content_disposition  
let content_disposition = field.content_disposition().unwrap().clone();  // Problem!
```

## Implementation Steps

### 1. Fix Regex Compilation

```rust
// Before
let re = Regex::new(r"_(\d{6})_\d{2}_(\d{3})").unwrap();

// After - use lazy_static or compile once
use once_cell::sync::Lazy;
static FILENAME_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"_(\d{6})_\d{2}_(\d{3})").expect("Invalid regex in source")
});

// Usage
if let Some(caps) = FILENAME_REGEX.captures(base_name) { ... }
```

Note: `expect()` is acceptable for compile-time constants that cannot fail.

### 2. Fix content_disposition Unwraps

```rust
// Before
let content_disposition = field.content_disposition().unwrap().clone();

// After
let content_disposition = field.content_disposition()
    .ok_or(AppError::MultipartError(
        actix_multipart::MultipartError::Incomplete
    ))?
    .clone();
```

Or more concisely:
```rust
let content_disposition = field.content_disposition()
    .cloned()
    .ok_or(AppError::InternalError("Missing content disposition".into()))?;
```

### 3. Audit All Handler Code

Run grep to find all occurrences:
```bash
grep -n "unwrap()" backend/src/handlers.rs
grep -n "expect(" backend/src/handlers.rs
```

Replace each with appropriate error handling.

### 4. Acceptable Uses

These are acceptable:
- `unwrap_or_default()` - Has explicit fallback
- `expect()` on compile-time constants (regex patterns)
- `unwrap()` in test code only

## Files to Modify

| File | Changes |
|------|---------|
| `backend/src/handlers.rs` | Replace unwrap() calls |
| `backend/Cargo.toml` | Add `once_cell` dependency if using Lazy |

## Testing Checklist

- [ ] No `unwrap()` calls in handler code (except fallbacks)
- [ ] Server doesn't panic on malformed requests
- [ ] All error cases return proper HTTP error responses
- [ ] Grep shows no problematic unwrap() usage

## Definition of Done

- All handler unwrap() replaced with ? or .ok_or()
- Regex compiled once with lazy_static/once_cell
- Server handles malformed input gracefully
- No panics in production code paths
