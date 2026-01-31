#!/bin/bash
# scripts/tail-diagnostics.sh
# Tail and format diagnostic logs (Frontend + Backend)

LOG_FILE="logs/diagnostic.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Creating log file..."
    mkdir -p logs
    touch "$LOG_FILE"
fi

echo "🔍 Tailing $LOG_FILE in Diagnostic Mode..."
echo "Press Ctrl+C to stop."

tail -f "$LOG_FILE" | jq -R -r '
  try (
    fromjson | 
    (
      if .timestampMs then
        # Raw Frontend Log (Legacy or direct)
        "[\(.timestamp | .[11:19])] \u001b[36mFRONTEND\u001b[0m [\(.level | ascii_upcase)] \u001b[35m\(.module)\u001b[0m \(.message) " + 
        (if .requestId then "\u001b[90m[\(.requestId)]\u001b[0m" else "" end) +
        (if .data then "\n    \u001b[90m\(.data)\u001b[0m" else "" end)
      elif .target == "frontend" then
        # Unified Frontend Log (Via Backend Tracing)
        "[\(.timestamp | .[11:19])] \u001b[36mFRONTEND\u001b[0m [\(.level | ascii_upcase)] \u001b[35m\(.fields.module // "Unknown")\u001b[0m \(.fields.message // .message) " +
        (if .fields.request_id then "\u001b[90m[\(.fields.request_id)]\u001b[0m" else "" end) +
        (if .fields.json_data then "\n    \u001b[90m\(.fields.json_data)\u001b[0m" else "" end)
      else
        # Backend Log
        "[\(.timestamp | .[11:19])] \u001b[32mBACKEND \u001b[0m [\(.level)] \u001b[33m\(.target)\u001b[0m \(.fields.message // .message) " +
        (if .fields.request_id then "\u001b[90m[\(.fields.request_id)]\u001b[0m" else "" end)
      end
    )
  ) catch .
'
