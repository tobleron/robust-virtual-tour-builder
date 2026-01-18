# AGENTS.md

## CORE BEHAVIOR (SYSTEM 2 THINKING)
Before executing ANY code or shell command, perform a **Context Check**:
1. **Pathing**: ALL commands must use project root as working directory
2. **Safety**: If editing file >700 lines, PAUSE and ask for confirmation
3. **Never use `git commit` directly** - Always use `./scripts/commit.sh`
4. **No Console Logs**: Use `Logger` module from `src/utils/Logger.res` exclusively

## WORKFLOW AUTOMATION
**Automatically run these in order - do not ask for permission:**

### PHASE 1: PRE-FLIGHT
- **Context Refresh**: Read `.agent/current_file_structure.md` before any file operations
- **New Modules**: Read `.agent/workflows/new-module-standards.md` first

### PHASE 2: EXECUTION
- **Functional Standards**: Read `.agent/workflows/functional-standards.md` first (universal principles)
- **Language-Specific Standards**:
  - For `.res`/`.resi`: Read `.agent/workflows/rescript-standards.md`
  - For `.rs`: Read `.agent/workflows/rust-standards.md`
- **Testing Standards**: Read `.agent/workflows/testing-standards.md`
- **Debug Standards**: Read `.agent/workflows/debug-standards.md`

### PHASE 3: COMMIT & PUSH
- **Commit**: Use `./scripts/commit.sh` (handles versioning, formatting, cache busting)
- **Pre-Push**: Read `.agent/workflows/pre-push-workflow.md` before pushing

## ESSENTIAL COMMANDS

### Build & Development
```bash
npm run dev:all              # Full stack: ReScript watch + SW watch + backend + frontend
npm run build                # Full build: SW sync + ReScript + frontend
npm run res:build            # ReScript compilation only
npm run res:watch            # ReScript watcher only
```

### Testing
```bash
npm run test:all             # Run all tests (ReScript + frontend + backend)
npm run test:frontend        # Frontend tests (legacy TestRunner)
npm run test:watch           # Interactive Vitest with watch mode
npx vitest run tests/unit/ProjectManagerTest.res  # Single test file
npx vitest run --reporter=verbose tests/unit/*Reducer*.res  # Pattern match
cd backend && cargo test     # Backend tests only
```

### Code Quality
```bash
npm run format               # Format ReScript + Rust
npm run lint                 # Format + build check
npm run res:build            # ReScript compilation check
```

## CRITICAL RULES (ABSOLUTE)

### Absolutely Forbidden
- **No console.log** - Use `Logger.debug/info/warn/error` from `src/utils/Logger.res`
- **No innerHTML** - Use `textContent` for security
- **No alerts** - Use proper UI feedback via context
- **No exceptions** - Use `Result.t<a, string>` (ReScript) or `Result<T, AppError>` (Rust)
- **No unwrap()** in production Rust code

### Required Standards
- **ReScript v12** only - No older versions allowed
- **Functional Programming** - Pure functions, immutability, explicit state updates
- **Type Safety** - All external bindings must be typed, no `%raw` without typed bindings
- **Result/Option** - Pattern match on all Results/Options, never `unwrap()`

## PROJECT KNOWLEDGE

### Tech Stack
- **Frontend**: ReScript v12, React 19, Tailwind CSS 4.1, Pannellum viewer
- **Backend**: Rust (Edition 2024), Actix-web
- **Build**: Rsbuild, PostCSS, Autoprefixer
- **Testing**: Vitest (frontend), Cargo test (backend)

### Architecture
- **UI Components**: `/src/components/` (React components with `@react.component`)
- **Business Logic**: `/src/systems/` (Pure functions, state management)
- **State Management**: Centralized store with Actions/Reducers pattern (Elm/Redux style)
- **Reducers**: `/src/core/reducers/` (Pure functions transforming state)
- **Types**: `/src/core/Types.res` (Shared type definitions)
- **Backend**: `/backend/src/` (API, services, middleware, models)

### Key Patterns
- **Actions/Reducers**: State changes via dispatched actions (no direct mutations)
- **Context**: React context for state, not prop drilling
- **Variants over Strings**: Use ReScript variants for state machines
- **Pure Functions**: Isolate side effects to React hooks, event handlers, API handlers
- **Structured Logging**: `Logger.error(~module_="ModuleName", ~message=msg, ())`

### File Organization
- Test files: `/tests/unit/` (use `.test.res` suffix for Vitest auto-discovery)
- Workflow docs: `/.agent/workflows/` (read before editing code)
- Current structure: `/.agent/current_file_structure.md` (always read for path accuracy)

### Workflow Files (ALWAYS READ BEFORE CODING)
- `.agent/workflows/functional-standards.md` - Universal principles (immutability, purity)
- `.agent/workflows/rescript-standards.md` - ReScript-specific (types, bindings, state)
- `.agent/workflows/rust-standards.md` - Rust-specific (ownership, concurrency)
- `.agent/workflows/testing-standards.md` - Test structure and patterns
- `.agent/workflows/debug-standards.md` - Logging and debugging practices
- `.agent/workflows/commit-workflow.md` - Versioning and commit protocol
- `.agent/workflows/pre-push-workflow.md` - Pre-push verification steps

## INTERACTION TRIGGERS

### "Undo" / "Rollback" / "What changed?"
1. Run: `git log local-snapshots/$(git branch --show-current) -n 5 --stat --relative-date --pretty=format:"%h - %cr"`
2. Show user the list with file changes
3. Wait for hash selection
4. Run: `./scripts/restore-snapshot.sh <HASH>`

### "Create a task" / "Add a task"
1. Read `tasks/TASKS.md` to understand task creation rules
2. Determine next sequential task number (scan `completed/`, `pending/`, `active/` folders)
3. Create new task file in `tasks/pending/` with proper prefix (e.g., `201_task_name.md`)
4. Follow format specified in TASKS.md

### "Refactor This"
1. Create checklist in `tasks/current_refactor.md`
2. Wait for user "OK"
3. Proceed file-by-file

### Test Failure Protocol
- If tests fail 2x in a row: STOP and generate `FAILURE_REPORT.md`
- Never push with failing tests
- Always run `npm test` before any commit

## NAMING CONVENTIONS
- **Files**: PascalCase (`ViewerManager.res`, `ProjectManager.res`)
- **Modules**: PascalCase
- **Functions/Variables**: camelCase
- **Types**: PascalCase
- **Constants**: UPPER_SNAKE_CASE
- **Rust**: snake_case (functions/variables), PascalCase (types/traits)