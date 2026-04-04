#!/usr/bin/env bash
# Pre-session hook: checks status.md freshness and audit staleness.
# Works on Linux (bash) and Windows (Git Bash).
# On macOS, falls back to BSD date (-j -f) when GNU date (-d) is unavailable.
# Outputs warnings only -- no output if everything is fine.
#
# Note: Claude Code runs hook commands with cwd set to the project root,
# so relative paths like ".claude/status.md" resolve correctly.

STATUS_FILE=".claude/status.md"

if [ ! -f "$STATUS_FILE" ]; then
  exit 0
fi

# Extract "Last updated" date from status.md
last_updated=$(grep -m1 'Last updated:' "$STATUS_FILE" | sed 's/.*Last updated:[[:space:]]*//' | tr -d '\r')

if [ -n "$last_updated" ]; then
  # Calculate days since last update (portable: GNU date, macOS date, Git Bash)
  now=$(date +%s)
  then=$(date -d "$last_updated" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$last_updated" +%s 2>/dev/null)
  if [ -n "$then" ]; then
    days_stale=$(( (now - then) / 86400 ))
    if [ "$days_stale" -gt 14 ]; then
      echo "[autopilot] status.md is ${days_stale} days old. Consider updating it."
    fi
  fi
fi

# Check audit staleness
last_audit=$(grep -m1 'Last audit:' "$STATUS_FILE" | sed 's/.*Last audit:[[:space:]]*//' | tr -d '\r')

if [ "$last_audit" = "never" ]; then
  echo "[autopilot] No audit recorded. Consider running project-audit."
elif [ -n "$last_audit" ]; then
  now=$(date +%s)
  audit_then=$(date -d "$last_audit" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$last_audit" +%s 2>/dev/null)
  if [ -n "$audit_then" ]; then
    audit_days=$(( (now - audit_then) / 86400 ))
    if [ "$audit_days" -gt 30 ]; then
      echo "[autopilot] Last audit was ${audit_days} days ago. Consider running project-audit."
    fi
  fi
fi
