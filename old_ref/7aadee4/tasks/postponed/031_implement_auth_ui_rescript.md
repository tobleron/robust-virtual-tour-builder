# Task 031: Implement Authentication UI & Client-side Integration

**Priority**: High
**Effort**: Medium (8-10 hours)
**Impact**: High
**Category**: Frontend / UI

## Objective

Create a professional login, signup, and password recovery flow in the ReScript frontend using the Supabase Auth SDK.

## Requirements

### 1. ReScript Bindings for Supabase
Create `src/lib/Supabase.res` with bindings for:
- `createClient`
- `auth.signInWithPassword`
- `auth.signUp`
- `auth.signOut`
- `auth.onAuthStateChange`

### 2. Auth Components
Create the following UI components in `src/components/auth/`:
- `LoginView.res`: Email/Password login.
- `SignUpView.res`: New user registration.
- `AuthModal.res`: A premium glassmorphism modal for auth triggers.
- `UserMenu.res`: Navbar component showing avatar or "Login" button.

### 3. Auth Context
Integrate auth state into `src/core/AppContext.res`:
- Track `currentUser: option<user>`.
- Handle session persistence and auto-login on refresh.

## Implementation Steps

### Phase 1: SDK Integration
- Install `@supabase/supabase-js`.
- Implement basic bindings and verify connection.

### Phase 2: UI Development
- Build the `LoginView` using the project's design tokens (`--primary`, `--accent`, etc.).
- Ensure responsive design and mobile-friendly inputs.
- Implement error handling (e.g., "Invalid credentials").

### Phase 3: Protected Routes/Actions
- Prevent "Save to Cloud" or "My Projects" access unless authenticated.
- Redirect unauthenticated users to Login when trying to perform project-level actions.

## Success Criteria

- [ ] User can sign up with email/password.
- [ ] User can log in and session persists across refresh.
- [ ] UI matches the "Premium" design system defined in `DESIGN_SYSTEM.md`.
- [ ] Logout correctly clears local state and Supabase session.
