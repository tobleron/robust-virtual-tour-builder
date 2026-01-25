#!/bin/bash

# Configuration
LIMIT=700
WATCH_DIRS="./src ./backend/src"
STATE_DIR="/tmp/project_guard"
mkdir -p "$STATE_DIR"

echo "👀 Project Guard Active: Monitoring Growth ($LIMIT lines), Tests & Structure..."

# Helper to get next Task ID
get_hints() {
    local file="$1"
    local hints=""
    
    if grep -q "Pannellum" "$file"; then
        hints="$hints\n- **Mock Pannellum**: This module interacts with Pannellum. Mock the global \`window.pannellum\` object in \`tests/node-setup.js\` or locally."
    fi
    if grep -q "FFmpeg" "$file"; then
        hints="$hints\n- **Mock FFmpeg**: This module uses FFmpeg. Ensure the FFmpeg core is mocked or its promises are resolved instantly."
    fi
    if grep -q "EventBus" "$file"; then
        hints="$hints\n- **EventBus Integration**: Use \`EventBus.dispatch\` spies to verify that actions are triggered correctly."
    fi
    if grep -q "Fetch" "$file" || grep -q "BackendApi" "$file"; then
        hints="$hints\n- **API Mocks**: Mock \`fetch\` and \`RequestQueue.schedule\`. Jules should verify that the correct endpoints are called with the expected payloads."
    fi
    if grep -q "Window" "$file" || grep -q "Dom" "$file"; then
        hints="$hints\n- **DOM/Window Bindings**: Use \`ReBindings\` to mock browser-specific properties like \`localStorage\`, \`location\`, or \`window.innerWidth\`."
    fi

    if [[ -n "$hints" ]]; then
        echo -e "\n## 💡 Implementation Hints for Cloud Agents (Jules)\n$hints"
    fi
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

    # Exception: Skip Version updates
    if [[ "$file_base" == "Version" ]]; then return; fi

    # 2. Check for Test Coverage (ReScript only for now, Rust has inline tests)
    if [[ "$file_ext" == "res" ]]; then
        local test_file_v="tests/unit/${file_base}_v.test.res"
        local test_file_dot="tests/unit/${file_base}.test.res"
        local test_file_classic="tests/unit/${file_base}Test.res"
        
        local test_found=false
        local actual_test_file=""

        if [[ -f "$test_file_v" ]]; then test_found=true; actual_test_file="$test_file_v"; fi
        if [[ "$test_found" == "false" ]] && [[ -f "$test_file_dot" ]]; then test_found=true; actual_test_file="$test_file_dot"; fi
        if [[ "$test_found" == "false" ]] && [[ -f "$test_file_classic" ]]; then test_found=true; actual_test_file="$test_file_classic"; fi

        if [[ "$test_found" == "false" ]]; then
            # Create Test Task if not already existing in any task directory
            if ! echo "$EXISTING_TASKS_CACHE" | grep -q "Test_${file_base}_New"; then
                local next_id=$(get_next_id)
                local task_path="tasks/pending/tests/${next_id}_Test_${file_base}_New.md"
                
                cat <<EOF > "$task_path"
# Task $next_id: Add Unit Tests for $filename

## 🚨 Trigger
Modifications detected in \`$file\` without established unit tests.

## Objective
Create a Vitest file \`tests/unit/${file_base}_v.test.res\` to cover logic in this module.

## Requirements
- Maintain code coverage for all exported functions.
- Follow /testing-standards.md.
$(get_hints "$file")
EOF
                echo "📝 Created Add Test Task: $task_path"
                EXISTING_TASKS_CACHE="$EXISTING_TASKS_CACHE\n$task_path"
            fi
        else
            # Test exists, check if it's STALE (Implementation is newer than Test)
            if [[ "$file" -nt "$actual_test_file" ]]; then
                if ! echo "$EXISTING_TASKS_CACHE" | grep -q "Test_${file_base}_Update"; then
                    local next_id=$(get_next_id)
                    local task_path="tasks/pending/tests/${next_id}_Test_${file_base}_Update.md"
                    
                    cat <<EOF > "$task_path"
# Task $next_id: Update Unit Tests for $filename

## 🚨 Trigger
Implementation file \`$file\` is newer than its test file \`$actual_test_file\`.

## Objective
Update \`$actual_test_file\` to ensure it covers recent changes in \`$filename\`.

## Requirements
- Review recent changes in \`$file\`.
- Update tests to maintain 100% coverage of new logic.
- Follow /testing-standards.md.
$(get_hints "$file")
EOF
                    echo "🔄 Created Update Test Task: $task_path"
                    EXISTING_TASKS_CACHE="$EXISTING_TASKS_CACHE\n$task_path"
                fi
            fi
        fi
    fi

    # 3. Check for File Size (Refactor)
    local count=$(wc -l < "$file" | xargs)
    if [[ "$count" -gt "$LIMIT" ]]; then
        if ! find tasks -name "*Refactor_${file_base}*" | grep -q .; then
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

check_structure() {
    local event_file="$1"
    # Trigger if a new file is created (ignoring temporary files)
    if [[ "$event_file" == *.res ]] || [[ "$event_file" == *.rs ]] || [[ "$event_file" == *.css ]]; then
        if ! find tasks -name "*Update_Codebase_Map*" | grep -q .; then
            local next_id=$(get_next_id)
            local task_path="tasks/pending/${next_id}_Update_Codebase_Map.md"
            
            cat <<EOF > "$task_path"
# Task $next_id: Synchronize Codebase Map (MAP.md)

## 🚨 Trigger
Directory structure change detected: \`$event_file\`.

## Objective
Update \`MAP.md\` to reflect the current project architecture. 
- Ensure the new module is added to its correct semantic group.
- Assign relevant #tags for pinpoint indexing.

## Verification
Verify \`MAP.md\` remains concise and accurate for AI context acquisition.
EOF
            echo "🗺️  Created Map Update Task: $task_path"
        fi
    fi
}

check_completed_tasks() {
    local completed_count=$(find tasks/completed -maxdepth 1 -name "*.md" | wc -l | xargs)
    if [[ "$completed_count" -gt 90 ]]; then
        if ! find tasks -name "*Aggregate_Completed_Tasks*" | grep -q .; then
            local next_id=$(get_next_id)
            local task_path="tasks/pending/${next_id}_Aggregate_Completed_Tasks.md"
            
            # Prepare the aggregation prompt
            cat <<EOF > "$task_path"
# Task $next_id: Aggregate Completed Tasks

## 🚨 Trigger
Completed tasks count exceeds 90 (Current: $completed_count).

## Objective
Aggregate the oldest 50 completed tasks into \`tasks/completed/_CONCISE_SUMMARY.md\` and cleanup.

## AI Prompt
"Please perform the following maintenance on the task system:
1. Identify the oldest 50 task files in \`tasks/completed/\` (based on their numerical prefix).
2. Read these 50 files and the existing \`tasks/completed/CONCISE_SUMMARY.md\` (or \`tasks/completed/_CONCISE_SUMMARY.md\`).
3. If \`tasks/completed/CONCISE_SUMMARY.md\` exists, rename it to \`tasks/completed/_CONCISE_SUMMARY.md\` to ensure it stays at the top.
4. Integrate the core accomplishments from these 50 tasks into \`tasks/completed/_CONCISE_SUMMARY.md\`, following its established style (categorized, bullet points, extremely concise).
5. After successful integration and verification, delete the 50 original task files from \`tasks/completed/\`.
6. Ensure the \`_CONCISE_SUMMARY.md\` remains the definitive high-level history of the project."
EOF
            echo "🧹 Created Maintenance Task: $task_path"
        fi
    fi
}

# Singleton Check
if pgrep -f "bash ./scripts/project-guard.sh" | grep -v $$ > /dev/null; then
    echo "❌ Project Guard is already running."
    exit 1
fi

# 1. Initial Scan
echo "🔍 Performing initial baseline check..."
check_completed_tasks
# Cache existing tasks to avoid expensive 'find' calls in a loop
EXISTING_TASKS_CACHE=$(find tasks -type f)

check_file_fast() {
    local file="$1"
    if [[ ! -f "$file" ]]; then return; fi
    if [[ "$file" == *.bs.js ]] || [[ "$file" == */libs/* ]]; then return; fi
    if [[ "$file" != *.res ]] && [[ "$file" != *.rs ]] && [[ "$file" != *.js ]]; then return; fi

    local filename=$(basename "$file")
    local file_base="${filename%.*}"
    local file_ext="${filename##*.}"

    # Exception: Skip Version updates
    if [[ "$file_base" == "Version" ]]; then return; fi

    if [[ "$file_ext" == "res" ]]; then
        local test_found=false
        local actual_test_file=""
        if [[ -f "tests/unit/${file_base}_v.test.res" ]]; then test_found=true; actual_test_file="tests/unit/${file_base}_v.test.res"; fi
        if [[ "$test_found" == "false" ]] && [[ -f "tests/unit/${file_base}.test.res" ]]; then test_found=true; actual_test_file="tests/unit/${file_base}.test.res"; fi
        if [[ "$test_found" == "false" ]] && [[ -f "tests/unit/${file_base}Test.res" ]]; then test_found=true; actual_test_file="tests/unit/${file_base}Test.res"; fi

        if [[ "$test_found" == "false" ]]; then
            if ! echo "$EXISTING_TASKS_CACHE" | grep -q "Test_${file_base}_New"; then
                check_file "$file" 
            fi
        else
            # Test exists, check if it's STALE
            if [[ "$file" -nt "$actual_test_file" ]]; then
                if ! echo "$EXISTING_TASKS_CACHE" | grep -q "Test_${file_base}_Update"; then
                    check_file "$file"
                fi
            fi
        fi
    fi

    local count=$(wc -l < "$file" | xargs)
    if [[ "$count" -gt "$LIMIT" ]]; then
        if ! echo "$EXISTING_TASKS_CACHE" | grep -q "Refactor_${file_base}"; then
            check_file "$file"
        fi
    fi
}

while read -r f; do
    check_file_fast "$f"
done < <(find $WATCH_DIRS -type f)

# 2. Watch loop
if [[ "$1" == "--scan-only" ]]; then
    echo "✅ Scan complete. Exiting."
    exit 0
fi

if command -v fswatch >/dev/null; then
    echo "⚡ Project Guard watching for modifications..."
    # fswatch output is absolute or relative based on inputs. 
    # Using relative paths for inputs should give relative outputs.
    fswatch --event Updated --event Created --event Removed -e ".*\.git.*" $WATCH_DIRS | while read -r event_file; do
        if [[ -f "$event_file" ]]; then
            check_file "$event_file"
        fi
        check_structure "$event_file"
        check_completed_tasks
    done
else
    echo "❌ fswatch not found. Project Guard limited to one-time scan."
    echo "💡 Suggestion: 'brew install fswatch' for real-time monitoring."
fi
