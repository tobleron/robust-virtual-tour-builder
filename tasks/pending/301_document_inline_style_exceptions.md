# Task 301: Document Inline Style Exceptions

**Priority**: Low  
**Effort**: Low (15 minutes)  
**Impact**: Low  
**Category**: Code Quality / Documentation

## Objective

Add documentation comments to inline style usage in components to clarify that these are valid exceptions according to CSS Architecture standards, preventing future confusion.

## Current Inline Styles

### Files with makeStyle:
1. **`src/components/SceneList.res`** - 4 instances
   - Line 116: Progress bar width (dynamic 0-100%)
   - Lines 364, 398, 440: Background images from dynamic URLs

2. **`src/components/Sidebar.res`** - 1 instance
   - Line 486: Progress percentage (dynamic 0-100%)

## Standard Reference

**Reference**: `CSS_ARCHITECTURE_AND_BEST_PRACTICES.md` §3  
> "Inline styles are permitted ONLY when the value is:
> 1. Truly Dynamic/Continuous: Values that change every frame or depend on arbitrary user input
> 2. External Image URLs: Background images sourced from API data"

## Analysis

All current inline styles are **valid exceptions**:
- ✅ Progress bars: Continuous 0-100% values
- ✅ Background images: Dynamic URLs from API

## Implementation Steps

1. **SceneList.res** - Add comments above each makeStyle:
   ```rescript
   // EXCEPTION: Dynamic progress percentage (CSS_ARCHITECTURE.md §3.1)
   // Value changes continuously 0-100% based on quality score
   style={makeStyle({"width": Float.toString(qualityScore * 10.0) ++ "%"})}
   ```

2. **SceneList.res** - For background images:
   ```rescript
   // EXCEPTION: Dynamic background image URL (CSS_ARCHITECTURE.md §3.2)
   // Image source comes from API data, not static asset
   style={makeStyle({"backgroundImage": `url(${imageUrl})`})}
   ```

3. **Sidebar.res** - Add comment:
   ```rescript
   // EXCEPTION: Dynamic progress percentage (CSS_ARCHITECTURE.md §3.1)
   // Value updates continuously during upload/processing
   style={makeStyle({"width": Float.toFixed(procState["progress"], ~digits=0) ++ "%"})}
   ```

## Verification

1. Review each comment for clarity
2. Ensure references to CSS_ARCHITECTURE.md are correct
3. Run build: `npm run build`

## Success Criteria

- [ ] All 5 inline style usages have explanatory comments
- [ ] Comments reference CSS_ARCHITECTURE.md sections
- [ ] Comments explain WHY the exception is valid
- [ ] Build passes without errors

## Benefits

- ✅ Code clarity for future developers
- ✅ Prevents confusion about CSS architecture violations
- ✅ Documents intentional design decisions
- ✅ Easier code reviews
