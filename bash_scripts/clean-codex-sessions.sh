#!/usr/bin/env bash

# Script to clear previous Codex session conversations, rollouts, transcripts, and logs
# Preserves the currently active conversation session if Codex is running.
# Preserves credentials (auth.json), settings (config.toml), skills, packages, and memories.

CODEX_DIR="$HOME/.codex"

if [ ! -d "$CODEX_DIR" ]; then
    echo "Codex directory not found at $CODEX_DIR"
    exit 1
fi

# Detect active conversation session ID(s) (if any process has open files under ~/.codex)
ACTIVE_IDS=""
if command -v lsof >/dev/null 2>&1; then
    ACTIVE_IDS=$(lsof +D "$CODEX_DIR" 2>/dev/null | awk '{print $NF}' | grep -oE '[a-f0-9-]{36}' | sort -u)
fi

# Check loaded threads in daemon if present
if [ -f "$CODEX_DIR/app-server-daemon/loaded-threads.json" ]; then
    DAEMON_THREADS=$(grep -oE '[a-f0-9-]{36}' "$CODEX_DIR/app-server-daemon/loaded-threads.json" 2>/dev/null || true)
    if [ -n "$DAEMON_THREADS" ]; then
        ACTIVE_IDS=$(printf "%s\n%s\n" "$ACTIVE_IDS" "$DAEMON_THREADS" | sed '/^$/d' | sort -u)
    fi
fi

# Check if Codex process is running
CODEX_RUNNING=0
if pgrep -x "codex" >/dev/null 2>&1 || pgrep -f "codex" >/dev/null 2>&1; then
    CODEX_RUNNING=1
fi

if [ -n "$ACTIVE_IDS" ]; then
    echo "Detected active Codex session(s):"
    echo "$ACTIVE_IDS"
    echo "Preserving active session files..."
elif [ "$CODEX_RUNNING" -eq 1 ]; then
    echo "Codex process is currently running. Preserving active state..."
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

# 1. Clean rollout session files (sessions/YYYY/MM/DD/rollout-*.jsonl)
if [ -d "$CODEX_DIR/sessions" ]; then
    while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        id=$(echo "$filename" | grep -oE '[a-f0-9-]{36}' || true)
        if [ -n "$id" ] && is_active "$id"; then
            continue
        fi
        rm -f "$file"
        count=$((count + 1))
    done < <(find "$CODEX_DIR/sessions" -type f -name "*.jsonl" -print0 2>/dev/null)

    # Clean empty date directories
    find "$CODEX_DIR/sessions" -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi

