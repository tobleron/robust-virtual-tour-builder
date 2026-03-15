#!/bin/bash
# Portal Upload Troubleshooting Script
# Run this on your VPS to diagnose upload issues

set -euo pipefail

echo "========================================"
echo "Portal Upload Diagnostic Script"
echo "========================================"
echo ""

# Configuration
APP_DIR="${PORTAL_VPS_APP_DIR:-/opt/robust-vtb/current}"
SERVICE_NAME="robust-vtb-portal"
BACKEND_PORT="8080"

echo "1. SERVICE STATUS"
echo "----------------"
systemctl is-active "$SERVICE_NAME" && echo "✓ Service is running" || echo "✗ Service is NOT running"
echo ""

echo "2. BINARY INFORMATION"
echo "--------------------"
if pgrep -f "portal" > /dev/null; then
    PID=$(pgrep -f "portal" | head -1)
    echo "Process ID: $PID"
    echo "Binary path: $(readlink -f /proc/$PID/exe)"
    echo "Build time: $(stat -c '%y' /proc/$PID/exe 2>/dev/null || echo 'Unknown')"
    echo "Binary size: $(du -h /proc/$PID/exe 2>/dev/null | cut -f1)"
else
    echo "✗ No portal process found!"
fi
echo ""

echo "3. BUILD ARTIFACTS"
echo "------------------"
if [[ -d "$APP_DIR/backend/target/release" ]]; then
    echo "Release binary exists: $(ls -lh $APP_DIR/backend/target/release/portal 2>/dev/null || echo 'Not found')"
    echo "Build timestamp: $(stat -c '%y' $APP_DIR/backend/target/release/portal 2>/dev/null || echo 'Unknown')"
else
    echo "✗ No build artifacts found!"
fi
echo ""

echo "4. ENVIRONMENT VARIABLES"
echo "------------------------"
if [[ -f "$APP_DIR/.env" ]]; then
    echo "NODE_ENV: $(grep NODE_ENV $APP_DIR/.env || echo 'Not set')"
    echo "CORS_ALLOWED_ORIGINS: $(grep CORS_ALLOWED_ORIGINS $APP_DIR/.env || echo 'Not set')"
    echo "BYPASS_AUTH: $(grep BYPASS_AUTH $APP_DIR/.env || echo 'Not set')"
else
    echo "✗ .env file not found!"
fi
echo ""

echo "5. CORS CONFIGURATION CHECK"
echo "---------------------------"
echo "Testing CORS headers from localhost..."
CORS_RESPONSE=$(curl -s -i -X OPTIONS "http://127.0.0.1:$BACKEND_PORT/api/portal/admin/tours/upload" \
  -H "Origin: http://www.robust-vtb.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type,authorization" \
  2>&1 | head -20)

if echo "$CORS_RESPONSE" | grep -q "Access-Control-Allow-Origin"; then
    echo "✓ CORS headers present:"
    echo "$CORS_RESPONSE" | grep -i "access-control" || true
else
    echo "✗ CORS headers NOT present!"
    echo "Response:"
    echo "$CORS_RESPONSE"
fi
echo ""

echo "6. HEALTH CHECK"
echo "---------------"
HEALTH=$(curl -s "http://127.0.0.1:$BACKEND_PORT/api/health" 2>&1)
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo "✓ Backend health check passed"
    echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"
else
    echo "✗ Backend health check FAILED"
    echo "$HEALTH"
fi
echo ""

echo "7. AUTHENTICATION CHECK"
echo "-----------------------"
echo "Testing /api/auth/me endpoint..."
AUTH_RESPONSE=$(curl -s "http://127.0.0.1:$BACKEND_PORT/api/auth/me" \
  -H "Authorization: Bearer dev-token" \
  2>&1)
echo "$AUTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$AUTH_RESPONSE"
echo ""

echo "8. RECENT SERVICE LOGS (last 50 lines)"
echo "--------------------------------------"
journalctl -u "$SERVICE_NAME" -n 50 --no-pager 2>/dev/null || echo "No logs available"
echo ""

echo "9. ERROR LOGS (last 24 hours)"
echo "-----------------------------"
journalctl -u "$SERVICE_NAME" --since "24 hours ago" -p err --no-pager 2>/dev/null || echo "No errors found"
echo ""

echo "10. DISK SPACE"
echo "--------------"
df -h "$APP_DIR" 2>/dev/null || df -h
echo ""

echo "11. UPLOAD ENDPOINT TEST"
echo "------------------------"
echo "Creating test multipart request..."
# Create a minimal test to see if endpoint responds
UPLOAD_TEST=$(curl -s -w "\nHTTP_CODE: %{http_code}" \
  -X POST "http://127.0.0.1:$BACKEND_PORT/api/portal/admin/tours/upload" \
  -H "Authorization: Bearer dev-token" \
  -F "title=Test Tour" \
  -F "zip=@/dev/null;type=application/zip" \
  2>&1)
echo "$UPLOAD_TEST"
echo ""

echo "========================================"
echo "Diagnostic Complete"
echo "========================================"
echo ""
echo "NEXT STEPS:"
echo "1. Check if CORS headers are present (section 5)"
echo "2. Verify binary timestamp matches your deployment (section 2-3)"
echo "3. Check for errors in logs (section 9)"
echo "4. Test upload endpoint response (section 11)"
echo ""
echo "If issues persist, share this output for further analysis."
