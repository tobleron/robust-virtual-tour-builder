---
description: Rust Backend Standards & Best Practices
---

# Rust Backend Standards

These rules apply specifically when editing **Rust (`.rs`)** files in the backend.

---

## 🔒 Part 1: Error Handling (CRITICAL)

### 1. Result Types Over Exceptions
- **Rule**: Handlers MUST return `Result<T, AppError>`.
- **Rule**: **NO** `unwrap()` in production code. Use `?` or `.ok_or()`.
- **Rule**: **NO** `panic!()` in business logic.

```rust
// ❌ BAD: Panic risk
let val = map.get("key").unwrap();

// ✅ GOOD: Propagated Error
let val = map.get("key").ok_or(AppError::MissingKey)?;
```

### 2. Custom Error Types
- **Rule**: Define domain-specific error enums.
- **Rule**: Implement `From<T>` for automatic conversion.

```rust
pub enum AppError {
    IoError(std::io::Error),
    ValidationError(String),
}
```

---

## 🏗️ Part 2: Architecture Standards

### 1. Immutability in Handlers
- **Rule**: Avoid `&mut self` methods where possible.
- **Rule**: Scope mutability tightly (e.g., inside a buffer filling loop).
- **Rule**: Prefer returning new values over mutating inputs.

### 2. Pure Helper Functions
- **Rule**: Separate I/O from business logic.
- **Rule**: Processing functions should be pure (deterministic input -> output).

```rust
// Pure logic
fn calculate_score(stats: &Stats) -> f32 { ... }

// I/O wrapper
async fn save_score(stats: &Stats) -> Result<()> {
    let score = calculate_score(stats);
    db.save(score).await?;
    Ok(())
}
```

---

## ⚡ Part 3: Performance & Logging

### 1. Parallel Processing
- **Rule**: Use `Rayon` for CPU-bound work on collections.
- **Rule**: Keep parallel closures pure (no shared mutable state).

### 2. Structured Logging
- **Rule**: Use `tracing` crate with structured fields.
- **Rule**: Include `module`, `operation`, and timing data.

```rust
info!(module = "Resizer", duration_ms = elapsed, "RESIZE_COMPLETE");
```

---

## ✅ Checklist for Rust Files

- [ ] Handler returns `Result`?
- [ ] No `unwrap()` or `panic!()` used?
- [ ] Mutability is scoped locally?
- [ ] I/O is separated from pure logic?
- [ ] `tracing` used for logging?
