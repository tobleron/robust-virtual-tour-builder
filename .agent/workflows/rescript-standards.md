---
description: ReScript Frontend Standards & Error Prevention Patterns
---

# ReScript Frontend Standards

These rules apply specifically when editing **ReScript (`.res`, `.resi`)** files.

---

## 🔒 Part 1: Error Prevention Patterns (CRITICAL)

### 1. CSP-Safe Schema Validation
**Goal**: Eliminate runtime errors and CSP violations (no `eval`).

- **Rule**: Use `rescript-json-combinators` (`@glennsl/rescript-json-combinators`) for ALL data validation.
- **Rule**: FORBID `rescript-schema` (uses `eval` -> CSP violation).
- **Rule**: Use `JsonCombinators.Json.decode` for parsing and `JsonCombinators.Json.stringify` for serialization.
- **Rule**: Define decoders/encoders in a dedicated `Schemas` or `Decoders` module.

```rescript
// ❌ BAD: Unsafe or Eval-based
let parse = json => {
  let data = JSON.parseExn(json) // Unsafe
  // OR
  S.parseOrThrow(json, schema) // Uses eval!
}

// ✅ GOOD: Combinator Validation
let decodeUser = {
  open JsonCombinators.Json.Decode
  object(field => {
      name: field.required("name", string),
      age: field.required("age", int)
  })
}

let parse = (json: JSON.t) => {
  JsonCombinators.Json.decode(json, decodeUser)
}
```

### 2. External Bindings
**Goal**: Prevent runtime crashes from unbound JS functions.

- **Rule**: Create proper `@send`/`@val` bindings instead of inline `%raw`.
- **Rule**: Use `@return(nullable)` for DOM APIs that might return null.
- **Rule**: Group bindings in modules (e.g., `Bindings.res`).

```rescript
// ❌ BAD: Inline Raw
let draw = %raw("(ctx) => ctx.draw()")

// ✅ GOOD: Proper Binding
module Canvas = {
  @send external draw: (context, unit) => unit = "draw"
}
```

### 3. Immutability Enforcement
**Goal**: Prevent race conditions and state desync.

- **Rule**: **NO** `mutable` fields in domain records.
- **Rule**: Use `React.useState` or Reducers for state.
- **Rule**: Return new instances instead of mutating.

```rescript
// ❌ BAD: Mutable Record
type state = { mutable count: int }

// ✅ GOOD: Immutable Update
let increment = state => {...state, count: state.count + 1}
```

### 4. Nullable Handling
**Goal**: Eliminate "undefined is not a function".

- **Rule**: Use `Nullable.t<T>` for JSON fields.
- **Rule**: Use `option<T>` for internal ReScript logic.
- **Rule**: Convert at the boundary using `Nullable.toOption`.

---

## 🏗️ Part 2: Architecture Standards

### 1. State Management
- **Single Source of Truth**: Application state lives in central stores.
- **Actions & Reducers**: Changes happen via dispatched actions (Elm/Redux pattern).

### 2. Side Effect Isolation
- **React**: Use `useEffect` for I/O.
- **Logic**: Keep business logic pure; push I/O to event handlers.
- **Wrappers**: Wrap imperative libraries (Pannellum) in pure modules.

### 3. Variants over Strings
- ❌ `type status = string` ("loading", "done")
- ✅ `type status = Idle | Loading | Success(data) | Error(string)`

---

## 📝 Part 3: Logging & Debugging

- **Rule**: Use `Logger` module, never `Console.log`.
- **Rule**: Use `Logger.attempt` for risky operations.
- **Rule**: Include context data in error logs.

```rescript
Logger.error(
  ~module_="Upload",
  ~message="FAILED",
  ~data={"id": id, "reason": "timeout"},
  ()
)
```

---

## 🎨 Part 4: Styling Standards (SoC)

- **Rule**: **NO** inline styles (`makeStyle`) unless value is strictly dynamic (e.g., coordinates, progress %).
- **Rule**: Use semantic, state-based classes defined in `css/components/`.
- **Rule**: Do not define colors or layout constants in ReScript; use CSS Variabes.
- **Reference**: See `/docs/PROJECT_SPECS.md`.

---

## ✅ Checklist for ReScript Files

- [ ] `Obj.magic` used ONLY at boundaries with explicit type?
- [ ] No inline `%raw` for repeated operations?
- [ ] No `mutable` fields in domain records?
- [ ] Nullables converted to Options?
- [ ] No variable shadowing (W45 warnings)?
- [ ] Error logs include context data?
