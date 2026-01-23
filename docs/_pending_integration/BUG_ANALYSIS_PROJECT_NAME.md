# 🐛 Bug Analysis: Project Name Defaults to "Unknown"

## Problem Statement
The project name input field shows "Unknown" instead of being automatically populated with a location-based name derived from image EXIF GPS metadata and Google Maps reverse geocoding.

## Root Cause

### Image Processing Pipeline Flow
1. **Frontend EXIF Extraction** (`Resizer.res:163-168`)
   - EXIF is extracted from the **original file** BEFORE compression
   - GPS coordinates and datetime are captured

2. **Frontend Compression** (`Resizer.res:171`)
   - Image is compressed to WebP format
   - **WebP compression strips EXIF metadata**

3. **Backend Processing** (`image.rs:149-155`)
   - Compressed WebP is sent to backend with preserved EXIF as separate metadata
   - Backend only generates filename-based suggestions (e.g., `240114_001` from `_240114_00_001.jpg`)
   - **Backend does NOT perform geocoding or location-based naming**

4. **Project Name Generation** (`ExifReportGenerator.res:37-115`)
   - This is called AFTER upload completes
   - Should generate: `Location_Word1_Word2_Word3_DDMMYYHH_MMSS`
   - **But the timing is wrong - metadata is already processed**

### The Critical Issue

The `ExifReportGenerator.generateExifReport()` function correctly:
- Extracts GPS from all uploaded images
- Calculates average location
- Performs reverse geocoding
- Generates smart project names

**However**, this happens AFTER the backend has already processed the images and set `suggestedName` based only on filename patterns.

In `UploadProcessor.res:616-621`:
```rescript
if res.suggestedName != "" {
  let currentName = GlobalStateBridge.getState().tourName
  if currentName == "" {
    GlobalStateBridge.dispatch(SetTourName(res.suggestedName))
  }
}
```

The `res.suggestedName` comes from the EXIF report, but by this time, the backend has already set a filename-based suggestion, so the location-based name is never used.

## Files Involved

### Frontend
- `src/systems/Resizer.res` - Image compression and EXIF extraction
- `src/systems/ExifParser.res` - EXIF metadata extraction
- `src/systems/ExifReportGenerator.res` - Project name generation logic
- `src/systems/UploadProcessor.res` - Upload orchestration
- `src/components/Sidebar.res` - Project name input display

### Backend
- `backend/src/api/media/image.rs` - Image processing endpoint
- `backend/src/services/media.rs` - Metadata extraction and name suggestion

## Expected vs Actual Behavior

### Expected
1. User uploads images with GPS EXIF data
2. System extracts GPS coordinates
3. System performs reverse geocoding to get address
4. System generates name like: `Beverly_Hills_California_220122_1430`
5. Project name input shows this generated name

### Actual
1. User uploads images
2. Frontend extracts EXIF from original
3. Frontend compresses to WebP (strips EXIF)
4. Backend receives compressed image + EXIF metadata
5. Backend generates filename-based name (e.g., `240114_001`)
6. EXIF report generates location-based name but it's too late
7. Project name shows "Unknown" or generic filename pattern

## Solution Strategy

### Option 1: Move Project Name Generation Earlier ✅ RECOMMENDED
- Generate project name in `ExifReportGenerator` BEFORE backend processing
- Pass the generated name to the upload processor
- Ensure it's set before any backend-generated names

### Option 2: Enhance Backend Name Generation
- Add geocoding capability to Rust backend
- Generate location-based names server-side
- Requires adding geocoding service to backend

### Option 3: Fix Timing in Upload Flow
- Ensure `ExifReportGenerator` runs first
- Set project name before individual file processing
- Update state management to prioritize location-based names

## Recommended Fix

Implement **Option 1** by:
1. Extract GPS from first uploaded image immediately
2. Perform geocoding early in upload process
3. Generate and set project name before backend processing
4. Ensure location-based names take precedence over filename patterns

## Testing Checklist

- [ ] Upload images WITH GPS EXIF data → Should show location-based name
- [ ] Upload images WITHOUT GPS data → Should show timestamp-based fallback
- [ ] Upload images with filename patterns → Should prioritize location over pattern
- [ ] Verify name appears in input field immediately after upload
- [ ] Verify name is used when saving project
