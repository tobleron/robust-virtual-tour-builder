---
description: Testing Standards & Best Practices (ReScript + Rust)
---

# Testing Standards (⚠️ SUSPENDED DURING REFACTORING)

These rules enforce a high standard of quality through unit testing across both the **ReScript frontend** and **Rust backend**.

**NOTE: MANDATORY TESTING IS CURRENTLY SUSPENDED UNTIL FURTHER NOTICE.**

---

## 🚀 Part 1: Mandatory Testing (INACTIVE)

1. **New Features**: (Optional) New feature unit tests are deferred.
2. **Bug Fixes**: (Optional) Regression tests are deferred.
3. **Refactoring**: (Optional) Testing after refactors is currently manual.
4. **Commits**: `npm test` is BYPASSED in all commit scripts.
5. **Iterative Code Changes**: During ongoing source calibration of any module, default to build verification first and defer unit-test rewrites until the implementation stabilizes.
6. **Single Deferred Review Task**: When tests are deferred, create or reuse one shared pending task that lists every changed source file/module needing later unit-test review. Do not create a new test-review task for every small code change.

---

## 🛠️ Part 2: ReScript Frontend Standards

### 1. Test File Structure
Create tests in `tests/unit/{ModuleName}.test.res`. Note the `.test.res` suffix which is required for Vitest discovery.

```rescript
/* tests/unit/MyModule.test.res */
open Vitest

test("MyModule: add function", t => {
  t->expect(MyModule.add(1, 2))->Expect.toBe(3)
})

test("MyModule: divide by zero", t => {
  t->expect(MyModule.divide(10, 0))->Expect.toBe(None)
})
```

### 2. Running Tests
- Use `npm run test:watch` for developer feedback.
- Use `npm run test:frontend` for CI/manual runs.
- **Note**: New Vitest tests do NOT need to be registered in `tests/TestRunner.res`. Vitest automatically discovers files matching `*.test.res`.
- **Process note**: If the source behavior is still in flux, prefer build verification first and postpone test edits to the shared deferred-review task.

---

## 🦀 Part 3: Rust Backend Standards

### 1. Inline Unit Tests
Use the `#[cfg(test)]` module pattern at the bottom of the source file.

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_my_function() {
        assert_eq!(my_function(input), expected);
    }

    #[tokio::test]
    async fn test_async_function() {
        let result = my_async_function().await.unwrap();
        assert!(result.is_ok());
    }
}
```

### 2. Business Logic Isolation
Separate I/O from business logic to make functions pure and easy to test.

---

## 📊 Part 4: What to Test

| Priority | Category | Example |
|----------|----------|---------|
| **CRITICAL** | Pure Logic | Math, coordinate transforms, parsing |
| **HIGH** | State Changes | Reducer actions, data transitions |
| **MEDIUM** | API Parsing | JSON decoding, error mapping |
| **LOW** | UI Components | Visual layout, hover states |

---

## ✅ Part 5: Checklist

- [ ] New ReScript module has `tests/unit/ModuleName.test.res` (Vitest)
- [ ] New Rust module has `#[cfg(test)]` block
- [ ] Happy paths are covered
- [ ] Edge cases (empty, null, zero) are covered
- [ ] Error paths (invalid input) are covered
- [ ] `npm test` passes locally
- [ ] Type coercion patterns follow `.agent/workflows/rescript-standards.md` Part 1
