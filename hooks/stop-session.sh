#!/usr/bin/env bash
# Stop-session hook: reminds Claude to update project tracking files before ending.
# Uses exit code 2 to block (once), then allows stop on retry via stop_hook_active.
# Skips entirely if the project doesn't use autopilot (no .claude/status.md).
#
# Input: JSON on stdin with { stop_hook_active: bool, ... }

# Read stdin (Claude sends JSON context)
INPUT=$(cat)

# CRITICAL: Always allow stop if we already blocked once (prevents infinite loops)
# Use printf instead of echo -- echo can misinterpret leading dashes as flags
ACTIVE=$(printf '%s\n' "$INPUT" | grep -o '"stop_hook_active"[[:space:]]*:[[:space:]]*true' || true)
if [ -n "$ACTIVE" ]; then
  exit 0
fi

# Skip if this project doesn't use autopilot tracking
if [ ! -f ".claude/status.md" ]; then
  exit 0
fi

# Remind Claude to update tracking files (block once)
echo "Before ending, please update .claude/status.md with a brief summary: what was done, what's next, any blockers. Set 'Last updated' to today's date. If task statuses changed, update .claude/tasks.md. If new files or directories were created, update .claude/filemap.md." >&2
exit 2
