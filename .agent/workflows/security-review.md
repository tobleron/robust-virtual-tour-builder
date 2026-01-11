---
description: Quick security review checklist for commits
---

# Security Review Workflow

Run this when changes involve user input, file handling, or external interactions.

## 1. Input Validation

**Check if changes handle user input**:
- Scene names
- Link labels
- File uploads
- URL parameters
- Form inputs

**Requirements**:
- [ ] All user inputs are sanitized
- [ ] No direct DOM insertion with `innerHTML` (use `textContent` or sanitize)
- [ ] Input length limits enforced
- [ ] Special characters properly escaped

**Example Issues**:
```javascript
// ❌ BAD
element.innerHTML = userInput;

// ✅ GOOD
element.textContent = userInput;
// OR
element.innerHTML = DOMPurify.sanitize(userInput);
```

## 2. File Upload Security

**If changes involve file uploads**:
- [ ] MIME type validation on backend
- [ ] File size limits enforced (check against constants)
- [ ] EXIF data sanitized if applicable
- [ ] Malicious filename handling (e.g., `../../etc/passwd`)

**Check**:
```javascript
// Verify MIME type checking exists
const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
if (!allowedTypes.includes(file.type)) { /* reject */ }
```

## 3. Blob URL Management

**If changes create/revoke blob URLs**:
- [ ] Centralized blob URL manager used (`BlobManager.js` or similar)
- [ ] Blob URLs revoked after use (prevent memory leaks)
- [ ] No dangling references to revoked URLs

**Check**:
```javascript
// Ensure cleanup happens
URL.revokeObjectURL(blobUrl);
```

## 4. Path Traversal Prevention

**If changes involve file paths or URLs**:
- [ ] User-provided paths are sanitized
- [ ] No `../` sequences allowed in filenames
- [ ] Paths validated against allowed directories

## 5. XSS Prevention

**If changes render dynamic content**:
- [ ] No `eval()` or `Function()` constructor with user data
- [ ] No `dangerouslySetInnerHTML` equivalent
- [ ] Event handlers don't use user-controlled strings

## 6. Authentication & Authorization

**If changes involve backend API calls**:
- [ ] Authentication tokens handled securely
- [ ] No credentials in client-side code
- [ ] API endpoints validate permissions

## 7. Error Handling

**Check error messages don't leak sensitive info**:
- [ ] Stack traces not exposed to users
- [ ] Error messages use generic language
- [ ] Detailed errors logged server-side only

**Example**:
```javascript
// ❌ BAD
showToast(`Error: ${error.stack}`, 'error');

// ✅ GOOD
showToast('Upload failed. Please try again.', 'error');
Debug.error('Upload', error.message, { stack: error.stack });
```

## 8. Dependency Security

**If changes added new dependencies**:
- [ ] Package from trusted source (npm)
- [ ] Check for known vulnerabilities (`npm audit`)
- [ ] Review package permissions/access

Run:
```bash
npm audit
```

## 9. CSP Compliance

**If changes add external resources**:
- [ ] Inline scripts avoided (use external files)
- [ ] External resources from trusted CDNs
- [ ] Subresource Integrity (SRI) hashes added if applicable

## 10. Rate Limiting

**If changes involve API calls or heavy operations**:
- [ ] Debouncing/throttling implemented where needed
- [ ] Backend rate limiting enforced
- [ ] DOS prevention considered

---

## Quick Command Reference

```bash
# Check for potential XSS vectors
grep -r "innerHTML" src/

# Check for eval usage
grep -r "eval(" src/

# Check for unescaped user input
grep -r "textContent" src/ | grep -v "user"

# Run npm security audit
npm audit

# Check for hardcoded secrets (basic check)
grep -rE "(password|secret|token|api_key).*=.*['\"][^'\"]{8,}" src/
```

---

## AI Agent Reminder Protocol

If issues found:
1. **Estimate fix time**: If < 15 minutes, proactively suggest fixes
2. **Explain risk**: Clearly state security implication
3. **Provide solution**: Offer concrete code fix
4. **User decision**: Let user decide to implement now or defer

**Example Message**:
> ⚠️ **Security Notice**: The current change uses `innerHTML` with user input on line 42 of `ViewerUI.js`, which could allow XSS attacks. 
> 
> **Recommended fix** (2 min):
> ```javascript
> element.textContent = userInput; // Safe alternative
> ```
> 
> Should I apply this fix now?

---

**Note**: This is not a comprehensive security audit. For production deployments, consider professional penetration testing.
