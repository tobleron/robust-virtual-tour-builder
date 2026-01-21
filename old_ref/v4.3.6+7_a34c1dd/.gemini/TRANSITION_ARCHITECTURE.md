# Transition Architecture - Clean Rebuild Plan

## Current System (Dual Viewer Architecture)

### 5 Key Areas You Asked About:

#### 1. **Transition Mechanism**
- **Two Viewers**: YES, there are 2 Pannellum viewers (A and B)
- **Purpose**: Enable smooth cross-dissolve between scenes
- **How it works**: 
  - One viewer is "active" (visible, opacity 1)
  - One viewer is "inactive" (hidden, opacity 0)
  - When navigating, the inactive viewer loads the new scene
  - Once loaded, a CSS transition swaps their opacity

#### 2. **Cross-Dissolve**
- Controlled by CSS transition on `.viewer-container` with class `.active`
- Default duration: 450ms (defined in CSS)
- Triggered by swapping which viewer has the `.active` class

#### 3. **Timing**
- Current flow for simulation mode:
  1. User clicks link → `navigateToScene` called
  2. Signal to pre-load next scene at 80% pan progress
  3. At 80%, call `store.setActiveScene` → triggers viewer swap
  4. Cross-dissolve happens during swap

#### 4. **Autoforward**
- `handleAutoForward` is called in `performSwap` after scene loads
- Checks if scene has `isAutoForward` flag
- If true, immediately triggers `navigateToScene` to next link

#### 5. **Viewer Swap Flow**
```
Scene A (Viewer A active, Viewer B hidden)
  ↓
Click Link → Load Scene B into Viewer B (still hidden)
  ↓
Viewer B loaded → performSwap()
  ↓
Swap .active class (A → B)
  ↓
CSS cross-dissolve (450ms)
  ↓
Scene B (Viewer B active, Viewer A hidden)
  ↓
Destroy old Viewer A after 1000ms
```

## Problems Identified

1. **Over-complicated panning logic** in NavigationSystem.js
2. **Scope issues** with animation variables
3. **Conflicting animation sources** (manual loop vs viewer.lookAt)
4. **Arrow moving but no camera movement** - manual animation broke
5. **Auto-forward timing unclear** - when does it trigger relative to cross-dissolve?

## Clean Solution Proposal

### Simplify to 3 Clear Phases:

#### Phase 1: Manual Click (Scene A → B)
- User clicks in simulation mode
- Start panning animation on current viewer (A)
- At 80% progress: Pre-load Scene B into inactive viewer (B)
- At 80% progress: Trigger cross-dissolve swap
- Cross-dissolve completes → Scene B visible

#### Phase 2: Auto-Forward (Scene B → C)
- `handleAutoForward` called AFTER swap completes
- Check if Scene B has autoForward flag
- If yes, immediately call `navigateToScene` for next link
- The "Moving Handover": Next scene starts panning from 0% (or 10% if we want momentum)

#### Phase 3: Continuous Chain
- Same as Phase 2, repeats

## Recommended Action

**Option A: Revert and Rebuild**
1. Revert `NavigationSystem.js` to a simpler version (before manual animation loop)
2. Use Pannellum's built-in `viewer.lookAt` for camera movement
3. Keep the 80% trigger timing
4. Focus on making auto-forward reliable

**Option B: Fix Current Code**
1. Fix variable scoping in NavigationSystem.js
2. Remove conflicting animation logic
3. Ensure one source of truth for camera animation

Which approach would you prefer?
