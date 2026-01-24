# Old Version Reference (old_ref)

This directory contains snapshots of the codebase from specific Git commits, each stored in a folder named after its commit hash or version number.

## Purpose
The purpose of this folder is to provide a quick reference to older, working versions of the application. It allows for:
1. **Code Revision**: Comparing current logic with known stable logic from the past.
2. **Code Extraction**: Retrieving working copies of functions, components, or systems when current updates introduce regressions or complex bugs.
3. **Forensics**: Analyzing exactly when and how a specific behavior changed.

## Structure
- `old_ref/<version>+<build_number>_<commit_hash>/`: A full export of the project at that specific point in time. For example: `v4.3.6+7_a34c1dd`.

## Usage
Do NOT modify the files in this directory. Treat them as read-only reference material.
