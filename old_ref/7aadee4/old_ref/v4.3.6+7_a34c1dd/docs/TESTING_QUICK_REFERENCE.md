# Testing Quick Reference Card

## 🚀 Running Tests

```bash
# Run all tests (frontend + backend)
npm test

# Frontend only
npm run test:frontend

# Backend only
cd backend && cargo test && cd ..

# Backend with output
cd backend && cargo test -- --nocapture && cd ..
```

---

## ✅ When Tests Run Automatically

1. **Every Commit** - via `./scripts/commit.sh`
2. **Pre-Push** - via `/pre-push-workflow`
3. **Manual** - via `npm test`

---

## 📝 Creating Tests

### Frontend (ReScript)

**1. Create test file:** `tests/unit/MyModuleTest.res`

```rescript
open MyModule

let run = () => {
  Console.log("Running MyModule tests...")
  
  // Test happy path
  assert(myFunction(input) == expected)
  Console.log("✓ myFunction works")
  
  // Test edge case
  assert(myFunction([]) == None)
  Console.log("✓ myFunction handles empty")
  
  Console.log("MyModule tests passed!")
}
```

**2. Register in runner:** `tests/TestRunner.res`

```rescript
MyModuleTest.run()
```

**3. Run:** `npm test`

---

### Backend (Rust)

**Add to bottom of source file:**

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

**Run:** `cargo test`

---

## 🎯 What to Test

| Priority | Type | Examples |
|----------|------|----------|
| **CRITICAL** | Pure logic | Math, transforms, parsing |
| **HIGH** | State changes | Reducer actions, transitions |
| **MEDIUM** | API parsing | JSON decode, error mapping |
| **LOW** | UI components | Visual layout, hover states |

---

## 🔧 Troubleshooting

### Tests fail on commit
```bash
# Run tests manually to see details
npm test

# Fix the failing tests
# Then commit again
./scripts/commit.sh "fix: ..."
```

### Backend tests fail
```bash
cd backend
cargo test -- --nocapture  # See full output
```

### Frontend tests fail
```bash
npm run test:frontend  # Run frontend only
```

---

## 📚 Full Documentation

- **Testing Standards:** `.agent/workflows/testing-standards.md`
- **Commit Workflow:** `.agent/workflows/commit-workflow.md`
- **New Module Standards:** `.agent/workflows/new-module-standards.md`
- **Integration Summary:** `docs/UNIT_TESTING_INTEGRATION.md`

---

## ✨ Current Status

- **Total Tests:** 40 (21 frontend + 19 backend)
- **Pass Rate:** 100%
- **Execution Time:** ~5 seconds
- **Last Run:** 2026-01-14 22:25
