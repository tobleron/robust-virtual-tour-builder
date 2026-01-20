# Build Verification Enhancement - Quick Reference

## 🎯 The Rule

### Normal Requests (Most Common)
**Example:** "Fix the CSS", "Update the animation", "Refactor this component"

✅ **DO:**
- Execute the request directly
- Make code changes
- Rely on `npm run dev` for live compilation

❌ **DON'T:**
- Create task files
- Run `npm run build`

---

### Formal Tasks (Explicit Only)
**Example:** "Create a task to...", "Work on task 288", "/create-task ..."

✅ **DO:**
- Follow `tasks/TASKS.md` workflow
- Run `npm run build` before completion
- Create task reports
- Move through task lifecycle (pending → active → completed)

---

## 📊 Workflow Comparison

```
┌─────────────────────────────────────────────────────────────┐
│                     NORMAL REQUEST                          │
│  "Fix the shine animation"                                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  Read relevant files  │
              └───────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Make code changes   │
              └───────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  ✅ DONE (dev runs)  │
              └───────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                     FORMAL TASK                             │
│  "Work on task 288"                                         │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │ Move to active folder │
              └───────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Read & implement    │
              └───────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  Run npm run build    │
              └───────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Create _REPORT      │
              └───────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │ Move to completed/    │
              └───────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │      ✅ DONE          │
              └───────────────────────┘
```

## ⚡ Performance Impact

| Metric | Normal Request | Formal Task |
|--------|----------------|-------------|
| **Task file creation** | ❌ No | ✅ Yes |
| **Build verification** | ❌ No | ✅ Yes |
| **Time saved** | ~30-60 sec | N/A |
| **Tokens saved** | ~500-1000 | N/A |
| **Dev experience** | Fast & smooth | Thorough & validated |

## 🔑 Key Files Updated

1. **`GEMINI.md`** - Build verification rules
2. **`tasks/TASKS.md`** - Added build step to workflow
3. **`.agent/workflows/create-task.md`** - Build note added

## 💡 Remember

- **`npm run dev`** is always running in background → provides live compilation
- **`npm run build`** is only needed for formal task validation
- This saves time AND tokens for everyday development work
