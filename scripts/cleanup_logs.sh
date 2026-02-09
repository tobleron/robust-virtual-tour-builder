#!/bin/bash
# Cleanup logs older than 6 hours
find ./logs -name "*.log" -type f -mmin +360 -delete
find ./logs -name "*.txt" -type f -mmin +360 -delete

# Function to trim large files (keep last 2000 lines)
trim_log() {
    file="$1"
    if [ -f "$file" ]; then
        # Check size (if > 5MB)
        size=$(wc -c < "$file")
        if [ "$size" -gt 5242880 ]; then
            echo "Trimming $file..."
            tail -n 2000 "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        fi
    fi
}

trim_log "frontend_log.txt"
trim_log "backend/startup_log.txt"

echo "Logs cleanup complete."
