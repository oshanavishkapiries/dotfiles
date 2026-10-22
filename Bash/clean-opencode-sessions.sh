#!/usr/bin/env bash

# Script to clear previous OpenCode session conversations, messages, snapshots, and logs
# Preserves the currently active conversation session if OpenCode is running.
# Preserves credentials (auth.json), settings (~/.config/opencode), plugins, and model cache.

OPENCODE_DATA_DIR="${OPENCODE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/opencode}"
OPENCODE_STATE_DIR="${OPENCODE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/opencode}"
OPENCODE_DB="$OPENCODE_DATA_DIR/opencode.db"

if [ ! -d "$OPENCODE_DATA_DIR" ]; then
    echo "OpenCode directory not found at $OPENCODE_DATA_DIR"
    exit 1
fi

# Check if an OpenCode process is running
OPENCODE_RUNNING=0
if pgrep -x "opencode" >/dev/null 2>&1; then
    OPENCODE_RUNNING=1
fi

# Detect active session ID(s): explicit --session args and the newest session
# for the working directory of each running OpenCode process.
ACTIVE_IDS=""
if [ "$OPENCODE_RUNNING" -eq 1 ] && command -v python3 >/dev/null 2>&1; then
    ACTIVE_IDS=$(python3 - "$OPENCODE_DB" << 'EOF'
import os, re, sqlite3, sys

db = sys.argv[1]
ids = set()
cwds = set()

for pid in os.listdir("/proc"):
    if not pid.isdigit():
        continue
    try:
        with open(f"/proc/{pid}/comm") as f:
            comm = f.read().strip()
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            args = f.read().split(b"\0")
    except OSError:
        continue
    if comm not in ("opencode", "bun", "node"):
        continue
    if not any(b"opencode" in a for a in args):
        continue
    for arg in args:
        for match in re.findall(rb"ses_[A-Za-z0-9]+", arg):
            ids.add(match.decode())
    try:
        cwds.add(os.readlink(f"/proc/{pid}/cwd"))
    except OSError:
        pass

if os.path.exists(db):
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=5)
    for cwd in cwds:
        row = con.execute(
            "SELECT id FROM session WHERE directory = ? ORDER BY time_updated DESC LIMIT 1",
            (cwd,),
        ).fetchone()
        if row:
            ids.add(row[0])
    if not ids:
        row = con.execute(
            "SELECT id FROM session ORDER BY time_updated DESC LIMIT 1"
        ).fetchone()
        if row:
            ids.add(row[0])
    con.close()

print("\n".join(sorted(ids)))
EOF
)
fi

if [ -n "$ACTIVE_IDS" ]; then
    echo "Detected active OpenCode session(s):"
    echo "$ACTIVE_IDS"
    echo "Preserving active session files..."
elif [ "$OPENCODE_RUNNING" -eq 1 ]; then
    echo "OpenCode process is currently running. Preserving active state..."
else
    echo "No active session detected. Cleaning all previous sessions..."
fi

count=0

# 1. Remove inactive sessions from the SQLite database (messages, parts, and
#    events cascade automatically). Keeps projects, permissions, and credentials.
if [ -f "$OPENCODE_DB" ] && command -v python3 >/dev/null 2>&1; then
    removed=$(python3 - "$OPENCODE_DB" "$ACTIVE_IDS" "$OPENCODE_RUNNING" << 'EOF'
import sqlite3, sys

db, active_raw, running = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
active = [line.strip() for line in active_raw.splitlines() if line.strip()]

con = sqlite3.connect(db, timeout=10)
con.execute("PRAGMA busy_timeout = 10000")
con.execute("PRAGMA foreign_keys = ON")

if active:
    placeholders = ",".join("?" for _ in active)
    removed = con.execute(
        f"SELECT COUNT(*) FROM session WHERE id NOT IN ({placeholders})", active
    ).fetchone()[0]
    con.execute(f"DELETE FROM session WHERE id NOT IN ({placeholders})", active)
    con.execute(
        f"DELETE FROM event_sequence WHERE aggregate_id NOT IN ({placeholders})", active
    )
else:
    removed = con.execute("SELECT COUNT(*) FROM session").fetchone()[0]
    con.execute("DELETE FROM session")
    con.execute("DELETE FROM event_sequence")

con.commit()

if not running:
    con.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    con.execute("VACUUM")

con.close()
print(removed)
EOF
)
    if [ -n "$removed" ]; then
        count=$((count + removed))
    fi
fi

# 2. Remove snapshots belonging to projects that no longer have any sessions
if [ -d "$OPENCODE_DATA_DIR/snapshot" ] && command -v python3 >/dev/null 2>&1; then
    KEEP_PROJECTS=$(python3 - "$OPENCODE_DB" << 'EOF'
import sqlite3, sys

con = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True, timeout=5)
for (project_id,) in con.execute("SELECT DISTINCT project_id FROM session"):
    if project_id and project_id != "global":
        print(project_id)
con.close()
EOF
)
    for dir in "$OPENCODE_DATA_DIR/snapshot"/*; do
        if [ -d "$dir" ]; then
            id=$(basename "$dir")
            if [ -n "$KEEP_PROJECTS" ] && echo "$KEEP_PROJECTS" | grep -qx "$id"; then
                continue
            fi
            rm -rf "$dir"
        fi
    done
fi

# 3. Clean temporary tool output and cloned repositories when nothing is running
if [ "$OPENCODE_RUNNING" -eq 0 ]; then
    rm -rf "$OPENCODE_DATA_DIR/tool-output"/* 2>/dev/null || true
    rm -rf "$OPENCODE_DATA_DIR/repos"/* 2>/dev/null || true
fi

# 4. Clean logs when no OpenCode process is running
if [ "$OPENCODE_RUNNING" -eq 0 ] && [ -d "$OPENCODE_DATA_DIR/log" ]; then
    rm -f "$OPENCODE_DATA_DIR/log"/*.log 2>/dev/null || true
fi

# 5. Clean convenience state: prompt history, file frecency, and stale locks
if [ "$OPENCODE_RUNNING" -eq 0 ] && [ -d "$OPENCODE_STATE_DIR" ]; then
    rm -f "$OPENCODE_STATE_DIR/prompt-history.jsonl"
    rm -f "$OPENCODE_STATE_DIR/frecency.jsonl"
    rm -rf "$OPENCODE_STATE_DIR/locks"/* 2>/dev/null || true
fi

# 6. Drop pinned session references that no longer exist
if [ -f "$OPENCODE_STATE_DIR/session.json" ] && [ -f "$OPENCODE_DB" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$OPENCODE_DB" "$OPENCODE_STATE_DIR/session.json" << 'EOF'
import json, sqlite3, sys

db, state_file = sys.argv[1], sys.argv[2]

try:
    with open(state_file) as f:
        state = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.exit(0)

pinned = state.get("pinned") or []
if pinned:
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=5)
    existing = {row[0] for row in con.execute("SELECT id FROM session")}
    con.close()
    state["pinned"] = [sid for sid in pinned if sid in existing]

    with open(state_file, "w") as f:
        json.dump(state, f)
EOF
fi

echo "Done! Clear complete. (Removed $count session(s))"
