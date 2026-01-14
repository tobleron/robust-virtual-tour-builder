---
description: Functional Programming Standards & Best Practices (ReScript + Rust)
---

# Functional Programming Standards

These rules enforce a functional programming paradigm across both the **ReScript frontend** and **Rust backend** to ensure type safety, predictability, and maintainability.

---

## Part 1: Universal Principles

These principles apply to **both** ReScript and Rust code.

### 1. Immutability First

- **Prefer immutable data**: Create new values rather than modifying existing ones.
- **Minimize mutable state**: When mutation is necessary, scope it as tightly as possible.
- **Copy-on-write**: Updates to data structures should return *new* instances.

### 2. Result Types Over Exceptions

- **Use Result/Option types**: Handle errors as values, not exceptions.
- **No panics/throws in business logic**: Reserve exceptions for truly unrecoverable states.
- **Chain with combinators**: Use `.map()`, `.and_then()`, `.map_err()` instead of early returns.

### 3. Pure Functions

- **Deterministic**: Same input → same output, always.
- **No side effects**: No I/O, no logging, no mutation inside pure functions.
- **Isolate side effects**: Push I/O to the edges (handlers, event callbacks).

### 4. Type Safety

- **No null/undefined**: Use `Option<T>` (Rust) or `option<t>` (ReScript).
- **Algebraic data types**: Use enums/variants for finite states.
- **Pattern matching**: Leverage exhaustive matching for control flow.

---

## Part 2: ReScript Frontend Standards

### 1. State Management (Elm/Redux Architecture)

- **Single Source of Truth**: Application state lives in a central immutable record.
- **Actions & Reducers**: State changes via dispatching Variants (Actions).
  - ❌ `store.state.value = 10; notify();`
  - ✅ `dispatch(UpdateValue(10))`
- **Pure Reducers**: `(state, action) => newState` must be pure.

### 2. Side Effect Isolation

- **React Hooks**: Use `useEffect` for I/O operations.
- **Event Handlers**: Side effects belong in component event handlers.
- **Encapsulation**: Wrap imperative libraries (Pannellum) in modules with pure APIs.

### 3. ReScript-Specific Rules

- **No mutable**: Avoid `mutable` struct fields and `ref` types.
  - ❌ `let isNavigating = ref(false)`
  - ✅ Pass state as arguments or use Context.
- **Variants over strings**: Use variant types for states.
  - ❌ `type status = string`
  - ✅ `type status = Idle | Loading | Success(data) | Error(string)`

### 4. Error Handling & Logging

> See `/debug-standards` for detailed logging guidelines.

- **Use Logger.attempt**: Wrap risky operations for auto-logging.
  ```rescript
  let result = Logger.attempt(~module_="Config", ~operation="PARSE", () => {
    parseJson(raw)
  })
  ```

- **Result types for recoverable errors**:
  ```rescript
  let parseConfig = (raw: string): result<config, string> => {
    // ...
  }
  ```

---

## Part 3: Rust Backend Standards

### 1. Error Handling

- **Custom Error Types**: Define domain-specific error enums.
  ```rust
  pub enum AppError {
      IoError(std::io::Error),
      ImageError(String),
      ValidationError(String),
  }
  ```

- **Implement From traits**: Enable automatic error conversion.
  ```rust
  impl From<std::io::Error> for AppError {
      fn from(err: std::io::Error) -> Self { AppError::IoError(err) }
  }
  ```

- **Use ? operator**: Propagate errors cleanly.
  ```rust
  let data = fs::read(&path)?;  // Automatically converts to AppError
  ```

### 2. Immutability in Handlers

- **Avoid &mut self methods**: Prefer taking ownership or using builders.
- **Scoped mutability**: When accumulating stream data, scope `mut` tightly.
  ```rust
  // Acceptable: mut scoped to function
  let mut buffer = Vec::new();
  while let Some(chunk) = stream.next().await? {
      buffer.extend_from_slice(&chunk);
  }
  // buffer is now complete, use immutably after
  process(&buffer)
  ```

- **Return new values**: Prefer returning new data over mutating inputs.
  ```rust
  // ❌ Mutates input
  fn clean_project(project: &mut Value) { ... }
  
  // ✅ Returns new value
  fn clean_project(project: Value) -> Result<Value, Error> { ... }
  ```

### 3. Pure Helper Functions

- **Processing functions should be pure**:
  ```rust
  // Pure function - no I/O, no side effects
  fn calculate_quality_score(stats: &QualityStats) -> f32 {
      let mut score = 7.5;
      if stats.is_blurry { score -= 2.0; }
      if stats.is_dark { score -= 2.5; }
      score.clamp(1.0, 10.0)
  }
  ```

- **Separate I/O from logic**:
  ```rust
  // Pure
  fn validate_project(data: &Value) -> ValidationReport { ... }
  
  // I/O at edges
  async fn save_project(data: Value) -> Result<(), Error> {
      let report = validate_project(&data);  // Pure
      fs::write("project.json", data)?;      // I/O at edge
      Ok(())
  }
  ```

### 4. Parallel Processing

- **Use Rayon for CPU-bound work**:
  ```rust
  let results: Vec<_> = images.par_iter()
      .map(|img| process_image(img))
      .collect();
  ```

- **Keep parallel closures pure**: No shared mutable state.

### 5. Logging Standards

- **Use tracing with structured fields**:
  ```rust
  use tracing::{info, warn, error, instrument};
  
  #[instrument(skip(payload), name = "resize_image")]
  pub async fn resize_image(payload: Multipart) -> Result<Response, Error> {
      info!(module = "Resizer", "RESIZE_START");
      // ...
      info!(module = "Resizer", duration_ms = elapsed, "RESIZE_COMPLETE");
  }
  ```

- **Error logging with context**:
  ```rust
  error!(module = "Exporter", error = %e, step = "compression", "EXPORT_FAILED");
  ```

### 6. Rust-Specific Rules

- **No unwrap() in production code**: Use `?` or `.ok_or()`.
  - ❌ `let value = map.get("key").unwrap();`
  - ✅ `let value = map.get("key").ok_or(AppError::MissingKey)?;`

- **No panic!() in handlers**: Return errors instead.
  - ❌ `panic!("Invalid state");`
  - ✅ `return Err(AppError::InvalidState("...".into()));`

- **Prefer iterators over loops**: Use `.map()`, `.filter()`, `.fold()`.
  ```rust
  // ❌ Imperative
  let mut results = Vec::new();
  for item in items {
      if item.valid {
          results.push(process(item));
      }
  }
  
  // ✅ Functional
  let results: Vec<_> = items.iter()
      .filter(|item| item.valid)
      .map(|item| process(item))
      .collect();
  ```

---

## Summary Checklist

### ReScript

- [ ] No `mutable` or `ref` for application state
- [ ] State changes via dispatch/reducer
- [ ] Side effects in useEffect or handlers
- [ ] Use `Logger.attempt` for error handling
- [ ] Variants for finite states

### Rust

- [ ] All handlers return `Result<T, AppError>`
- [ ] Custom error enum with From traits
- [ ] No `unwrap()` or `panic!()` in handlers
- [ ] Pure helper functions (no I/O)
- [ ] Prefer returning new values over mutation
- [ ] Use `tracing` for structured logging
- [ ] Parallel processing with rayon where applicable
