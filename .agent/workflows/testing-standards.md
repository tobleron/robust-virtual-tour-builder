---
description: Testing Standards & Best Practices (ReScript + Rust)
---

# Testing Standards

These rules enforce a high standard of quality through unit testing across both the **ReScript frontend** and **Rust backend**.

---

## 🚀 Part 1: Mandatory Testing

1. **New Features**: Every new feature MUST have corresponding unit tests.
2. **Bug Fixes**: Every bug fix MUST include a regression test that reproduces the bug before fixing it.
3. **Refactoring**: When refactoring modules (especially those > 700 lines), tests MUST be run before and after to ensure behavior preservation.
4. **Commits**: `npm test` MUST pass before ANY commit via `./scripts/commit.sh`.

---

## 🛠️ Part 2: ReScript Frontend Standards

### 1. Test File Structure
Create tests in `tests/unit/{ModuleName}Test.res`.

```rescript
/* tests/unit/MyModuleTest.res */
open MyModule

let run = () => {
  Console.log("Running MyModule tests...")
  
  // 1. Pure Function Test
  assert(add(1, 2) == 3)
  Console.log("✓ add function")
  
  // 2. Edge Case Test
  assert(divide(10, 0) == None)
  Console.log("✓ divide by zero")
  
  Console.log("MyModule tests passed!")
}
```

### 2. Integration with Runner
Update `tests/TestRunner.res` to include your new test:
```rescript
MyModuleTest.run()
```

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

- [ ] New module has `tests/unit/ModuleNameTest.res`
- [ ] Test is registered in `TestRunner.res`
- [ ] Happy paths are covered
- [ ] Edge cases (empty, null, zero) are covered
- [ ] Error paths (invalid input) are covered
- [ ] `npm test` passes locally
