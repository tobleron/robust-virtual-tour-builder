#!/bin/bash
WATCH_DIRS="./src ./backend/src"
echo "Checking for implementation files newer than their tests..."

get_next_id() {
    local last_id=$(find tasks -type f -name "[0-9]*_*.md" -exec basename {} \; | cut -d_ -f1 | sort -n | tail -n 1)
    if [[ -z "$last_id" ]]; then last_id=0; fi
    echo $((last_id + 1))
}

EXISTING_TASKS_CACHE=$(find tasks -type f)

find $WATCH_DIRS -type f | while read -r file; do
    if [[ "$file" == *.bs.js ]] || [[ "$file" == */libs/* ]]; then continue; fi
    if [[ "$file" != *.res ]]; then continue; fi

    filename=$(basename "$file")
    file_base="${filename%.*}"
    
    test_file_v="tests/unit/${file_base}_v.test.res"
    test_file_dot="tests/unit/${file_base}.test.res"
    test_file_classic="tests/unit/${file_base}Test.res"
    
    actual_test_file=""
    if [[ -f "$test_file_v" ]]; then actual_test_file="$test_file_v";
    elif [[ -f "$test_file_dot" ]]; then actual_test_file="$test_file_dot";
    elif [[ -f "$test_file_classic" ]]; then actual_test_file="$test_file_classic"; fi

    if [[ -n "$actual_test_file" ]]; then
        if [[ "$file" -nt "$actual_test_file" ]]; then
            echo "STALE: $file is newer than $actual_test_file"
            if ! echo "$EXISTING_TASKS_CACHE" | grep -q "Update_Tests_${file_base}"; then
                echo "  -> Task needed for $file_base"
            fi
        fi
    fi
done
