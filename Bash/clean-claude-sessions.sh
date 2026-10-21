#!/usr/bin/env bash

# Script to clear previous Claude Code session conversations, transcripts, and logs
# Preserves the currently active conversation session if Claude Code is running.
# Preserves credentials, settings, and project memories.

CLAUDE_DIR="$HOME/.claude"

if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Claude directory not found at $CLAUDE_DIR"
    exit 1
fi

# Detect active conversation session ID(s) (if any process has open files under ~/.claude)
ACTIVE_IDS=""
if command -v lsof >/dev/null 2>&1; then
    ACTIVE_IDS=$(lsof +D "$CLAUDE_DIR" 2>/dev/null | awk '{print $NF}' | grep -oE '[a-f0-9-]{36}' | sort -u)
fi

if [ -n "$ACTIVE_IDS" ]; then
    echo "Detected active Claude Code session(s):"
    echo "$ACTIVE_IDS"
    echo "Preserving active session files..."
else
    echo "No active session detected. Cleaning all previous sessions..."
fi

# Helper function to check if a session ID is active
is_active() {
    local id="$1"
    [ -z "$id" ] && return 1
    if [ -n "$ACTIVE_IDS" ]; then
        echo "$ACTIVE_IDS" | grep -q "$id" && return 0
    fi
    return 1
}

count=0

# 1. Clean session transcripts and directories inside projects
if [ -d "$CLAUDE_DIR/projects" ]; then
    for proj_dir in "$CLAUDE_DIR/projects"/*; do
        if [ -d "$proj_dir" ]; then
            for item in "$proj_dir"/*; do
                if [ -e "$item" ]; then
                    filename=$(basename "$item")
                    
                    # Never delete project memory folder
                    if [ "$filename" = "memory" ]; then
                        continue
                    fi

                    # Extract UUID from filename or directory name
                    id=$(echo "$filename" | grep -oE '[a-f0-9-]{36}')

                    if [ -n "$id" ] && is_active "$id"; then
                        continue
                    fi

                    rm -rf "$item"
                    ((count++))
                fi
            done
        fi
    done
fi

# 2. Clean session environment directories
if [ -d "$CLAUDE_DIR/session-env" ]; then
    for dir in "$CLAUDE_DIR/session-env"/*; do
        if [ -d "$dir" ]; then
            id=$(basename "$dir")
            if is_active "$id"; then
                continue
            fi
            rm -rf "$dir"
        fi
    done
fi

# 3. Clean file history directories
if [ -d "$CLAUDE_DIR/file-history" ]; then
    for dir in "$CLAUDE_DIR/file-history"/*; do
        if [ -d "$dir" ]; then
            id=$(basename "$dir")
            if is_active "$id"; then
                continue
            fi
            rm -rf "$dir"
        fi
    done
fi

# 4. Clean session lock files
if [ -d "$CLAUDE_DIR/sessions" ]; then
    for item in "$CLAUDE_DIR/sessions"/*; do
        if [ -e "$item" ]; then
            id=$(basename "$item" | grep -oE '[a-f0-9-]{36}')
            if [ -n "$id" ] && is_active "$id"; then
                continue
            fi
            rm -rf "$item"
        fi
    done
fi

# 5. Clear global history log, plans, snapshots, paste cache, telemetry, and daemon logs if no active session
if [ -z "$ACTIVE_IDS" ]; then
    rm -rf "$CLAUDE_DIR/plans"/* 2>/dev/null
    rm -rf "$CLAUDE_DIR/shell-snapshots"/* 2>/dev/null
    rm -rf "$CLAUDE_DIR/paste-cache"/* 2>/dev/null
    rm -rf "$CLAUDE_DIR/telemetry"/* 2>/dev/null
    rm -rf "$CLAUDE_DIR/jobs"/* 2>/dev/null
    rm -f "$CLAUDE_DIR/history.jsonl"
    rm -f "$CLAUDE_DIR/daemon.log"
    
    # Also clean session data in ~/.config/Claude if present
    CONFIG_CLAUDE="$HOME/.config/Claude"
    if [ -d "$CONFIG_CLAUDE/claude-code-sessions" ]; then
        rm -rf "$CONFIG_CLAUDE/claude-code-sessions"/* 2>/dev/null
    fi
    if [ -d "$CONFIG_CLAUDE/local-agent-mode-sessions" ]; then
        rm -rf "$CONFIG_CLAUDE/local-agent-mode-sessions"/* 2>/dev/null
    fi
fi

echo "Done! Clear complete. (Removed $count session item(s))"
