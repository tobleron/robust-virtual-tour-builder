# Debug Telemetry Security Fix Plan

## Problem Statement
The current debug system automatically sends ALL log entries (including debug, info, and warn levels) to the backend telemetry endpoint, creating potential privacy and security risks in production environments. This includes sensitive information like:
- User agent strings
- Screen resolution and device information  
- Current URL and application state
- Potentially user data in log messages

## Current Vulnerable Code
**File**: `src/utils/Debug.js`
**Lines**: 128-136 and 159-181

### Current Logic Issues:
1. **Line 136**: `this.sendTelemetry({ ...entry, systemContext });` is called for EVERY log entry
2. **Lines 160-162**: The filtering logic is insufficient - it still sends non-error logs that meet the minLevel threshold

## Proposed Solution

### Step 1: Add Environment Detection
Create a helper function to detect if the application is running in development or production:

```javascript
// Add to Debug.js
const isDevelopment = () => {
  return window.location.hostname === 'localhost' || 
         window.location.hostname === '127.0.0.1' ||
         window.location.protocol === 'file:';
};
```

### Step 2: Update sendTelemetry Function
Modify the `sendTelemetry` function to only send error logs in production:

```javascript
/**
 * Send log entry to backend telemetry
 */
async sendTelemetry(entry) {
  // In production: only send error logs
  // In development: send all logs that meet minLevel threshold
  const isDev = this.isDevelopment();
  
  if (!isDev) {
    // Production: only send errors
    if (entry.level !== 'error') {
      return;
    }
  } else {
    // Development: respect minLevel threshold but don't send debug logs unless explicitly enabled
    if (entry.level !== 'error' && LOG_LEVELS[entry.level] < LOG_LEVELS[this.minLevel]) {
      return;
    }
  }

  try {
    // Import constant dynamically to avoid circular dependencies
    const { BACKEND_URL } = await import('../constants.js');
    await fetch(`${BACKEND_URL}/log-telemetry`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        level: entry.level,
        module: entry.module,
        message: entry.message,
        data: entry.data,
        timestamp: entry.time
      })
    });
  } catch (e) {
    // Silent fail for telemetry to avoid infinite loops
  }
}
```

### Step 3: Add isDevelopment Method to Debug Object
Add the environment detection method to the Debug object:

```javascript
/**
 * Check if running in development environment
 * @returns {boolean}
 */
isDevelopment() {
  return window.location.hostname === 'localhost' || 
         window.location.hostname === '127.0.0.1' ||
         window.location.protocol === 'file:';
},
```

### Step 4: Update Log Function Call
Update the log function to pass the correct context:

```javascript
// Keep existing log function but ensure it calls sendTelemetry correctly
log(module, level, message, data = null) {
  // ... existing code ...
  
  // AUTO-TELEMETRY: Send logs to backend based on environment
  const systemContext = {
    ua: navigator.userAgent,
    screen: `${window.screen.width}x${window.screen.height}`,
    url: window.location.href,
    memory: navigator.deviceMemory ? `${navigator.deviceMemory}GB` : 'unknown'
  };
  this.sendTelemetry({ ...entry, systemContext });
  
  // ... rest of existing code ...
}
```

## Security Benefits
1. **Production Safety**: Only error logs (which are critical for monitoring) are sent to the backend
2. **Development Flexibility**: Full logging capabilities remain available for debugging during development
3. **Privacy Protection**: Sensitive user information is not transmitted in production environments
4. **Bandwidth Optimization**: Reduces unnecessary network traffic in production

## Implementation Notes
- This fix should be implemented in **code mode** since architect mode can only edit markdown files
- The change is backward compatible and doesn't break existing functionality
- Error monitoring and crash reporting will continue to work as expected
- Development debugging capabilities remain fully intact

## Testing Strategy
1. **Production Test**: Verify that only error logs are sent when running from non-localhost URLs
2. **Development Test**: Verify that all log levels are sent when running from localhost
3. **File Protocol Test**: Verify that file:// protocol (desktop app) behaves like production
4. **Error Log Test**: Ensure error logs are always sent regardless of environment

## Risk Assessment
- **Low Risk**: This is a security enhancement that restricts data flow rather than changing core functionality
- **No Breaking Changes**: Existing console logging behavior remains unchanged
- **Reversible**: If issues arise, the original logic can be restored easily