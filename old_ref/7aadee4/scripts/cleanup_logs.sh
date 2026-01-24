#!/bin/bash
# Cleanup logs older than 9 days
find ./logs -name "*.log" -type f -mtime +9 -delete
find ./logs -name "*.txt" -type f -mtime +9 -delete
echo "Logs cleanup complete."
