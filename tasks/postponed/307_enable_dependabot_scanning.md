# Task 307: Enable Dependabot for Dependency Scanning

**Priority**: Low  
**Effort**: Low (30 minutes)  
**Impact**: Medium  
**Category**: Security / Maintenance

## Objective

Enable GitHub Dependabot to automatically scan for vulnerable dependencies and create pull requests for security updates.

## Current Status

**Security Coverage**: 95%  
**What's Implemented**:
- ✅ OWASP Top 10 addressed
- ✅ Input sanitization
- ✅ CSP, XSS prevention
- ✅ Rate limiting

**Gap**:
- ⚠️ No automated dependency vulnerability scanning
- ⚠️ Manual `npm audit` required

## Why Dependabot?

- Automated security updates
- Monitors npm and cargo dependencies
- Creates PRs for vulnerable packages
- Configurable update frequency
- Free for public and private repos

## Implementation Steps

### Phase 1: Create Dependabot Config (15 minutes)

Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  # Frontend dependencies (npm)
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    reviewers:
      - "tobleron"  # Replace with actual GitHub username
    labels:
      - "dependencies"
      - "security"
    commit-message:
      prefix: "chore(deps)"
      include: "scope"
    # Group non-security updates
    groups:
      development-dependencies:
        dependency-type: "development"
        update-types:
          - "minor"
          - "patch"

  # Backend dependencies (Cargo)
  - package-ecosystem: "cargo"
    directory: "/backend"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    reviewers:
      - "tobleron"  # Replace with actual GitHub username
    labels:
      - "dependencies"
      - "rust"
      - "security"
    commit-message:
      prefix: "chore(deps)"
      include: "scope"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
    labels:
      - "dependencies"
      - "github-actions"
```

### Phase 2: Configure Security Alerts (5 minutes)

1. Go to GitHub repo settings
2. Navigate to "Security & analysis"
3. Enable:
   - ✅ Dependency graph
   - ✅ Dependabot alerts
   - ✅ Dependabot security updates
   - ✅ Dependabot version updates

### Phase 3: Review Initial Alerts (10 minutes)

1. Check "Security" tab on GitHub
2. Review any existing vulnerabilities
3. Prioritize critical/high severity issues
4. Merge Dependabot PRs or update manually

## Verification

1. Dependabot config file created
2. Security features enabled on GitHub
3. Initial scan completed
4. No critical vulnerabilities (or PRs created)
5. Weekly updates scheduled

## Success Criteria

- [ ] `.github/dependabot.yml` created
- [ ] Dependabot alerts enabled on GitHub
- [ ] Dependabot security updates enabled
- [ ] Dependabot version updates enabled
- [ ] Initial vulnerability scan completed
- [ ] Critical vulnerabilities addressed (if any)
- [ ] Weekly update schedule configured
- [ ] PR labels configured

## Expected Behavior

### Security Updates (Immediate):
- Dependabot creates PR when vulnerability found
- PR includes:
  - Vulnerability description
  - Severity level
  - Recommended version
  - Changelog link

### Version Updates (Weekly):
- Dependabot checks for new versions every Monday
- Creates PRs for:
  - npm packages
  - Cargo crates
  - GitHub Actions
- Groups minor/patch updates to reduce PR noise

## Maintenance

### Weekly:
1. Review Dependabot PRs
2. Run tests on PR branch
3. Merge if tests pass
4. Close if incompatible (document reason)

### Monthly:
1. Review dependency health
2. Check for deprecated packages
3. Plan major version upgrades

## Benefits

- ✅ Automated security monitoring
- ✅ Proactive vulnerability patching
- ✅ Reduced manual audit effort
- ✅ Stay up-to-date with dependencies
- ✅ Improved security posture
- ✅ Compliance with security best practices

## Alternative Tools

If not using GitHub:
- **Snyk**: https://snyk.io/
- **npm audit**: Built-in, manual
- **cargo audit**: Built-in, manual
- **Renovate**: https://www.mend.io/renovate/

## Resources

- Dependabot Docs: https://docs.github.com/en/code-security/dependabot
- Configuration Options: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file
