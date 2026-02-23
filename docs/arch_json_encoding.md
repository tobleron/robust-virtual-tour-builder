# JSON Encoding & Validation Standards

**Version**: 1.0  
**Last Updated**: 2026-02-04  
**Status**: Active Standard

---

## Overview

This document defines best practices for JSON encoding, decoding, and validation in modern web applications, with a focus on type safety and Content Security Policy (CSP) compliance.

---

## 1. Core Principles

### Type Safety First
- **Never trust external data**: All JSON from APIs, files, or user input must be validated
- **Fail explicitly**: Return typed errors instead of throwing exceptions
- **Validate at boundaries**: Parse and validate at the IO boundary, not deep in business logic

### CSP Compliance
- **No eval()**: Avoid libraries that use `eval()`, `Function()`, or `new Function()`
- **No inline scripts**: All JSON parsing must use safe, declarative approaches
- **Static analysis friendly**: Prefer compile-time type checking over runtime code generation

---

## 2. Recommended Approaches by Language

### ReScript

#### ✅ Recommended: rescript-json-combinators
```rescript
open JsonCombinators.Json

// Define decoder
let userDecoder = {
  open Decode
  object(field => {
    id: field.required("id", string),
    name: field.required("name", string),
    age: field.required("age", int),
    email: field.optional("email", string)
  })
}

// Define encoder
let userEncoder = user => {
  open Encode
  object([
    ("id", string(user.id)),
    ("name", string(user.name)),
    ("age", int(user.age)),
    ("email", nullable(string, user.email))
  ])
}

// Parse
let parseUser = (json: JSON.t): result<user, string> => {
  Json.decode(json, userDecoder)
}

// Serialize
let serializeUser = (user: user): string => {
  Json.encode(userEncoder(user))
}
```

**Benefits**:
- CSP-compliant (no eval)
- Functional composition
- Explicit error handling
- Type-safe by design

#### ❌ Forbidden: rescript-schema
```rescript
// DON'T USE - Violates CSP
let schema = S.object(s => {
  id: s.field("id", S.string),
  name: s.field("name", S.string)
})

// This uses eval() internally!
let user = S.parseOrThrow(json, schema)
```

**Why Forbidden**: Uses `eval()` for code generation, violating CSP policies.

### Rust

#### ✅ Recommended: serde_json
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct User {
    id: String,
    name: String,
    age: u32,
    email: Option<String>,
}

// Parse
fn parse_user(json: &str) -> Result<User, serde_json::Error> {
    serde_json::from_str(json)
}

// Serialize
fn serialize_user(user: &User) -> Result<String, serde_json::Error> {
    serde_json::to_string(user)
}
```

**Benefits**:
- Zero-cost abstractions
- Compile-time validation
- Excellent error messages
- Industry standard

---

## 3. Validation Patterns

### Boundary Validation

```rescript
// ✅ GOOD: Validate at API boundary
let fetchUser = async (id: string) => {
  let response = await fetch(`/api/users/${id}`)
  let json = await response.json()
  // Validate immediately
  parseUser(json)
}
```

---

## 4. Error Handling

### Structured Errors

```rescript
type validationError = {
  field: string,
  message: string,
  code: string
}
```

---

## 5. Performance Considerations

### Lazy Validation

Validate only when needed, especially when handling potentially massive project manifest files. Defer parsing of scene data until strictly necessary.

---

## 6. Migration Guide

### From eval-based Libraries

```rescript
// ❌ BEFORE: rescript-schema (uses eval)
let user = S.parseOrThrow(json, userSchema)

// ✅ AFTER: rescript-json-combinators
let user = switch Json.decode(json, userDecoder) {
| Ok(u) => Some(u)
| Error(_) => None
}
```

---

## 7. Best Practices Checklist

- [ ] All external JSON is validated at the IO boundary
- [ ] Validation uses CSP-compliant libraries (no eval)
- [ ] Errors are returned as values, not thrown
- [ ] Schemas are colocated with type definitions
- [ ] User-facing error messages are friendly and actionable
- [ ] Edge cases are covered by tests
- [ ] Large datasets use streaming validation
- [ ] Validation logic is reusable across encode/decode
