# Fix All Security Issues (innerHTML / dangerouslySetInnerHTML)

## Objective
Remove XSS vulnerabilities by replacing all unsafe HTML content insertion methods with safe DOM manipulation or proper sanitization.

## Technical Details
**Total Instances: 2** across 2 files:

1. **TourTemplateScripts.res** - 2 instances (lines 20, 33)
   - Direct `innerHTML` assignment in export templates
   - Context: Rendering SVG content for tour export
   - Risk: XSS if user-controlled content reaches export templates

2. **ModalContext.res** - 1 instance (line 188)
   - `dangerouslySetInnerHTML={"__html": html}`
   - Context: Rendering modal content from config
   - Risk: XSS if HTML content contains malicious scripts

## Implementation

### Phase 1: TourTemplateScripts.res (lines 20, 33)

**Current Issue:**
```rescript
hotSpotDiv.innerHTML = `...SVG content...`
```

**Options:**
- **Option A**: Create DOM nodes via ReScript DOM bindings
  - Safest, most maintainable
  - Requires refactoring template system to build DOM programmatically

- **Option B**: Sanitize HTML before insertion
  - Use DOMPurify library or similar
  - Preserve current template structure
  - Add sanitization step

- **Option C**: Use React's createElement approach
  - Build SVG via JSX
  - Type-safe, no escaping needed

**Recommended: Option A or C** for long-term safety

### Phase 2: ModalContext.res (line 188)

**Current Issue:**
```rescript
<div dangerouslySetInnerHTML={"__html": html} />
```

**Analysis Required:**
1. Identify source of `html` content
2. Determine if user-generated or static/controlled
3. Assess if structured content is feasible

**Options:**
- **Option A**: Convert HTML to structured ReScript JSX
  - Most secure, but requires refactoring all modal configs
  - Check if modal content types are limited

- **Option B**: Sanitize with DOMPurify
  - Quick fix, maintains flexibility
  - Add sanitization before rendering

- **Option C**: Use React's innerHTML with sanitization wrapper
  - Balanced approach

**Recommended: Start with Option B, plan for Option A**

### Phase 3: Testing
For each file after changes:
1. Test export functionality with various scene configurations
2. Test modal rendering with different content types
3. Verify no XSS injection possible
4. Test with malicious content attempts

## Implementation Steps

### Step 1: TourTemplateScripts
1. Read current implementation
2. Analyze SVG content being inserted
3. Choose approach (A, B, or C)
4. Implement replacement
5. Test export functionality

### Step 2: ModalContext
1. Read current implementation
2. Trace HTML content sources
3. Assess security risk (user-controlled vs static)
4. Implement sanitization or structured content
5. Test modal rendering

### Step 3: Security Audit
1. Verify no new HTML insertion methods added
2. Run security tests (if available)
3. Manual XSS testing
4. Document security measures

## Success Criteria
- **Zero** `innerHTML` assignments remain in codebase
- **Zero** `dangerouslySetInnerHTML` usages remain
- Export functionality works correctly with safe DOM methods
- Modal rendering works correctly with safe DOM methods
- XSS vulnerabilities mitigated
- All existing tests pass
- No functional regression

## Verification
After completion, run:
```bash
grep -r "innerHTML" src/ --include="*.res"
grep -r "dangerouslySetInnerHTML" src/ --include="*.res"
```
Expected result: No matches found (or only in comments/documentation)

## Additional Notes
- Consider adding linter rules to catch future unsafe HTML usage
- Document security best practices for team
- Consider adding DOMPurify dependency if sanitization approach chosen
