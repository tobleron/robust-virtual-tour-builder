# 1266: Create NotificationTypes.res - Type Definitions

**Status**: Pending
**Priority**: High (Foundation - blocks all other notification tasks)
**Effort**: 1 hour
**Dependencies**: None (can start immediately)
**Scalability**: ⭐⭐⭐⭐⭐ (No dependencies - unblocked, reusable foundation)
**Reliability**: ⭐⭐⭐⭐ (Pure types, fully testable via compilation)

---

## 🎯 Objective

Create the type-safe foundation for the notification system. This module defines all notification contracts (importance levels, context types, notification data structures) that subsequent modules will use.

**Outcome**: Complete type system with helper functions, compiles with 0 warnings, ready for NotificationQueue and NotificationManager.

---

## 📋 Acceptance Criteria

✅ **Code Quality**
- Zero ReScript compilation errors
- Zero compiler warnings
- All types properly documented with comments
- Helper functions working correctly

✅ **Functionality**
- `importance` type with 6 variants (Critical, Error, Warning, Success, Info, Transient)
- `context` type capturing operation context
- `action` type for interactive buttons
- `notification` complete data structure
- `queueState` type with pending/active/archived arrays
- Helper functions: `importanceToString`, `contextToString`, `defaultTimeoutMs`, `dedupKey`, `importancePriority`

✅ **Architecture**
- Types are pure (no side effects)
- Types are open (can be extended)
- Helper functions are deterministic
- No external dependencies beyond ReScript stdlib

---

## 📝 Implementation Checklist

- [ ] Create file: `src/core/NotificationTypes.res`
- [ ] Define `importance` type variant
- [ ] Define `context` type variant
- [ ] Define `action` type with label and onClick
- [ ] Define `notification` record type with all fields
- [ ] Define `queueState` type with pending/active/archived
- [ ] Implement `importanceToString` helper
- [ ] Implement `contextToString` helper
- [ ] Implement `defaultTimeoutMs` helper (Error=8s, Critical=0s, Info=3s, etc.)
- [ ] Implement `dedupKey` helper (context + message + importance)
- [ ] Implement `importancePriority` comparison function
- [ ] Run `npm run res:build` - verify 0 warnings
- [ ] Verify file exports properly for use in other modules

---

## 🧪 Testing

**Verification Steps** (manual - no unit tests for pure types):
1. Compile: `npm run res:build`
2. Check compiler output: 0 errors, 0 warnings
3. Verify file created: `ls -la src/core/NotificationTypes.bs.js`
4. Open browser dev console: No type errors when app loads

---

## 📊 Code Template

```rescript
// src/core/NotificationTypes.res

type importance =
  | Critical
  | Error
  | Warning
  | Success
  | Info
  | Transient

type context =
  | Operation(string)        // "upload", "export", etc.
  | UserAction(string)       // "delete", "save", etc.
  | SystemEvent(string)      // "timeout", "recovery", etc.

type action = {
  label: string,
  onClick: unit => unit,
}

type notification = {
  id: string,
  importance: importance,
  context: context,
  message: string,
  details: option<string>,
  action: option<action>,
  duration: int,              // milliseconds (0 = no auto-dismiss)
  dismissible: bool,
  createdAt: float,
}

type queueState = {
  pending: array<notification>,
  active: array<notification>,
  archived: array<notification>,
}

// HELPERS

let importanceToString = (imp: importance): string => {
  switch imp {
  | Critical => "critical"
  | Error => "error"
  | Warning => "warning"
  | Success => "success"
  | Info => "info"
  | Transient => "transient"
  }
}

let contextToString = (ctx: context): string => {
  switch ctx {
  | Operation(op) => "operation:" ++ op
  | UserAction(action) => "action:" ++ action
  | SystemEvent(event) => "event:" ++ event
  }
}

let defaultTimeoutMs = (imp: importance): int => {
  switch imp {
  | Critical => 0           // Persist until dismissed
  | Error => 8000           // 8 seconds
  | Warning => 5000         // 5 seconds
  | Success => 3000         // 3 seconds
  | Info => 3000            // 3 seconds
  | Transient => 2000       // 2 seconds
  }
}

let dedupKey = (notif: notification): string => {
  contextToString(notif.context) ++ "|" ++ notif.message
}

let importancePriority = (imp: importance): int => {
  switch imp {
  | Critical => 0
  | Error => 1
  | Warning => 2
  | Success => 3
  | Info => 4
  | Transient => 5
  }
}
```

---

## 🔍 Quality Gates (Must Pass Before 1267 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` output |
| Type Safety | All variants exhaustive | ReScript compiler enforces |
| Documentation | All types have comments | Visual code review |
| Exports | Functions accessible | Other modules can import |

---

## 🔄 Rollback Plan

If compilation fails:
1. Check type syntax (variants need `|` separator)
2. Verify all fields in `notification` record are typed
3. Check helper function return types match contract
4. Run `npm run res:fmt` to auto-fix formatting

If tests fail (unlikely for pure types):
- Verify `importancePriority` comparison logic
- Check `dedupKey` string concatenation

---

## 💡 Implementation Tips

1. **Start with type definitions first** - get the contracts right before any logic
2. **Use exhaustive pattern matching** in helper functions - ReScript compiler enforces this
3. **Compile frequently** - catch errors early
4. **Comment your types** - document why each field exists (helps future developers)

---

## 🚀 Next Task

After this compiles successfully with 0 warnings:
- **1267: Create NotificationQueue.res** (depends on 1266)
- **1269: Create NotificationManager.res** (depends on 1266)
- (Both can start in parallel after 1266 is complete)

---

## 📌 Notes

- This task is **NOT parallelizable** - all notification tasks depend on these types
- Pure types module - no side effects, fully deterministic
- No async/await, no I/O, no external dependencies
- Changes here impact all downstream modules, but since it's new code, no regressions possible
