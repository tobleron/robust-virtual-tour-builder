# Testing Guide: Optimistic Updates & Recovery

## Rollback Testing

1. **Scene Deletion Rollback**
   - Load project with multiple scenes
   - Disconnect network (DevTools > Network > Offline)
   - Delete a scene
   - Verify: Scene reappears, warning notification shown

2. **Hotspot Rollback**
   - Add hotspot while offline
   - Verify: Hotspot removed, warning shown

## Recovery Testing

1. **Interrupted Save**
   - Start save operation
   - Close browser tab immediately
   - Reopen app
   - Verify: Recovery prompt appears
   - Click "Retry All"
   - Verify: Save completes

2. **Interrupted Upload**
   - Start image upload
   - Force close browser
   - Reopen app
   - Verify: Recovery prompt shows upload
   - Dismiss or retry
