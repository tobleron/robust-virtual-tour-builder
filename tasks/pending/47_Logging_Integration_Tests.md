# Task: Create Logging Integration Tests

## Objective
Create integration tests to verify the logging system works end-to-end from frontend through backend persistence.

## Context
With a hybrid logging system, we need to verify that logs flow correctly from ReScript through Debug.js to the Rust backend and are persisted to files.

## Prerequisites
- All logging tasks completed

## Implementation Steps

### 1. Create Test Script

Create `scripts/test-logging.js`:

```javascript
/**
 * Logging System Integration Test
 * Run with: node scripts/test-logging.js
 */

const BACKEND_URL = 'http://localhost:8080';

async function testTelemetryEndpoint() {
    console.log('Testing /log-telemetry endpoint...');
    
    const entry = {
        level: 'info',
        module: 'TestModule',
        message: 'TEST_LOG_ENTRY',
        data: { test: true, timestamp: Date.now() },
        timestamp: new Date().toISOString()
    };
    
    const response = await fetch(`${BACKEND_URL}/log-telemetry`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(entry)
    });
    
    if (response.ok) {
        console.log('✅ Telemetry endpoint working');
        return true;
    } else {
        console.log('❌ Telemetry endpoint failed:', response.status);
        return false;
    }
}

async function testErrorEndpoint() {
    console.log('Testing /log-error endpoint...');
    
    const entry = {
        level: 'error',
        module: 'TestModule',
        message: 'TEST_ERROR_ENTRY',
        data: { error: 'Test error message' },
        timestamp: new Date().toISOString()
    };
    
    const response = await fetch(`${BACKEND_URL}/log-error`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(entry)
    });
    
    if (response.ok) {
        console.log('✅ Error endpoint working');
        return true;
    } else {
        console.log('❌ Error endpoint failed:', response.status);
        return false;
    }
}

async function verifyLogFiles() {
    console.log('Verifying log files...');
    
    const fs = require('fs');
    const path = require('path');
    
    const telemetryPath = path.join(__dirname, '../logs/telemetry.log');
    const errorPath = path.join(__dirname, '../logs/error.log');
    
    const checks = [];
    
    if (fs.existsSync(telemetryPath)) {
        const content = fs.readFileSync(telemetryPath, 'utf8');
        if (content.includes('TEST_LOG_ENTRY')) {
            console.log('✅ Telemetry log contains test entry');
            checks.push(true);
        } else {
            console.log('❌ Telemetry log missing test entry');
            checks.push(false);
        }
    } else {
        console.log('❌ Telemetry log file not found');
        checks.push(false);
    }
    
    if (fs.existsSync(errorPath)) {
        const content = fs.readFileSync(errorPath, 'utf8');
        if (content.includes('TEST_ERROR_ENTRY')) {
            console.log('✅ Error log contains test entry');
            checks.push(true);
        } else {
            console.log('❌ Error log missing test entry');
            checks.push(false);
        }
    } else {
        console.log('❌ Error log file not found');
        checks.push(false);
    }
    
    return checks.every(c => c);
}

async function runTests() {
    console.log('=== Logging System Integration Tests ===\n');
    
    const results = [];
    
    results.push(await testTelemetryEndpoint());
    results.push(await testErrorEndpoint());
    
    // Wait for file writes
    await new Promise(r => setTimeout(r, 500));
    
    results.push(await verifyLogFiles());
    
    console.log('\n=== Results ===');
    if (results.every(r => r)) {
        console.log('✅ All tests passed!');
        process.exit(0);
    } else {
        console.log('❌ Some tests failed');
        process.exit(1);
    }
}

runTests().catch(console.error);
```

### 2. Create Browser Console Test

Create instructions for manual testing:

```javascript
// Run in browser console:

// 1. Enable debug mode
DEBUG.enable();
DEBUG.setLevel('trace');

// 2. Test each log level
DEBUG.debug('TestModule', 'Debug message', { level: 'debug' });
DEBUG.info('TestModule', 'Info message', { level: 'info' });
DEBUG.warn('TestModule', 'Warning message', { level: 'warn' });
DEBUG.error('TestModule', 'Error message', { level: 'error' });
DEBUG.perf('TestModule', 'Performance test', 150);

// 3. Check buffer
console.log('Buffer entries:', DEBUG.getLog().length);
console.log('Summary:', DEBUG.getSummary());

// 4. Export logs
DEBUG.downloadLog('test_export');

// 5. Verify backend received logs
// Check logs/telemetry.log on server
```

### 3. Add to package.json

```json
{
  "scripts": {
    "test:logging": "node scripts/test-logging.js"
  }
}
```

## Testing Checklist

- [ ] Backend endpoints respond with 200
- [ ] Telemetry entries appear in telemetry.log
- [ ] Error entries appear in both logs
- [ ] Browser Debug module functions work
- [ ] Log export/download works
- [ ] Performance logging works
- [ ] Log levels filter correctly

## Definition of Done

- Integration test script created
- Manual browser test documented
- All tests pass
- Can be run as part of CI/CD
