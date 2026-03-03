#!/bin/bash
# USAGE: ./scripts/commit.sh "feat: Description" [target-branch] [bump-override]
# Default target-branch is 'development'.
# Optional third argument: 'major', 'minor', 'patch' to override auto-detection.

MSG="$1"

if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

add_commit_files() {
    if [ "${INCLUDE_DEV_SYSTEM:-0}" = "1" ]; then
        git add .
    else
        git add . ':(exclude)_dev-system/plans/**' ':(exclude)tasks/pending/dev_tasks/**'
    fi
}

add_intent_files() {
    if [ "${INCLUDE_DEV_SYSTEM:-0}" = "1" ]; then
        git add -N .
    else
        git add -N . ':(exclude)_dev-system/plans/**' ':(exclude)tasks/pending/dev_tasks/**'
    fi
}

CURRENT_BRANCH=$(git branch --show-current)
TARGET_BRANCH="${2:-development}"

if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
    echo "❌ Wrong Branch: Target is '$TARGET_BRANCH' but current is '$CURRENT_BRANCH'."
    echo "   ► To commit to this branch, use: ./scripts/commit.sh \"$MSG\" $CURRENT_BRANCH"
    exit 1
fi

# 1.5 Project Guard (Static Analysis)
./scripts/project-guard.sh

# 2. Versioning (Smart Detection)
BUMP_REQUEST="${3:-$MSG}"
echo "📈 Processing versioning..."
node scripts/bump-version.js "$BUMP_REQUEST"
node scripts/update-version.js
node scripts/sync-sw.cjs
NEW_VER=$(node -p "require('./package.json').version")
BUILD_NUM=$(node -p "require('./package.json').buildNumber")
FULL_VER="${NEW_VER}+${BUILD_NUM}"

# 3. Cache Busting
# Already handled by update-version.js above

# 4. Auto-Format
echo "🎨 Formatting Code..."
npm run format

# 5. Build Verification (Zero Warning Policy)
echo "🔨 Verifying Build (Strict Mode)..."
npm run res:clean > /dev/null
# Set intent to add so detect-missing-tests sees internal changes
add_intent_files
if ! ./node_modules/.bin/rescript build --warn-error "+a"; then 
    echo "❌ Build failed or contains warnings."; 
    # Cleanup intent to add on failure so we don't leave the repo in a weird state
    git reset > /dev/null
    exit 1; 
fi

# 6. Test Gap Detection (Optional/Bypassed)
# echo "🔍 Checking for test gaps..."
# node scripts/detect-missing-tests.cjs || echo "⚠️  Warning: Missing unit tests detected (Bypassing block as per user preference)"


# 7. Test Verification (Skipped for speed)
echo "🧪 Skipping Tests (Run manually if needed)..."

# 8. Update Documentation
echo "📝 Updating Documentation (README & Changelog)..."
node scripts/update-changelog.js "$MSG"
node scripts/update-readme.js

# 9. Log & Commit
echo "[$(date '+%Y-%m-%d %H:%M')] v$NEW_VER - $MSG" >> logs/log_changes.txt
rm -f logs/telemetry.log
add_commit_files
git commit -m "v$FULL_VER: $MSG"
echo "✅ Committed v$FULL_VER"

# 10. Push to Remote
echo "🚀 Pushing to origin/$CURRENT_BRANCH..."
git push origin "$CURRENT_BRANCH"
echo "✅ Push Complete."
