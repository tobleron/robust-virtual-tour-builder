/**
 * Logging System Integration Test
 * Run with: node scripts/test-logging.js
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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

    try {
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
    } catch (e) {
        console.log('❌ Telemetry endpoint unreachable:', e.message);
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

    try {
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
    } catch (e) {
        console.log('❌ Error endpoint unreachable:', e.message);
        return false;
    }
}

async function verifyLogFiles() {
    console.log('Verifying log files...');

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
    await new Promise(r => setTimeout(r, 1000));

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
