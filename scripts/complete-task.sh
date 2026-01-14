#!/bin/bash

# Define directories
PENDING_DIR="tasks/pending"
COMPLETED_DIR="tasks/completed"

# Ensure directories exist
mkdir -p "$COMPLETED_DIR"

# 1. Select Task
# If argument provided, use it. Otherwise, look for the most recently modified file in pending.
if [ -z "$1" ]; then
    TASK_FILE=$(ls -t "$PENDING_DIR"/*.md 2>/dev/null | head -n 1)
else
    TASK_FILE="$1"
fi

if [ -z "$TASK_FILE" ]; then
    echo "❌ No pending tasks found."
    exit 1
fi

BASENAME=$(basename "$TASK_FILE" .md)
echo "📝 Completing task: $BASENAME"

# 2. Get Summary
echo ""
echo "Enter a brief completion summary (Press Enter to open editor, or type here):"
read -r SUMMARY

if [ -z "$SUMMARY" ]; then
    TMP_MSG="/tmp/task_summary_$$"
    echo "# Task Completion: $BASENAME" > "$TMP_MSG"
    echo "" >> "$TMP_MSG"
    echo "Describe what was accomplished, changed, and any next steps." >> "$TMP_MSG"
    ${EDITOR:-nano} "$TMP_MSG"
    SUMMARY=$(cat "$TMP_MSG" | grep -v "^#")
    rm "$TMP_MSG"
fi

if [ -z "$SUMMARY" ]; then
    echo "❌ completion aborted (empty summary)."
    exit 1
fi

# 3. Transform Content
# We append the completion report to the file content
REPORT_FILE="$COMPLETED_DIR/${BASENAME}_REPORT.md"

{
    echo "---"
    echo "status: completed"
    echo "completed_at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
    echo ""
    echo "# COMPLETED TASK REPORT"
    echo ""
    echo "## Summary"
    echo "$SUMMARY"
    echo ""
    echo "## Original Task Content"
    cat "$TASK_FILE"
} > "$REPORT_FILE"

# 4. Cleanup
rm "$TASK_FILE"

echo "✅ Task moved to: $REPORT_FILE"
