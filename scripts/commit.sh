#!/bin/bash
# USAGE: ./scripts/commit.sh "feat: Description" [bump-override]
# RESTRICTION: Only runs on 'development' branch.
# Optional second argument: 'major', 'minor', 'patch' to override auto-detection.

MSG="$1"

if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "development" ]; then
    echo "❌ Wrong Branch: Standard commits are restricted to 'development'."
    echo "   ► Current branch: $CURRENT_BRANCH"
    echo "   ► Switch branches: git checkout development"
    exit 1
fi

# 1.5 Project Guard (Static Analysis)
./scripts/project-guard.sh

# 2. Versioning (Smart Detection)
BUMP_REQUEST="${2:-$MSG}"
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
git add -N .
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
git add .
git commit -m "v$FULL_VER: $MSG"
echo "✅ Committed v$FULL_VER"

# 10. Push to Remote
echo "🚀 Pushing to origin/$CURRENT_BRANCH..."
git push origin "$CURRENT_BRANCH"
echo "✅ Push Complete."
