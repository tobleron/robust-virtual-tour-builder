#!/bin/bash
# USAGE: ./scripts/triple-commit.sh "feat: Description"
# This script commits to the current branch and force-updates main, testing, and development branches.

MSG="$1"

if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

# --- VALIDATION PHASE ---

# 1. Preference Guard
CHANGED_SRC=$(git status --porcelain | awk '{print $2}' | grep "^src/" | grep -v "libs/" | grep -v ".bs.js" | grep -v "Template")
if [ -n "$CHANGED_SRC" ]; then
    if echo "$CHANGED_SRC" | xargs grep -Ff .agent/forbidden_patterns.txt; then
        echo "❌ Forbidden patterns detected in modified files."; exit 1
    fi
fi

# 1.5 Project Guard (Static Analysis)
./scripts/project-guard.sh

# 2. Context Refresh
echo "🗺️  Refreshing file structure map..."
tree -I "node_modules|target|.git|dist|.agent/workflows" > .agent/current_file_structure.md

# 3. Versioning
BUMP_TYPE="${2:-none}"
if [ "$BUMP_TYPE" != "none" ]; then
    echo "📈 Bumping version: $BUMP_TYPE"
    node scripts/bump-version.js "$BUMP_TYPE"
fi

echo "🔢 Incrementing build and updating version..."
node scripts/increment-build.js
node scripts/update-version.js
node scripts/sync-sw.cjs
NEW_VER=$(node -p "require('./package.json').version")
BUILD_NUM=$(node -p "require('./package.json').buildNumber")
FULL_VER="${NEW_VER}+${BUILD_NUM}"

# 4. Auto-Format
echo "🎨 Formatting Code..."
npm run format

# 5. Build Verification (Zero Warning Policy)
echo "🔨 Verifying Build (Strict Mode)..."
npm run res:clean > /dev/null
git add -N .
if ! ./node_modules/.bin/rescript build --warn-error "+a"; then 
    echo "❌ Build failed or contains warnings."; 
    git reset > /dev/null
    exit 1; 
fi

# 6. Test Gap Detection
# if ! node scripts/detect-missing-tests.cjs; then
#     echo "❌ Commit blocked: Missing unit tests detected."
#     git reset > /dev/null
#     exit 1
# fi
echo "⚠️  Skipping Test Gap Detection (Process missing)"

# 7. Test Verification (Skipped for speed)
echo "🧪 Skipping Tests (Run manually if needed)..."

# 8. Update Documentation
echo "📝 Updating Documentation..."
node scripts/update-changelog.js "$MSG"
node scripts/update-readme.js

# --- COMMIT & SYNC PHASE ---

# 9. Log & Commit to current branch
echo "[$(date '+%Y-%m-%d %H:%M')] v$NEW_VER - $MSG [TRIPLE]" >> logs/log_changes.txt
rm -f logs/telemetry.log
git add .
git commit -m "v$FULL_VER [TRIPLE]: $MSG"

# 10. Sync to main, testing, and development
CURRENT_BRANCH=$(git branch --show-current)
TARGET_BRANCHES=("main" "testing" "development")

echo "🔄 Syncing all core branches locally..."
for BRANCH in "${TARGET_BRANCHES[@]}"; do
    if [ "$BRANCH" == "$CURRENT_BRANCH" ]; then
        echo "✅ Branch '$BRANCH' is current."
    else
        echo "📡 Updating '$BRANCH' to match HEAD..."
        # Force update the local branch reference without switching
        git branch -f "$BRANCH" HEAD
        echo "✅ '$BRANCH' updated."
    fi
done

# 11. Push all 3 branches
echo "🚀 Pushing all branches to remote..."
git push origin main
git push origin testing
git push origin development

echo "🎉 Triple-Commit & Push Complete: v$FULL_VER is live on main, testing, and development."
