---
description: ReScript Frontend Standards & Error Prevention Patterns
---

# ReScript Frontend Standards

These rules apply specifically when editing **ReScript (`.res`, `.resi`)** files.

---

## 🔒 Part 1: Error Prevention Patterns (CRITICAL)

### 1. Type Coercion Safety
**Goal**: Eliminate runtime errors from invalid data shapes.

- **Rule**: Define `JsonTypes` for all external data (API responses, LocalStorage).
- **Rule**: Use `Obj.magic` **ONLY** at the API boundary, never internally.
- **Rule**: Always annotate `Obj.magic` with the target type.

```rescript
// ❌ BAD: Unsafe Access
let parse = json => {
  let data = Obj.magic(json) // Untyped magic
  data["field"] // Runtime risk!
}

// ✅ GOOD: Typed Boundary
type responseJson = {
  data: Nullable.t<string>,
  count: int
}

let parse = (json: JSON.t): data => {
  let typed: responseJson = Obj.magic(json) // Typed boundary
  switch Nullable.toOption(typed.data) { // Safe conversion
  | Some(d) => process(d)
  | None => default()
  }
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
- **Reference**: See `/docs/DESIGN_SYSTEM.md`.

---

## ✅ Checklist for ReScript Files

- [ ] `Obj.magic` used ONLY at boundaries with explicit type?
- [ ] No inline `%raw` for repeated operations?
- [ ] No `mutable` fields in domain records?
- [ ] Nullables converted to Options?
- [ ] No variable shadowing (W45 warnings)?
- [ ] Error logs include context data?
