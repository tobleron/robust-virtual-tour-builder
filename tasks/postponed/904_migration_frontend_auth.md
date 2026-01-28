# Migration Phase 4: Frontend Auth, Legal & i18n Integration

**Goal**: Implement the user-facing side of the authentication system in ReScript, including state management, legal compliance, and internationalization support.

## 📋 Requirements
1. **Auth Context**: A central React Context to track `user`, `token`, and `isAuthenticated` state.
2. **Unified Fetch**: A wrapper around the `Fetch` API that automatically injects the `Authorization: Bearer <token>` header.
3. **UI Components**: Modern Login and Registration forms styled with the existing design system.
4. **Legal Compliance**: Integrate Privacy Policy and Terms of Service into the registration flow.
5. **i18n Infrastructure**: Implement internationalization support for UI text.

## 🛠️ Implementation Steps
1. **Auth State Management**:
   - Create `src/core/AuthContext.res`.
   - Implement `useAuth()` hook.
   - Persist JWT to `localStorage` or a secure cookie.
2. **Secure API Client**:
   - Create `src/systems/api/AuthenticatedClient.res`.
   - Implement a `request` function that handles token injection and `401` auto-logout logic.
3. **Legal Documentation**:
   - Create `docs/PRIVACY_POLICY.md` and `docs/TERMS_OF_SERVICE.md`.
   - Decide on a LICENSE (MIT/Proprietary) and add to root.
   - Add "I agree to the Terms" checkbox to `RegisterForm.res`.
4. **Internationalization (i18n)**:
   - Create `src/i18n/I18n.res` and initial locale files (`en.json`, `es.json`).
   - Extract hardcoded strings from auth forms into translation keys.
   - Implement a language switcher in the user settings.
5. **Authentication UI**:
   - Create `src/components/auth/LoginForm.res` and `RegisterForm.res`.
   - Use `rescript-schema` to validate form inputs.
   - Integrate with `NotificationContext` for success/error feedback.

## ✅ Success Criteria
- User can sign up (agreeing to terms) and log in.
- The sidebar shows the user's name and an "Avatar/Logout" button.
- UI text successfully switches between at least two languages.
- API calls fail gracefully with a notification if the session expires.