# 2. Clean TUI thread reference capabilities
if [ -d "$CODEX_DIR/tui-thread-reference-capabilities" ]; then
    for dir in "$CODEX_DIR/tui-thread-reference-capabilities"/*; do
        if [ -d "$dir" ]; then
            id=$(basename "$dir" | grep -oE '[a-f0-9-]{36}' || true)
            if [ -n "$id" ] && is_active "$id"; then
                continue
            fi
            rm -rf "$dir"
            count=$((count + 1))
        fi
    done
fi

# 3. Clean shell snapshots
if [ -d "$CODEX_DIR/shell_snapshots" ]; then
    rm -rf "$CODEX_DIR/shell_snapshots"/* 2>/dev/null || true
fi

# 4. Clean inactive thread writer locks
if [ -d "$CODEX_DIR/thread-writer-locks" ]; then
    for lock in "$CODEX_DIR/thread-writer-locks"/*; do
        if [ -f "$lock" ]; then
            id=$(basename "$lock" | grep -oE '[a-f0-9-]{36}' || true)
            if [ -n "$id" ] && is_active "$id"; then
                continue
            fi
            if [ "$(basename "$lock")" = ".coordination.lock" ] && [ "$CODEX_RUNNING" -eq 1 ]; then
                continue
            fi
            rm -f "$lock"
        fi
    done
fi

# 5. Clean cache and temp files
rm -rf "$CODEX_DIR/tmp"/* 2>/dev/null || true
rm -rf "$CODEX_DIR/cache"/* 2>/dev/null || true
rm -rf "$CODEX_DIR/plugins/cache"/* 2>/dev/null || true

# 6. Update session index and history logs
if [ -z "$ACTIVE_IDS" ] && [ "$CODEX_RUNNING" -eq 0 ]; then
    rm -f "$CODEX_DIR/session_index.jsonl"
    rm -f "$CODEX_DIR/history.jsonl"
    rm -f "$CODEX_DIR/app-server-daemon"/*.log 2>/dev/null || true
else
    # Active session detected: filter history files to keep only active session records
    if [ -f "$CODEX_DIR/session_index.jsonl" ]; then
        temp_index=$(mktemp)
        while IFS= read -r line; do
            id=$(echo "$line" | grep -oE '[a-f0-9-]{36}' | head -n 1)
            if [ -n "$id" ] && is_active "$id"; then
                echo "$line" >> "$temp_index"
            fi
        done < "$CODEX_DIR/session_index.jsonl"
        mv "$temp_index" "$CODEX_DIR/session_index.jsonl"
    fi

    if [ -f "$CODEX_DIR/history.jsonl" ]; then
        temp_hist=$(mktemp)
        while IFS= read -r line; do
            id=$(echo "$line" | grep -oE '[a-f0-9-]{36}' | head -n 1)
            if [ -n "$id" ] && is_active "$id"; then
                echo "$line" >> "$temp_hist"
            fi
        done < "$CODEX_DIR/history.jsonl"
        mv "$temp_hist" "$CODEX_DIR/history.jsonl"
    fi
fi

# 7. Clean SQLite database records (preserves schema migrations and memories_*.sqlite)
if command -v python3 >/dev/null 2>&1; then
    if [ -z "$ACTIVE_IDS" ] && [ "$CODEX_RUNNING" -eq 0 ]; then
        python3 - "$CODEX_DIR" << 'EOF'
import sqlite3, sys, os

codex_dir = sys.argv[1]

def clean_db(filename, queries):
    path = os.path.join(codex_dir, filename)
    if not os.path.exists(path):
        return
    try:
        con = sqlite3.connect(path)
        con.execute("PRAGMA foreign_keys = ON")
        for q in queries:
            try:
                con.execute(q)
            except sqlite3.OperationalError:
                pass
        con.commit()
        con.execute("VACUUM")
        con.close()
    except Exception as e:
        print(f"Warning: could not clean {filename}: {e}", file=sys.stderr)

clean_db("state_5.sqlite", ["DELETE FROM threads"])
clean_db("thread_history_1.sqlite", [
    "DELETE FROM thread_turns",
    "DELETE FROM thread_items",
    "DELETE FROM thread_history_projection_state",
    "DELETE FROM thread_realtime_items"
])
clean_db("goals_1.sqlite", ["DELETE FROM thread_goals"])
clean_db("queue_1.sqlite", ["DELETE FROM queued_items", "DELETE FROM queued_thread_revisions"])
clean_db("logs_2.sqlite", ["DELETE FROM logs"])
EOF
    elif [ -n "$ACTIVE_IDS" ]; then
        python3 - "$CODEX_DIR" "$ACTIVE_IDS" << 'EOF'
import sqlite3, sys, os

codex_dir = sys.argv[1]
active_ids = [line.strip() for line in sys.argv[2].splitlines() if line.strip()]

if active_ids:
    placeholders = ",".join("?" for _ in active_ids)

    def clean_inactive(filename, table, col="thread_id"):
        path = os.path.join(codex_dir, filename)
        if not os.path.exists(path):
            return
        try:
            con = sqlite3.connect(path)
            con.execute("PRAGMA foreign_keys = ON")
            con.execute(f"DELETE FROM {table} WHERE {col} NOT IN ({placeholders})", active_ids)
            con.commit()
            con.close()
        except Exception as e:
            print(f"Warning: could not clean {filename}: {e}", file=sys.stderr)

    clean_inactive("state_5.sqlite", "threads", "id")
    clean_inactive("thread_history_1.sqlite", "thread_turns", "thread_id")
    clean_inactive("thread_history_1.sqlite", "thread_items", "thread_id")
    clean_inactive("thread_history_1.sqlite", "thread_history_projection_state", "thread_id")
    clean_inactive("thread_history_1.sqlite", "thread_realtime_items", "thread_id")
    clean_inactive("goals_1.sqlite", "thread_goals", "thread_id")
    clean_inactive("queue_1.sqlite", "queued_items", "thread_id")
    clean_inactive("queue_1.sqlite", "queued_thread_revisions", "thread_id")
    clean_inactive("logs_2.sqlite", "logs", "thread_id")
EOF
    fi
fi

echo "Done! Clear complete. (Removed $count session item(s))"
