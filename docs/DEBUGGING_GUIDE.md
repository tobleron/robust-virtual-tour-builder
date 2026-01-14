# Debugging Guide

## Development Mode

### State Inspection

In development builds, you can inspect application state via the browser console:

```javascript
// Get a safe snapshot of current state
window.store.state

// Get full state (frozen, read-only)
window.store.getFullState()
```

**Note**: These are read-only snapshots. Mutations will not affect the application.

### Recommended Tools

1. **React DevTools**: Best for inspecting component state and props
2. **Redux DevTools**: If using Redux (currently using useReducer)
3. **Logger Module**: Check browser console for structured logs
4. **Network Tab**: Monitor backend API calls

## Production Mode

State inspector is **disabled** in production builds for security and performance.

### Debugging Production Issues

1. **Enable Telemetry Logs**: Check backend logs at `backend/backend.log`
2. **Error Tracking**: All errors are logged via `Logger.error()`
3. **Network Monitoring**: Use browser DevTools Network tab
4. **Performance Profiling**: Use Chrome DevTools Performance tab

### Emergency State Access

If you need to inspect state in production:

1. Set environment variable: `ENABLE_STATE_INSPECTOR=true`
2. Rebuild the application: `npm run build`
3. Access via `window.store.state`
4. **Remember to disable after debugging**

## Best Practices

- ❌ Don't rely on `window.store` for application logic
- ❌ Don't mutate state directly via console
- ✅ Use React DevTools for component debugging
- ✅ Use Logger module for runtime debugging
- ✅ Use unit tests for logic verification
