# Task 75: Fix Critical index.html Bugs

## Priority: 🔴 CRITICAL

## Context
The project analysis revealed two critical issues in `index.html` that affect application startup and security.

## Issues to Fix

### Issue 1: Duplicate Script Tag and Extra Body
**Location**: `index.html` lines 113-122

**Current (Broken):**
```html
  <script type="module" src="src/Main.bs.js?v=4.2.39"></script>
</body>

<!-- LIBRARIES -->
<!-- <script src="src/libs/gif.js"></script> -->
<!-- <script src="src/libs/ffmpeg.js"></script> -->
<!-- <script src="src/libs/ffmpeg-util.js"></script> -->

<script type="module" src="src/Main.bs.js?v=4.2.39"></script>
</body>

</html>
```

**Expected (Fixed):**
```html
  <script type="module" src="src/Main.bs.js?v=4.2.39"></script>

  <!-- LIBRARIES (currently unused) -->
  <!-- <script src="src/libs/gif.js"></script> -->
  <!-- <script src="src/libs/ffmpeg.js"></script> -->
  <!-- <script src="src/libs/ffmpeg-util.js"></script> -->
</body>

</html>
```

**Impact**: The main application script loads twice, potentially causing double-initialization, duplicate event handlers, and state corruption.

---

### Issue 2: Malformed CSP Header
**Location**: `index.html` line 9

**Current (Broken):**
```html
<meta http-equiv=4.2.39"Content-Security-Policy" content="...">
```

**Expected (Fixed):**
```html
<meta http-equiv="Content-Security-Policy" content="...">
```

**Impact**: Content Security Policy is not being applied, leaving the application vulnerable to XSS attacks.

---

## Acceptance Criteria
- [ ] Only ONE `<script type="module" src="src/Main.bs.js">` tag exists
- [ ] Only ONE `</body>` closing tag exists
- [ ] CSP `http-equiv` attribute is properly quoted
- [ ] Application loads without console errors
- [ ] Manual verification that CSP is applied (check Network tab headers)

## Testing
1. Open browser DevTools → Console
2. Verify no duplicate module loading messages
3. Check Network tab → document → Response Headers for CSP

## Files Modified
- `index.html`
