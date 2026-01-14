#!/bin/bash
# USAGE: ./scripts/commit.sh "feat: Description"
MSG="$1"
if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

# 1. Preference Guard (Only check modified files in src)
CHANGED_SRC=$(git status --porcelain | awk '{print $2}' | grep "^src/" | grep -v "libs/" | grep -v ".bs.js")
if [ -n "$CHANGED_SRC" ]; then
    if echo "$CHANGED_SRC" | xargs grep -Ff .agent/forbidden_patterns.txt; then
        echo "❌ Forbidden patterns detected in modified files."; exit 1
    fi
fi

# 2. Context Refresh (Anti-Hallucination)
echo "🗺️  Refreshing file structure map..."
tree -I "node_modules|target|.git|dist|.agent/workflows" > .agent/current_file_structure.md

# 3. Versioning (Auto-increment Patch)
npm version patch --no-git-tag-version
NEW_VER=$(node -p "require('./package.json').version")

# 4. Cache Busting
sed -i '' "s/v=[0-9.]*/v=$NEW_VER/g" index.html

# 5. Build Verification
echo "🔨 Verifying Build..."
if ! npm run res:build; then echo "❌ Build failed."; exit 1; fi

# 6. Log & Commit
echo "[$(date '+%Y-%m-%d %H:%M')] v$NEW_VER - $MSG" >> logs/log_changes.txt
rm -f logs/telemetry.log
git add .
git commit -m "v$NEW_VER: $MSG"
echo "✅ Committed v$NEW_VER"
