---
description: Run a full project audit -- checks structure, content, contradictions, efficiency, and generates a health score
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(wc:*), Bash(git:*), Bash(grep:*)
---

Run the project-audit skill (full audit mode).

If $ARGUMENTS contains "json" or "file", use that output format. Otherwise, use interactive mode.

Follow the audit process exactly: inventory scan, run all checks, generate report with health score, then ask which actions to execute.
