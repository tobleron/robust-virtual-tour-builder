#!/bin/bash
# USAGE: ./scripts/commit.sh "feat: Description"
MSG="$1"
if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

# 1. Preference Guard (Only check modified files in src, excluding templates)
CHANGED_SRC=$(git status --porcelain | awk '{print $2}' | grep "^src/" | grep -v "libs/" | grep -v ".bs.js" | grep -v "Template")
if [ -n "$CHANGED_SRC" ]; then
    if echo "$CHANGED_SRC" | xargs grep -Ff .agent/forbidden_patterns.txt; then
        echo "❌ Forbidden patterns detected in modified files."; exit 1
    fi
fi

# 2. Context Refresh (Anti-Hallucination)
echo "🗺️  Refreshing file structure map..."
tree -I "node_modules|target|.git|dist|.agent/workflows" > .agent/current_file_structure.md

# 3. Versioning (Increment Build Number)
node scripts/increment-build.js
node scripts/update-version.js
node scripts/sync-sw.cjs
NEW_VER=$(node -p "require('./package.json').version")
BUILD_NUM=$(node -p "require('./package.json').buildNumber")
FULL_VER="${NEW_VER}+${BUILD_NUM}"

# 4. Cache Busting
# Already handled by update-version.js above

# 5. Auto-Format
echo "🎨 Formatting Code..."
npm run format

# 6. Build Verification (Zero Warning Policy)
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

# 7. Test Gap Detection
if ! node scripts/detect-missing-tests.js; then
    echo "❌ Commit blocked: Missing unit tests detected."
    echo "   ► Tasks have been auto-generated in tasks/pending/"
    echo "   ► Please complete these tasks before committing."
    git reset > /dev/null
    exit 1
fi

# 8. Test Verification
echo "🧪 Running Tests..."
if ! npm test; then echo "❌ Tests failed."; exit 1; fi

# 9. Log & Commit
echo "[$(date '+%Y-%m-%d %H:%M')] v$NEW_VER - $MSG" >> logs/log_changes.txt
rm -f logs/telemetry.log
git add .
git commit -m "v$FULL_VER: $MSG"
echo "✅ Committed v$FULL_VER"
