#!/bin/bash

# Configuration
LIMIT=700
WATCH_DIRS="./src ./backend/src"
STATE_DIR="/tmp/remax_sentinel"
mkdir -p "$STATE_DIR"

echo "👀 REMAX Sentinel Active: Monitoring Growth ($LIMIT lines) & Test Coverage..."

# Helper to get next Task ID
get_next_id() {
    local last_id=$(ls tasks/pending tasks/completed tasks/postponed 2>/dev/null | grep -E '^[0-9]+_' | sort -V | tail -n 1 | cut -d_ -f1)
    if [[ -z "$last_id" ]]; then last_id=0; fi
    echo $((last_id + 1))
}

check_file() {
    local file="$1"
    
    # 1. Basic Filters
    if [[ ! -f "$file" ]]; then return; fi
    if [[ "$file" == *.bs.js ]] || [[ "$file" == */libs/* ]]; then return; fi
    if [[ "$file" != *.res ]] && [[ "$file" != *.rs ]] && [[ "$file" != *.js ]]; then return; fi

    local filename=$(basename "$file")
    local file_base="${filename%.*}"
    local file_ext="${filename##*.}"

    # 2. Check for Test Coverage (ReScript only for now, Rust has inline tests)
    if [[ "$file_ext" == "res" ]]; then
        local test_file_v="tests/unit/${file_base}_v.test.res"
        local test_file_dot="tests/unit/${file_base}.test.res"
        local test_file_classic="tests/unit/${file_base}Test.res"
        
        if [[ ! -f "$test_file_v" ]] && [[ ! -f "$test_file_dot" ]] && [[ ! -f "$test_file_classic" ]]; then
            # Create Test Task if not already existing
            if ! ls tasks/pending/*Test_${file_base}* tasks/postponed/tests/*Test_${file_base}* 1> /dev/null 2>&1; then
                local next_id=$(get_next_id)
                local task_path="tasks/pending/${next_id}_Test_${file_base}.md"
                
                cat <<EOF > "$task_path"
# Task $next_id: Add Unit Tests for $filename

## 🚨 Trigger
Modifications detected in \`$file\` without established unit tests.

## Objective
Create a Vitest file \`tests/unit/${file_base}_v.test.res\` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.
EOF
                echo "📝 Created Test Task: $task_path"
            fi
        fi
    fi

    # 3. Check for File Size (Refactor)
    local count=$(wc -l < "$file" | xargs)
    if [[ "$count" -gt "$LIMIT" ]]; then
        if ! ls tasks/pending/*Refactor_${file_base}* 1> /dev/null 2>&1; then
            local next_id=$(get_next_id)
            local task_path="tasks/pending/${next_id}_Refactor_${file_base}.md"
            
            cat <<EOF > "$task_path"
# Task $next_id: Refactor $filename (Oversized)

## 🚨 Trigger
File \`$file\` exceeds **$LIMIT lines** (Current: $count).

## Objective
Decompose \`$filename\` into smaller, focused modules. Aim for < 400 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze $file. It has $count lines. Extract the core logic into new specialized modules (e.g. ${file_base}Types.res, ${file_base}Logic.res) while keeping the main module as a lightweight facade."
EOF
            echo "⚠️  Created Refactor Task: $task_path"
        fi
    fi
}

# 1. Initial Scan
echo "🔍 Performing initial baseline check..."
find $WATCH_DIRS -type f | while read -r f; do
    check_file "$f"
done

# 2. Watch loop
if command -v fswatch >/dev/null; then
    echo "⚡ Sentinel watching for modifications..."
    # fswatch output is absolute or relative based on inputs. 
    # Using relative paths for inputs should give relative outputs.
    fswatch --event Updated --event Created -e ".*\.git.*" $WATCH_DIRS | while read -r event_file; do
        check_file "$event_file"
    done
else
    echo "❌ fswatch not found. Sentinel limited to one-time scan."
    echo "💡 Suggestion: 'brew install fswatch' for real-time monitoring."
fi
