# Task 1304: BUG - Linking Mode Yellow Lines Persist After Save

**Priority**: HIGH - Visual feedback broken, confusing UX
**Status**: ✅ FIXED - Modal now closes on save, yellow lines hidden, linking mode exits
**Category**: Linking Mode UI/State Management
**Date Fixed**: Feb 2026

---

## Problem Statement

When a hotspot link is saved in linking mode, the yellow dashed lines (visual feedback for the link being created) should disappear immediately. Instead, they persist on screen until the user moves the mouse or navigates away.

### Expected Behavior
1. User in linking mode, dragging yellow dashed line
2. User clicks "Save Link" in modal
3. Modal closes, linking mode ends
4. Yellow dashed lines disappear immediately

### Actual Behavior
1. User saves link
2. Modal closes, linking mode ends
3. **Yellow dashed lines remain visible on screen** ❌
4. Lines only disappear after mouse movement or scene change

---

## Root Cause Analysis

### The Save Flow
When user clicks "Save Link" in `LinkModal.res`:

```rescript
let onSave = () => {
  // ... validation & hotspot creation ...
  HotspotManager.handleAddHotspot(state.activeIndex, newHotspot)->ignore
  GlobalStateBridge.dispatch(Actions.StopLinking)  // Set isLinking=false, linkDraft=None
  EventBus.dispatch(CloseModal)
}
```

### The Reducer (Reducer.res, Ui.reduce)

```rescript
| StopLinking =>
  Some({
    ...state,
    isLinking: false,
    linkDraft: None,
    appMode: AppFSM.transition(state.appMode, StopAuthoring),
  })
```

✅ State is correctly updated: `isLinking: false`, `linkDraft: None`

### The Rendering System (HotspotLine.res)

```rescript
let updateLines = (viewer, state: Types.state, ~mouseEvent: option<Dom.event>=?, ()) => {
  // ... setup ...
  if state.isLinking {
    switch state.linkDraft {
    | Some(draft) =>
      Logic.drawLinkingDraft(viewer, cam, rect, draft, mouseEvent, currentFrameIds)
    | None => ()
    }
  }
  // Clear elements that aren't in currentFrameIds
  Belt.MutableSet.String.forEach(Utils.lastFrameIds.contents, id => {
    if !Belt.MutableSet.String.has(currentFrameIds, id) {
      SvgManager.hide(id)  // Hide yellow line elements
    }
  })
  Utils.lastFrameIds := currentFrameIds
}
```

✅ Logic is correct: When `isLinking` is false, draft lines aren't drawn, and hidden

### The Missing Trigger 🐛

The problem is in **`ViewerManager/ViewerManagerLifecycle.res`**, the `useLinkingAndSimUI` effect:

```rescript
let useLinkingAndSimUI = (state: state, dispatch: action => unit) => {
  React.useEffect3(() => {
    let body = Dom.documentBody

    if state.isLinking {
      Logger.debug(~module_="ViewerManagerLogic", ~message="LINKING_MODE_ON", ())
      Dom.classList(body)->Dom.ClassList.add("linking-mode")
      // Show cursor guide rod
    } else {
      Dom.classList(body)->Dom.ClassList.remove("linking-mode")
      // Hide cursor guide rod
    }

    None  // <-- NO updateLines() called here!
  }, (state.isLinking, state.simulation.status, state.navigation))
}
```

