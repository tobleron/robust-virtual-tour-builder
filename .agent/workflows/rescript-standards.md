---
description: ReScript Frontend Standards & Error Prevention Patterns
---

# ReScript Frontend Standards

These rules apply specifically when editing **ReScript (`.res`, `.resi`)** files.

---

## 🔒 Part 1: Error Prevention Patterns (CRITICAL)

### 1. Schema-Driven IO
**Goal**: Eliminate runtime errors from invalid data shapes.

- **Rule**: Use `rescript-schema` for ALL data entering or leaving the system (API, LocalStorage, IndexedDB).
- **Rule**: Forbid native `JSON.stringify` for complex objects or records. ALWAYS use `S.reverseConvertToJsonStringOrThrow` to ensure schema integrity.
- **Rule**: Use `S.json` for arbitrary `JSON.t` data instead of `S.unknown`. `S.unknown` is not reversible. Note: The `TypeError` ("setting '~r'") issue was resolved by upgrading to `rescript-schema@9.3.0-rescript12.0`.
- **Rule**: NO `Obj.magic` or unsafe casts at the boundary. Use `S.parseOrThrow` or `S.parse`.

```rescript
// ❌ BAD: Unsafe Access or Legacy Decode
let parse = json => {
  let data = JSON.Decode.string(json) // Legacy
}

// ✅ GOOD: Schema Validation
let parse = (json: JSON.t): data => {
  S.parseOrThrow(json, Schemas.Domain.someSchema)
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
