# AGENTS.md

## Project Overview
A hybrid ReScript v12 + Rust virtual tour builder with React 19 frontend and Actix-web backend. Features a functional programming architecture with strict type safety, comprehensive testing, and automated development workflows.

## Tech Stack
- **Frontend**: ReScript v12, React 19, Tailwind CSS 4.1, Pannellum viewer
- **Backend**: Rust (Edition 2024), Actix-web
- **Build**: Rsbuild, PostCSS, Autoprefixer
- **Testing**: Vitest + custom ReScript test runner

## Development Commands

### Build & Development
```bash
# Full build (service worker + ReScript + frontend)
npm run build

# ReScript compilation only
npm run res:build

# Start all development servers (ReScript watcher + SW watcher + backend + frontend)
npm run dev:all

# ReScript watcher only
npm run res:watch
```

### Testing
```bash
# Run all tests (ReScript build + frontend + backend)
npm run test:all

# Frontend tests only
npm run test:frontend

# Interactive testing with watch mode
npm run test:watch

# Run individual test modules
node --import ./tests/node-setup.js tests/unit/ProjectManagerTest.bs.js
node --import ./tests/node-setup.js tests/unit/ViewerManagerTest.bs.js

# Backend tests only
cd backend && cargo test
```

### Code Quality
```bash
# Format all code (ReScript + Rust)
npm run format

# Lint (format + build check)
npm run lint

# ReScript build check
npm run res:build
```

## Architecture Principles

### Directory Structure
- **UI Components**: `/src/components/` (React components with hooks)
- **Business Logic**: `/src/systems/` (Pure functions, state management)
- **State Management**: Centralized store with Actions/Reducers pattern
- **Tests**: `/tests/unit/` (Mirrors src structure)
- **Backend**: `/backend/src/` (API, services, middleware, models)

### Functional Programming Tenets
- Pure functions in systems layer
- Immutable state with explicit updates
- Result/Option types for error handling
- No side effects in business logic
- Structured logging over console.log

## Code Style Guidelines

### ReScript Code Style
```rescript
// External bindings with proper typing
@val external userAgent: string = "userAgent"
@send external getContext: (Dom.element, string) => Nullable.t<t> = "getContext"

// Functional error handling (NEVER throw)
let result = validateProjectStructure(data)
switch result {
| Ok(data) => processData(data)
| Error(msg) => Logger.error(~module_="ProjectManager", ~message=msg, ())
}

// React components with hooks
@react.component
let make = () => {
  let state = AppContext.useAppState()
  React.useEffect0(() => {
    // initialization logic
    Some(() => /* cleanup */)
  })
}

// Type definitions
type project = {
  id: string,
  name: string,
  scenes: array<scene>,
}
```

### Naming Conventions
- **Files**: PascalCase (ViewerManager.res, ProjectManager.res)
- **Modules**: PascalCase
- **Functions/Variables**: camelCase
- **Types**: PascalCase
- **Constants**: UPPER_SNAKE_CASE
- **Rust**: snake_case for functions/variables, PascalCase for types/traits

### Import Organization
```rescript
// Standard library first
module Log = Belt.Printf

// External libraries
@module("@pannellum/pannellum") external loadPannellum: unit => promise<t> = "default"

// Internal modules (grouped by directory)
module ProjectManager = Systems.ProjectManager
module ViewerComponent = Components.ViewerManager
```

### Error Handling
- **ReScript**: Use `Result.t<a, string>` or `Option.t<a>` types
- **Rust**: Use `Result<T, AppError>` enum
- **Pattern match** on all Results/Options
- **Structured logging** with module names: `Logger.error(~module_="ModuleName", ~message=msg, ())`
- **Forbidden**: console.log, alerts, exceptions in business logic

### React Component Rules
- Use functional components with `@react.component`
- Hooks for state and side effects
- Props interfaces with clear typing
- No class components
- Propagation of state via context, not prop drilling

## Testing Guidelines

### Test Structure
```rescript
// File: tests/unit/ProjectManagerTest.res
let run = () => {
  Console.log("Running ProjectManager tests...")
  
  // Test setup
  let testProject = ProjectManager.create("test-project")
  
  // Test assertions (Console.log based)
  switch ProjectManager.addScene(testProject, sceneData) {
  | Ok(updatedProject) => Console.log("✓ Scene addition test passed")
  | Error(_) => Console.log("✗ Scene addition test failed")
  }
  
  Console.log("ProjectManager tests completed.")
}
```

### Test Organization
- Each module has corresponding test file
- Tests use Console.log for assertions
- TestRunner orchestrates all tests
- Backend uses Rust's built-in test framework
- Integration tests for API endpoints

### Coverage Requirements
- All public functions must have tests
- Error paths must be tested
- React components need integration tests
- API endpoints need full coverage

## Critical Development Rules

### Absolutely Forbidden
- **No console.log** - Use Logger module instead
- **No innerHTML** - Use textContent for security
- **No alerts** - Use proper UI feedback
- **No exceptions** - Use Result types
- **No unwrap()** in production Rust code

### Required Standards
- **ReScript v12** only (no older versions)
- **Version everything** - All artifacts must be versioned
- **Stability first** - No breaking changes without proper migration
- **Functional patterns** over imperative code
- **Type safety** - All external bindings must be typed

### Workflow Requirements
- All code must compile before commits
- Tests must pass before pushes
- Format must be applied
- Automated workflows handle version bumping
- Shadow branch creates snapshots on save

## Backend Specific Rules

### Rust Patterns
```rust
// Error handling with Result types
pub fn process_request(data: RequestData) -> Result<ResponseData, AppError> {
    validate_request(data)
        .and_then(|validated| process_validated(validated))
        .map_err(|e| AppError::ValidationError(e.to_string()))
}

// Service layer pattern
impl TourService {
    pub async fn create_tour(&self, request: CreateTourRequest) -> Result<Tour, ServiceError> {
        // Business logic here
    }
}
```

### API Standards
- RESTful endpoints with proper HTTP methods
- Structured error responses
- Request/response validation
- Middleware for logging, auth, CORS
- OpenAPI documentation

## Development Workflow
1. Use `dev:all` for full-stack development
2. Run `lint` before commits
3. Run `test:all` before pushes
4. Automated workflows handle versioning
5. Shadow branch provides live snapshots
6. Use structured logging for debugging

## Configuration Files
- **ReScript**: `rescript.json` - ES6 modules, JSX v4, strict warnings
- **Build**: `rsbuild.config.mjs` - React plugin, dev proxy to backend
- **Testing**: `vitest.config.mjs` - jsdom environment, test patterns
- **Styling**: `tailwind.config.js` - custom palette, Inter/Outfit fonts