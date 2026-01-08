# Simulation Mode Implementation

## Overview
Added a **Simulation Mode Toggle** to control when jump link auto-navigation occurs, solving the issue where clicking on jump link scenes would automatically redirect users during editing.

## Problem Analysis
Previously, jump links would automatically navigate to their target scene in two scenarios:
1. When a jump link scene was clicked in the builder
2. When **NOT** in linking mode (to allow editing)

This caused unwanted auto-navigation when users were trying to edit or view jump link scenes.

## Solution Implemented

### 1. **Simulation Mode Toggle Button**
- **Location**: Viewer utility bar (top-left, second button after Add Link)
- **Icon**: Play symbol (▶)
- **States**:
  - **Inactive (default)**: Indigo background (#6366f1)
  - **Active**: Green background (#10b981) with pulsing glow animation

### 2. **Jump Link Logic - Builder**
Jump links now only auto-navigate when **ALL** of these conditions are met:
1. Scene is marked as `isJumpLink`
2. NOT in linking mode (allows editing)
3. **Simulation mode IS active** ← New condition

**Code location**: `/src/components/Viewer.js` lines 776-799

### 3. **Jump Link Logic - Exported Tours**
Exported tours **always** execute jump link auto-navigation (simulation mode is always ON).

**Code location**: `/src/systems/Exporter.js` lines 554-573

### 4. **UI Design**
The simulation toggle follows the existing circular button style:
- 46px diameter
- Smooth hover animation (scale 1.08)
- Tooltip: "Simulation Mode: Test final tour navigation"
- Toast notifications when toggled ON/OFF

## Usage Instructions

### For Users:
1. **Normal Editing** (Simulation Mode OFF - default):
   - Click on any scene including jump links
   - Edit jump link settings without auto-redirect
   - Add/remove hotspots freely

2. **Testing Final Tour** (Simulation Mode ON):
   - Click the play button (▶) in viewer utility bar
   - Button turns green with pulsing glow
   - Jump links now auto-navigate like in exported tours
   - Test the complete tour flow

3. **Exported Tours**:
   - Jump links always auto-navigate
   - Users experience seamless transitions through connecting scenes

## Technical Details

### State Management
- **Variable**: `isSimulationMode` (boolean, default: false)
- **Scope**: Module-level in `Viewer.js`
- **Persistence**: Not persisted (resets on page reload)

### Button Integration
The simulation toggle is inserted into the utility bar between:
- Add Link FAB (yellow)
- **Simulation Toggle** (indigo/green) ← NEW
- Category Toggle (orange/green)
- Label Button (petroleum)

### Export Metadata
- Added `isJumpLink` field to scene metadata in exports
- Exported HTML includes jump link detection logic
- 500ms delay creates smooth "bridge" effect

## Files Modified

1. **`/src/components/Viewer.js`**
   - Added `isSimulationMode` state variable
   - Created simulation toggle button
   - Added CSS styling with pulse animation
   - Modified jump link logic to check simulation mode

2. **`/src/systems/Exporter.js`**
   - Added `isJumpLink` to exported scene metadata
   - Implemented jump link auto-navigation in exported tours
   - Added 500ms delay matching builder behavior

3. **`/src/version.js`**
   - Updated to version 1.9.3
   - Build info: "Simulation Mode Toggle"

4. **`/index.html`**
   - Cache busting updated to v1.9.3

5. **`/logs/log_changes.txt`**
   - Added detailed changelog entry

## Best Practice Validation

### UI Placement ✓
The simulation toggle is placed in the viewer utility bar where:
- It's contextually relevant (controls viewer behavior)
- It's easily accessible during testing
- It doesn't interfere with scene editing controls

### User Experience ✓
- **Clear visual feedback**: Color change + pulsing animation
- **Toast notifications**: Confirms mode changes
- **Intuitive icon**: Play symbol (▶) suggests simulation/preview
- **Safe default**: OFF by default prevents unexpected behavior

### Code Quality ✓
- Follows existing code patterns
- Maintains consistency with other toggle buttons
- Proper event handling with stopPropagation
- Clear comments explaining logic

## Testing Recommendations

1. **Test jump link creation**:
   - Create a jump link scene
   - Click on it with simulation OFF → should NOT auto-navigate
   - Enable simulation mode → should auto-navigate

2. **Test editing workflow**:
   - Edit jump link hotspots with simulation OFF
   - Verify camera position is preserved
   - Verify delete functionality still works

3. **Test exported tours**:
   - Export a tour with jump links
   - Verify auto-navigation works in all export formats (4K, 2K, HD)
   - Check 500ms delay timing

4. **Test UI states**:
   - Verify button color changes
   - Check pulse animation when active
   - Test tooltip display

## Future Enhancements (Optional)

- **Persist simulation mode**: Save preference in localStorage
- **Keyboard shortcut**: Add hotkey for quick toggle (e.g., S key)
- **Visual indicator**: Show "SIMULATION" badge in viewer when active
- **Speed control**: Allow adjusting the 500ms delay

---

**Version**: 1.9.3  
**Date**: 2025-12-31  
**Build Info**: Simulation Mode Toggle
