#!/usr/bin/env bash

# Script to clear previous Antigravity session conversations and logs
# Preserves the currently active conversation session if Antigravity is running.

ANTIGRAVITY_DIR="$HOME/.gemini/antigravity-cli"

if [ ! -d "$ANTIGRAVITY_DIR" ]; then
    echo "Antigravity directory not found at $ANTIGRAVITY_DIR"
    exit 1
fi

# Detect active conversation ID (if any process has open files under antigravity-cli)
ACTIVE_ID=""
if command -v lsof >/dev/null 2>&1; then
    ACTIVE_ID=$(lsof +D "$ANTIGRAVITY_DIR/conversations" 2>/dev/null | awk '{print $NF}' | grep -oE '[a-f0-9-]{36}' | head -n 1)
fi

if [ -n "$ACTIVE_ID" ]; then
    echo "Detected active conversation session: $ACTIVE_ID"
    echo "Preserving active session files..."
else
    echo "No active session detected. Cleaning all previous sessions..."
fi

count=0

# Clean old brain directories (artifacts, subagent logs)
if [ -d "$ANTIGRAVITY_DIR/brain" ]; then
    for dir in "$ANTIGRAVITY_DIR/brain"/*; do
        if [ -d "$dir" ]; then
            id=$(basename "$dir")
            if [ -n "$ACTIVE_ID" ] && [ "$id" = "$ACTIVE_ID" ]; then
                continue
            fi
            rm -rf "$dir"
            ((count++))
        fi
    done
fi

# Clean old conversation DB files
if [ -d "$ANTIGRAVITY_DIR/conversations" ]; then
    for file in "$ANTIGRAVITY_DIR/conversations"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ -n "$ACTIVE_ID" ] && [[ "$filename" == "$ACTIVE_ID"* ]]; then
                continue
            fi
            rm -f "$file"
        fi
    done
fi

# Clear conversation summary database and history log if no active session
if [ -z "$ACTIVE_ID" ]; then
    rm -f "$ANTIGRAVITY_DIR/conversation_summaries.db"*
    rm -f "$ANTIGRAVITY_DIR/history.jsonl"
fi

echo "Done! Clear complete."
