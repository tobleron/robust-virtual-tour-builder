# Task 123: Add GitHub Actions CI Pipeline

## Priority: MEDIUM (High if adding collaborators)

## Context
While the project has robust local testing enforced by `commit.sh`, there is no secondary verification layer in the cloud. A GitHub Actions CI pipeline provides "clean room" verification, ensuring that the codebase builds and tests pass on a fresh environment without local artifacts or configurations.

## Objective
Implement a GitHub Actions CI pipeline that automatically runs the full test suite on every push and pull request.

## Acceptance Criteria
- [ ] Create `.github/workflows/ci.yml` with a multi-step build/test pipeline
- [ ] Pipeline must run on `ubuntu-latest`
- [ ] Pipeline must install Node.js (v20+) and Rust (stable)
- [ ] Pipeline must cache `npm` and `cargo` dependencies for speed
- [ ] Pipeline must run `npm test` successfully
- [ ] Pipeline must report failure if any test fails or build fails
- [ ] README.md updated with a CI status badge (optional but recommended)

## Implementation Details

### GitHub Actions Workflow (`.github/workflows/ci.yml`)

```yaml
name: CI

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main, dev ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Setup Rust
        uses: actions-rust-lang/setup-rust-toolchain@v1
        with:
          toolchain: stable
          cache: true

      - name: Install Dependencies
        run: npm ci

      - name: Build ReScript
        run: npm run res:build

      - name: Run Frontend Tests
        run: npm run test:frontend

      - name: Run Backend Tests
        run: |
          cd backend
          cargo test --release

      - name: Check Formatting
        run: npm run format # Optional: ensure code style is maintained
```

## Security Considerations
- The pipeline runs in a sandbox.
- Ensure no secrets (like API keys) are needed for tests. If they are, use GitHub Secrets.
- Currently, tests appear to be unit tests not requiring external credentials.

## Verification
1. Push the new workflow file to GitHub.
2. Navigate to the "Actions" tab in your repository.
3. Verify that a "CI" workflow starts automatically.
4. Ensure all steps turn green ✅.
5. Intentionally break a test locally, push (if not using commit.sh which would block it), and verify the CI fails ❌.

## Estimated Effort
2-4 hours (including debugging any environment-specific test failures)
