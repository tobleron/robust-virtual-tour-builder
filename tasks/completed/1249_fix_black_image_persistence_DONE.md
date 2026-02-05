# Task 1249: Fix Black Image Persistence Issue

**Status**: Pending  
**Priority**: Critical  
**Estimated Effort**: 2-3 hours  
**Created**: 2026-02-05

## Problem Statement

Uploaded images appear as black images in the sidebar and fail to load in the viewer after page reload or state restoration from IndexedDB. This is caused by attempting to persist `File` and `Blob` objects directly to IndexedDB, which results in empty/invalid references when retrieved.

## Root Cause Analysis

### Current Broken Flow
1. Images uploaded as `File` objects → stored in state as `Types.File(fileObject)`
2. State persisted to IndexedDB with encoder using `castFileToJson(file)`
3. IndexedDB stores File/Blob references, but they become invalid/empty when retrieved
4. On state restoration, scenes have File/Blob references pointing to nothing
5. Result: Black images in sidebar and viewer

### Why File/Blob Cannot Be Persisted
- File and Blob objects are **memory references** to binary data
- IndexedDB can technically store them, but the data is not properly serialized
- When retrieved from IndexedDB, File/Blob objects lose their underlying data
- Blob URLs (`blob:http://...`) are session-specific and invalid after page reload

## Solution Design

### Architecture Decision
Images should follow this lifecycle:
1. **Upload Phase**: Keep File/Blob in memory for immediate processing
2. **Backend Processing**: Send to `/api/media/process-full` for server-side storage
3. **Persistence Phase**: Store only URLs (backend URLs or empty strings)
4. **Restoration Phase**: Load from backend URLs, not from stale File/Blob references

### Implementation Strategy

**Option A: Force Backend URL Fallback (Recommended - Quick Fix)**
- Modify encoder to convert File/Blob to empty strings during persistence
- Forces app to use backend URLs on restoration
- Leverages existing `ProjectManagerUrl.rebuildSceneUrls` logic

**Option B: Convert to Blob URLs Before Persistence (Alternative)**
- Create blob URLs before saving to IndexedDB
- Store blob data separately in IndexedDB
- Reconstruct on load (more complex, better offline support)

## Implementation Plan

### Phase 1: Fix Encoder (Quick Fix)

**File**: `src/core/JsonParsersEncoders.res`

**Current Code** (Lines 15-24):
```rescript
external castFileToJson: ReBindings.File.t => JSON.t = "%identity"
external castBlobToJson: ReBindings.Blob.t => JSON.t = "%identity"

let file = (f: Types.file) => {
  switch f {
  | Url(u) => Encode.string(u)
  | File(file) => castFileToJson(file)
  | Blob(blob) => castBlobToJson(blob)
  }
}
```

**New Code**:
```rescript
// Remove external casts - no longer needed
// external castFileToJson: ReBindings.File.t => JSON.t = "%identity"
// external castBlobToJson: ReBindings.Blob.t => JSON.t = "%identity"

let file = (f: Types.file) => {
  switch f {
  | Url(u) => Encode.string(u)
  | File(_) => Encode.string("")  // Force backend URL fallback on restoration
  | Blob(_) => Encode.string("")  // Force backend URL fallback on restoration
  }
}
```

**Rationale**:
- Empty strings trigger the fallback logic in `ProjectManagerUrl.rebuildSceneUrls`
- Scene name is used to construct backend URL: `/api/project/{sessionId}/file/{sceneName}`
- Existing backend infrastructure already serves these files

### Phase 2: Verify Decoder (Should Already Work)

**File**: `src/core/JsonParsersDecoders.res`

**Current Code** (Lines 26-36):
```rescript
let file = id->map(json => {
  if %raw("(t => typeof t === 'string')")(json) {
    Types.Url(Obj.magic(json))
  } else if %raw("(t => t instanceof File)")(json) {
    Types.File(Obj.magic(json))
  } else if %raw("(t => t instanceof Blob)")(json) {
    Types.Blob(Obj.magic(json))
  } else {
    Types.Url("")
  }
})
```

**Verification**:
- Decoder correctly handles empty strings → `Types.Url("")`
- This triggers fallback in `ProjectManagerUrl.rebuildSceneUrls`
- No changes needed here

### Phase 3: Test URL Reconstruction Logic

**File**: `src/systems/ProjectManagerUrl.res`

**Key Function**: `rebuildSceneUrls` (Lines 57-93)

**Verify Fallback Logic** (Lines 60-73):
```rescript
let file = switch rebuildUrl(scene.file, ~sessionId, ~tokenQuery) {
| Url(u) if u != "" && (String.startsWith(u, "http") || String.startsWith(u, "blob:")) =>
  Types.Url(u)
| _ =>
  // Fallback: Use scene name as filename
  Types.Url(
    Constants.backendUrl ++
    "/api/project/" ++
    sessionId ++
    "/file/" ++
    encodeURIComponent(scene.name) ++
    tokenQuery,
  )
}
```

**Expected Behavior**:
- When `scene.file` is `Url("")`, fallback triggers
- Backend URL constructed using scene name
- Token query appended for authentication

### Phase 4: Handle Edge Cases

#### 4.1 Newly Uploaded Images (Not Yet Saved)
**Issue**: Images uploaded but not saved to backend yet
**Solution**: Keep File/Blob in memory until backend processing completes
**Location**: `src/systems/UploadProcessorLogic.res`

