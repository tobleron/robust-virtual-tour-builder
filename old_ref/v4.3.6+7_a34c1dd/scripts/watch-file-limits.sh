#!/bin/bash

LIMIT=700
WATCH_DIRS="./src ./backend/src"

echo "👀 Starting File Growth Sentinel (Limit: $LIMIT lines)..."

check_file() {
    local file="$1"
    
    # Ignore directories and non-existent files
    if [[ ! -f "$file" ]]; then return; fi

    # Filter: Only source files, exclude compiled/libs
    if [[ "$file" == *.bs.js ]] || [[ "$file" == */libs/* ]]; then return; fi
    if [[ "$file" != *.res ]] && [[ "$file" != *.rs ]] && [[ "$file" != *.js ]]; then return; fi

    # Count lines
    local count=$(wc -l < "$file" | xargs)
    
    if [[ "$count" -gt "$LIMIT" ]]; then
        local filename=$(basename "$file")
        local file_base="${filename%.*}"
        
        # Check if active task already exists in pending (case-insensitive check)
        if ls tasks/pending/*Refactor_${file_base}* 1> /dev/null 2>&1; then
            return
        fi
        
        echo "⚠️  $filename exceeds $LIMIT lines ($count lines). Generating task..."
        
        # Calculate next ID from both pending and completed
        local last_id=$(ls tasks/pending tasks/completed | grep -E '^[0-9]+_' | sort -V | tail -n 1 | cut -d_ -f1)
        if [[ -z "$last_id" ]]; then last_id=0; fi
        local next_id=$((last_id + 1))
        
        local task_file="tasks/pending/${next_id}_Refactor_${file_base}.md"
        
        # Create Task Content
        cat <<EOF > "$task_file"
# Task $next_id: Refactor $filename

## 🚨 Trigger
This task was automatically generated because \`$file\` exceeded **$LIMIT lines** (Current: $count).

## Objective
Refactor \`$filename\` to reduce complexity and file size below $LIMIT lines.

## Guidelines
1. Identify distinct responsibilities in the module.
2. Extract sub-modules or helper files.
3. Ensure no logic or functionality is lost.
4. Verify tests pass after refactoring.

## Context
- File: \`$file\`
- Size: $count lines
EOF
        
        echo "✅ Created task: $task_file"
    fi
}

# 1. Initial Scan
echo "🔍 Performing initial size check..."
find $WATCH_DIRS -type f | while read -r f; do
    check_file "$f"
done

# 2. Watch loop
if command -v fswatch >/dev/null; then
    echo "⚡ Watching for changes..."
    fswatch --event Updated --event Created -e ".*\.git.*" $WATCH_DIRS | while read -r event_file; do
        check_file "$event_file"
    done
else
    echo "❌ fswatch not found. Sentinel disabled."
fi
