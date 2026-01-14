# Report: Migrate HotspotManager.res to Logger System

## Objective (Completed)
Update HotspotManager.res to use the new Logger module for tracking hotspot interactions and link management.

## Context
HotspotManager handles user clicks on navigation arrows and info hotspots. It's where user intent translates into navigation actions. Logging here helps diagnose click detection issues, missing targets, and link state problems.

## Prerequisites
- Logger.res module exists ✅
- Debug.js updated with perf() method ✅

## Implementation Details

### 1. Update Hotspot Click Handling

```rescript
let handleHotspotClick = (hotspot: hotspot): unit => {
  Logger.info(~module_="Hotspot", ~message="HOTSPOT_CLICK", ~data=Some({
    "type": hotspotTypeToString(hotspot.type_),
    "id": hotspot.id,
    "target": hotspot.target
  }), ())
  
  // ... existing logic
}
```

### 2. Update Navigation Trigger

```rescript
// On successful navigation start
Logger.info(~module_="Hotspot", ~message="NAV_TRIGGERED", ~data=Some({
  "target": hotspot.target,
  "fromScene": currentScene.name
}), ())

// On target not found
Logger.warn(~module_="Hotspot", ~message="TARGET_NOT_FOUND", ~data=Some({
  "targetId": hotspot.target
}), ())

// On target index not found
Logger.warn(~module_="Hotspot", ~message="TARGET_INDEX_NOT_FOUND", ~data=Some({
  "targetScene": targetScene.name
}), ())
```

### 3. Update Link Creation

```rescript
let createLink = (fromScene: scene, toScene: scene, coords: coords): unit => {
  Logger.info(~module_="Hotspot", ~message="LINK_CREATE", ~data=Some({
    "from": fromScene.name,
    "to": toScene.name,
    "pitch": coords.pitch,
    "yaw": coords.yaw
  }), ())
  
  // ... existing logic
}
```

### 4. Update Link Deletion

```rescript
let deleteLink = (hotspotId: string): unit => {
  Logger.info(~module_="Hotspot", ~message="LINK_DELETE", ~data=Some({
    "hotspotId": hotspotId
  }), ())
  
  // ... existing logic
}
```

### 5. Update Hover States (Debug Level)

```rescript
let handleHotspotHover = (hotspotId: string, isEnter: bool): unit => {
  Logger.debug(~module_="Hotspot", ~message=isEnter ? "HOVER_ENTER" : "HOVER_EXIT", ~data=Some({
    "hotspotId": hotspotId
  }), ())
}
```

### 6. Update Render/Update Cycle (Trace Level)

```rescript
let updateHotspotPositions = (): unit => {
  Logger.trace(~module_="Hotspot", ~message="UPDATE_POSITIONS", ~data=Some({
    "count": Belt.Array.length(hotspots)
  }), ())
  
  // ... existing logic
}
```

## Standard Log Points

| Event | Level | Message | Data |
|-------|-------|---------|------|
| Click | `info` | `HOTSPOT_CLICK` | type, id, target |
| Nav trigger | `info` | `NAV_TRIGGERED` | target, fromScene |
| Target missing | `warn` | `TARGET_NOT_FOUND` | targetId |
| Link create | `info` | `LINK_CREATE` | from, to, coords |
| Link delete | `info` | `LINK_DELETE` | hotspotId |
| Hover | `debug` | `HOVER_ENTER/EXIT` | hotspotId |
| Position update | `trace` | `UPDATE_POSITIONS` | count |

## Files to Modify

| File | Changes |
|------|---------|
| `src/components/HotspotManager.res` | Replace all Debug calls with Logger calls |

## Testing Checklist

- [ ] Clicking hotspot logs click event with target
- [ ] Navigation trigger logs source and destination
- [ ] Missing target logs warning
- [ ] Creating link logs both scenes
- [ ] Deleting link logs hotspot ID
- [ ] Debug mode shows hover events
- [ ] Trace mode shows position updates

## Definition of Done

- All Debug calls replaced with Logger calls
- User interactions fully logged
- Clear target/source context in navigation events
- Appropriate levels for each event type
