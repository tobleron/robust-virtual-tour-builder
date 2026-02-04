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

### TypeScript / JavaScript

#### ✅ Recommended: Zod
```typescript
import { z } from 'zod'

// Define schema
const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  age: z.number().int().positive(),
  email: z.string().email().optional()
})

type User = z.infer<typeof UserSchema>

// Validate
function parseUser(json: unknown): Result<User, string> {
  const result = UserSchema.safeParse(json)
  
  if (result.success) {
    return { ok: true, value: result.data }
  } else {
    return { ok: false, error: result.error.message }
  }
}
```

**Benefits**:
- TypeScript-first design
- Excellent error messages
- Composable schemas
- No runtime code generation

#### ✅ Recommended: io-ts
```typescript
import * as t from 'io-ts'
import { isRight } from 'fp-ts/Either'

const UserCodec = t.type({
  id: t.string,
  name: t.string,
  age: t.number,
  email: t.union([t.string, t.undefined])
})

type User = t.TypeOf<typeof UserCodec>

function parseUser(json: unknown): Result<User, string> {
  const result = UserCodec.decode(json)
  
  if (isRight(result)) {
    return { ok: true, value: result.right }
  } else {
    return { ok: false, error: 'Validation failed' }
  }
}
```

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

```typescript
// ✅ GOOD: Validate at API boundary
async function fetchUser(id: string): Promise<Result<User>> {
  const response = await fetch(`/api/users/${id}`)
  const json = await response.json()
  
  // Validate immediately
  return parseUser(json)
}

// ❌ BAD: Pass unvalidated data deep into app
async function fetchUser(id: string): Promise<any> {
  const response = await fetch(`/api/users/${id}`)
  return response.json() // Unvalidated!
}
```

### Nested Validation

```typescript
const AddressSchema = z.object({
  street: z.string(),
  city: z.string(),
  zipCode: z.string().regex(/^\d{5}$/)
})

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  address: AddressSchema // Compose schemas
})
```

### Array Validation

```typescript
const UsersSchema = z.array(UserSchema)

function parseUsers(json: unknown): Result<User[]> {
  return UsersSchema.safeParse(json)
}
```

### Union Types

```typescript
const ResponseSchema = z.discriminatedUnion('status', [
  z.object({ status: z.literal('success'), data: UserSchema }),
  z.object({ status: z.literal('error'), message: z.string() })
])
```

---

## 4. Error Handling

### Structured Errors

```typescript
type ValidationError = {
  field: string
  message: string
  code: string
}

function parseWithDetails(json: unknown): Result<User, ValidationError[]> {
  const result = UserSchema.safeParse(json)
  
  if (result.success) {
    return { ok: true, value: result.data }
  }
  
  const errors = result.error.errors.map(err => ({
    field: err.path.join('.'),
    message: err.message,
    code: err.code
  }))
  
  return { ok: false, errors }
}
```

### User-Friendly Messages

```typescript
function formatValidationError(error: ValidationError): string {
  const fieldName = error.field.split('.').pop()
  
  switch (error.code) {
    case 'invalid_type':
      return `${fieldName} has an invalid format`
    case 'too_small':
      return `${fieldName} is too short`
    case 'too_big':
      return `${fieldName} is too long`
    default:
      return `${fieldName} is invalid`
  }
}
```

---

## 5. Performance Considerations

### Lazy Validation

```typescript
// Validate only when needed
class LazyUser {
  private validated: User | null = null
  
  constructor(private json: unknown) {}
  
  validate(): Result<User> {
    if (this.validated) {
      return { ok: true, value: this.validated }
    }
    
    const result = parseUser(this.json)
    if (result.ok) {
      this.validated = result.value
    }
    
    return result
  }
}
```

### Streaming Validation

```typescript
// For large datasets
async function* validateStream(
  stream: AsyncIterable<unknown>
): AsyncGenerator<Result<User>> {
  for await (const item of stream) {
    yield parseUser(item)
  }
}
```

---

## 6. Testing Validation Logic

### Property-Based Testing

```typescript
import { fc } from 'fast-check'

test('UserSchema accepts valid users', () => {
  fc.assert(
    fc.property(
      fc.record({
        id: fc.string(),
        name: fc.string(),
        age: fc.integer({ min: 0, max: 150 }),
        email: fc.option(fc.emailAddress())
      }),
      (user) => {
        const result = UserSchema.safeParse(user)
        expect(result.success).toBe(true)
      }
    )
  )
})
```

### Edge Cases

```typescript
test('UserSchema rejects invalid data', () => {
  const invalidCases = [
    { id: 123, name: 'John' },           // id is number
    { id: '1', name: null },             // name is null
    { id: '1', name: 'John', age: -5 },  // negative age
    { id: '1', name: 'John', age: 'old' } // age is string
  ]
  
  invalidCases.forEach(invalid => {
    const result = UserSchema.safeParse(invalid)
    expect(result.success).toBe(false)
  })
})
```

---

## 7. Migration Guide

### From Manual Parsing

```typescript
// ❌ BEFORE: Manual, error-prone
function parseUser(json: any): User {
  return {
    id: json.id,
    name: json.name,
    age: parseInt(json.age),
    email: json.email || undefined
  }
}

// ✅ AFTER: Validated, type-safe
const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  age: z.number(),
  email: z.string().optional()
})

function parseUser(json: unknown): Result<User> {
  return UserSchema.safeParse(json)
}
```

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

## 8. Best Practices Checklist

- [ ] All external JSON is validated at the IO boundary
- [ ] Validation uses CSP-compliant libraries (no eval)
- [ ] Errors are returned as values, not thrown
- [ ] Schemas are colocated with type definitions
- [ ] User-facing error messages are friendly and actionable
- [ ] Edge cases are covered by tests
- [ ] Large datasets use streaming validation
- [ ] Validation logic is reusable across encode/decode

---

## References

- [Zod Documentation](https://zod.dev/)
- [io-ts Documentation](https://gcanti.github.io/io-ts/)
- [rescript-json-combinators](https://github.com/glennsl/rescript-json-combinators)
- [serde Documentation](https://serde.rs/)
- [OWASP: Input Validation](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)