**Verify** (Lines 95-112):
```rescript
let createScenePayload = (items: array<UploadTypes.uploadItem>) => {
  Belt.Array.map(items, item => {
    let preview = Option.getOr(item.preview, item.original)
    let tiny = Option.getOr(item.tiny, preview)

    JsonEncoders.Upload.sceneItem(
      ~id=Nullable.toOption(item.id)->Option.getOr(""),
      ~originalName=File.name(item.original),
      ~name=File.name(preview),
      ~original=Types.File(item.original),  // Keep File in memory
      ~preview=Types.File(preview),          // Keep File in memory
      ~tiny=Types.File(tiny),                // Keep File in memory
      ~quality=item.quality,
      ~metadata=item.metadata,
      ~colorGroup=Option.getOr(item.colorGroup, "0"),
    )
  })
}
```

**Note**: `JsonEncoders.Upload.sceneItem` uses a separate encoder that should also be updated

#### 4.2 Update Upload Encoder
**File**: `src/core/JsonEncoders.res`

**Current Code** (Lines 10-16):
```rescript
let encodeFileFromTypes = (f: Types.file) => {
  switch f {
  | Url(s) => Encode.string(s)
  | File(file) => castFileToJson(file)
  | Blob(blob) => castBlobToJson(blob)
  }
}
```

**New Code**:
```rescript
let encodeFileFromTypes = (f: Types.file) => {
  switch f {
  | Url(s) => Encode.string(s)
  | File(_) => Encode.string("")  // Consistent with main encoder
  | Blob(_) => Encode.string("")  // Consistent with main encoder
  }
}
```

#### 4.3 Thumbnail Display
**File**: `src/components/SceneList/SceneItem.res`

**Verify** (Lines 6-17):
```rescript
let getThumbUrl = (scene: Types.scene) => {
  switch scene.tinyFile {
  | Some(tiny) =>
    let url = UrlUtils.fileToUrl(tiny)
    if url == "" {
      UrlUtils.fileToUrl(scene.file)
    } else {
      url
    }
  | None => UrlUtils.fileToUrl(scene.file)
  }
}
```

**Expected Behavior**:
- `UrlUtils.fileToUrl` converts File/Blob to blob URLs for display
- For persisted scenes, uses backend URLs
- Should work without changes

## Testing Plan

### Test Case 1: Fresh Upload
1. Upload new images
2. Verify images display correctly in sidebar
3. Verify images load in viewer
4. Save project
5. Reload page
6. **Expected**: Images load from backend URLs

### Test Case 2: Existing Project Load
1. Load existing `.vt.zip` project
2. Verify all images display correctly
3. Navigate between scenes
4. **Expected**: All images load from backend

### Test Case 3: Session Recovery
1. Upload images
2. Trigger browser refresh before saving
3. **Expected**: Session recovery shows images (from memory)
4. Complete save
5. Reload page
6. **Expected**: Images load from backend

### Test Case 4: Mixed State
1. Load project with existing scenes
2. Upload new images
3. Save project
4. Reload page
5. **Expected**: Both old and new images load correctly

## Verification Checklist

- [ ] Encoder modified to return empty strings for File/Blob
- [ ] Upload encoder updated for consistency
- [ ] External casts removed from `JsonParsersEncoders.res`
- [ ] Decoder verified to handle empty strings correctly
- [ ] URL reconstruction logic tested with empty string input
- [ ] Fresh upload test passed
- [ ] Project load test passed
- [ ] Session recovery test passed
- [ ] Mixed state test passed
- [ ] No console errors related to image loading
- [ ] No black images in sidebar
- [ ] Viewer loads images correctly
- [ ] Backend URLs properly constructed with auth tokens

## Rollback Plan

If issues arise:
1. Revert changes to `JsonParsersEncoders.res`
2. Revert changes to `JsonEncoders.res`
3. Clear IndexedDB: `PersistenceLayer.clearSession()`
4. Reload application

## Files to Modify

1. **Primary Changes**:
   - `src/core/JsonParsersEncoders.res` (Lines 15-24)
   - `src/core/JsonEncoders.res` (Lines 10-16)

2. **Verification Only** (No changes needed):
   - `src/core/JsonParsersDecoders.res`
   - `src/systems/ProjectManagerUrl.res`
   - `src/components/SceneList/SceneItem.res`
   - `src/utils/UrlUtils.res`

## Success Criteria

1. ✅ No black images after page reload
2. ✅ Images load correctly in viewer
3. ✅ Thumbnails display in sidebar
4. ✅ Session recovery preserves images
5. ✅ Project save/load cycle works correctly
6. ✅ No console errors related to image loading
7. ✅ Backend URLs properly authenticated

## Notes

- This fix relies on backend storage being the source of truth for images
- File/Blob objects are only kept in memory during active session
- After save, all images must be retrievable from backend
- Blob URLs created by `UrlUtils.fileToUrl` are for display only, not persistence
- The `sessionId` in backend URLs is managed by `ProjectManager.loadProject`

## Related Issues

- Versions affected: 4.8.14, 4.8.13 (noted in CHANGELOG.md)
- Related to IndexedDB persistence layer
- Related to project save/load functionality
- May affect offline capability (future consideration)
