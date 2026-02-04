#!/bin/bash
# USAGE: ./scripts/fast-commit.sh "feat: Description"
MSG="$1"

if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

# 0. Branch Guard
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "development" ]; then
    echo "❌ Error: fast-commit is restricted to the 'development' branch."
    echo "   ► Current branch: $CURRENT_BRANCH"
    echo "   ► Switch: git checkout development"
    exit 1
fi

# 0.5 Project Guard (Quick Check)
./scripts/project-guard.sh

# 1. Versioning (Smart Detection)
BUMP_REQUEST="${2:-$MSG}"
echo "📈 Processing versioning..."
node scripts/bump-version.js "$BUMP_REQUEST"
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
