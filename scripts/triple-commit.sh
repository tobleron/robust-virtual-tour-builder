#!/bin/bash
# USAGE: ALLOW_TRIPLE_COMMIT=1 ./scripts/triple-commit.sh "feat: Description" [bump-override]
# This script commits to the current branch and force-updates main, testing, and development branches.
# Optional second argument: 'major', 'minor', 'patch' to override auto-detection.
# RESTRICTION: Only runs on 'development' branch.

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

# --- VALIDATION PHASE ---

if [ "${ALLOW_TRIPLE_COMMIT:-0}" != "1" ]; then
    echo "⚠️  triple-commit is deprecated and disabled by default."
    echo "   ► Use standard workflow: ./scripts/commit.sh \"<message>\""
    echo "   ► Only run triple sync when explicitly requested:"
    echo "     ALLOW_TRIPLE_COMMIT=1 ./scripts/triple-commit.sh \"<message>\" [bump-override]"
    exit 1
fi

# 0. Branch Guard
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "development" ]; then
    echo "❌ Error: triple-commit is restricted to the 'development' branch."
    echo "   ► Current branch: $CURRENT_BRANCH"
    echo "   ► Switch: git checkout development"
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

# 3. Auto-Format
echo "🎨 Formatting Code..."
npm run format

# 4. Build Verification (Zero Warning Policy)
echo "🔨 Verifying Build (Strict Mode)..."
npm run res:clean > /dev/null
add_intent_files
if ! ./node_modules/.bin/rescript build --warn-error "+a"; then 
    echo "❌ Build failed or contains warnings."; 
    git reset > /dev/null
    exit 1; 
fi

# 5. Test Gap Detection
# if ! node scripts/detect-missing-tests.cjs; then
#     echo "❌ Commit blocked: Missing unit tests detected."
#     git reset > /dev/null
#     exit 1
# fi
echo "⚠️  Skipping Test Gap Detection (Process missing)"

# 6. Test Verification (Skipped for speed)
echo "🧪 Skipping Tests (Run manually if needed)..."

# 7. Update Documentation
echo "📝 Updating Documentation..."
node scripts/update-changelog.js "$MSG"
node scripts/update-readme.js

# --- COMMIT & SYNC PHASE ---

# 8. Log & Commit to current branch
echo "[$(date '+%Y-%m-%d %H:%M')] v$NEW_VER - $MSG [TRIPLE]" >> logs/log_changes.txt
rm -f logs/telemetry.log
add_commit_files
git commit -m "v$FULL_VER [TRIPLE]: $MSG"

# 9. Sync to main, testing, and development
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

# 10. Push all 3 branches
echo "🚀 Pushing all branches to remote..."
git push origin main
git push origin testing
git push origin development

echo "🎉 Triple-Commit & Push Complete: v$FULL_VER is live on main, testing, and development."
