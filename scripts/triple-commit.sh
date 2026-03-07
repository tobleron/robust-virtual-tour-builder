#!/bin/bash
set -euo pipefail

echo "❌ triple-commit has been removed."
echo "   Use one branch-aware commit at a time."
echo "   Development work belongs on 'development'."
echo "   Production-safe promotion to 'main' must be selective and pass the main release guard."
exit 1
