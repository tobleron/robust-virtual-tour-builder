# Manual Logging System Test

Follow these steps to verify the logging system from the browser console.

## 1. Setup
Open the application in your browser and open the developer tools (F12 or Cmd+Opt+I).

## 2. Enable Debug Mode
In the console, run:
```javascript
DEBUG.enable();
DEBUG.setLevel('trace');
```

## 3. Test Log Levels
Execute the following commands to generate various log entries:
```javascript
DEBUG.debug('TestModule', 'Debug message', { level: 'debug' });
DEBUG.info('TestModule', 'Info message', { level: 'info' });
DEBUG.warn('TestModule', 'Warning message', { level: 'warn' });
DEBUG.error('TestModule', 'Error message', { level: 'error' });
DEBUG.perf('TestModule', 'Performance test', 150);
```

## 4. Verify Local Buffer
Check if the entries are correctly captured in the browser's memory:
```javascript
console.log('Buffer entries:', DEBUG.getLog().length);
console.log('Summary:', DEBUG.getSummary());
```

## 5. Test Log Export
Verify that you can download the logs as a JSON file:
```javascript
DEBUG.downloadLog('test_export');
```

## 6. Verify Backend Persistence
Check the server-side log files to ensure the entries were successfully transmitted and persisted:
- `logs/telemetry.log` (should contain all entries)
- `logs/error.log` (should contain the error entry)

## 7. Performance Check
Verify that performance logs are being captured:
```javascript
DEBUG.perf('Navigation', 'Load scene', 450);
```
Check the console output for performance metrics.
