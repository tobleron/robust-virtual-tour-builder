#!/bin/bash

SESSIONS=(
  "16568109063450929556"
  "13115277965539912054"
  "12364672165030832933"
  "1352685524032740757"
  "14434168488717935459"
  "1083224110222862406"
  "17730740403321439996"
)

echo "Monitoring Jules sessions: ${SESSIONS[*]}"

while true; do
  STATUS_LIST=$(jules remote list --session)
  FINISHED_COUNT=0
  
  echo "--- $(date '+%H:%M:%S') ---"
  
  for ID in "${SESSIONS[@]}"; do
    # Extract status (last columns)
    LINE=$(echo "$STATUS_LIST" | grep "$ID")
    if [[ -z "$LINE" ]]; then
      echo "Session $ID: Not found (assuming finished/archived)"
      ((FINISHED_COUNT++))
      continue
    fi
    
    # Check if any active status keywords are present
    if [[ "$LINE" =~ "Planning" ]] || [[ "$LINE" =~ "In Progress" ]] || [[ "$LINE" =~ "Awaiting Plan App" ]]; then
      # Still active
      STATUS_SHORT=$(echo "$LINE" | grep -oE "(Planning|In Progress|Awaiting Plan App)")
      echo "Session $ID: $STATUS_SHORT"
    else
      # Presumed finished
      echo "Session $ID: Finished"
      ((FINISHED_COUNT++))
    fi
  done
  
  if [ "$FINISHED_COUNT" -eq "${#SESSIONS[@]}" ]; then
    echo "All Jules sessions have finished!"
    exit 0
  fi
  
  sleep 45
done
