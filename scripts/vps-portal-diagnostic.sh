#!/bin/bash
# Quick Portal Upload Diagnostic - Run on VPS
# Usage: ssh root@164.90.242.73 "bash -s" < scripts/vps-portal-diagnostic.sh

set -euo pipefail

echo "=== PORTAL UPLOAD DIAGNOSTIC ==="
echo ""

# 1. Check running binary
echo "1. RUNNING BINARY CHECK"
echo "----------------------"
PID=$(pgrep -f "portal" | head -1 || echo "")
if [[ -n "$PID" ]]; then
    echo "✓ Portal process running (PID: $PID)"
    BINARY_PATH=$(readlink -f /proc/$PID/exe)
    echo "Binary: $BINARY_PATH"
    echo "Build time: $(stat -c '%Y %y' /proc/$PID/exe)"
    echo "Binary size: $(du -h /proc/$PID/exe | cut -f1)"
    
    # Check if binary is newer than deployment
    APP_DIR="/opt/robust-vtb/current"
    if [[ -f "$APP_DIR/backend/target/release/portal" ]]; then
        DEPLOY_BINARY_TIME=$(stat -c '%Y' "$APP_DIR/backend/target/release/portal")
        RUNNING_BINARY_TIME=$(stat -c '%Y' /proc/$PID/exe)
        echo ""
        if [[ "$DEPLOY_BINARY_TIME" -gt "$RUNNING_BINARY_TIME" ]]; then
            echo "⚠ WARNING: Deployed binary is NEWER than running binary!"
            echo "You need to restart the service."
        else
            echo "✓ Running binary matches deployed binary"
        fi
    fi
else
    echo "✗ Portal process NOT running!"
fi
echo ""

# 2. Check service status
echo "2. SERVICE STATUS"
echo "-----------------"
systemctl is-active robust-vtb-portal && echo "✓ Service active" || echo "✗ Service inactive"
echo ""

# 3. Check .env file
echo "3. ENVIRONMENT CONFIG"
echo "---------------------"
APP_DIR="/opt/robust-vtb/current"
if [[ -f "$APP_DIR/.env" ]]; then
    NODE_ENV=$(grep "^NODE_ENV=" "$APP_DIR/.env" | cut -d'=' -f2)
    CORS=$(grep "^CORS_ALLOWED_ORIGINS=" "$APP_DIR/.env" | cut -d'=' -f2)
    echo "NODE_ENV: $NODE_ENV"
    echo "CORS_ALLOWED_ORIGINS: $CORS"
    
    # Check if www.robust-vtb.com is in CORS list
    if echo "$CORS" | grep -q "www.robust-vtb.com"; then
        echo "✓ CORS includes www.robust-vtb.com"
    else
        echo "✗ CORS does NOT include www.robust-vtb.com - THIS IS THE ISSUE!"
    fi
else
    echo "✗ .env file not found in $APP_DIR"
fi
echo ""

# 4. Test CORS
echo "4. CORS HEADER TEST"
echo "-------------------"
echo "Testing OPTIONS request..."
CORS_TEST=$(curl -s -i -X OPTIONS "http://127.0.0.1:8080/api/portal/admin/tours/upload" \
  -H "Origin: http://www.robust-vtb.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type,authorization" \
  2>&1 | head -15)

if echo "$CORS_TEST" | grep -qi "access-control-allow-origin"; then
    echo "✓ CORS headers present:"
    echo "$CORS_TEST" | grep -i "access-control" || true
else
    echo "✗ CORS headers MISSING!"
    echo "Full response:"
    echo "$CORS_TEST"
fi
echo ""

# 5. Health check
echo "5. BACKEND HEALTH"
echo "-----------------"
HEALTH=$(curl -s "http://127.0.0.1:8080/api/health" 2>&1)
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo "✓ Backend healthy"
else
    echo "✗ Backend health check failed:"
    echo "$HEALTH"
fi
echo ""

# 6. Test upload endpoint (without actual file)
echo "6. UPLOAD ENDPOINT TEST"
echo "-----------------------"
echo "Testing with empty request..."
UPLOAD_TEST=$(curl -s -w "\n\nHTTP_CODE: %{http_code}" \
  -X POST "http://127.0.0.1:8080/api/portal/admin/tours/upload" \
  -H "Authorization: Bearer dev-token" \
  -F "title=" \
  -F "zip=@/dev/null" \
  2>&1)
echo "$UPLOAD_TEST"
echo ""

# 7. Recent errors
echo "7. RECENT ERRORS (last 20)"
echo "--------------------------"
journalctl -u robust-vtb-portal -n 20 --no-pager -p err 2>/dev/null || echo "No errors found"
echo ""

# 8. Check if build completed
echo "8. BUILD STATUS"
echo "---------------"
if [[ -f /tmp/cargo-build.log ]]; then
    echo "Last build log exists"
    COMPILE_COUNT=$(grep -c "Compiling" /tmp/cargo-build.log || echo "0")
    FRESH_COUNT=$(grep -c "Fresh" /tmp/cargo-build.log || echo "0")
    echo "Compiling messages: $COMPILE_COUNT"
    echo "Fresh messages: $FRESH_COUNT"
    
    if [[ "$COMPILE_COUNT" -gt 50 ]]; then
        echo "⚠ Large number of compilations - full rebuild occurred"
    else
        echo "✓ Incremental build detected"
    fi
else
    echo "No build log found at /tmp/cargo-build.log"
fi
echo ""

echo "=== DIAGNOSTIC COMPLETE ==="
echo ""
echo "QUICK FIX COMMANDS:"
echo "------------------"
echo "1. If CORS is missing, update .env and restart:"
echo "   cd /opt/robust-vtb/current"
echo "   echo 'CORS_ALLOWED_ORIGINS=http://www.robust-vtb.com,https://www.robust-vtb.com' >> .env"
echo "   systemctl restart robust-vtb-portal"
echo ""
echo "2. If binary is old, restart service:"
echo "   systemctl restart robust-vtb-portal"
echo ""
echo "3. Check live logs during upload:"
echo "   journalctl -u robust-vtb-portal -f"
