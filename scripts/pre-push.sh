#!/bin/bash
# Pre-Push Safety Check Script
# This script performs sanitization checks before pushing to remote.

echo "🔍 Starting Pre-Push Sanitization..."

# 1. Check for Large Files (>1MB)
echo "📦 Checking for large binaries..."
LARGE_FILES=$(find . -type f -not -path '*/.*' -not -path './node_modules/*' -not -path './backend/target/*' -not -path './dist/*' -size +1M)
if [ -n "$LARGE_FILES" ]; then
    echo "⚠️  Found files > 1MB:"
    echo "$LARGE_FILES"
    echo "   (Make sure these are intended assets and not accidental binaries)"
fi

# 2. Check for Production Constants
echo "⚙️  Verifying Production Constants in src/utils/Constants.res..."
if grep -q "debugEnabledDefault = true" src/utils/Constants.res; then
    echo "❌ Error: debugEnabledDefault is still true in Constants.res"
    exit 1
fi

# 3. Check for leftover test artifacts
echo "🧹 Checking for test artifacts..."
TEST_ARTIFACTS=$(find tests/unit -name "*.zip" -o -name "*.webp" -o -name "*.log")
if [ -n "$TEST_ARTIFACTS" ]; then
    echo "⚠️  Found leftover test artifacts in tests/unit:"
    echo "$TEST_ARTIFACTS"
    echo "   (Consider removing these before pushing)"
fi

# 4. Final Environment Check
echo "✅ Sanitization Complete."
echo "🚀 Recommendation: Run './scripts/commit.sh' one last time if you made changes here."
