#!/bin/bash
# USAGE: ./scripts/fast-commit.sh "feat: Description"
MSG="$1"

if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

# 0. Project Guard (Quick Check)
echo "🛡️  Running Project Guard..."
node scripts/guard/index.js

# 1. Versioning (Semantic Bump + Build Increment)
BUMP_TYPE="${2:-none}"
if [ "$BUMP_TYPE" != "none" ]; then
    echo "📈 Bumping version: $BUMP_TYPE"
    node scripts/bump-version.js "$BUMP_TYPE"
fi

echo "🔢 Incrementing build..."
node scripts/increment-build.js
node scripts/update-version.js

NEW_VER=$(node -p "require('./package.json').version")
BUILD_NUM=$(node -p "require('./package.json').buildNumber")
FULL_VER="${NEW_VER}+${BUILD_NUM}"

# 2. Changelog (Maintain history)
echo "📝 Updating Changelog..."
node scripts/update-changelog.js "$MSG"

# 3. Commit
git add .
git commit -m "v$FULL_VER [FAST]: $MSG"
echo "🚀 Fast-Committed v$FULL_VER"
