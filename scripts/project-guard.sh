#!/bin/bash
# Project Guard Wrapper for Rust Analyzer
# Ported from JS guard in Task 1074

set -e

# Use absolute path to project root
ROOT=$(pwd)

echo "🛡️  Starting Rust Project Guard..."

# Ensure we are in the correct directory for the analyzer
cd "$ROOT/_dev-system/analyzer"

# Run the analyzer (handles rebuilding if necessary)
# We use --quiet to keep the commit log clean
cargo run --quiet

echo "✅ Project Guard Complete."