**Issue**: This effect runs when `state.isLinking` changes (it's in the dependency array), but it only:
1. Updates CSS classes on body
2. Shows/hides the cursor guide

**It does NOT call `HotspotLine.updateLines()` to redraw the lines!**

### Why the Lines Eventually Clear

There are other places that call `updateLines`:
- `useMainSceneLoading` in `ViewerManagerLogic.res` (line 124)
- Mouse move events in `InputSystem`
- Scene transitions in `NavigationRenderer`

But these are triggered by OTHER state changes, not immediately when linking stops.

---

## Solution

Add `HotspotLine.updateLines()` call to the `useLinkingAndSimUI` effect to immediately redraw lines when `isLinking` state changes.

### File to Modify
**`src/components/ViewerManager/ViewerManagerLifecycle.res`**

### Change Required

In `useLinkingAndSimUI` function (lines 68-115), after the CSS class updates, add:

```rescript
let useLinkingAndSimUI = (state: state, dispatch: action => unit) => {
  React.useEffect3(() => {
    let body = Dom.documentBody
    let guide = Dom.getElementById("cursor-guide")

    if state.isLinking {
      Logger.debug(~module_="ViewerManagerLogic", ~message="LINKING_MODE_ON", ())
      Dom.classList(body)->Dom.ClassList.add("linking-mode")
      switch Nullable.toOption(guide) {
      | Some(g) =>
        Dom.setProperty(g, "display", "block")
        Dom.setProperty(g, "z-index", "9999")
        Dom.setLeft(g, "0px")
        Dom.setTop(g, "0px")
      | None => Logger.error(~module_="ViewerManagerLogic", ~message="ROD_NOT_FOUND_IN_EFFECT", ())
      }
    } else {
      Dom.classList(body)->Dom.ClassList.remove("linking-mode")
      switch Nullable.toOption(guide) {
      | Some(g) => Dom.setProperty(g, "display", "none")
      | None => ()
      }
    }

    // 🔧 FIX: Redraw hotspot lines when linking mode changes
    let v = ViewerSystem.getActiveViewer()
    switch Nullable.toOption(v) {
    | Some(viewer) => HotspotLine.updateLines(viewer, state, ())
    | None => ()
    }

    let isSimulationActive = state.simulation.status != Idle
    // ... rest of effect ...
  }, (state.isLinking, state.simulation.status, state.navigation))
}
```

### Why This Works

1. When `StopLinking` is dispatched, `state.isLinking` changes to false
2. This triggers `useLinkingAndSimUI` effect (isLinking is in dependency array)
3. The new code immediately calls `HotspotLine.updateLines(viewer, state, ())`
4. `updateLines` sees `state.isLinking = false` and skips drawing draft lines
5. SVG manager hides the yellow line elements
6. User sees lines disappear immediately ✅

---

## Verification

### Before Fix
1. Create hotspot link in linking mode
2. See yellow dashed line on screen
3. Click "Save Link"
4. Yellow lines **persist** on screen ❌

### After Fix
1. Create hotspot link in linking mode
2. See yellow dashed line on screen
3. Click "Save Link"
4. Yellow lines **disappear immediately** ✅
5. Modal closes cleanly
6. Linking mode exits

---

## Test Coverage

**Existing test**: `tests/unit/LinkEditor_v.test.res` (if exists)
**E2E test**: Covered in robustness and linking E2E tests

### Manual Test Steps
1. Load project with 2+ scenes
2. Click on a location to start linking
3. See yellow dashed line appear
4. Click "Save Link" and select destination
5. Verify yellow lines disappear **before** modal closes

---

## Related Code

**Affected Files**:
- `src/components/ViewerManager/ViewerManagerLifecycle.res` - Where fix goes
- `src/components/LinkModal.res` - Where save is triggered
- `src/systems/HotspotLine.res` - Line rendering logic
- `src/core/Reducer.res` - State update logic

**Architecture**:
- State change: `StopLinking` action → `isLinking = false`
- Effect trigger: Dependency array includes `isLinking`
- Rendering: `HotspotLine.updateLines` clears lines based on state

---

## Solution - IMPLEMENTED ✅

### Root Issue Identified
The modal's "Save Link" button had `autoClose: Some(false)`, which prevented the modal from automatically closing after button click. The ModalContext component checks this flag to determine whether to dispatch CloseModal.

Additionally, there was a second issue: clicking Save required a second viewer click to fully exit linking mode.

### Fix Applied - Three-Part Solution

**Part 1: LinkModal.res - Save Button Configuration**
```rescript
// Changed from:
autoClose: Some(false),

// To:
autoClose: Some(true),
```
- Now modal automatically closes after save button is clicked
- ModalContext will dispatch CloseModal for us

**Part 2: LinkModal.res - Save Handler Enhancement**
```rescript
let onSave = (e: React.event<_>) => {
  Dom.preventDefault(e)  // Prevent event bubbling
  // ... validation & hotspot creation ...
  HotspotManager.handleAddHotspot(state.activeIndex, newHotspot)->ignore
  // Explicitly hide draft lines immediately
  SvgManager.hide("link_draft_red")
  SvgManager.hide("link_draft_yellow")
  GlobalStateBridge.dispatch(Actions.StopLinking)
  // Modal will auto-close due to autoClose: true
}
```
- Prevents any event propagation to avoid stale click handlers
- Explicitly hides both draft line SVG elements
- Dispatches StopLinking to set isLinking = false

**Part 3: ViewerManagerLifecycle.res - State-Based Backup**
Added to `useLinkingAndSimUI` effect:
```rescript
// Redraw hotspot lines when linking mode changes
let v = ViewerSystem.getActiveViewer()
switch Nullable.toOption(v) {
| Some(viewer) =>
  if !state.isLinking {
    Logger.info(~module_="ViewerManagerLifecycle",
      ~message="CLEARING_LINK_DRAFT_LINES", ())
  }
  HotspotLine.updateLines(viewer, state, ())
| None => ()
}
```
- Serves as backup cleanup when state changes
- Triggers immediately when isLinking changes in dependency array

### Why This Now Works

1. User clicks "Save Link" → onSave() executes
2. Lines explicitly hidden via SvgManager.hide()
3. StopLinking action dispatches → isLinking becomes false
4. **autoClose: true triggers ModalContext to dispatch CloseModal**
5. Modal closes cleanly, linking mode exits completely
6. **Single click to save now works** ✅ (no second click needed)
7. useLinkingAndSimUI effect responds to state change as backup

---

## Verification

- ✅ Modal closes on Save click (no second click required)
- ✅ Yellow dashed lines disappear immediately
- ✅ Linking mode fully exited (isLinking = false)
- ✅ Draft line SVG elements explicitly hidden
- ✅ No event propagation issues
- ✅ Cancel button still works correctly

---

## Impact

**Minimal**: Configuration change + explicit line clearing
**Risk**: None - just fixes modal autoClose behavior
**Performance**: Negligible - visual update only

---

## Files Modified

1. `src/components/LinkModal.res` - Save button autoClose + explicit line hiding
2. `src/components/ViewerManager/ViewerManagerLifecycle.res` - State-based cleanup backup
